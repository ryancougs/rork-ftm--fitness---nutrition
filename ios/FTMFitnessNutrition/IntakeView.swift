//
//  IntakeView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Onboarding intake: goal, experience, days/week, lifestyle, equipment
/// access, and optional body stats that feed the BMR-based nutrition targets.
struct IntakeView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var step: Int = 0
    @State private var goal: FitnessGoal = .buildMuscle
    @State private var experience: ExperienceLevel = .beginner
    @State private var daysPerWeek: Int = 4
    @State private var lifestyle: Lifestyle = .mostlySitting
    @State private var equipment: EquipmentAccess = .fullGym
    @State private var bodyweightLbs: String = ""
    @State private var heightFt: String = ""
    @State private var heightIn: String = ""
    @State private var age: String = ""

    /// After the last question: a personalized "your plan is ready" reveal
    /// that builds anticipation before the trial offer.
    @State private var showReveal: Bool = false
    @State private var isBuilding: Bool = true
    @State private var revealed: Bool = false

    private let totalSteps = 7

    var body: some View {
        if showReveal {
            planReveal
                .transition(.opacity)
        } else {
            questionnaire
        }
    }

    private var questionnaire: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(spacing: 24) {
                        stepHeader
                        stepContent
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
                .scrollDismissesKeyboard(.immediately)
                .dismissKeyboardOnTap()
                navigationBar
            }
            .keyboardDoneBar()
            .toolbar(.hidden, for: .navigationBar)
        }
        .background(TF.bg.ignoresSafeArea())
    }

    // MARK: Progress

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Let's set you up")
                    .font(.headline)
                    .foregroundStyle(TF.text)
                Spacer()
                Text("Step \(step + 1) of \(totalSteps)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TF.card).frame(height: 6)
                    Capsule()
                        .fill(TF.blue)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var progress: Double {
        Double(step + 1) / Double(totalSteps)
    }

    // MARK: Step content

    @ViewBuilder
    private var stepHeader: some View {
        switch step {
        case 0:
            introHeader
        case 1:
            Text("What's your main goal right now?")
                .font(.title2.weight(.bold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        case 2:
            Text("How experienced are you with lifting?")
                .font(.title2.weight(.bold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        case 3:
            Text("How many days a week can you train?")
                .font(.title2.weight(.bold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        case 4:
            Text("What's your day-to-day like outside the gym?")
                .font(.title2.weight(.bold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        case 5:
            Text("What equipment do you have access to?")
                .font(.title2.weight(.bold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        default:
            Text("A bit about you (optional)")
                .font(.title2.weight(.bold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var introHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Welcome, \(app.profile.name.isEmpty ? "friend" : app.profile.name.split(separator: " ").first.map(String.init) ?? app.profile.name)")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(TF.blue)
            Text("This is a space where you don't have to explain yourself before you start training. The only FTM fitness app you'll need. Let's tailor things to you — this takes about two minutes.")
                .font(.body)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.leading)
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(TF.blue)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:
            EmptyView()
        case 1:
            VStack(spacing: 12) {
                ForEach(FitnessGoal.allCases) { g in
                    TFChip(g.rawValue, subtitle: g.blurb, emoji: g.emoji, selected: goal == g) {
                        goal = g
                    }
                }
            }
        case 2:
            VStack(spacing: 12) {
                ForEach(ExperienceLevel.allCases) { lvl in
                    TFChip(lvl.rawValue, subtitle: lvl.blurb, emoji: nil, selected: experience == lvl) {
                        experience = lvl
                    }
                }
            }
        case 3:
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ForEach([3, 4, 5, 6], id: \.self) { d in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { daysPerWeek = d }
                        } label: {
                            Text("\(d)")
                                .font(.title2.weight(.bold))
                                .foregroundStyle(daysPerWeek == d ? TF.bg : TF.text)
                                .frame(width: 64, height: 64)
                                .background {
                                    if daysPerWeek == d {
                                        Circle().fill(TF.blue)
                                    } else {
                                        Circle().fill(TF.input)
                                    }
                                }
                        }
                    }
                }
                Text("days per week")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text("We'll spread your program across these days so training fits your life, not the other way around.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
        case 4:
            VStack(spacing: 12) {
                ForEach(Lifestyle.allCases) { l in
                    TFChip(l.rawValue, subtitle: l.blurb, emoji: l.emoji, selected: lifestyle == l) {
                        lifestyle = l
                    }
                }
                Text("Moving outside the gym counts — it shapes your calorie targets.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        case 5:
            VStack(spacing: 12) {
                ForEach(EquipmentAccess.allCases) { e in
                    TFChip(e.rawValue, subtitle: e.blurb, emoji: e.emoji, selected: equipment == e) {
                        equipment = e
                    }
                }
                Text("Your plan adapts to what you have — a full gym, dumbbells at home, or just the floor.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        default:
            optionalStats
        }
    }

    private var optionalStats: some View {
        VStack(spacing: 14) {
            TFCard(background: TF.blue.opacity(0.10)) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Why we ask", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TF.blue)
                    Text("Your height, weight, and age drive your BMR — the calories your body burns just existing. That's how we set calorie and protein targets that actually fit you, instead of guessing.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            statField("Bodyweight (lbs)", text: $bodyweightLbs)
            HStack(spacing: 10) {
                statField("Height (ft)", text: $heightFt)
                statField("Height (in)", text: $heightIn)
            }
            statField("Age", text: $age)
            Text("Skip anything you'd rather not share — we'll use sensible estimates you can refine any time in Profile.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)
        }
    }

    @ViewBuilder
    private func statField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(TF.text)
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .foregroundStyle(TF.text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
        }
    }

    // MARK: Navigation bar

    private var navigationBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                TFButton(title: "Back", systemImage: "chevron.left", style: .ghost) {
                    withAnimation { step -= 1 }
                }
            }
            TFButton(
                title: step == totalSteps - 1 ? "Finish" : "Continue",
                systemImage: step == totalSteps - 1 ? "checkmark" : "arrow.right",
                style: .primary,
                action: advance
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(TF.bg.shadow(color: .black.opacity(0.4), radius: 8, y: -4))
    }

    private func advance() {
        if step < totalSteps - 1 {
            withAnimation(.easeOut(duration: 0.25)) { step += 1 }
        } else {
            startReveal()
        }
    }

    // MARK: Body stats (entered in US units, stored as kg/cm for BMR math)

    private var bodyweightKgValue: Double? {
        let bw = (Double(bodyweightLbs) ?? 0) * 0.453592
        return bw > 0 ? (bw * 10).rounded() / 10 : nil
    }

    private var heightCmValue: Double? {
        let h = (Double(heightFt) ?? 0) * 30.48 + (Double(heightIn) ?? 0) * 2.54
        return h > 0 ? (h * 10).rounded() / 10 : nil
    }

    private var ageValue: Int? {
        guard let a = Int(age), a > 0 else { return nil }
        return a
    }

    /// The profile as it will be saved, used to preview the real plan.
    private var draftProfile: UserProfile {
        var p = app.profile
        p.goal = goal
        p.experience = experience
        p.daysPerWeek = daysPerWeek
        p.lifestyle = lifestyle
        p.equipment = equipment
        p.bodyweightKg = bodyweightKgValue
        p.heightCm = heightCmValue
        p.age = ageValue
        return p
    }

    private func finishIntake() {
        app.completeIntake(
            goal: goal, experience: experience, daysPerWeek: daysPerWeek,
            lifestyle: lifestyle, equipment: equipment,
            bodyweightKg: bodyweightKgValue,
            heightCm: heightCmValue,
            age: ageValue
        )
    }

    // MARK: Plan reveal

    private func startReveal() {
        isBuilding = true
        revealed = false
        withAnimation(.easeInOut(duration: 0.35)) { showReveal = true }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { isBuilding = false }
            try? await Task.sleep(for: .seconds(0.15))
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { revealed = true }
        }
    }

    private var firstName: String {
        let n = app.profile.name.split(separator: " ").first.map(String.init) ?? ""
        return n.isEmpty ? "friend" : n
    }

    private var planReveal: some View {
        let profile = draftProfile
        let targets = PlanEngine.targets(for: profile)
        let program = PlanEngine.generateProgram(for: profile)

        return ZStack {
            TF.bg.ignoresSafeArea()
            TF.accentGradient.ignoresSafeArea()

            if isBuilding {
                VStack(spacing: 22) {
                    ProgressView()
                        .controlSize(.large)
                        .tint(TF.blue)
                    Text("Building your plan, \(firstName)…")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(TF.text)
                    VStack(alignment: .leading, spacing: 8) {
                        buildLine("Calculating your daily energy needs")
                        buildLine("Setting protein for \(profile.goal.rawValue.lowercased())")
                        buildLine("Designing a \(profile.daysPerWeek)-day training split")
                    }
                    .font(.subheadline)
                    .foregroundStyle(TF.textSecondary)
                }
                .padding(24)
                .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Your plan is ready")
                                    .font(.largeTitle.weight(.bold))
                                    .foregroundStyle(TF.text)
                                Text("Built around you, \(firstName). Your goal, your body, your schedule. No explaining yourself required.")
                                    .font(.body)
                                    .foregroundStyle(TF.textSecondary)
                            }

                            revealCard(delay: 0.0) {
                                VStack(alignment: .leading, spacing: 14) {
                                    Label("Daily nutrition", systemImage: "fork.knife")
                                        .font(.headline)
                                        .foregroundStyle(TF.blue)
                                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                                        Text("\(targets.calories)")
                                            .font(.system(size: 44, weight: .bold, design: .rounded))
                                            .foregroundStyle(TF.text)
                                            .contentTransition(.numericText())
                                        Text("calories")
                                            .font(.subheadline)
                                            .foregroundStyle(TF.textSecondary)
                                    }
                                    HStack(spacing: 10) {
                                        macroPill("Protein", targets.protein, TF.protein)
                                        macroPill("Carbs", targets.carbs, TF.carbs)
                                        macroPill("Fat", targets.fat, TF.fat)
                                    }
                                }
                            }

                            revealCard(delay: 0.12) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Your training", systemImage: "figure.strengthtraining.traditional")
                                        .font(.headline)
                                        .foregroundStyle(TF.blue)
                                    Text(program.name)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(TF.text)
                                    Text("\(program.days.count) sessions a week · \(profile.experience.rawValue) · \(profile.equipment.rawValue)")
                                        .font(.subheadline)
                                        .foregroundStyle(TF.textSecondary)
                                }
                            }

                            revealCard(delay: 0.24) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Label("Included with your plan", systemImage: "sparkles")
                                        .font(.headline)
                                        .foregroundStyle(TF.pink)
                                    perkLine("camera.viewfinder", "AI meal scanning: snap a photo, get the macros")
                                    perkLine("barcode.viewfinder", "Barcode scanner and food search")
                                    perkLine("chart.line.uptrend.xyaxis", "Weekly check-ins that adjust your targets")
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 28)
                        .padding(.bottom, 24)
                    }

                    TFButton(title: "Start my plan", systemImage: "arrow.right", style: .primary) {
                        finishIntake()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .opacity(revealed ? 1 : 0)
                }
                .transition(.opacity)
            }
        }
    }

    private func buildLine(_ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(TF.success)
            Text(text)
        }
    }

    private func revealCard<Content: View>(delay: Double, @ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(RoundedRectangle(cornerRadius: TF.cornerL).fill(TF.card))
            .overlay(RoundedRectangle(cornerRadius: TF.cornerL).stroke(TF.border, lineWidth: 1))
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 18)
            .animation(.spring(response: 0.6, dampingFraction: 0.85).delay(delay), value: revealed)
    }

    private func macroPill(_ label: String, _ grams: Int, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(grams)g")
                .font(.headline)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(TF.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
    }

    private func perkLine(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(TF.blue)
                .frame(width: 22)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(TF.text)
        }
    }
}

#Preview {
    IntakeView().environment(AppModel())
}
