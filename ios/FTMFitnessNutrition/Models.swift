//
//  Models.swift
//  FTMFitnessNutrition
//

import Foundation

enum FitnessGoal: String, CaseIterable, Identifiable, Codable {
    case buildMuscle = "Build Muscle"
    case loseFat = "Lose Fat"
    case recomp = "Recomp"
    case maintain = "Maintain"

    var id: String { rawValue }
    var blurb: String {
        switch self {
        case .buildMuscle: "Hypertrophy-focused training and a protein-rich surplus."
        case .loseFat: "Training plus a gentle deficit to lose fat, keep strength."
        case .recomp: "Build muscle and lose fat simultaneously — steady and patient."
        case .maintain: "Keep your current physique and performance, feel great."
        }
    }
    var emoji: String {
        switch self {
        case .buildMuscle: "💪"
        case .loseFat: "🔥"
        case .recomp: "⚖️"
        case .maintain: "🧘"
        }
    }
}

enum ExperienceLevel: String, CaseIterable, Identifiable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"

    var id: String { rawValue }
    var blurb: String {
        switch self {
        case .beginner: "New to lifting or returning after a long break."
        case .intermediate: "Consistent for 6+ months, comfortable with main lifts."
        case .advanced: "Years of consistent training, knows your way around a barbell."
        }
    }
}

/// Day-to-day activity outside the gym — nudges the calorie math.
enum Lifestyle: String, CaseIterable, Identifiable, Codable {
    case mostlySitting = "Mostly sitting"
    case onMyFeet = "On my feet"
    case physicalJob = "Physical job"

    var id: String { rawValue }
    var blurb: String {
        switch self {
        case .mostlySitting: "Desk job, studying, or mostly at home."
        case .onMyFeet: "Retail, caregiving, on the move most of the day."
        case .physicalJob: "Construction, warehouse, deliveries — paid to move."
        }
    }
    var emoji: String {
        switch self {
        case .mostlySitting: "🪑"
        case .onMyFeet: "🚶"
        case .physicalJob: "🧰"
        }
    }
}

/// Training equipment access — shapes exercise selection.
enum EquipmentAccess: String, CaseIterable, Identifiable, Codable {
    case fullGym = "Full gym"
    case homeDumbbells = "Dumbbells at home"
    case bodyweightOnly = "Bodyweight only"

    var id: String { rawValue }
    var blurb: String {
        switch self {
        case .fullGym: "Barbells, machines, cables — the works."
        case .homeDumbbells: "Dumbbells (and maybe a bench) at home."
        case .bodyweightOnly: "No equipment — just me and the floor."
        }
    }
    var emoji: String {
        switch self {
        case .fullGym: "🏋️"
        case .homeDumbbells: "🏠"
        case .bodyweightOnly: "🤸"
        }
    }
}

struct UserProfile: Codable, Equatable {
    var name: String = ""
    var email: String = ""
    var goal: FitnessGoal = .buildMuscle
    var experience: ExperienceLevel = .beginner
    var daysPerWeek: Int = 4
    var lifestyle: Lifestyle = .mostlySitting
    var equipment: EquipmentAccess = .fullGym
    var bodyweightKg: Double? = nil
    var heightCm: Double? = nil
    var age: Int? = nil
    var targetCalories: Int = 2200
    var targetProtein: Int = 160
    var targetCarbs: Int = 240
    var targetFat: Int = 70

    init() {}

    /// Tolerant decoding: older saved states may lack newer fields — every
    /// key falls back to its default instead of failing the whole decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        email = try c.decodeIfPresent(String.self, forKey: .email) ?? ""
        goal = try c.decodeIfPresent(FitnessGoal.self, forKey: .goal) ?? .buildMuscle
        experience = try c.decodeIfPresent(ExperienceLevel.self, forKey: .experience) ?? .beginner
        daysPerWeek = try c.decodeIfPresent(Int.self, forKey: .daysPerWeek) ?? 4
        lifestyle = try c.decodeIfPresent(Lifestyle.self, forKey: .lifestyle) ?? .mostlySitting
        equipment = try c.decodeIfPresent(EquipmentAccess.self, forKey: .equipment) ?? .fullGym
        bodyweightKg = try c.decodeIfPresent(Double.self, forKey: .bodyweightKg)
        heightCm = try c.decodeIfPresent(Double.self, forKey: .heightCm)
        age = try c.decodeIfPresent(Int.self, forKey: .age)
        targetCalories = try c.decodeIfPresent(Int.self, forKey: .targetCalories) ?? 2200
        targetProtein = try c.decodeIfPresent(Int.self, forKey: .targetProtein) ?? 160
        targetCarbs = try c.decodeIfPresent(Int.self, forKey: .targetCarbs) ?? 240
        targetFat = try c.decodeIfPresent(Int.self, forKey: .targetFat) ?? 70
    }

    /// Compute default targets from the plan engine (stats-aware) when the
    /// user hasn't customized them. Falls back to population defaults if
    /// the engine is unavailable.
    mutating func applyDefaultTargets() {
        let t = PlanEngine.targets(for: self)
        targetCalories = t.calories
        targetProtein = t.protein
        targetCarbs = t.carbs
        targetFat = t.fat
    }
}

// MARK: - Workout models

struct Exercise: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var muscleGroup: String
    var sets: Int
    var reps: String          // e.g. "8-10" or "AMRAP"
    var restSeconds: Int
    var description: String

    nonisolated init(id: UUID = UUID(), name: String, muscleGroup: String, sets: Int,
         reps: String, restSeconds: Int, description: String) {
        self.id = id; self.name = name; self.muscleGroup = muscleGroup
        self.sets = sets; self.reps = reps; self.restSeconds = restSeconds
        self.description = description
    }
}

struct WorkoutDay: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String          // "Day 1 — Push"
    var focus: String          // "Chest / Shoulders / Triceps"
    var exercises: [Exercise]

    init(id: UUID = UUID(), title: String, focus: String, exercises: [Exercise]) {
        self.id = id; self.title = title; self.focus = focus
        self.exercises = exercises
    }
}

struct WorkoutProgram: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var summary: String
    var level: ExperienceLevel
    var goal: FitnessGoal
    var daysPerWeek: Int
    var days: [WorkoutDay]

    init(id: UUID = UUID(), name: String, summary: String, level: ExperienceLevel,
         goal: FitnessGoal, daysPerWeek: Int, days: [WorkoutDay]) {
        self.id = id; self.name = name; self.summary = summary; self.level = level
        self.goal = goal; self.daysPerWeek = daysPerWeek; self.days = days
    }
}

// MARK: - Set logging

struct LoggedSet: Identifiable, Codable, Equatable {
    let id: UUID
    var weight: Double         // kg
    var reps: Int

    init(id: UUID = UUID(), weight: Double, reps: Int) {
        self.id = id; self.weight = weight; self.reps = reps
    }
}

/// Per-exercise log for today's date (keyed by exercise id + date string).
struct ExerciseLog: Codable, Equatable {
    var sets: [LoggedSet]
}

// MARK: - Nutrition models

struct FoodItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var serving: String        // "1 cup (240ml)", "100 g", "1 serving (58 g)" etc.
    var calories: Int          // base values: per `serving` below
    var protein: Int
    var carbs: Int
    var fat: Int
    var brand: String?         // branded products (Open Food Facts)
    var barcode: String?
    var source: FoodSource
    // Nutrition per 100 g for weighable foods (remote sources, local "100 g" rows).
    var kcalPer100g: Double?
    var proteinPer100g: Double?
    var carbsPer100g: Double?
    var fatPer100g: Double?
    var servingGrams: Double?  // grams in one listed serving, when known

    init(id: UUID = UUID(), name: String, serving: String,
         calories: Int, protein: Int, carbs: Int, fat: Int,
         brand: String? = nil, barcode: String? = nil, source: FoodSource = .local,
         kcalPer100g: Double? = nil, proteinPer100g: Double? = nil,
         carbsPer100g: Double? = nil, fatPer100g: Double? = nil,
         servingGrams: Double? = nil) {
        self.id = id; self.name = name; self.serving = serving
        self.calories = calories; self.protein = protein
        self.carbs = carbs; self.fat = fat
        self.brand = brand; self.barcode = barcode; self.source = source
        self.kcalPer100g = kcalPer100g; self.proteinPer100g = proteinPer100g
        self.carbsPer100g = carbsPer100g; self.fatPer100g = fatPer100g
        self.servingGrams = servingGrams
    }

    /// Tolerant decoding: foods persisted before the remote-search round lack
    /// every extension field — they fall back to plain local rows.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        serving = try c.decode(String.self, forKey: .serving)
        calories = try c.decode(Int.self, forKey: .calories)
        protein = try c.decode(Int.self, forKey: .protein)
        carbs = try c.decode(Int.self, forKey: .carbs)
        fat = try c.decode(Int.self, forKey: .fat)
        brand = try c.decodeIfPresent(String.self, forKey: .brand)
        barcode = try c.decodeIfPresent(String.self, forKey: .barcode)
        source = try c.decodeIfPresent(FoodSource.self, forKey: .source) ?? .local
        kcalPer100g = try c.decodeIfPresent(Double.self, forKey: .kcalPer100g)
        proteinPer100g = try c.decodeIfPresent(Double.self, forKey: .proteinPer100g)
        carbsPer100g = try c.decodeIfPresent(Double.self, forKey: .carbsPer100g)
        fatPer100g = try c.decodeIfPresent(Double.self, forKey: .fatPer100g)
        servingGrams = try c.decodeIfPresent(Double.self, forKey: .servingGrams)
    }

    var isPer100g: Bool { kcalPer100g != nil }

    /// "Oikos — Oikos Greek" style display for branded products.
    var displayName: String {
        guard let brand, !brand.isEmpty else { return name }
        return "\(name) — \(brand)"
    }

    /// Stable identity for favorites/recents: UUIDs are re-randomized every
    /// parse, so match on barcode/brand/name.
    var stableKey: String {
        [barcode ?? "", brand?.lowercased() ?? "", name.lowercased()]
            .joined(separator: "|")
    }

    /// Aweighable portion choices for the serving picker. Local listed-serving
    /// foods only offer the listed serving; per-100g foods also offer grams
    /// and ounces. Cups/pieces surface as the product's listed serving when
    /// the source defines one.
    var portionOptions: [PortionOption] {
        var options: [PortionOption] = []
        if let grams = servingGrams, grams > 0 {
            options.append(PortionOption(id: "listed", label: "Serving (\(Int(grams)) g)", grams: grams))
        } else if !isPer100g {
            options.append(PortionOption(id: "listed", label: serving, grams: nil))
        }
        if isPer100g {
            options.append(PortionOption(id: "100g", label: "100 g", grams: 100))
            options.append(PortionOption(id: "oz", label: "1 oz", grams: 28.35))
            if options.isEmpty || options.first?.id != "listed" {
                options.insert(PortionOption(id: "listed", label: serving, grams: servingGrams), at: 0)
            }
        }
        return options
    }
}

/// One choice in the serving picker: a named unit and its gram weight
/// (nil for listed servings of local foods, which scale by count only).
struct PortionOption: Hashable {
    let id: String
    let label: String
    let grams: Double?
}

enum FoodSource: String, Codable, Equatable {
    case local
    case openFoodFacts
    case usda
    case custom

    /// Short badge shown on search rows.
    var badge: String? {
        switch self {
        case .local: nil
        case .openFoodFacts: "OFF"
        case .usda: "USDA"
        case .custom: "Custom"
        }
    }
}

enum MealType: String, CaseIterable, Identifiable, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .breakfast: "🌅"
        case .lunch: "☀️"
        case .dinner: "🌙"
        case .snack: "🍎"
        }
    }
}

struct LoggedFood: Identifiable, Codable, Equatable {
    let id: UUID
    var food: FoodItem
    var servings: Double
    var meal: MealType
    /// Human portion label for weighable entries, e.g. "150 g" or "2 oz".
    var portionLabel: String?

    init(id: UUID = UUID(), food: FoodItem, servings: Double, meal: MealType,
         portionLabel: String? = nil) {
        self.id = id; self.food = food; self.servings = servings; self.meal = meal
        self.portionLabel = portionLabel
    }

    var calories: Double { Double(food.calories) * servings }
    var protein: Double { Double(food.protein) * servings }
    var carbs: Double { Double(food.carbs) * servings }
    var fat: Double { Double(food.fat) * servings }
}

// MARK: - Weekly check-in

enum WorkoutAdherence: String, CaseIterable, Identifiable, Codable {
    case all = "All of them"
    case most = "Most of them"
    case some = "Some of them"
    case none = "None"
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .all: "💪"
        case .most: "👍"
        case .some: "🙂"
        case .none: "🛌"
        }
    }
}

enum ProgressFeeling: String, CaseIterable, Identifiable, Codable {
    case great = "Great"
    case good = "Good"
    case neutral = "Neutral"
    case frustrated = "Frustrated"
    case reallyStruggling = "Really struggling"
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .great: "🟢"
        case .good: "🟩"
        case .neutral: "🟡"
        case .frustrated: "🟠"
        case .reallyStruggling: "🔴"
        }
    }
}

struct WeeklyCheckIn: Identifiable, Codable, Equatable {
    let id: UUID
    var weekStart: Date          // Monday of the week
    var energy: Int               // 1-10
    var sleep: Int                // 1-10
    var stress: Int               // 1-10 (10 = high stress)
    var hunger: Int              // 1-10 (10 = very hungry)
    var workoutAdherence: WorkoutAdherence
    var progressFeeling: ProgressFeeling
    var notes: String             // open text
    var frontPhoto: Data? = nil   // mandatory front-on progress photo
    var sidePhoto: Data? = nil    // optional
    var backPhoto: Data? = nil    // optional
    var posePhoto: Data? = nil    // optional favorite pose

    init(id: UUID = UUID(), weekStart: Date, energy: Int, sleep: Int,
         stress: Int, hunger: Int, workoutAdherence: WorkoutAdherence,
         progressFeeling: ProgressFeeling, notes: String,
         frontPhoto: Data? = nil, sidePhoto: Data? = nil,
         backPhoto: Data? = nil, posePhoto: Data? = nil) {
        self.id = id; self.weekStart = weekStart
        self.energy = energy; self.sleep = sleep
        self.stress = stress; self.hunger = hunger
        self.workoutAdherence = workoutAdherence
        self.progressFeeling = progressFeeling
        self.notes = notes
        self.frontPhoto = frontPhoto
        self.sidePhoto = sidePhoto
        self.backPhoto = backPhoto
        self.posePhoto = posePhoto
    }
}

// MARK: - Coach content

enum CoachCategory: String, CaseIterable, Identifiable, Codable {
    case prep = "Prep"
    case offSeason = "Off-Season"
    case nutrition = "Nutrition"
    case ftmHealth = "FTM Health"
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .prep: "🏆"
        case .offSeason: "🔋"
        case .nutrition: "🥗"
        case .ftmHealth: "🩵"
        }
    }
}

struct CoachUpdate: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var body: String
    var category: CoachCategory
    var date: Date
    var isPremium: Bool

    init(id: UUID = UUID(), title: String, body: String,
         category: CoachCategory, date: Date, isPremium: Bool = false) {
        self.id = id; self.title = title; self.body = body
        self.category = category; self.date = date; self.isPremium = isPremium
    }
}

struct Supplement: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var description: String
    var generalDose: String

    init(id: UUID = UUID(), name: String, category: String,
         description: String, generalDose: String) {
        self.id = id; self.name = name; self.category = category
        self.description = description; self.generalDose = generalDose
    }
}

struct MasonTip: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var text: String
    var category: String

    init(id: UUID = UUID(), text: String, category: String) {
        self.id = id; self.text = text; self.category = category
    }
}

// MARK: - Coming soon features

struct ComingSoonFeature: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var title: String
    var description: String
    var icon: String         // SF Symbol name
    var isFree: Bool

    init(id: UUID = UUID(), title: String, description: String,
         icon: String, isFree: Bool = true) {
        self.id = id; self.title = title; self.description = description
        self.icon = icon; self.isFree = isFree
    }
}
