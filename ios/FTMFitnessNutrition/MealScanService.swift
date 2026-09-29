//
//  MealScanService.swift
//  FTMFitnessNutrition
//

import Foundation
import Supabase

/// AI meal scanning.
///
/// - Vision: sends a plate photo through the Rork AI proxy and returns
///   estimated foods with calories/macros.
/// - Free-tier counter: 3 scans per week, tracked on the backend via the
///   `consume_ai_scan` RPC (so reinstalling doesn't reset it) with a local
///   fallback for signed-out users or backend hiccups.
struct MealScanService {
    static let shared = MealScanService()

    /// Free weekly AI scans per user (mirrors the backend RPC's limit).
    static let freeWeeklyScans = 3

    // MARK: - Scanned food model

    struct ScannedFood: Identifiable, Codable {
        var id = UUID()
        let name: String
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double

        enum CodingKeys: String, CodingKey {
            case name, calories, protein, carbs, fat
        }

        init(name: String, calories: Double, protein: Double, carbs: Double, fat: Double) {
            self.name = name
            self.calories = calories
            self.protein = protein
            self.carbs = carbs
            self.fat = fat
        }

        /// Tolerant decoding: models sometimes emit ints, doubles, or quoted
        /// numbers — accept all so a scan never hard-fails on formatting.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            name = (try? c.decode(String.self, forKey: .name)) ?? "Unknown item"
            calories = Self.number(in: c, forKey: .calories)
            protein = Self.number(in: c, forKey: .protein)
            carbs = Self.number(in: c, forKey: .carbs)
            fat = Self.number(in: c, forKey: .fat)
        }

        private static func number(in c: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> Double {
            if let d = try? c.decode(Double.self, forKey: key) { return d }
            if let i = try? c.decode(Int.self, forKey: key) { return Double(i) }
            if let s = try? c.decode(String.self, forKey: key) {
                return Double(s.replacingOccurrences(of: ",", with: ".")) ?? 0
            }
            return 0
        }
    }

    enum MealScanError: LocalizedError {
        case notConfigured
        case badResponse
        case unavailable
        case tooManyRequests
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .notConfigured: "AI scanning isn't available right now."
            case .badResponse: "Couldn't read that photo. Try again with the whole plate in frame."
            case .unavailable: "AI scanning is temporarily unavailable. Please try again later."
            case .tooManyRequests: "You're scanning quickly — give it a moment and try again."
            case .serverError: "Something went wrong on our end. Please try again."
            }
        }
    }

    struct ScanAllowance {
        let allowed: Bool
        let remaining: Int
    }

    // MARK: - Vision

    private static let prompt = """
        You are a nutrition estimator inside a fitness app. Look at the meal photo. \
        Identify each distinct food item and estimate its calories (kcal) and \
        protein/carbs/fat in grams for the ENTIRE visible portion. \
        Respond with ONLY a JSON array, no other text: \
        [{"name":"Grilled chicken breast","calories":280,"protein":40,"carbs":0,"fat":6}] \
        Cap the list at 8 items. If there is no food in the photo, respond with [].
        """

    func analyze(imageData: Data) async throws -> [ScannedFood] {
        let toolkit = Config.EXPO_PUBLIC_TOOLKIT_URL
        let secret = Config.EXPO_PUBLIC_RORK_TOOLKIT_SECRET_KEY
        guard !toolkit.isEmpty, !secret.isEmpty else { throw MealScanError.notConfigured }

        struct ChatResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String? }
                let message: Message
            }
            let choices: [Choice]
        }

        let body: [String: Any] = [
            "model": "openai/gpt-4o-mini",
            "messages": [[
                "role": "user",
                "content": [
                    ["type": "text", "text": Self.prompt],
                    ["type": "image_url",
                     "image_url": ["url": "data:image/jpeg;base64,\(imageData.base64EncodedString())"]]
                ]
            ]],
            "max_tokens": 1000
        ]

        var request = URLRequest(url: URL(string: "\(toolkit)/v2/vercel/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(secret)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MealScanError.badResponse }
        switch http.statusCode {
        case 200: break
        case 401, 402: throw MealScanError.unavailable
        case 429: throw MealScanError.tooManyRequests
        default: throw MealScanError.serverError(http.statusCode)
        }

        let chat = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = chat.choices.first?.message.content else { throw MealScanError.badResponse }
        let foods = try Self.parseFoods(from: content)
        guard !foods.isEmpty else { throw MealScanError.badResponse }
        return foods
    }

    /// Strips code fences / prose and decodes the first JSON array found.
    nonisolated private static func parseFoods(from content: String) throws -> [ScannedFood] {
        var text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("```") {
            text = text
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let start = text.firstIndex(of: "["),
              let end = text.lastIndex(of: "]"),
              start < end else { throw MealScanError.badResponse }
        let json = String(text[start...end])
        guard let data = json.data(using: .utf8),
              let foods = try? JSONDecoder().decode([ScannedFood].self, from: data) else {
            throw MealScanError.badResponse
        }
        return foods
    }

    // MARK: - Free scan counter

    /// Remaining free scans this week, or nil when the source is unknown
    /// (callers then show neutral copy). Backend is the source of truth when
    /// signed in; UserDefaults is the fallback.
    func remainingScans() async -> Int? {
        if SupabaseService.shared.currentUserID != nil {
            do {
                let response = try await SupabaseService.shared.client
                    .rpc("remaining_ai_scans")
                    .execute()
                if let value = try? JSONDecoder().decode(Int.self, from: response.data), value >= 0 {
                    return value
                }
            } catch {
                print("Remaining scans RPC failed: \(error.localizedDescription)")
            }
        }
        return localRemaining()
    }

    /// Consumes one scan before an AI call. Uses the backend RPC when signed
    /// in (atomic, survives reinstall) and falls back to local counting
    /// otherwise. Remaining is counted AFTER this scan.
    func consumeScan() async -> ScanAllowance {
        if SupabaseService.shared.currentUserID != nil {
            do {
                let response = try await SupabaseService.shared.client
                    .rpc("consume_ai_scan")
                    .execute()
                if let value = try? JSONDecoder().decode(Int.self, from: response.data) {
                    if value == -1 {
                        return ScanAllowance(allowed: false, remaining: 0)
                    }
                    if value >= 0 {
                        return ScanAllowance(allowed: true, remaining: value)
                    }
                    // -2 → the server saw no session; fall through to local.
                }
            } catch {
                print("Consume scan RPC failed: \(error.localizedDescription)")
            }
        }
        let remaining = localRemaining()
        guard remaining > 0 else {
            return ScanAllowance(allowed: false, remaining: 0)
        }
        recordLocalScan()
        return ScanAllowance(allowed: true, remaining: remaining - 1)
    }

    // MARK: Local fallback (UserDefaults, Monday-based week)

    private func localRemaining() -> Int {
        let defaults = UserDefaults.standard
        guard defaults.string(forKey: "tf.scanWeek") == Self.currentWeekKey() else {
            return Self.freeWeeklyScans
        }
        let used = defaults.integer(forKey: "tf.scanCount")
        return max(0, Self.freeWeeklyScans - used)
    }

    private func recordLocalScan() {
        let defaults = UserDefaults.standard
        let week = Self.currentWeekKey()
        if defaults.string(forKey: "tf.scanWeek") != week {
            defaults.set(week, forKey: "tf.scanWeek")
            defaults.set(1, forKey: "tf.scanCount")
        } else {
            defaults.set(defaults.integer(forKey: "tf.scanCount") + 1, forKey: "tf.scanCount")
        }
    }

    nonisolated private static func currentWeekKey() -> String {
        let cal = Calendar(identifier: .iso8601)
        let monday = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return SupabaseService.dateKey(monday)
    }
}
