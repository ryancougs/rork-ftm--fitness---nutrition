//
//  AppModel.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Main tab selection, hoisted here so Home cards can deep-link
/// into other tabs (e.g. "start today's workout" → Train).
enum AppTab: Hashable, CaseIterable {
    case home, train, eat, community, profile

    var label: String {
        switch self {
        case .home: "Home"
        case .train: "Train"
        case .eat: "Nutrition"
        case .community: "Community"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .train: "dumbbell.fill"
        case .eat: "fork.knife"
        case .community: "person.3.fill"
        case .profile: "person.crop.circle"
        }
    }
}

/// Top-level app state: session, profile, and logged data.
/// All local for this first version; persisted via @SceneStorage / AppStorage
/// through a simple JSON file in the documents directory.
@MainActor
@Observable
final class AppModel {

    enum SessionState: Equatable {
        case unauthenticated
        case needsIntake
        case ready
    }

    var session: SessionState = .unauthenticated
    var profile: UserProfile = UserProfile()

    /// True for the first moments of launch while a cloud session is restored.
    var isRestoringSession: Bool = true

    /// Onboarding-once guard: set when intake completes, checked at launch so
    /// returning users never see onboarding again — even if a cloud check
    /// hiccups. Mirrored in UserDefaults for extra resilience.
    var hasCompletedOnboarding: Bool = false

    /// Recently logged foods (device-local, newest first) — pinned in Add Food.
    var recentFoods: [FoodItem] = []

    /// Favorited foods (device-local) — pinned in Add Food.
    var favoriteFoods: [FoodItem] = []

    // Logged data keyed by ISO date string (yyyy-MM-dd).
    var foodLog: [String: [LoggedFood]] = [:]
    var exerciseLogs: [String: [UUID: ExerciseLog]] = [:]   // date → exerciseID → log

    // Mutable in-memory copy of sample programs so we could later modify reps etc.
    var programs: [WorkoutProgram] = SampleData.programs

    /// The user's personalized program, generated on-device by the plan engine.
    var personalProgram: WorkoutProgram? = nil

    /// Starter list (household servings) merged with the bundled USDA-derived
    /// database (FoodsDatabase.json) so search covers hundreds of foods.
    var foodDatabase: [FoodItem] = SampleData.foods + AppModel.bundledFoods

    /// Foods decoded once from the bundled FoodsDatabase.json, minus the
    /// starter items already present in SampleData.foods.
    private static let bundledFoods: [FoodItem] = {
        struct Row: Decodable {
            let name: String; let serving: String
            let calories: Int; let protein: Int; let carbs: Int; let fat: Int
        }
        guard let url = Bundle.main.url(forResource: "FoodsDatabase", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let rows = try? JSONDecoder().decode([Row].self, from: data) else { return [] }
        let starterNames = Set(SampleData.foods.map { $0.name.lowercased() })
        return rows
            .filter { !starterNames.contains($0.name.lowercased()) }
            .map { row -> FoodItem in
                // Rows quoted per 100 g become weighable: the serving picker
                // can then scale them by grams/ounces.
                let normalized = row.serving.lowercased().replacingOccurrences(of: " ", with: "")
                let isPer100g = normalized == "100g"
                return FoodItem(
                    name: row.name, serving: row.serving,
                    calories: row.calories, protein: row.protein,
                    carbs: row.carbs, fat: row.fat,
                    source: .local,
                    kcalPer100g: isPer100g ? Double(row.calories) : nil,
                    proteinPer100g: isPer100g ? Double(row.protein) : nil,
                    carbsPer100g: isPer100g ? Double(row.carbs) : nil,
                    fatPer100g: isPer100g ? Double(row.fat) : nil
                )
            }
    }()

    // Coach content (static sample data)
    var coachUpdates: [CoachUpdate] = SampleData.coachUpdates
    var supplements: [Supplement] = SampleData.supplements

    // Weekly check-ins, persisted.
    var checkIns: [WeeklyCheckIn] = []

    // Selection state for the current day on Train tab (persisted in-memory).
    var selectedProgramID: UUID? = nil
    var selectedDayID: UUID? = nil

    // Active main tab, so Home cards can deep-link into other tabs.
    var selectedTab: AppTab = .home

    /// One-shot dismissible soft offer shown when onboarding completes.
    /// Consumed by MainTabView; never re-shown for the same completion.
    var showPostOnboardingPaywall: Bool = false

    // Today's date key
    var todayKey: String { Self.dateKey(Date()) }

    init() {
        load()
        // The cloud session is the source of truth; handleAppLaunch() resolves it.
    }

    // MARK: - Auth (Supabase, email + password)

    /// Restore any persisted cloud session at launch, then sync state from the cloud.
    func handleAppLaunch() async {
        await CheckInReminder.requestAndSchedule()
        defer { isRestoringSession = false }
        guard await SupabaseService.shared.restoreSession() else { return }
        await restoreFromCloud()
    }

    func signUp(name: String, email: String, password: String) async throws {
        let result = try await SupabaseService.shared.signUp(email: email, password: password)
        if result.needsEmailConfirmation {
            throw SupabaseService.AuthError.emailConfirmationRequired
        }
        var p = UserProfile()
        p.name = name
        p.email = email
        p.applyDefaultTargets()
        profile = p
        session = .needsIntake
        save()
    }

    func logIn(email: String, password: String) async throws {
        let result = try await SupabaseService.shared.signIn(email: email, password: password)
        // A different account signing in on this device starts fresh locally.
        if profile.email.caseInsensitiveCompare(result.email ?? email) != .orderedSame {
            profile = UserProfile()
            checkIns.removeAll()
            foodLog.removeAll()
            exerciseLogs.removeAll()
            personalProgram = nil
            hasCompletedOnboarding = false
            recentFoods.removeAll()
            favoriteFoods.removeAll()
        }
        profile.email = result.email ?? email
        await restoreFromCloud()
        save()
    }

    func logOut() {
        session = .unauthenticated
        showPostOnboardingPaywall = false
        Task { await SupabaseService.shared.signOut() }
    }

    /// Deletes the account everywhere — cloud (auth user cascades to all data
    /// tables) and local storage. Throws when the server-side delete fails so
    /// the caller can keep the account intact and surface the error.
    func deleteAccount() async throws {
        if SupabaseService.shared.currentUserID != nil {
            try await SupabaseService.shared.deleteAccount()
        }
        wipeLocalData()
    }

    private func wipeLocalData() {
        profile = UserProfile()
        foodLog.removeAll()
        exerciseLogs.removeAll()
        checkIns.removeAll()
        personalProgram = nil
        hasCompletedOnboarding = false
        recentFoods.removeAll()
        favoriteFoods.removeAll()
        selectedTab = .home
        showPostOnboardingPaywall = false
        session = .unauthenticated
        save()
    }

    /// Merge the cloud profile and check-ins into local state after sign-in
    /// or session restore. Local logs (food/workout) remain device-local in v1.
    private func restoreFromCloud() async {
        guard let row = await SupabaseService.shared.fetchProfile() else {
            // Offline or missing row: fall back to local state. The onboarding
            // flag guards against cloud hiccups bouncing users back to intake.
            if !profile.email.isEmpty {
                session = (profile.name.isEmpty && !hasCompletedOnboarding) ? .needsIntake : .ready
            } else {
                session = hasCompletedOnboarding ? .ready : .needsIntake
            }
            return
        }

        if let name = row.name, !name.isEmpty {
            profile.name = name
            if let email = row.email { profile.email = email }
            if let g = row.goal, let goal = FitnessGoal(rawValue: g) { profile.goal = goal }
            if let e = row.experience, let exp = ExperienceLevel(rawValue: e) { profile.experience = exp }
            if let ls = row.lifestyle, let l = Lifestyle(rawValue: ls) { profile.lifestyle = l }
            if let eq = row.equipment, let eqAccess = EquipmentAccess(rawValue: eq) { profile.equipment = eqAccess }
            if let d = row.daysPerWeek { profile.daysPerWeek = d }
            if let bw = row.bodyweightKg { profile.bodyweightKg = bw }
            if let h = row.heightCm { profile.heightCm = h }
            if let a = row.age { profile.age = a }
            if let c = row.targetCalories { profile.targetCalories = c }
            if let p = row.targetProtein { profile.targetProtein = p }
            if let cb = row.targetCarbs { profile.targetCarbs = cb }
            if let f = row.targetFat { profile.targetFat = f }
        } else if let email = row.email {
            // Account exists but intake was never completed on any device.
            profile.email = email
        }

        if personalProgram == nil, !profile.name.isEmpty {
            regeneratePlan()
        }

        // Merge cloud check-ins into any local ones (union by week start).
        for cloudRow in await SupabaseService.shared.fetchCheckIns() {
            guard let weekStart = SupabaseService.date(fromKey: cloudRow.weekStart),
                  let adherence = WorkoutAdherence(rawValue: cloudRow.workoutAdherence),
                  let feeling = ProgressFeeling(rawValue: cloudRow.progressFeeling),
                  !checkIns.contains(where: { $0.weekStart.isSameDay(as: weekStart) })
            else { continue }
            checkIns.append(WeeklyCheckIn(
                weekStart: weekStart,
                energy: cloudRow.energy,
                sleep: cloudRow.sleep,
                stress: cloudRow.stress,
                hunger: cloudRow.hunger,
                workoutAdherence: adherence,
                progressFeeling: feeling,
                notes: cloudRow.notes
            ))
        }
        checkIns.sort { $0.weekStart > $1.weekStart }

        // A completed cloud profile (or the local flag) means intake is done:
        // never bounce returning users back to onboarding.
        if !profile.name.isEmpty { hasCompletedOnboarding = true }
        session = (profile.name.isEmpty && !hasCompletedOnboarding) ? .needsIntake : .ready
    }

    func completeIntake(goal: FitnessGoal, experience: ExperienceLevel, daysPerWeek: Int,
                        lifestyle: Lifestyle, equipment: EquipmentAccess,
                        bodyweightKg: Double?, heightCm: Double?, age: Int?) {
        profile.goal = goal
        profile.experience = experience
        profile.daysPerWeek = daysPerWeek
        profile.lifestyle = lifestyle
        profile.equipment = equipment
        profile.bodyweightKg = bodyweightKg
        profile.heightCm = heightCm
        profile.age = age
        profile.applyDefaultTargets()
        regeneratePlan()
        hasCompletedOnboarding = true
        session = .ready
        showPostOnboardingPaywall = true
        save()
        Task { await SupabaseService.shared.syncProfile(profile) }
    }

    func updateProfile(_ mutation: (inout UserProfile) -> Void) {
        let oldGoal = profile.goal
        let oldExperience = profile.experience
        let oldDays = profile.daysPerWeek
        let oldLifestyle = profile.lifestyle
        let oldEquipment = profile.equipment
        mutation(&profile)
        // Goal or lifestyle changes recompute fueling targets (they feed the
        // activity math); any training-relevant change rebuilds the program.
        if oldGoal != profile.goal || oldLifestyle != profile.lifestyle {
            profile.applyDefaultTargets()
        }
        if oldGoal != profile.goal || oldExperience != profile.experience
            || oldDays != profile.daysPerWeek || oldEquipment != profile.equipment {
            regeneratePlan()
        }
        save()
        Task { await SupabaseService.shared.syncProfile(profile) }
    }

    /// Rebuild the personalized training program from the current profile.
    func regeneratePlan() {
        personalProgram = PlanEngine.generateProgram(for: profile)
    }

    /// Mason's read on the most recent check-in, if there is one.
    var weeklyAdjustment: PlanEngine.WeeklyAdjustment? {
        guard let latest = checkIns.first else { return nil }
        return PlanEngine.weeklyAdjustment(for: latest, goal: profile.goal)
    }

    /// Today's session from the personalized plan, spread across the user's
    /// preferred training weekdays. Nil on rest days.
    var todayWorkout: WorkoutDay? {
        guard let program = personalProgram ?? SampleData.programs.first,
              !program.days.isEmpty else { return nil }
        let weekday = Calendar.current.component(.weekday, from: Date())
        let trainingDays = SampleData.preferredTrainingDays(weekly: profile.daysPerWeek)
        guard let idx = trainingDays.firstIndex(of: weekday) else { return nil }
        return program.days[idx % program.days.count]
    }

    // MARK: - Workout logging

    func log(forExercise id: UUID, on date: Date = Date()) -> ExerciseLog {
        let key = Self.dateKey(date)
        return exerciseLogs[key]?[id] ?? ExerciseLog(sets: [])
    }

    func addSet(toExercise id: UUID, weight: Double, reps: Int, on date: Date = Date()) {
        let key = Self.dateKey(date)
        var dayLogs = exerciseLogs[key] ?? [:]
        var log = dayLogs[id] ?? ExerciseLog(sets: [])
        log.sets.append(LoggedSet(weight: weight, reps: reps))
        dayLogs[id] = log
        exerciseLogs[key] = dayLogs
        save()
    }

    func removeSet(_ setId: UUID, fromExercise exerciseId: UUID, on date: Date = Date()) {
        let key = Self.dateKey(date)
        guard var dayLogs = exerciseLogs[key], var log = dayLogs[exerciseId] else { return }
        log.sets.removeAll { $0.id == setId }
        if log.sets.isEmpty {
            dayLogs.removeValue(forKey: exerciseId)
        } else {
            dayLogs[exerciseId] = log
        }
        exerciseLogs[key] = dayLogs
        save()
    }

    // MARK: - Food logging

    func foods(on date: Date = Date()) -> [LoggedFood] {
        foodLog[Self.dateKey(date)] ?? []
    }

    func addFood(_ food: FoodItem, servings: Double, meal: MealType,
                 portionLabel: String? = nil, on date: Date = Date()) {
        let key = Self.dateKey(date)
        var list = foodLog[key] ?? []
        list.append(LoggedFood(food: food, servings: servings, meal: meal, portionLabel: portionLabel))
        foodLog[key] = list
        recordRecent(food)
        save()
    }

    func removeFood(_ id: UUID, on date: Date = Date()) {
        let key = Self.dateKey(date)
        var list = foodLog[key] ?? []
        list.removeAll { $0.id == id }
        foodLog[key] = list
        save()
    }

    // MARK: - Food favorites & recents

    func isFavorite(_ food: FoodItem) -> Bool {
        favoriteFoods.contains { $0.stableKey == food.stableKey }
    }

    func toggleFavorite(_ food: FoodItem) {
        if let idx = favoriteFoods.firstIndex(where: { $0.stableKey == food.stableKey }) {
            favoriteFoods.remove(at: idx)
        } else {
            favoriteFoods.insert(food, at: 0)
            if favoriteFoods.count > 50 { favoriteFoods = Array(favoriteFoods.prefix(50)) }
        }
        save()
    }

    private func recordRecent(_ food: FoodItem) {
        recentFoods.removeAll { $0.stableKey == food.stableKey }
        recentFoods.insert(food, at: 0)
        if recentFoods.count > 12 { recentFoods = Array(recentFoods.prefix(12)) }
    }

    /// Developer tool: re-run onboarding immediately (Profile → Developer).
    func resetOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "tf.hasCompletedOnboarding")
        session = .needsIntake
        save()
    }

    // MARK: - Aggregates

    func nutritionTotals(on date: Date = Date()) -> (cal: Double, pro: Double, carb: Double, fat: Double) {
        foods(on: date).reduce(into: (0.0, 0.0, 0.0, 0.0)) { acc, f in
            acc.0 += f.calories; acc.1 += f.protein; acc.2 += f.carbs; acc.3 += f.fat
        }
    }

    // MARK: - Weekly check-ins

    var currentWeekStart: Date { SampleData.mondayOfWeek() }

    func hasCheckedInThisWeek() -> Bool {
        checkIns.contains { $0.weekStart.isSameDay(as: currentWeekStart) }
    }

    func currentWeekCheckIn() -> WeeklyCheckIn? {
        checkIns.first { $0.weekStart.isSameDay(as: currentWeekStart) }
    }

    func saveCheckIn(_ checkIn: WeeklyCheckIn) {
        if let idx = checkIns.firstIndex(where: { $0.weekStart.isSameDay(as: checkIn.weekStart) }) {
            checkIns[idx] = checkIn
        } else {
            checkIns.append(checkIn)
        }
        checkIns.sort { $0.weekStart > $1.weekStart }
        save()
        Task { await SupabaseService.shared.syncCheckIn(checkIn) }
    }

    var sortedCheckIns: [WeeklyCheckIn] {
        checkIns.sorted { $0.weekStart > $1.weekStart }
    }

    /// Total volume (weight × reps) logged per week for the last `weeks` weeks,
    /// oldest first — feeds the check-in lifting trend chart.
    func weeklyLiftingVolume(weeks: Int = 8) -> [(week: Date, volume: Double)] {
        let cal = Calendar.current
        var result: [(week: Date, volume: Double)] = []
        for offset in stride(from: weeks - 1, through: 0, by: -1) {
            guard let start = cal.date(byAdding: .weekOfYear, value: -offset, to: currentWeekStart) else { continue }
            var volume: Double = 0
            for day in 0..<7 {
                guard let date = cal.date(byAdding: .day, value: day, to: start) else { continue }
                let key = Self.dateKey(date)
                if let logs = exerciseLogs[key] {
                    for log in logs.values {
                        for set in log.sets { volume += set.weight * Double(set.reps) }
                    }
                }
            }
            result.append((start, volume))
        }
        return result
    }

    // MARK: - Helpers

    static func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    // MARK: - Persistence (simple JSON file in Documents)

    private let storeURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("transfit_state.json")
    }()

    struct Persisted: Codable {
        var profile: UserProfile
        var foodLog: [String: [LoggedFood]]
        var exerciseLogs: [String: [UUID: ExerciseLog]]
        var checkIns: [WeeklyCheckIn]
        var personalProgram: WorkoutProgram?
        var hasCompletedOnboarding: Bool
        var recentFoods: [FoodItem]
        var favoriteFoods: [FoodItem]

        init(profile: UserProfile, foodLog: [String: [LoggedFood]],
             exerciseLogs: [String: [UUID: ExerciseLog]], checkIns: [WeeklyCheckIn],
             personalProgram: WorkoutProgram?, hasCompletedOnboarding: Bool,
             recentFoods: [FoodItem], favoriteFoods: [FoodItem]) {
            self.profile = profile; self.foodLog = foodLog; self.exerciseLogs = exerciseLogs
            self.checkIns = checkIns; self.personalProgram = personalProgram
            self.hasCompletedOnboarding = hasCompletedOnboarding
            self.recentFoods = recentFoods; self.favoriteFoods = favoriteFoods
        }

        /// Tolerant decoding: state files saved before the onboarding-once
        /// round lack the new keys — fall back to defaults instead of failing.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            profile = try c.decode(UserProfile.self, forKey: .profile)
            foodLog = try c.decodeIfPresent([String: [LoggedFood]].self, forKey: .foodLog) ?? [:]
            exerciseLogs = try c.decodeIfPresent([String: [UUID: ExerciseLog]].self, forKey: .exerciseLogs) ?? [:]
            checkIns = try c.decodeIfPresent([WeeklyCheckIn].self, forKey: .checkIns) ?? []
            personalProgram = try c.decodeIfPresent(WorkoutProgram?.self, forKey: .personalProgram) ?? nil
            hasCompletedOnboarding = try c.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
            recentFoods = try c.decodeIfPresent([FoodItem].self, forKey: .recentFoods) ?? []
            favoriteFoods = try c.decodeIfPresent([FoodItem].self, forKey: .favoriteFoods) ?? []
        }
    }

    func save() {
        let p = Persisted(profile: profile, foodLog: foodLog, exerciseLogs: exerciseLogs,
                          checkIns: checkIns, personalProgram: personalProgram,
                          hasCompletedOnboarding: hasCompletedOnboarding,
                          recentFoods: recentFoods, favoriteFoods: favoriteFoods)
        if let data = try? JSONEncoder().encode(p) {
            try? data.write(to: storeURL, options: .atomic)
        }
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: "tf.hasCompletedOnboarding")
    }

    func load() {
        guard let data = try? Data(contentsOf: storeURL),
              let p = try? JSONDecoder().decode(Persisted.self, from: data) else {
            // File missing or unreadable — UserDefaults still guards onboarding.
            hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "tf.hasCompletedOnboarding")
            return
        }
        self.profile = p.profile
        self.foodLog = p.foodLog
        self.exerciseLogs = p.exerciseLogs
        self.checkIns = p.checkIns
        self.personalProgram = p.personalProgram
        self.hasCompletedOnboarding = p.hasCompletedOnboarding
            || UserDefaults.standard.bool(forKey: "tf.hasCompletedOnboarding")
        self.recentFoods = p.recentFoods
        self.favoriteFoods = p.favoriteFoods
    }
}
