//
//  SampleData.swift
//  FTMFitnessNutrition
//

import Foundation

enum SampleData {

    // MARK: - Workout programs

    static let programs: [WorkoutProgram] = [foundations, pushPullLegs, upperLower]

    static let foundations: WorkoutProgram = WorkoutProgram(
        name: "Foundations",
        summary: "A welcoming full-body intro to lifting. Learn the big movement patterns with manageable volume.",
        level: .beginner,
        goal: .buildMuscle,
        daysPerWeek: 3,
        days: [
            WorkoutDay(
                title: "Day 1 — Full Body A",
                focus: "Squat / Pull / Push",
                exercises: [
                    Exercise(name: "Goblet Squat", muscleGroup: "Legs", sets: 3, reps: "8-10",
                             restSeconds: 90, description: "Hold a single dumbbell at chest height. Squat down keeping your chest tall and knees tracking over your toes. Drive through your heels to stand. Great for learning squat pattern with less spinal load than a barbell."),
                    Exercise(name: "Dumbbell Row", muscleGroup: "Back", sets: 3, reps: "10-12",
                             restSeconds: 75, description: "Hinge at the hips with a flat back. Row the dumbbell to your hip, squeezing the shoulder blade. Keep your core braced — avoid twisting the torso."),
                    Exercise(name: "Push-up", muscleGroup: "Chest", sets: 3, reps: "8-12",
                             restSeconds: 60, description: "Hands under shoulders, body in a straight line. Lower until your chest nearly touches the floor, then press up. Drop to knees if needed — quality over quantity."),
                    Exercise(name: "Plank", muscleGroup: "Core", sets: 3, reps: "30-45s",
                             restSeconds: 45, description: "Forearms down, body in a straight line from head to heels. Brace your abs and glutes. Don't let your hips sag or pike."),
                    Exercise(name: "Lat Pulldown", muscleGroup: "Back", sets: 2, reps: "10-12",
                             restSeconds: 75, description: "Pull the bar to your upper chest, leading with the elbows. Control the stretch on the way up. Avoid swinging."),
                ]
            ),
            WorkoutDay(
                title: "Day 2 — Full Body B",
                focus: "Hinge / Push / Carry",
                exercises: [
                    Exercise(name: "Romanian Deadlift", muscleGroup: "Legs", sets: 3, reps: "8-10",
                             restSeconds: 90, description: "Soft knees, hinge at the hips with a flat back. Lower the weights along your legs until you feel a hamstring stretch. Drive hips forward to stand."),
                    Exercise(name: "Dumbbell Shoulder Press", muscleGroup: "Shoulders", sets: 3, reps: "8-12",
                             restSeconds: 75, description: "Press dumbbells from shoulder height overhead without leaning back. Keep ribs down and core tight."),
                    Exercise(name: "Lat Pulldown", muscleGroup: "Back", sets: 3, reps: "10-12",
                             restSeconds: 75, description: "Pull the bar to your upper chest, leading with the elbows. Control the stretch on the way up."),
                    Exercise(name: "Dumbbell Goblet Split Squat", muscleGroup: "Legs", sets: 2, reps: "10/leg",
                             restSeconds: 60, description: "Stagger your stance, lower straight down until back knee nears the floor. Drive through the front heel."),
                    Exercise(name: "Dead Bug", muscleGroup: "Core", sets: 3, reps: "8/side",
                             restSeconds: 45, description: "On your back, arms and legs up. Lower opposite arm and leg slowly while keeping your lower back pressed flat."),
                ]
            ),
            WorkoutDay(
                title: "Day 3 — Full Body C",
                focus: "Mixed compound + accessory",
                exercises: [
                    Exercise(name: "Dumbbell Bench Press", muscleGroup: "Chest", sets: 3, reps: "8-12",
                             restSeconds: 90, description: "Press dumbbells from chest to lockout, keeping shoulder blades pinched. Lower with control."),
                    Exercise(name: "Cable Seated Row", muscleGroup: "Back", sets: 3, reps: "10-12",
                             restSeconds: 75, description: "Row the handle to your belly, squeezing the shoulder blades together. Keep your chest tall."),
                    Exercise(name: "Walking Lunge", muscleGroup: "Legs", sets: 2, reps: "12/leg",
                             restSeconds: 60, description: "Step forward and lower until back knee nears the floor. Keep your torso tall."),
                    Exercise(name: "Dumbbell Curl", muscleGroup: "Biceps", sets: 2, reps: "12-15",
                             restSeconds: 45, description: "Curl with elbows pinned to your sides. Avoid swinging."),
                    Exercise(name: "Triceps Pushdown", muscleGroup: "Triceps", sets: 2, reps: "12-15",
                             restSeconds: 45, description: "Push the cable down to full extension. Keep elbows tucked."),
                ]
            ),
        ]
    )

    static let pushPullLegs: WorkoutProgram = WorkoutProgram(
        name: "Push / Pull / Legs",
        summary: "A classic 6-day split for intermediate lifters wanting more volume per muscle group.",
        level: .intermediate,
        goal: .buildMuscle,
        daysPerWeek: 6,
        days: [
            WorkoutDay(
                title: "Day 1 — Push",
                focus: "Chest / Shoulders / Triceps",
                exercises: [
                    Exercise(name: "Barbell Bench Press", muscleGroup: "Chest", sets: 4, reps: "6-8",
                             restSeconds: 120, description: "Lower the bar to mid-chest, touch lightly, press up to lockout. Keep shoulder blades retracted and feet planted."),
                    Exercise(name: "Overhead Press", muscleGroup: "Shoulders", sets: 3, reps: "6-8",
                             restSeconds: 120, description: "Press the bar from shoulders overhead. Brace your core and avoid leaning back."),
                    Exercise(name: "Incline Dumbbell Press", muscleGroup: "Chest", sets: 3, reps: "8-12",
                             restSeconds: 90, description: "Press dumbbells on an incline bench (~30°). Great for upper chest."),
                    Exercise(name: "Lateral Raise", muscleGroup: "Shoulders", sets: 3, reps: "12-15",
                             restSeconds: 60, description: "Raise dumbbells out to the sides to shoulder height. Lead with the elbows."),
                    Exercise(name: "Triceps Pushdown", muscleGroup: "Triceps", sets: 3, reps: "10-15",
                             restSeconds: 60, description: "Push the cable down with elbows tucked. Squeeze at the bottom."),
                ]
            ),
            WorkoutDay(
                title: "Day 2 — Pull",
                focus: "Back / Biceps",
                exercises: [
                    Exercise(name: "Pull-up", muscleGroup: "Back", sets: 4, reps: "6-10",
                             restSeconds: 120, description: "Pull your chin over the bar with elbows driving down. Use a band if needed."),
                    Exercise(name: "Barbell Row", muscleGroup: "Back", sets: 4, reps: "8-10",
                             restSeconds: 105, description: "Hinge to ~45°, row the bar to your lower ribs. Keep your back flat."),
                    Exercise(name: "Cable Seated Row", muscleGroup: "Back", sets: 3, reps: "10-12",
                             restSeconds: 75, description: "Row the handle to your belly, squeezing the shoulder blades."),
                    Exercise(name: "Dumbbell Curl", muscleGroup: "Biceps", sets: 3, reps: "10-12",
                             restSeconds: 60, description: "Curl with elbows pinned. No swinging."),
                    Exercise(name: "Face Pull", muscleGroup: "Rear Delts", sets: 3, reps: "15-20",
                             restSeconds: 60, description: "Pull the rope to your face, elbows high. Great for posture and rear delts."),
                ]
            ),
            WorkoutDay(
                title: "Day 3 — Legs",
                focus: "Quads / Hams / Glutes",
                exercises: [
                    Exercise(name: "Back Squat", muscleGroup: "Legs", sets: 4, reps: "6-8",
                             restSeconds: 150, description: "Bar on your upper back. Squat to depth with chest tall. Drive through mid-foot."),
                    Exercise(name: "Romanian Deadlift", muscleGroup: "Hamstrings", sets: 3, reps: "8-10",
                             restSeconds: 105, description: "Hinge at hips with flat back. Feel the hamstring stretch, then drive hips through."),
                    Exercise(name: "Leg Press", muscleGroup: "Quads", sets: 3, reps: "10-12",
                             restSeconds: 90, description: "Lower the platform to ~90° knee bend. Don't lock out hard at the top."),
                    Exercise(name: "Walking Lunge", muscleGroup: "Legs", sets: 3, reps: "12/leg",
                             restSeconds: 75, description: "Step forward and lower. Keep your torso tall."),
                    Exercise(name: "Calf Raise", muscleGroup: "Calves", sets: 4, reps: "12-15",
                             restSeconds: 45, description: "Rise onto the balls of your feet. Pause at the top."),
                ]
            ),
            WorkoutDay(
                title: "Day 4 — Push",
                focus: "Chest / Shoulders / Triceps",
                exercises: [
                    Exercise(name: "Incline Barbell Press", muscleGroup: "Chest", sets: 4, reps: "6-8",
                             restSeconds: 120, description: "Press on a 30° incline. Touch the bar to your upper chest."),
                    Exercise(name: "Seated Dumbbell Press", muscleGroup: "Shoulders", sets: 3, reps: "8-12",
                             restSeconds: 90, description: "Seated press from shoulder height. Keep your chest up."),
                    Exercise(name: "Cable Fly", muscleGroup: "Chest", sets: 3, reps: "12-15",
                             restSeconds: 60, description: "Bring the cables together in an arc. Slight elbow bend."),
                    Exercise(name: "Rope Overhead Extension", muscleGroup: "Triceps", sets: 3, reps: "12-15",
                             restSeconds: 60, description: "Extend overhead, squeezing the triceps at the top."),
                ]
            ),
            WorkoutDay(
                title: "Day 5 — Pull",
                focus: "Back / Biceps",
                exercises: [
                    Exercise(name: "Deadlift", muscleGroup: "Posterior Chain", sets: 3, reps: "5",
                             restSeconds: 180, description: "Pull the bar from the floor with a flat back and braced core. Hips and shoulders rise together."),
                    Exercise(name: "Weighted Pull-up", muscleGroup: "Back", sets: 4, reps: "5-8",
                             restSeconds: 120, description: "Pull-ups with added weight via belt. Drop weight if form breaks."),
                    Exercise(name: "Pendlay Row", muscleGroup: "Back", sets: 3, reps: "8-10",
                             restSeconds: 90, description: "Row the bar from the floor each rep, explosive. Torso parallel to floor."),
                    Exercise(name: "Hammer Curl", muscleGroup: "Biceps", sets: 3, reps: "10-12",
                             restSeconds: 60, description: "Curl with neutral grip. Keep elbows pinned."),
                ]
            ),
            WorkoutDay(
                title: "Day 6 — Legs",
                focus: "Quads / Hams / Glutes",
                exercises: [
                    Exercise(name: "Front Squat", muscleGroup: "Quads", sets: 4, reps: "6-8",
                             restSeconds: 150, description: "Bar in front rack. Squat upright — very quad-dominant."),
                    Exercise(name: "Bulgarian Split Squat", muscleGroup: "Legs", sets: 3, reps: "10/leg",
                             restSeconds: 75, description: "Rear foot on a bench. Lower straight down. Drive through front heel."),
                    Exercise(name: "Glute Ham Raise", muscleGroup: "Hamstrings", sets: 3, reps: "8-12",
                             restSeconds: 75, description: "Lower your body with control using the hamstrings, then pull back up."),
                    Exercise(name: "Seated Calf Raise", muscleGroup: "Calves", sets: 4, reps: "15-20",
                             restSeconds: 45, description: "Slow, controlled reps. Pause at the bottom stretch."),
                ]
            ),
        ]
    )

    static let upperLower: WorkoutProgram = WorkoutProgram(
        name: "Upper / Lower",
        summary: "A balanced 4-day split great for recomp. Hits each muscle group twice a week.",
        level: .intermediate,
        goal: .recomp,
        daysPerWeek: 4,
        days: [
            WorkoutDay(
                title: "Day 1 — Upper A",
                focus: "Strength push + volume pull",
                exercises: [
                    Exercise(name: "Barbell Bench Press", muscleGroup: "Chest", sets: 4, reps: "5-8",
                             restSeconds: 150, description: "Heavy bench. Keep shoulder blades retracted, feet planted."),
                    Exercise(name: "Weighted Pull-up", muscleGroup: "Back", sets: 4, reps: "6-8",
                             restSeconds: 120, description: "Add weight via belt. Pull chin over bar."),
                    Exercise(name: "Overhead Press", muscleGroup: "Shoulders", sets: 3, reps: "8-10",
                             restSeconds: 105, description: "Press the bar from shoulders to lockout. Brace core."),
                    Exercise(name: "Cable Seated Row", muscleGroup: "Back", sets: 3, reps: "10-12",
                             restSeconds: 75, description: "Row to belly, squeeze shoulder blades."),
                    Exercise(name: "Triceps Pushdown", muscleGroup: "Triceps", sets: 2, reps: "12-15",
                             restSeconds: 60, description: "Push the cable down, elbows tucked."),
                    Exercise(name: "Dumbbell Curl", muscleGroup: "Biceps", sets: 2, reps: "12-15",
                             restSeconds: 60, description: "Curl with elbows pinned."),
                ]
            ),
            WorkoutDay(
                title: "Day 2 — Lower A",
                focus: "Squat focus",
                exercises: [
                    Exercise(name: "Back Squat", muscleGroup: "Legs", sets: 4, reps: "5-8",
                             restSeconds: 180, description: "Heavy squat to depth. Drive through mid-foot."),
                    Exercise(name: "Romanian Deadlift", muscleGroup: "Hamstrings", sets: 3, reps: "8-10",
                             restSeconds: 105, description: "Hinge with flat back. Feel the hamstring stretch."),
                    Exercise(name: "Bulgarian Split Squat", muscleGroup: "Legs", sets: 3, reps: "10/leg",
                             restSeconds: 75, description: "Rear foot on bench. Drive through front heel."),
                    Exercise(name: "Leg Curl", muscleGroup: "Hamstrings", sets: 3, reps: "12-15",
                             restSeconds: 60, description: "Curl with control, squeeze at the top."),
                    Exercise(name: "Calf Raise", muscleGroup: "Calves", sets: 4, reps: "12-15",
                             restSeconds: 45, description: "Full ROM, pause at the top."),
                ]
            ),
            WorkoutDay(
                title: "Day 3 — Upper B",
                focus: "Volume push + heavy pull",
                exercises: [
                    Exercise(name: "Incline Dumbbell Press", muscleGroup: "Chest", sets: 4, reps: "8-12",
                             restSeconds: 90, description: "Press on 30° incline. Squeeze the chest at the top."),
                    Exercise(name: "Barbell Row", muscleGroup: "Back", sets: 4, reps: "6-8",
                             restSeconds: 120, description: "Heavy row to lower ribs. Flat back."),
                    Exercise(name: "Lateral Raise", muscleGroup: "Shoulders", sets: 3, reps: "12-15",
                             restSeconds: 60, description: "Raise out to shoulder height, lead with elbows."),
                    Exercise(name: "Lat Pulldown", muscleGroup: "Back", sets: 3, reps: "10-12",
                             restSeconds: 75, description: "Pull bar to upper chest, lead with elbows."),
                    Exercise(name: "Face Pull", muscleGroup: "Rear Delts", sets: 3, reps: "15-20",
                             restSeconds: 60, description: "Rope to face, elbows high. Posture builder."),
                ]
            ),
            WorkoutDay(
                title: "Day 4 — Lower B",
                focus: "Deadlift focus",
                exercises: [
                    Exercise(name: "Deadlift", muscleGroup: "Posterior Chain", sets: 3, reps: "5",
                             restSeconds: 210, description: "Heavy pull from the floor. Flat back, brace core."),
                    Exercise(name: "Front Squat", muscleGroup: "Quads", sets: 3, reps: "8-10",
                             restSeconds: 120, description: "Front rack, upright torso. Quad focus."),
                    Exercise(name: "Walking Lunge", muscleGroup: "Legs", sets: 3, reps: "12/leg",
                             restSeconds: 75, description: "Step forward and lower. Tall torso."),
                    Exercise(name: "Glute Ham Raise", muscleGroup: "Hamstrings", sets: 3, reps: "8-12",
                             restSeconds: 75, description: "Hamstring-driven lower and pull-up."),
                    Exercise(name: "Seated Calf Raise", muscleGroup: "Calves", sets: 4, reps: "15-20",
                             restSeconds: 45, description: "Slow reps, pause at the bottom."),
                ]
            ),
        ]
    )

    // MARK: - Food database (sample)

    static let foods: [FoodItem] = [
        FoodItem(name: "Greek Yogurt (plain)", serving: "1 cup (245g)", calories: 130, protein: 23, carbs: 9, fat: 1),
        FoodItem(name: "Chicken Breast (cooked)", serving: "100g", calories: 165, protein: 31, carbs: 0, fat: 3),
        FoodItem(name: "White Rice (cooked)", serving: "1 cup (160g)", calories: 205, protein: 4, carbs: 45, fat: 0),
        FoodItem(name: "Oats (dry)", serving: "1/2 cup (40g)", calories: 150, protein: 5, carbs: 27, fat: 3),
        FoodItem(name: "Banana", serving: "1 medium", calories: 105, protein: 1, carbs: 27, fat: 0),
        FoodItem(name: "Eggs (whole)", serving: "2 large", calories: 156, protein: 12, carbs: 1, fat: 11),
        FoodItem(name: "Egg Whites", serving: "1/2 cup", calories: 63, protein: 13, carbs: 1, fat: 0),
        FoodItem(name: "Almonds", serving: "1 oz (28g)", calories: 164, protein: 6, carbs: 6, fat: 14),
        FoodItem(name: "Whey Protein Scoop", serving: "1 scoop (30g)", calories: 120, protein: 24, carbs: 3, fat: 2),
        FoodItem(name: "Sweet Potato (baked)", serving: "1 medium (150g)", calories: 130, protein: 3, carbs: 30, fat: 0),
        FoodItem(name: "Broccoli (steamed)", serving: "1 cup (160g)", calories: 55, protein: 4, carbs: 11, fat: 1),
        FoodItem(name: "Salmon (baked)", serving: "150g", calories: 280, protein: 39, carbs: 0, fat: 13),
        FoodItem(name: "Tofu (firm)", serving: "1/2 cup (126g)", calories: 181, protein: 22, carbs: 4, fat: 11),
        FoodItem(name: "Black Beans", serving: "1/2 cup (130g)", calories: 114, protein: 8, carbs: 20, fat: 0),
        FoodItem(name: "Olive Oil", serving: "1 tbsp", calories: 119, protein: 0, carbs: 0, fat: 14),
        FoodItem(name: "Avocado", serving: "1/2 medium", calories: 161, protein: 2, carbs: 9, fat: 15),
        FoodItem(name: "Whole-grain Bread", serving: "1 slice", calories: 80, protein: 4, carbs: 14, fat: 1),
        FoodItem(name: "Peanut Butter", serving: "2 tbsp", calories: 188, protein: 8, carbs: 6, fat: 16),
        FoodItem(name: "Apple", serving: "1 medium", calories: 95, protein: 0, carbs: 25, fat: 0),
        FoodItem(name: "Lean Ground Beef (5%)", serving: "100g", calories: 175, protein: 26, carbs: 0, fat: 8),
    ]

    // MARK: - Suggested workouts by day-of-week → program/day index

    /// Returns a workout day for today based on the user's preferred days-per-week and programs.
    static func todaysWorkout(for profile: UserProfile) -> WorkoutDay? {
        let cal = Calendar.current
        let weekday = cal.component(.weekday, from: Date())        // 1=Sun ... 7=Sat
        // Pick a program that matches goal+level, else first
        let program = programs.first(where: { $0.level == profile.experience && $0.goal == profile.goal })
            ?? programs.first(where: { $0.level == profile.experience })
            ?? programs.first
        guard let program else { return nil }
        // Spread program days across the week based on daysPerWeek
        let trainingDays = preferredTrainingDays(weekly: profile.daysPerWeek)
        if trainingDays.contains(weekday), !program.days.isEmpty {
            let idx = (trainingDays.firstIndex(of: weekday) ?? 0) % program.days.count
            return program.days[idx]
        }
        return nil
    }

    /// Simple mapping of how many days/week → which weekdays (1=Sun).
    static func preferredTrainingDays(weekly count: Int) -> [Int] {
        switch count {
        case 3: return [2, 4, 6]           // Mon, Wed, Fri
        case 4: return [2, 3, 5, 6]        // Mon, Tue, Thu, Fri
        case 5: return [2, 3, 4, 5, 6]     // Mon-Fri
        case 6: return [2, 3, 4, 5, 6, 7]
        default: return [2, 4, 6]
        }
    }

    // MARK: - Coach updates (sample posts from Mason)

    static let coachUpdates: [CoachUpdate] = [
        CoachUpdate(
            title: "Welcome to FTMFitnessNutrition",
            body: "I built this space because I was tired of apps that don't get it. You shouldn't have to explain yourself before you start training. This is a place where you belong from day one. Whether you're pre-T, years on hormones, pre- or post-op, or anywhere in between — your training matters and your body deserves care. Let's get to work.",
            category: .ftmHealth,
            date: Date().addingTimeInterval(-86400 * 2)
        ),
        CoachUpdate(
            title: "Off-Season Training: Building the X-Frame",
            body: "For trans masculine lifters, building an X-frame (wide shoulders, wide lats, developed upper chest) can help create a masculine silhouette regardless of where you are in your transition. Focus on overhead press, lateral raises, lat work, and upper chest. The V-taper comes from broad shoulders and a narrow waist — genetics play a role, but training shapes what you've got. Don't compare your chapter 1 to someone else's chapter 20.",
            category: .ftmHealth,
            date: Date().addingTimeInterval(-86400 * 5)
        ),
        CoachUpdate(
            title: "Fueling for Muscle: Not All Calories Are Equal",
            body: "You can hit your calorie target with junk food and feel terrible, or hit it with whole foods and feel unstoppable. Protein from chicken, tofu, eggs, fish. Carbs from rice, oats, potatoes, fruit. Fats from olive oil, avocado, nuts, salmon. Whole foods give you micronutrients, fiber, and sustained energy that processed foods can't match. Hit your macros, yes — but the quality of those calories matters for how you feel and how you progress.",
            category: .nutrition,
            date: Date().addingTimeInterval(-86400 * 7)
        ),
        CoachUpdate(
            title: "Programming for Testosterone Timelines",
            body: "If you're early on T, your recovery capacity is changing rapidly. You may be able to add volume faster than before, but your tendons and ligaments need time to catch up to your muscles. Start conservative, progress weekly, and listen to your body. If you're pre-T, you can still build significant strength and muscle — training hard and eating well will maximize whatever your hormone profile gives you. Consistency beats intensity every time.",
            category: .ftmHealth,
            date: Date().addingTimeInterval(-86400 * 10)
        ),
        CoachUpdate(
            title: "Pre- and Post-Surgery Training Considerations",
            body: "Top surgery recovery is not the time to push. Follow your surgeon's protocol — typically 6+ weeks before upper body training resumes, and even then you start light. Pre-surgery, focus on building your back and chest foundation so you have something to rebuild from. Post-surgery, start with mobility, then light resistance, then full training. Patience here pays off for years. I've been through it — I know it's frustrating, but your body is healing.",
            category: .ftmHealth,
            date: Date().addingTimeInterval(-86400 * 14)
        ),
        CoachUpdate(
            title: "Prep Week 4: Dialing In",
            body: "As we get deeper into prep, training volume stays high but intensity moderates. Sleep becomes non-negotiable. Stress management isn't optional. This is where the people who treat it as a lifestyle pull ahead of the people who treat it as a diet. You're not starving — you're sculpting. Mindset matters.",
            category: .prep,
            date: Date().addingTimeInterval(-86400 * 18)
        ),
        CoachUpdate(
            title: "Supplements Mason Recommends",
            body: "Before anything else: food first. No supplement out-trains sleep, protein, or consistency. Inside the Prep Team I break down the short list I actually stand behind — how to read a label, what the research supports, and what to skip so you don't waste money. Always loop in your doctor before adding anything, especially if you're on hormone therapy.",
            category: .nutrition,
            date: Date().addingTimeInterval(-86400 * 21),
            isPremium: true
        ),
    ]

    // MARK: - Supplements (general health info)

    static let supplements: [Supplement] = [
        Supplement(name: "Whey Protein", category: "Protein",
                   description: "A convenient way to hit protein targets. Not magic — just food in powder form. Choose one with minimal additives if possible.",
                   generalDose: "1 scoop (20-30g protein) post-workout or between meals"),
        Supplement(name: "Creatine Monohydrate", category: "Performance",
                   description: "The most researched supplement in fitness. Increases strength output and muscle hydration. Safe, effective, and cheap.",
                   generalDose: "3-5g daily, any time. No need to load."),
        Supplement(name: "Vitamin D3", category: "General Health",
                   description: "Many people are deficient, especially those who train indoors. Important for bone health, mood, and hormone function.",
                   generalDose: "1000-4000 IU daily with a meal (check with your doctor)"),
        Supplement(name: "Omega-3 Fish Oil", category: "General Health",
                   description: "Supports joint health, inflammation management, and cardiovascular health. Get one high in EPA/DHA.",
                   generalDose: "1-3g combined EPA+DHA daily with food"),
        Supplement(name: "Magnesium", category: "Recovery",
                   description: "Supports sleep quality, muscle recovery, and stress management. Glycinate form is best for sleep; citrate if you want the laxative effect.",
                   generalDose: "200-400mg before bed"),
        Supplement(name: "Zinc", category: "General Health",
                   description: "Important for testosterone production, immune function, and recovery. Don't overdo it — more is not better.",
                   generalDose: "10-15mg daily with food"),
    ]

    // MARK: - Mason's tips (rotating daily)

    static let tips: [MasonTip] = [
        MasonTip(text: "You don't have to explain yourself before you start training. This is your space.", category: "Mindset"),
        MasonTip(text: "Consistency beats intensity. Show up 3 days a week for a year, and you'll outpace everyone who went hard for a month and quit.", category: "Training"),
        MasonTip(text: "Not all calories are equal. Hit your protein, then fill the rest with whole foods. You'll feel the difference.", category: "Nutrition"),
        MasonTip(text: "Rest is part of the work. Muscle grows during recovery, not during the set.", category: "Recovery"),
        MasonTip(text: "Your transition timeline doesn't define your potential. It shapes the path, but the path still leads somewhere good.", category: "Mindset"),
        MasonTip(text: "Sleep is the most underrated performance enhancer. 7+ hours will do more for your gains than any supplement.", category: "Recovery"),
        MasonTip(text: "Track your lifts. If you don't know what you did last week, you don't know if you're progressing.", category: "Training"),
        MasonTip(text: "Whole foods first. Supplements supplement — they don't replace.", category: "Nutrition"),
        MasonTip(text: "The X-frame comes from shoulders, lats, and a lean waist. Train all three with intention.", category: "Training"),
        MasonTip(text: "Be patient with your body. It's doing a lot behind the scenes. Keep winning.", category: "Mindset"),
    ]

    /// Returns a daily-rotating tip (deterministic by day of year).
    static func dailyTip() -> MasonTip {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return tips[(dayOfYear - 1) % tips.count]
    }

    // MARK: - Week start helper

    /// Returns the Monday of the current week.
    static func mondayOfWeek(for date: Date = Date()) -> Date {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }
}
