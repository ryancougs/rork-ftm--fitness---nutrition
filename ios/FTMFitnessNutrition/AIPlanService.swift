//
//  AIPlanService.swift
//  FTMFitnessNutrition
//
//  Premium AI training plans. The app posts the plan-builder answers to the
//  `generate-plan` edge function, which confirms Premium with RevenueCat,
//  applies a daily build cap, asks the AI for a program and validates it.
//  No AI credentials live in the app.
//

import Foundation
import Supabase

struct AIPlanService {
    static let shared = AIPlanService()

    enum PlanError: LocalizedError {
        case notSignedIn
        case notPremium
        case dailyLimit
        case busy
        case unavailable
        case badResponse
        case offline
        case serverError(Int)

        var errorDescription: String? {
            switch self {
            case .notSignedIn: "Sign in to build your plan. (P401)"
            case .notPremium: "AI plans are part of Premium. If you just subscribed, give it a minute and try again. (P403)"
            case .dailyLimit: "You've rebuilt your plan a lot today. Try again tomorrow. (P429D)"
            case .busy: "The plan builder is busy. Give it a minute and try again. (P429)"
            case .unavailable: "Couldn't build your plan right now. Please try again in a few minutes. (P503)"
            case .badResponse: "Your plan came back incomplete. Please try again. (P200)"
            case .offline: "No connection. Check your internet and try again. (P0)"
            case .serverError(let code): "Something went wrong on our end. Please try again. (P\(code))"
            }
        }
    }

    /// Everything the generator needs: profile basics plus the intake answers.
    struct Request: Encodable {
        let answers: Answers

        struct Answers: Encodable {
            let goal: String
            let experience: String
            let lifestyle: String
            let equipment: String
            let weekdays: [Int]           // 1 = Sun ... 7 = Sat
            let age: Int?
            let heightCm: Double?
            let bodyweightKg: Double?
            let focusAreas: [String]
            let successLooksLike: String
            let sessionMinutes: Int
            let timeOfDay: String
            let workSchedule: String
            let otherActivities: [String]
            let otherActivitiesNote: String
            let sleep: String
            let stress: String
            let trainingHistory: String
            let equipmentItems: [String]
            let injuries: [String]
            let injuryNotes: String
            let binding: String
            let topSurgery: String
            let testosterone: String
            let style: String
            let cardio: String
            let gymComfort: String
            let likes: String
            let dislikes: String
        }
    }

    struct Response: Decodable {
        let name: String
        let summary: String
        let days: [Day]
        let notes: [String]

        struct Day: Decodable {
            let title: String
            let focus: String
            let exercises: [Ex]
        }

        struct Ex: Decodable {
            let name: String
            let muscleGroup: String
            let sets: Int
            let reps: String
            let restSeconds: Int
            let cue: String
        }
    }

    func buildPlan(profile: UserProfile, intake: PlanIntake, weekdays: [Int]) async throws -> WorkoutProgram {
        let session: Session
        do {
            session = try await SupabaseService.shared.client.auth.session
        } catch {
            throw PlanError.notSignedIn
        }

        let payload = Request(answers: .init(
            goal: profile.goal.rawValue,
            experience: profile.experience.rawValue,
            lifestyle: profile.lifestyle.rawValue,
            equipment: profile.equipment.rawValue,
            weekdays: weekdays,
            age: profile.age,
            heightCm: profile.heightCm,
            bodyweightKg: profile.bodyweightKg,
            focusAreas: intake.focusAreas,
            successLooksLike: intake.successLooksLike,
            sessionMinutes: intake.sessionMinutes,
            timeOfDay: intake.timeOfDay,
            workSchedule: intake.workSchedule,
            otherActivities: intake.otherActivities,
            otherActivitiesNote: intake.otherActivitiesNote,
            sleep: intake.sleep,
            stress: intake.stress,
            trainingHistory: intake.trainingHistory,
            equipmentItems: intake.equipmentItems,
            injuries: intake.injuries,
            injuryNotes: intake.injuryNotes,
            binding: intake.binding,
            topSurgery: intake.topSurgery,
            testosterone: intake.testosterone,
            style: intake.style,
            cardio: intake.cardio,
            gymComfort: intake.gymComfort,
            likes: intake.likes,
            dislikes: intake.dislikes
        ))

        var request = URLRequest(
            url: URL(string: "\(Config.EXPO_PUBLIC_SUPABASE_URL)/functions/v1/generate-plan")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 140
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.EXPO_PUBLIC_SUPABASE_ANON_KEY, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw PlanError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw PlanError.unavailable }

        switch http.statusCode {
        case 200:
            guard let plan = try? JSONDecoder().decode(Response.self, from: data),
                  plan.days.count == weekdays.count,
                  plan.days.allSatisfy({ !$0.exercises.isEmpty }) else {
                throw PlanError.badResponse
            }
            return program(from: plan, profile: profile)
        case 401: throw PlanError.notSignedIn
        case 403: throw PlanError.notPremium
        case 429:
            let body = String(data: data, encoding: .utf8) ?? ""
            throw body.contains("daily_limit") ? PlanError.dailyLimit : PlanError.busy
        case 503: throw PlanError.unavailable
        default:
            print("generate-plan returned \(http.statusCode): \(String(data: data, encoding: .utf8) ?? "")")
            throw PlanError.serverError(http.statusCode)
        }
    }

    private func program(from plan: Response, profile: UserProfile) -> WorkoutProgram {
        let days = plan.days.map { day in
            WorkoutDay(
                title: day.title,
                focus: day.focus,
                exercises: day.exercises.map { ex in
                    Exercise(name: ex.name, muscleGroup: ex.muscleGroup, sets: ex.sets,
                             reps: ex.reps, restSeconds: ex.restSeconds, description: ex.cue)
                }
            )
        }
        return WorkoutProgram(
            name: plan.name,
            summary: plan.summary,
            level: profile.experience,
            goal: profile.goal,
            daysPerWeek: days.count,
            days: days,
            coachNotes: plan.notes
        )
    }
}
