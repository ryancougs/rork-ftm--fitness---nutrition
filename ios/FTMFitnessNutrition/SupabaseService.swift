//
//  SupabaseService.swift
//  FTMFitnessNutrition
//
//  Native Supabase Auth (email/password). The SDK owns the session
//  storage — no manual token handling in this mode.
//

import Foundation
import Supabase

/// Thin service layer over the Supabase client: auth, profile sync,
/// check-in sync, and account deletion. All errors are surfaced to callers
/// for user-friendly handling.
@MainActor
@Observable
final class SupabaseService {

    static let shared = SupabaseService()

    let client: SupabaseClient

    /// The signed-in user's UUID, nil when signed out.
    private(set) var currentUserID: String?

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: Config.EXPO_PUBLIC_SUPABASE_URL)!,
            supabaseKey: Config.EXPO_PUBLIC_SUPABASE_ANON_KEY
        )
    }

    // MARK: - Auth

    struct AuthResult {
        let userID: String
        let email: String?
        let needsEmailConfirmation: Bool
    }

    enum AuthError: LocalizedError {
        case emailConfirmationRequired
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .emailConfirmationRequired:
                "Account created — check your email to confirm it, then log in."
            case .invalidResponse:
                "The server didn't respond correctly. Please try again."
            }
        }
    }

    func signUp(email: String, password: String) async throws -> AuthResult {
        let response = try await client.auth.signUp(email: email, password: password)
        if let session = response.session {
            currentUserID = session.user.id.uuidString
            return AuthResult(userID: session.user.id.uuidString,
                              email: session.user.email,
                              needsEmailConfirmation: false)
        }
        // No session returned → email confirmation is enabled on the project.
        let user = response.user
        return AuthResult(userID: user.id.uuidString,
                          email: user.email,
                          needsEmailConfirmation: true)
    }

    func signIn(email: String, password: String) async throws -> AuthResult {
        let session = try await client.auth.signIn(email: email, password: password)
        currentUserID = session.user.id.uuidString
        return AuthResult(userID: session.user.id.uuidString,
                          email: session.user.email,
                          needsEmailConfirmation: false)
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
        } catch {
            print("Supabase signOut failed: \(error)")
        }
        currentUserID = nil
    }

    /// Restore a persisted session at launch. True when the user is signed in.
    func restoreSession() async -> Bool {
        do {
            let session = try await client.auth.session
            currentUserID = session.user.id.uuidString
            return true
        } catch {
            currentUserID = nil
            return false
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }

    // MARK: - Profile sync

    nonisolated struct ProfileUpsert: Encodable, Sendable {
        let id: String
        let email: String
        let name: String
        let goal: String
        let experience: String
        let lifestyle: String
        let equipment: String
        let daysPerWeek: Int
        let bodyweightKg: Double?
        let heightCm: Double?
        let age: Int?
        let targetCalories: Int
        let targetProtein: Int
        let targetCarbs: Int
        let targetFat: Int
        let updatedAt: Date

        enum CodingKeys: String, CodingKey {
            case id, email, name, goal, experience, lifestyle, equipment
            case daysPerWeek = "days_per_week"
            case bodyweightKg = "bodyweight_kg"
            case heightCm = "height_cm"
            case age
            case targetCalories = "target_calories"
            case targetProtein = "target_protein"
            case targetCarbs = "target_carbs"
            case targetFat = "target_fat"
            case updatedAt = "updated_at"
        }
    }

    nonisolated struct ProfileRow: Decodable, Sendable {
        let id: String
        let email: String?
        let name: String?
        let goal: String?
        let experience: String?
        let lifestyle: String?
        let equipment: String?
        let daysPerWeek: Int?
        let bodyweightKg: Double?
        let heightCm: Double?
        let age: Int?
        let targetCalories: Int?
        let targetProtein: Int?
        let targetCarbs: Int?
        let targetFat: Int?

        enum CodingKeys: String, CodingKey {
            case id, email, name, goal, experience, lifestyle, equipment
            case daysPerWeek = "days_per_week"
            case bodyweightKg = "bodyweight_kg"
            case heightCm = "height_cm"
            case age
            case targetCalories = "target_calories"
            case targetProtein = "target_protein"
            case targetCarbs = "target_carbs"
            case targetFat = "target_fat"
        }
    }

    /// Push the local profile to the cloud. Fire-and-forget best effort:
    /// local data stays the source of truth on device.
    func syncProfile(_ profile: UserProfile) async {
        guard let userID = currentUserID else { return }
        let payload = ProfileUpsert(
            id: userID,
            email: profile.email,
            name: profile.name,
            goal: profile.goal.rawValue,
            experience: profile.experience.rawValue,
            lifestyle: profile.lifestyle.rawValue,
            equipment: profile.equipment.rawValue,
            daysPerWeek: profile.daysPerWeek,
            bodyweightKg: profile.bodyweightKg,
            heightCm: profile.heightCm,
            age: profile.age,
            targetCalories: profile.targetCalories,
            targetProtein: profile.targetProtein,
            targetCarbs: profile.targetCarbs,
            targetFat: profile.targetFat,
            updatedAt: Date()
        )
        do {
            try await client.from("profiles").upsert(payload).execute()
        } catch {
            print("Profile sync failed: \(error)")
        }
    }

    /// Fetch the cloud profile row. Nil when no signed-in user or no row.
    func fetchProfile() async -> ProfileRow? {
        guard let userID = currentUserID else { return nil }
        do {
            let rows: [ProfileRow] = try await client
                .from("profiles")
                .select()
                .eq("id", value: userID)
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            print("Profile fetch failed: \(error)")
            return nil
        }
    }

    // MARK: - Check-in sync

    nonisolated struct CheckInUpsert: Encodable, Sendable {
        let userId: String
        let weekStart: String
        let energy: Int
        let sleep: Int
        let stress: Int
        let hunger: Int
        let workoutAdherence: String
        let progressFeeling: String
        let notes: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case weekStart = "week_start"
            case energy, sleep, stress, hunger, notes
            case workoutAdherence = "workout_adherence"
            case progressFeeling = "progress_feeling"
        }
    }

    nonisolated struct CheckInRow: Decodable, Sendable {
        let weekStart: String
        let energy: Int
        let sleep: Int
        let stress: Int
        let hunger: Int
        let workoutAdherence: String
        let progressFeeling: String
        let notes: String

        enum CodingKeys: String, CodingKey {
            case weekStart = "week_start"
            case energy, sleep, stress, hunger, notes
            case workoutAdherence = "workout_adherence"
            case progressFeeling = "progress_feeling"
        }
    }

    func syncCheckIn(_ checkIn: WeeklyCheckIn) async {
        guard let userID = currentUserID else { return }
        let payload = CheckInUpsert(
            userId: userID,
            weekStart: Self.dateKey(checkIn.weekStart),
            energy: checkIn.energy,
            sleep: checkIn.sleep,
            stress: checkIn.stress,
            hunger: checkIn.hunger,
            workoutAdherence: checkIn.workoutAdherence.rawValue,
            progressFeeling: checkIn.progressFeeling.rawValue,
            notes: checkIn.notes
        )
        do {
            // Replace the server row for this week (delete + insert avoids
            // needing the server-side row id for the upsert conflict target).
            try await client.from("check_ins")
                .delete()
                .eq("user_id", value: userID)
                .eq("week_start", value: payload.weekStart)
                .execute()
            try await client.from("check_ins").insert(payload).execute()
        } catch {
            print("Check-in sync failed: \(error)")
        }
    }

    func fetchCheckIns() async -> [CheckInRow] {
        guard let userID = currentUserID else { return [] }
        do {
            return try await client
                .from("check_ins")
                .select()
                .eq("user_id", value: userID)
                .order("week_start", ascending: false)
                .execute()
                .value
        } catch {
            print("Check-in fetch failed: \(error)")
            return []
        }
    }

    // MARK: - Community

    nonisolated struct CommunityPost: Codable, Sendable, Identifiable {
        let id: UUID
        let userId: String
        let displayName: String
        let body: String
        let createdAt: Date

        enum CodingKeys: String, CodingKey {
            case id
            case userId = "user_id"
            case displayName = "display_name"
            case body
            case createdAt = "created_at"
        }
    }

    nonisolated struct CommunityPostInsert: Encodable, Sendable {
        let userId: String
        let displayName: String
        let body: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case displayName = "display_name"
            case body
        }
    }

    nonisolated struct CommunityReportInsert: Encodable, Sendable {
        let postId: UUID
        let reporterId: String
        let reason: String

        enum CodingKeys: String, CodingKey {
            case postId = "post_id"
            case reporterId = "reporter_id"
            case reason
        }
    }

    enum ServiceError: LocalizedError {
        case notSignedIn

        var errorDescription: String? {
            switch self {
            case .notSignedIn: "You need to be signed in to do that."
            }
        }
    }

    func fetchCommunityPosts(limit: Int = 50) async throws -> [CommunityPost] {
        try await client
            .from("community_posts")
            .select()
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value
    }

    func createCommunityPost(displayName: String, body: String) async throws {
        guard let userID = currentUserID else { throw ServiceError.notSignedIn }
        try await client.from("community_posts")
            .insert(CommunityPostInsert(userId: userID, displayName: displayName, body: body))
            .execute()
    }

    func deleteCommunityPost(id: UUID) async throws {
        try await client.from("community_posts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    func reportCommunityPost(postId: UUID, reason: String) async throws {
        guard let userID = currentUserID else { throw ServiceError.notSignedIn }
        try await client.from("community_reports")
            .insert(CommunityReportInsert(postId: postId, reporterId: userID, reason: reason))
            .execute()
    }

    // MARK: - Account deletion

    /// Deletes the account server-side (auth user + all data via cascade).
    /// The caller is responsible for wiping local state afterwards.
    func deleteAccount() async throws {
        try await client.functions.invoke("delete-account", options: .init(method: .post))
    }

    // MARK: - Helpers

    nonisolated static func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: date)
    }

    nonisolated static func date(fromKey key: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.date(from: key)
    }
}

// MARK: - Friendly auth error messages

extension SupabaseService {
    /// Maps raw Supabase/auth errors to plain-language messages that match
    /// FTMFitnessNutrition's supportive voice. Never exposes internals.
    nonisolated static func friendlyMessage(for error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        let raw = error.localizedDescription.lowercased()
        if raw.contains("invalid login credentials") {
            return "That email and password don't match. Double-check for typos, or reset your password below."
        }
        if raw.contains("email not confirmed") {
            return "Your email isn't confirmed yet — check your inbox (and spam folder) for the confirmation link."
        }
        if raw.contains("already registered") || raw.contains("already been registered") {
            return "An account with that email already exists. Try logging in instead."
        }
        if raw.contains("at least") && raw.contains("password") {
            return "That password is too easy to guess — use at least 6 characters."
        }
        if raw.contains("rate limit") {
            return "Too many attempts in a row. Give it a minute and try again."
        }
        if raw.contains("network") || raw.contains("connection") || raw.contains("offline") {
            return "Can't reach the server. Check your internet connection and try again."
        }
        print("Unmapped auth error: \(error)")
        return "Something went wrong on our end. Please try again — your data is safe."
    }
}
