//
//  MealScanService.swift
//  FTMFitnessNutrition
//
//

import Foundation
import Supabase

/// AI meal scanning.
///
/// Scans run server-side: the app posts the plate photo to the `scan-meal`
/// edge function, which checks Premium, enforces the free weekly limit
/// (3/week, tracked in the backend), calls the AI proxy, and refunds the
/// scan when the AI fails or finds no food. No AI credentials live in the app.
struct MealScanService {
    static let shared = MealScanService()

    /// Free weekly AI scans per user (mirrors the backend's limit).
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
        case notSignedIn
        case limitReached
        case badResponse
        case noFood
        case photoTooLarge
        case unavailable
        case tooManyRequests
        case offline
        case serverError(Int)

        /// Each message ends with a short code so testers can report exactly
        /// which failure they hit ("scan said S503").
        var errorDescription: String? {
            switch self {
            case .notSignedIn: "Sign in to use AI scanning. (S401)"
            case .limitReached: "You've used all 3 free scans this week. Go Premium for unlimited scanning."
            case .badResponse: "Couldn't read the scan result. Please try again. (S200)"
            case .noFood: "No food found in that photo. Try again with the whole plate in frame and good light. (S422)"
            case .photoTooLarge: "That photo was too large to send. Please try again. (S400)"
            case .unavailable: "AI scanning is temporarily unavailable. Please try again later. (S503)"
            case .tooManyRequests: "You're scanning quickly. Give it a moment and try again. (S429)"
            case .offline: "No connection. Check your internet and try again. (S0)"
            case .serverError(let code): "Something went wrong on our end. Please try again. (S\(code))"
            }
        }
    }

    struct ScanResponse: Decodable {
        let foods: [ScannedFood]
        let remaining: Int?
    }

    // MARK: - Scan

    /// Sends the plate photo to the server-side scanner. The server consumes
    /// a free scan before the AI call and refunds it on failure, so a
    /// successful response always contains at least one food.
    func scan(imageData: Data) async throws -> [ScannedFood] {
        let session: Session
        do {
            session = try await SupabaseService.shared.client.auth.session
        } catch {
            throw MealScanError.notSignedIn
        }

        let body: Data
        do {
            body = try JSONSerialization.data(withJSONObject: ["image": imageData.base64EncodedString()])
        } catch {
            throw MealScanError.badResponse
        }

        var request = URLRequest(
            url: URL(string: "\(Config.EXPO_PUBLIC_SUPABASE_URL)/functions/v1/scan-meal")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.EXPO_PUBLIC_SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw MealScanError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw MealScanError.unavailable }
        switch http.statusCode {
        case 200:
            let decoded = try? JSONDecoder().decode(ScanResponse.self, from: data)
            guard let foods = decoded?.foods, !foods.isEmpty else {
                throw MealScanError.badResponse
            }
            return foods
        case 400, 413: throw MealScanError.photoTooLarge
        case 401: throw MealScanError.notSignedIn
        case 403: throw MealScanError.limitReached
        case 422: throw MealScanError.noFood
        case 429: throw MealScanError.tooManyRequests
        case 503: throw MealScanError.unavailable
        default:
            print("scan-meal returned \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
            throw MealScanError.serverError(http.statusCode)
        }
    }

    // MARK: - Free scan counter

    /// Remaining free scans this week, or nil when unknown (callers then show
    /// neutral copy). The backend is the source of truth; premium members
    /// have unlimited scans and don't need this at all.
    func remainingScans() async -> Int? {
        guard SupabaseService.shared.currentUserID != nil else { return nil }
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
        return nil
    }
}
