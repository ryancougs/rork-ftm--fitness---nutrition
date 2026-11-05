//
//  PlanIntake.swift
//  FTMFitnessNutrition
//
//  The Premium plan builder's answers: everything about someone's life that
//  should shape their training. Stored on the phone only. Sent to the
//  generate-plan function (and from there to the AI) only when the person
//  taps "Build my plan", after agreeing to the AI disclosure.
//

import Foundation

struct PlanIntake: Codable, Equatable {
    // Goal
    var focusAreas: [String] = []
    var successLooksLike: String = ""

    // Schedule
    var sessionMinutes: Int = 60
    var timeOfDay: String = Option.timeOfDay[0]
    var workSchedule: String = Option.workSchedule[0]

    // Life
    var otherActivities: [String] = []
    var otherActivitiesNote: String = ""
    var sleep: String = Option.sleep[2]
    var stress: String = Option.stress[1]

    // Experience & equipment
    var trainingHistory: String = Option.trainingHistory[1]
    var equipmentItems: [String] = []

    // Body & safety (all optional, "Prefer not to say" by default)
    var injuries: [String] = []
    var injuryNotes: String = ""
    var binding: String = Option.preferNot
    var topSurgery: String = Option.preferNot
    var testosterone: String = Option.preferNot

    // Preferences
    var style: String = Option.style[2]
    var cardio: String = Option.cardio[1]
    var gymComfort: String = Option.gymComfort[0]
    var likes: String = ""
    var dislikes: String = ""

    init() {}

    /// Tolerant decoding so adding questions later never wipes saved answers.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = PlanIntake()
        focusAreas = (try? c.decode([String].self, forKey: .focusAreas)) ?? d.focusAreas
        successLooksLike = (try? c.decode(String.self, forKey: .successLooksLike)) ?? d.successLooksLike
        sessionMinutes = (try? c.decode(Int.self, forKey: .sessionMinutes)) ?? d.sessionMinutes
        timeOfDay = (try? c.decode(String.self, forKey: .timeOfDay)) ?? d.timeOfDay
        workSchedule = (try? c.decode(String.self, forKey: .workSchedule)) ?? d.workSchedule
        otherActivities = (try? c.decode([String].self, forKey: .otherActivities)) ?? d.otherActivities
        otherActivitiesNote = (try? c.decode(String.self, forKey: .otherActivitiesNote)) ?? d.otherActivitiesNote
        sleep = (try? c.decode(String.self, forKey: .sleep)) ?? d.sleep
        stress = (try? c.decode(String.self, forKey: .stress)) ?? d.stress
        trainingHistory = (try? c.decode(String.self, forKey: .trainingHistory)) ?? d.trainingHistory
        equipmentItems = (try? c.decode([String].self, forKey: .equipmentItems)) ?? d.equipmentItems
        injuries = (try? c.decode([String].self, forKey: .injuries)) ?? d.injuries
        injuryNotes = (try? c.decode(String.self, forKey: .injuryNotes)) ?? d.injuryNotes
        binding = (try? c.decode(String.self, forKey: .binding)) ?? d.binding
        topSurgery = (try? c.decode(String.self, forKey: .topSurgery)) ?? d.topSurgery
        testosterone = (try? c.decode(String.self, forKey: .testosterone)) ?? d.testosterone
        style = (try? c.decode(String.self, forKey: .style)) ?? d.style
        cardio = (try? c.decode(String.self, forKey: .cardio)) ?? d.cardio
        gymComfort = (try? c.decode(String.self, forKey: .gymComfort)) ?? d.gymComfort
        likes = (try? c.decode(String.self, forKey: .likes)) ?? d.likes
        dislikes = (try? c.decode(String.self, forKey: .dislikes)) ?? d.dislikes
    }

    /// Answer choices. Plain strings so the AI reads them as written.
    enum Option {
        static let preferNot = "Prefer not to say"

        static let focusAreas = [
            "Broader shoulders", "Wider back", "Chest", "Arms", "Legs & glutes",
            "Core", "Getting stronger", "Conditioning", "Posture", "Sport performance",
        ]
        static let sessionMinutes = [30, 45, 60, 75, 90]
        static let timeOfDay = ["It varies", "Early morning", "Midday", "Evening", "Late night"]
        static let workSchedule = [
            "Regular daytime hours", "Early starts", "Rotating shifts",
            "Night shifts", "Irregular or on call", "Student", "Not working right now",
        ]
        static let otherActivities = [
            "Lots of walking", "Running", "Cycling", "Team sports", "Martial arts",
            "Climbing", "Hiking", "Yoga or mobility", "Swimming",
        ]
        static let sleep = ["Under 5 hours", "5 to 6 hours", "6 to 7 hours", "7 to 8 hours", "8+ hours"]
        static let stress = ["Low", "Moderate", "High", "Very high right now"]
        static let trainingHistory = [
            "Never really trained", "Under 6 months", "6 months to 2 years",
            "2 to 5 years", "5+ years", "Coming back after a long break",
        ]
        static let equipmentItems = [
            "Barbell & plates", "Squat rack", "Flat/incline bench", "Dumbbells",
            "Adjustable dumbbells", "Cable machine", "Leg press", "Selectorized machines",
            "Smith machine", "Pull-up bar", "Kettlebells", "Resistance bands",
            "Treadmill / bike / rower",
        ]
        static let injuries = [
            "Shoulder", "Lower back", "Knee", "Hip", "Wrist or elbow", "Neck", "Ankle or foot",
        ]
        static let binding = ["I don't bind", "I bind sometimes", "I bind most days", preferNot]
        static let topSurgery = [
            "Not planning it", "Planning or on a waitlist", "Recovering (under 3 months)",
            "Recovering (3 to 6 months)", "Fully healed", preferNot,
        ]
        static let testosterone = [
            "Not on testosterone", "Started in the last year", "On it for over a year", preferNot,
        ]
        static let style = ["Get stronger (heavier, fewer reps)", "Build muscle (moderate weight, more reps)", "A mix of both", "Athletic and functional"]
        static let cardio = ["As little as possible", "A little, short and simple", "Regular cardio, I enjoy it"]
        static let gymComfort = [
            "I'm comfortable anywhere in the gym",
            "I prefer a quieter setup (one station, less floor traffic)",
        ]
    }
}
