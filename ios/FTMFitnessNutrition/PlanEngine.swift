//
//  PlanEngine.swift
//  FTMFitnessNutrition
//
//  Deterministic, on-device plan generation — no AI calls, no cost, works offline.
//  Encodes Mason's coaching philosophy:
//   • X-frame development (shoulders, lats, quads — keep the waist tight)
//   • Safety first: quality over ego, always leave 1-2 reps in reserve
//   • Wellbeing over numbers: check-ins steer the week, never shame
//   • Fueling, not restriction: gentle deficits, high protein, whole foods first
//

import Foundation

/// Pure, deterministic plan generator. All decisions are rules-based.
nonisolated enum PlanEngine {

    // MARK: - Nutrition targets

    struct NutritionTargets: Equatable {
        let calories: Int
        let protein: Int
        let carbs: Int
        let fat: Int
        let rationale: String
    }

    /// Mifflin-St Jeor BMR × activity factor, adjusted by goal with Mason's
    /// "small and sustainable" numbers. Falls back to population defaults
    /// when body stats are missing rather than blocking the user.
    static func targets(for profile: UserProfile) -> NutritionTargets {
        let weight = profile.bodyweightKg ?? 70
        let height = profile.heightCm ?? 175
        let age = Double(profile.age ?? 27)

        let bmr = 10 * weight + 6.25 * height - 5 * age + 5
        // Base activity from training frequency, nudged by day-to-day lifestyle.
        let base: Double
        switch profile.daysPerWeek {
        case 3: base = 1.45
        case 4: base = 1.50
        case 5: base = 1.55
        default: base = 1.60
        }
        let lifestyleBump: Double
        switch profile.lifestyle {
        case .mostlySitting: lifestyleBump = 0.0
        case .onMyFeet: lifestyleBump = 0.08
        case .physicalJob: lifestyleBump = 0.20
        }
        let activity = min(base + lifestyleBump, 1.85)
        let tdee = bmr * activity

        let calorieMultiplier: Double
        let proteinPerKg: Double
        let fatPerKg: Double
        let rationale: String

        switch profile.goal {
        case .buildMuscle:
            calorieMultiplier = 1.10
            proteinPerKg = 2.0
            fatPerKg = 0.8
            rationale = "A gentle surplus — enough to grow without burying your hard work. Protein sits around 2g per kilo to protect the muscle you're building. Whole foods first; shakes are backup, not the plan."
        case .loseFat:
            calorieMultiplier = 0.85
            proteinPerKg = 2.2
            fatPerKg = 0.7
            rationale = "A moderate deficit — slow enough to keep your strength and your sanity. Protein stays high so the weight you lose is fat, not muscle. You're not starving — you're sculpting."
        case .recomp:
            calorieMultiplier = 0.97
            proteinPerKg = 1.9
            fatPerKg = 0.8
            rationale = "Roughly maintenance with protein high — the patient way to build muscle and let fat take care of itself. Trust the process; the mirror moves slower than the numbers do."
        case .maintain:
            calorieMultiplier = 1.0
            proteinPerKg = 1.6
            fatPerKg = 0.85
            rationale = "Maintenance fuel. Enough to train well, recover fully, and feel good in your body — because feeling good is the point."
        }

        // Never dip below a safe floor (≈BMR + 10%).
        let floor = (bmr * 1.1).rounded()
        var calories = max(tdee * calorieMultiplier, floor)

        let protein = weight * proteinPerKg
        let fat = weight * fatPerKg
        let energyFromPF = protein * 4 + fat * 9
        // Carbs get the remainder, floored so training fuel never disappears.
        let carbs = max((calories - energyFromPF) / 4, 80)
        // If flooring carbs pushed past the calorie budget, let calories absorb it.
        calories = max(calories, protein * 4 + fat * 9 + carbs * 4)

        return NutritionTargets(
            calories: Int((calories / 10).rounded() * 10),
            protein: Int((protein / 5).rounded() * 5),
            carbs: Int((carbs / 5).rounded() * 5),
            fat: Int((fat / 5).rounded() * 5),
            rationale: rationale
        )
    }

    // MARK: - Program generation

    /// A movement with per-level variants. Level drives exercise selection,
    /// set/rep scheme, and rest — beginners earn machines before barbells.
    private struct Move {
        let beginner: Exercise
        let intermediate: Exercise
        let advanced: Exercise

        func pick(for level: ExperienceLevel) -> Exercise {
            switch level {
            case .beginner: beginner
            case .intermediate: intermediate
            case .advanced: advanced
            }
        }
    }

    private static func move(_ b: Exercise, _ i: Exercise, _ a: Exercise) -> Move {
        Move(beginner: b, intermediate: i, advanced: a)
    }

    private static func ex(_ name: String, _ muscle: String, _ sets: Int, _ reps: String,
                           _ rest: Int, _ cue: String) -> Exercise {
        Exercise(name: name, muscleGroup: muscle, sets: sets, reps: reps,
                 restSeconds: rest, description: cue)
    }

    // MARK: Movement library (Mason's picks, safety cues built in)

    // Horizontal press
    private static let mPress = move(
        ex("Dumbbell Bench Press", "Chest", 3, "8-12", 90,
           "Press dumbbells from chest to lockout, shoulder blades pinched. Lower with control — leave 1-2 reps in reserve."),
        ex("Barbell Bench Press", "Chest", 4, "6-10", 120,
           "Lower the bar to mid-chest, touch lightly, press up. Shoulder blades retracted, feet planted. Leave 1-2 reps in reserve."),
        ex("Barbell Bench Press", "Chest", 5, "5-8", 150,
           "Heavy bench, never sloppy. If the bar speed dies or form drifts, the set is over — that's the rep you don't need."))
    // Incline press
    private static let mIncline = move(
        ex("Incline Dumbbell Press", "Chest", 3, "8-12", 90,
           "Press on a ~30° incline. Great for upper chest — the shelf that reads 'built' in a T-shirt."),
        ex("Incline Dumbbell Press", "Chest", 4, "8-12", 90,
           "Press on a ~30° incline, squeezing the chest at the top. Quality reps, no bouncing."),
        ex("Incline Barbell Press", "Chest", 4, "6-8", 120,
           "Bar on a 30° incline, touch the upper chest, press. Keep the bar path over your shoulders at lockout."))
    // Overhead press
    private static let mOhp = move(
        ex("Dumbbell Shoulder Press", "Shoulders", 3, "8-12", 90,
           "Seated press from shoulder height. Ribs down, core tight, no leaning back. Boulders are built patiently."),
        ex("Overhead Press", "Shoulders", 4, "6-10", 120,
           "Press the bar from shoulders to lockout. Brace your core, squeeze glutes — don't lean back into a standing incline."),
        ex("Overhead Press", "Shoulders", 4, "5-8", 150,
           "Strict press. If you have to cheat it up with a lean, the weight's lying to you."))
    // Vertical pull (lats — the width side of the X)
    private static let mLatPull = move(
        ex("Lat Pulldown", "Back", 3, "10-12", 90,
           "Pull the bar to your upper chest, leading with the elbows. Control the stretch up. This builds the lat width that reads 'V'."),
        ex("Pull-up", "Back", 4, "6-10", 120,
           "Chin over the bar, elbows driving down. Band-assisted counts — earn the strict ones over time."),
        ex("Weighted Pull-up", "Back", 4, "5-8", 150,
           "Add weight via belt only when strict bodyweight reps feel easy. Form breaks = set over."))
    // Horizontal row
    private static let mRow = move(
        ex("One-Arm Dumbbell Row", "Back", 3, "10-12", 75,
           "Hand and knee on the bench, flat back. Row the dumbbell to your hip, squeeze the shoulder blade. No torso twisting."),
        ex("Barbell Row", "Back", 4, "8-10", 105,
           "Hinge to ~45°, row the bar to your lower ribs, flat back. The mid-back thickness that balances all your pressing."),
        ex("Pendlay Row", "Back", 4, "6-8", 120,
           "Row the bar from the floor each rep, explosive but controlled. Torso parallel to the floor."))
    // Seated row
    private static let mSeatedRow = move(
        ex("Cable Seated Row", "Back", 3, "10-12", 75,
           "Row the handle to your belly, squeezing the shoulder blades together. Chest tall, no rocking."),
        ex("Cable Seated Row", "Back", 3, "10-12", 75,
           "Row to the belly, squeeze the blades, control the return. Think 'proud chest' the whole set."),
        ex("Cable Seated Row", "Back", 4, "8-10", 90,
           "Slow eccentric on the way back — the stretch is half the rep."))
    // Squat
    private static let mSquat = move(
        ex("Goblet Squat", "Legs", 3, "8-12", 90,
           "Hold a dumbbell at chest height. Squat with your chest tall, knees tracking over your toes. The friendliest way to learn the pattern."),
        ex("Back Squat", "Legs", 4, "6-10", 150,
           "Bar on your upper back, squat to depth with a tall chest. Drive through mid-foot. Depth you control beats depth you bounce into."),
        ex("Back Squat", "Legs", 5, "5-8", 180,
           "Heavy squats build the frame. Brace hard, own the descent, no dive-bombing."))
    // Hinge
    private static let mHinge = move(
        ex("Romanian Deadlift", "Legs", 3, "8-12", 90,
           "Soft knees, hinge at the hips, flat back. Lower until you feel the hamstring stretch, then drive the hips forward. Your lower back will thank you for learning this one slow."),
        ex("Romanian Deadlift", "Legs", 4, "8-10", 105,
           "Hinge with a flat back and feel the hamstrings load. This is not a squat — the hips travel back, not down."),
        ex("Deadlift", "Posterior Chain", 4, "5", 180,
           "Pull from the floor, flat back, hips and shoulders rising together. Reset your brace every rep."))
    // Single-leg
    private static let mSplit = move(
        ex("Goblet Split Squat", "Legs", 2, "10/leg", 75,
           "Stagger your stance, lower straight down until the back knee nears the floor. Drive through the front heel."),
        ex("Bulgarian Split Squat", "Legs", 3, "10/leg", 90,
           "Rear foot on a bench, lower straight down. Humbling, and worth it — build the quads that widen your frame from the front."),
        ex("Bulgarian Split Squat", "Legs", 4, "8/leg", 105,
           "Rear foot elevated, torso tall. Add load slowly — these bite twice on the second set."))
    // Lunge
    private static let mLunge = move(
        ex("Walking Lunge", "Legs", 2, "12/leg", 75,
           "Step forward and lower until the back knee nears the floor. Torso tall, controlled steps."),
        ex("Walking Lunge", "Legs", 3, "12/leg", 75,
           "Long strides, tall torso. These finish a leg day honestly."),
        ex("Walking Lunge", "Legs", 3, "12/leg", 90,
           "Loaded walking lunges. Steady tempo — no rushing the sore ones."))
    // Hamstring isolation
    private static let mLegCurl = move(
        ex("Leg Curl", "Hamstrings", 3, "12-15", 60,
           "Curl with control and squeeze at the top. No swinging the stack."),
        ex("Leg Curl", "Hamstrings", 3, "12-15", 60,
           "Controlled reps, pause at the top. Hamstrings protect your knees — pay them attention."),
        ex("Glute Ham Raise", "Hamstrings", 3, "8-12", 75,
           "Lower with control using the hamstrings, pull back up. Brutal and excellent."))
    // Calves
    private static let mCalf = move(
        ex("Calf Raise", "Calves", 3, "12-15", 45,
           "Rise onto the balls of your feet, pause at the top. Full range, no bouncing."),
        ex("Calf Raise", "Calves", 4, "12-15", 45,
           "Full stretch at the bottom, pause at the top. Calves respond to honesty, not momentum."),
        ex("Seated Calf Raise", "Calves", 4, "15-20", 45,
           "Slow, controlled reps with a pause in the stretch."))
    // X-frame: lateral raise (Mason's signature width builder)
    private static let mLateral = move(
        ex("Lateral Raise", "Shoulders", 2, "12-15", 60,
           "Raise dumbbells out to the sides to shoulder height, leading with the elbows. Light weight, honest reps — this is the width builder."),
        ex("Lateral Raise", "Shoulders", 4, "12-15", 60,
           "Lead with the elbows to shoulder height. The single best investment for a wider frame. No swinging."),
        ex("Lateral Raise", "Shoulders", 4, "10-15", 75,
           "Strict laterals, pause at the top. Width is built in the last three honest reps."))
    // Rear delts / posture
    private static let mFacePull = move(
        ex("Face Pull", "Rear Delts", 3, "15-20", 60,
           "Pull the rope to your face, elbows high. Unsexy, unbeatable for posture and rear delts."),
        ex("Face Pull", "Rear Delts", 3, "15-20", 60,
           "Rope to face, elbows high, squeeze the rear delts. Your shoulders will thank you for every pressing day."),
        ex("Face Pull", "Rear Delts", 4, "15-20", 60,
           "High reps, strict form. Insurance for your shoulder joints."))
    // Arms
    private static let mCurl = move(
        ex("Dumbbell Curl", "Biceps", 2, "12-15", 60,
           "Curl with elbows pinned to your sides. No swinging — the muscle doesn't know the weight, only the tension."),
        ex("Hammer Curl", "Biceps", 3, "10-12", 60,
           "Neutral grip, elbows pinned. Builds the arm thickness sleeves show off."),
        ex("Incline Dumbbell Curl", "Biceps", 3, "10-12", 60,
           "Curl on an incline for a deep stretch. Slow down, controlled up."))
    private static let mTriceps = move(
        ex("Triceps Pushdown", "Triceps", 2, "12-15", 60,
           "Push the cable down to full extension, elbows tucked. Squeeze at the bottom."),
        ex("Triceps Pushdown", "Triceps", 3, "10-15", 60,
           "Elbows tucked, full extension, squeeze. Two-thirds of your arm is triceps — act like it."),
        ex("Rope Overhead Extension", "Triceps", 3, "12-15", 60,
           "Extend overhead and stretch long. The overhead angle hits the long head."))
    // Core — kept minimal on purpose (Mason: the waist stays tight through the big lifts)
    private static let mPlank = move(
        ex("Plank", "Core", 3, "30-45s", 45,
           "Straight line from head to heels, abs and glutes braced. The abs you build here are written by your squats anyway."),
        ex("Hanging Knee Raise", "Core", 3, "10-12", 60,
           "Hang and raise your knees without swinging. Control beats height."),
        ex("Hanging Leg Raise", "Core", 3, "10-15", 60,
           "Straight legs up to the bar, no swing. Strict core work keeps the midsection tight."))
    // Conditioning (loseFat finisher)
    private static let conditioning = Exercise(
        name: "Conditioning Finisher — Incline Walk", muscleGroup: "Cardio", sets: 1,
        reps: "15-20 min", restSeconds: 0,
        description: "Easy pace you could hold a conversation at. This isn't punishment — it's gentle extra energy out, and it helps your recovery besides. Steps first, cardio second, always.")

    // MARK: Equipment adaptation (home dumbbells / bodyweight only)

    /// name → (home dumbbell variant, bodyweight variant). A nil variant means
    /// "keep the original" — the move already fits that setup.
    private static let substitutions: [String: (home: (name: String, cue: String)?,
                                                 bodyweight: (name: String, cue: String)?)] = [
        "Barbell Bench Press": (
            home: ("Dumbbell Bench Press", "Press dumbbells from chest to lockout, shoulder blades pinched. Lower with control — leave 1-2 reps in reserve."),
            bodyweight: ("Push-up", "Hands under shoulders, body straight. Lower until your chest nearly touches the floor. Slow your tempo when 12 feel easy — that's your barbell.")),
        "Dumbbell Bench Press": (
            home: nil,
            bodyweight: ("Push-up", "Hands under shoulders, body straight. Lower until your chest nearly touches the floor. Slow your tempo when 12 feel easy — that's your barbell.")),
        "Incline Barbell Press": (
            home: ("Incline Dumbbell Press", "Press dumbbells on a ~30° incline. Great for upper chest — the shelf that reads 'built' in a T-shirt."),
            bodyweight: ("Push-up (Feet Elevated)", "Feet on a step or couch to bias the upper chest. Keep the body straight — no sagging hips.")),
        "Incline Dumbbell Press": (
            home: nil,
            bodyweight: ("Push-up (Feet Elevated)", "Feet on a step or couch to bias the upper chest. Keep the body straight — no sagging hips.")),
        "Overhead Press": (
            home: ("Dumbbell Shoulder Press", "Seated press from shoulder height. Ribs down, core tight, no leaning back."),
            bodyweight: ("Pike Push-up", "Hips high, head traveling toward the floor between your hands — the bodyweight overhead press. Deepen the pike as you get stronger.")),
        "Dumbbell Shoulder Press": (
            home: nil,
            bodyweight: ("Pike Push-up", "Hips high, head traveling toward the floor between your hands — the bodyweight overhead press. Deepen the pike as you get stronger.")),
        "Pull-up": (
            home: ("One-Arm Dumbbell Row", "Hand and knee on a bench (or couch), flat back. Row the dumbbell to your hip, squeeze the shoulder blade. No torso twisting."),
            bodyweight: ("Inverted Row", "Lie under a sturdy table, grip the edge, and pull your chest to it with your body straight. Walk your feet out to make it harder.")),
        "Weighted Pull-up": (
            home: ("One-Arm Dumbbell Row", "Hand and knee on a bench (or couch), flat back. Row a heavy dumbbell to your hip, squeeze the shoulder blade."),
            bodyweight: ("Inverted Row (Feet Elevated)", "Lie under a sturdy table, feet up on a second surface. Pull your chest to the edge with your body dead straight.")),
        "Lat Pulldown": (
            home: ("Dumbbell Pullover", "Lie on the floor (or a bed), dumbbell overhead. Lower it behind your head slowly, feeling the lats stretch, then pull it back over your chest."),
            bodyweight: ("Inverted Row", "Lie under a sturdy table, grip the edge, and pull your chest to it with your body straight. Walk your feet out to make it harder.")),
        "Barbell Row": (
            home: ("One-Arm Dumbbell Row", "Hand and knee on a bench (or couch), flat back. Row the dumbbell to your hip, squeeze the shoulder blade."),
            bodyweight: ("Backpack Row", "Load a backpack with books. Hinge over with a flat back and row it to your hip. Homemade, honest, and it works.")),
        "Pendlay Row": (
            home: ("One-Arm Dumbbell Row", "Hand and knee on a bench (or couch), flat back. Row a heavy dumbbell to your hip with control."),
            bodyweight: ("Backpack Row", "Load a backpack with books. Hinge over with a flat back and row it to your hip. Homemade, honest, and it works.")),
        "Cable Seated Row": (
            home: ("Bent-Over Dumbbell Row", "Hinge to ~45°, both dumbbells hanging. Row to your lower ribs, squeeze the blades, flat back."),
            bodyweight: ("Reverse Snow Angels", "Lie face down, arms at your sides. Sweep them overhead like a snow angel, thumbs up, keeping them off the floor the whole way. Humbling and effective.")),
        "One-Arm Dumbbell Row": (
            home: nil,
            bodyweight: ("Backpack Row", "Load a backpack with books. Hinge over with a flat back and row it to your hip. Homemade, honest, and it works.")),
        "Back Squat": (
            home: ("Goblet Squat", "Hold a dumbbell at chest height. Squat with your chest tall, knees tracking over your toes. Add load slowly — depth first, weight second."),
            bodyweight: ("Bodyweight Squat", "Feet shoulder-width, squat to depth with a tall chest, drive through mid-foot. Slow 3-second descents when they get easy.")),
        "Front Squat": (
            home: ("Goblet Squat", "Hold a dumbbell at chest height and squat tall — the goblet position keeps your torso honest."),
            bodyweight: ("Split Squat", "Stagger your stance, lower straight down until the back knee nears the floor. Drive through the front heel.")),
        "Goblet Squat": (
            home: nil,
            bodyweight: ("Bodyweight Squat", "Feet shoulder-width, squat to depth with a tall chest, drive through mid-foot. Slow 3-second descents when they get easy.")),
        "Goblet Split Squat": (
            home: nil,
            bodyweight: ("Split Squat", "Stagger your stance, lower straight down until the back knee nears the floor. Drive through the front heel.")),
        "Deadlift": (
            home: ("Dumbbell Deadlift", "Dumbbells at your sides, flat back, hips and shoulders rising together. Brace before every rep."),
            bodyweight: ("Hip Thrust (Shoulders Elevated)", "Upper back on a couch or bed, feet planted. Drive the hips to the ceiling and squeeze at the top.")),
        "Romanian Deadlift": (
            home: ("Dumbbell Romanian Deadlift", "Soft knees, hinge at the hips with dumbbells close to your legs, flat back. Feel the hamstring stretch, then drive the hips forward."),
            bodyweight: ("Glute Bridge", "Lie on your back, feet planted. Drive the hips up and squeeze the glutes at the top — don't arch your lower back.")),
        "Leg Curl": (
            home: ("Single-Leg Romanian Deadlift", "Hinge on one leg, flat back, other leg reaching back. Slow and balanced — it trains the hinge and the stabilizers."),
            bodyweight: ("Single-Leg Glute Bridge", "One foot planted, other leg extended. Drive the hips up evenly — no twisting.")),
        "Glute Ham Raise": (
            home: ("Single-Leg Romanian Deadlift", "Hinge on one leg, flat back, other leg reaching back. Slow and balanced."),
            bodyweight: ("Single-Leg Glute Bridge", "One foot planted, other leg extended. Drive the hips up evenly — no twisting.")),
        "Seated Calf Raise": (
            home: ("Calf Raise", "Full stretch at the bottom, pause at the top. Calves respond to honesty, not momentum."),
            bodyweight: ("Single-Leg Calf Raise", "One foot at a time, full stretch at the bottom, pause at the top. Hold a wall for balance.")),
        "Lateral Raise": (
            home: nil,
            bodyweight: ("Prone Y-Raise", "Lie face down, arms overhead in a Y, thumbs up. Lift your arms as high as they'll go, pause, lower slow. Real delt work without a weight.")),
        "Face Pull": (
            home: ("Dumbbell Rear Delt Fly", "Hinge to ~45°, dumbbells hanging. Raise them out to the sides, leading with the thumbs slightly up. Light weight, honest reps."),
            bodyweight: ("Prone T-Raise", "Lie face down, arms straight out in a T, thumbs up. Lift toward the ceiling, pause, lower slow.")),
        "Triceps Pushdown": (
            home: ("Dumbbell Overhead Triceps Extension", "One dumbbell in both hands overhead. Lower behind your head, stretch long, press back up."),
            bodyweight: ("Bench Dips", "Hands on a sturdy chair or step, legs out. Lower until your elbows hit ~90°, press back up. Keep your back close to the bench.")),
        "Rope Overhead Extension": (
            home: ("Dumbbell Overhead Triceps Extension", "One dumbbell in both hands overhead. Lower behind your head, stretch long, press back up."),
            bodyweight: ("Bench Dips", "Hands on a sturdy chair or step, legs out. Lower until your elbows hit ~90°, press back up. Keep your back close to the bench.")),
        "Hammer Curl": (
            home: nil,
            bodyweight: ("Backpack Curl", "Load a backpack with books, grab the strap, and curl. Slow and controlled — the muscle doesn't know the price of the equipment.")),
        "Incline Dumbbell Curl": (
            home: ("Dumbbell Curl", "Curl with elbows pinned to your sides. No swinging — the muscle doesn't know the weight, only the tension."),
            bodyweight: ("Backpack Curl", "Load a backpack with books, grab the strap, and curl. Slow and controlled — the muscle doesn't know the price of the equipment.")),
        "Dumbbell Curl": (
            home: nil,
            bodyweight: ("Backpack Curl", "Load a backpack with books, grab the strap, and curl. Slow and controlled — the muscle doesn't know the price of the equipment.")),
        "Hanging Knee Raise": (
            home: ("Dead Bug", "On your back, arms and legs up. Lower opposite arm and leg slowly while keeping your lower back pressed flat."),
            bodyweight: ("Dead Bug", "On your back, arms and legs up. Lower opposite arm and leg slowly while keeping your lower back pressed flat.")),
        "Hanging Leg Raise": (
            home: ("Dead Bug", "On your back, arms and legs up. Lower opposite arm and leg slowly while keeping your lower back pressed flat."),
            bodyweight: ("Dead Bug", "On your back, arms and legs up. Lower opposite arm and leg slowly while keeping your lower back pressed flat.")),
    ]

    /// Swap gym exercises for home-dumbbell or bodyweight equivalents,
    /// keeping the level-appropriate sets, reps, and rest.
    private static func adapted(_ exercise: Exercise, for equipment: EquipmentAccess) -> Exercise {
        guard equipment != .fullGym,
              let sub = substitutions[exercise.name] else { return exercise }
        let variant: (name: String, cue: String)?
        switch equipment {
        case .homeDumbbells: variant = sub.home
        case .bodyweightOnly: variant = sub.bodyweight
        case .fullGym: variant = nil
        }
        guard let v = variant else { return exercise }
        return Exercise(name: v.name, muscleGroup: exercise.muscleGroup, sets: exercise.sets,
                        reps: exercise.reps, restSeconds: exercise.restSeconds, description: v.cue)
    }

    // MARK: Day templates

    private static func upperA(_ p: UserProfile) -> [Exercise] {
        [mPress.pick(for: p.experience), mLatPull.pick(for: p.experience),
         mOhp.pick(for: p.experience), mRow.pick(for: p.experience),
         mLateral.pick(for: p.experience), mFacePull.pick(for: p.experience)]
    }

    private static func lowerA(_ p: UserProfile) -> [Exercise] {
        [mSquat.pick(for: p.experience), mHinge.pick(for: p.experience),
         mSplit.pick(for: p.experience), mLegCurl.pick(for: p.experience),
         mCalf.pick(for: p.experience)]
    }

    private static func upperB(_ p: UserProfile) -> [Exercise] {
        [mIncline.pick(for: p.experience), mLatPull.pick(for: p.experience),
         mSeatedRow.pick(for: p.experience), mLateral.pick(for: p.experience),
         mFacePull.pick(for: p.experience), mCurl.pick(for: p.experience)]
    }

    private static func lowerB(_ p: UserProfile) -> [Exercise] {
        [mHinge.pick(for: p.experience), mSquat.pick(for: p.experience),
         mLunge.pick(for: p.experience), mLegCurl.pick(for: p.experience),
         mCalf.pick(for: p.experience)]
    }

    private static func xFrameDay(_ p: UserProfile) -> [Exercise] {
        [mOhp.pick(for: p.experience), mLatPull.pick(for: p.experience),
         mLateral.pick(for: p.experience), mFacePull.pick(for: p.experience),
         mCurl.pick(for: p.experience), mTriceps.pick(for: p.experience)]
    }

    private static func pushDay(_ p: UserProfile) -> [Exercise] {
        [mPress.pick(for: p.experience), mOhp.pick(for: p.experience),
         mIncline.pick(for: p.experience), mLateral.pick(for: p.experience),
         mTriceps.pick(for: p.experience)]
    }

    private static func pullDay(_ p: UserProfile) -> [Exercise] {
        [mLatPull.pick(for: p.experience), mRow.pick(for: p.experience),
         mSeatedRow.pick(for: p.experience), mFacePull.pick(for: p.experience),
         mCurl.pick(for: p.experience)]
    }

    private static func legsDay(_ p: UserProfile) -> [Exercise] {
        [mSquat.pick(for: p.experience), mHinge.pick(for: p.experience),
         mSplit.pick(for: p.experience), mLegCurl.pick(for: p.experience),
         mCalf.pick(for: p.experience), mPlank.pick(for: p.experience)]
    }

    private static func fullBodyA(_ p: UserProfile) -> [Exercise] {
        [mSquat.pick(for: p.experience), mPress.pick(for: p.experience),
         mLatPull.pick(for: p.experience), mLateral.pick(for: p.experience),
         mPlank.pick(for: p.experience)]
    }

    private static func fullBodyB(_ p: UserProfile) -> [Exercise] {
        [mHinge.pick(for: p.experience), mOhp.pick(for: p.experience),
         mRow.pick(for: p.experience), mLateral.pick(for: p.experience),
         mLegCurl.pick(for: p.experience)]
    }

    private static func fullBodyC(_ p: UserProfile) -> [Exercise] {
        [mIncline.pick(for: p.experience), mSeatedRow.pick(for: p.experience),
         mLunge.pick(for: p.experience), mTriceps.pick(for: p.experience),
         mCurl.pick(for: p.experience), mFacePull.pick(for: p.experience)]
    }

    // MARK: Program assembly

    /// Build a personalized program from the profile: split by schedule,
    /// exercise selection and rep schemes by experience, goal-specific tweaks.
    static func generateProgram(for profile: UserProfile) -> WorkoutProgram {
        let level = profile.experience
        let goal = profile.goal

        let dayTemplates: [(String, String, (UserProfile) -> [Exercise])]
        switch profile.daysPerWeek {
        case 3:
            dayTemplates = [
                ("Day 1 — Full Body A", "Squat / Press / Pull", fullBodyA),
                ("Day 2 — Full Body B", "Hinge / Shoulders / Row", fullBodyB),
                ("Day 3 — Full Body C", "Incline / Row / Single-Leg", fullBodyC),
            ]
        case 4:
            dayTemplates = [
                ("Day 1 — Upper A", "Strength Press + Volume Pull", upperA),
                ("Day 2 — Lower A", "Squat Focus", lowerA),
                ("Day 3 — Upper B", "Volume Press + Heavy Row", upperB),
                ("Day 4 — Lower B", "Hinge Focus", lowerB),
            ]
        case 5:
            dayTemplates = [
                ("Day 1 — Upper A", "Strength Press + Volume Pull", upperA),
                ("Day 2 — Lower A", "Squat Focus", lowerA),
                ("Day 3 — Upper B", "Volume Press + Heavy Row", upperB),
                ("Day 4 — Lower B", "Hinge Focus", lowerB),
                ("Day 5 — X-Frame", "Delts / Lats / Arms — the width day", xFrameDay),
            ]
        default: // 6 days
            dayTemplates = [
                ("Day 1 — Push A", "Chest / Shoulders / Triceps", pushDay),
                ("Day 2 — Pull A", "Back / Biceps", pullDay),
                ("Day 3 — Legs A", "Quads / Hams / Glutes", legsDay),
                ("Day 4 — Push B", "Chest / Shoulders / Triceps", pushDay),
                ("Day 5 — Pull B", "Back / Biceps", pullDay),
                ("Day 6 — Legs B", "Quads / Hams / Glutes", legsDay),
            ]
        }

        let days = dayTemplates.map { (title, focus, builder) in
            var exercises = builder(profile).map { adapted($0, for: profile.equipment) }
            // Maintain: a lighter week — keep the big lifts, drop the last accessory.
            if goal == .maintain, exercises.count > 4 {
                exercises.removeLast()
            }
            // Lose fat: same lifts, plus a gentle conditioning finisher.
            if goal == .loseFat {
                exercises.append(conditioning)
            }
            return WorkoutDay(title: title, focus: focus, exercises: exercises)
        }

        let splitName: String
        switch profile.daysPerWeek {
        case 3: splitName = "Full Body"
        case 4: splitName = "Upper / Lower"
        case 5: splitName = "Upper / Lower + X-Frame"
        default: splitName = "Push / Pull / Legs"
        }

        let summary = summaryFor(goal: goal, level: level, splitName: splitName, equipment: profile.equipment)

        return WorkoutProgram(
            name: "Your Plan — \(splitName)",
            summary: summary,
            level: level,
            goal: goal,
            daysPerWeek: profile.daysPerWeek,
            days: days
        )
    }

    private static func summaryFor(goal: FitnessGoal, level: ExperienceLevel, splitName: String,
                                   equipment: EquipmentAccess) -> String {
        var lines: [String] = []
        lines.append("Your \(splitName) program, built for a \(level.rawValue.lowercased()) lifter chasing '\(goal.rawValue)'.")
        switch equipment {
        case .fullGym:
            break
        case .homeDumbbells:
            lines.append("Built for a home dumbbell setup — every lift has a dumbbell-friendly equivalent, so nothing gets skipped, just adapted.")
        case .bodyweightOnly:
            lines.append("Built for bodyweight training — no equipment needed beyond a sturdy table, a loaded backpack, and the floor.")
        }
        switch goal {
        case .buildMuscle:
            lines.append("Every upper day carries lateral raises and lat work — that's the X-frame: wide shoulders and lats standing on solid quads. Progressive overload is the whole game: when you hit the top of a rep range, add a small weight jump next session — reps first, then weight, never both at once.")
        case .loseFat:
            lines.append("You keep every heavy lift — a deficit is no excuse to train small — with a gentle conditioning finisher to close each day. Strength holds, fat trends down, hunger stays manageable. Add reps or a small weight jump when the top of the range feels easy.")
        case .recomp:
            lines.append("Balanced volume, twice-weekly frequency per muscle, and patient progression. You're building the frame and letting nutrition do the revealing. When the top of a rep range feels easy, take a small weight jump.")
        case .maintain:
            lines.append("The big lifts, slightly trimmed, so you keep everything you've built with room to live your life. Hold your numbers — maintenance is an achievement, not a consolation prize.")
        }
        return lines.joined(separator: " ")
    }

    // MARK: - Weekly adjustment (check-in driven)

    struct WeeklyAdjustment: Equatable {
        let title: String
        let message: String
        let symbol: String
        let calorieDelta: Int
        let isDeload: Bool
    }

    /// Mason reads the week's check-in and adjusts the plan. Wellbeing leads,
    /// numbers follow — and no outcome is ever framed as failure.
    static func weeklyAdjustment(for checkIn: WeeklyCheckIn, goal: FitnessGoal) -> WeeklyAdjustment {
        // 1. Struggling → planned deload. Rest is training.
        if checkIn.progressFeeling == .reallyStruggling || checkIn.progressFeeling == .frustrated {
            return WeeklyAdjustment(
                title: "Lighter week — and that's smart, not soft",
                message: "Your check-in says this week was heavy going, so this week we lift lighter on purpose. Cut one set off each exercise and leave 3-4 reps in reserve. Recovery is part of the work — the plan bends so you don't break. You showed up to check in at all; that counts.",
                symbol: "figure.cooldown",
                calorieDelta: 0,
                isDeload: true)
        }

        // 2. Life stress or poor sleep → protect recovery.
        if checkIn.sleep <= 4 || checkIn.stress >= 8 {
            return WeeklyAdjustment(
                title: "Protect your recovery this week",
                message: "Sleep is low or stress is high, and your body reads both as the same emergency. Keep showing up, but drop the last exercise of each session and keep 2-3 reps in reserve on everything. A preserved week beats a hero week every time. And if you can trade one gym session for an extra hour of sleep — do it. I'd coach that as a win.",
                symbol: "moon.zzz.fill",
                calorieDelta: 0,
                isDeload: false)
        }

        // 3. Ravenous in a deficit → feed a little more, gently.
        if checkIn.hunger >= 8 && goal == .loseFat {
            return WeeklyAdjustment(
                title: "Fuel up — we're adding a little food",
                message: "Hunger that loud is data, not weakness. Add about 100 kcal this week (a Greek yogurt, a piece of fruit with peanut butter) and keep protein high — it blunts hunger and protects muscle. A slightly slower deficit you can live with beats a fast one you quit.",
                symbol: "fork.knife",
                calorieDelta: 100,
                isDeload: false)
        }

        // 4. All green → green light to progress.
        if checkIn.energy >= 7, checkIn.sleep >= 7, checkIn.stress <= 5,
           checkIn.workoutAdherence == .all || checkIn.workoutAdherence == .most {
            return WeeklyAdjustment(
                title: "Green light — push it",
                message: "Energy's up, sleep's solid, and you did the work. This is the week to progress: on your last set of each exercise, take one extra rep or a small weight jump — never both at once. Log honestly, lift with intent, and let the numbers chase you.",
                symbol: "bolt.fill",
                calorieDelta: 0,
                isDeload: false)
        }

        // 5. Steady default.
        return WeeklyAdjustment(
            title: "Steady week — consistency is the flex",
            message: "Nothing needs fixing. Keep training, keep fueling, and keep the check-ins coming — we adjust when the data says to, not just because the calendar turned. Slow is smooth, smooth is fast.",
            symbol: "figure.walk.motion",
            calorieDelta: 0,
            isDeload: false)
    }
}
