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

    private let totalSteps = 7

    var body: some View {
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
            // Entered in US units (lbs, ft+in); stored as kg/cm for BMR math.
            let bw = (Double(bodyweightLbs) ?? 0) * 0.453592
            let ft = Double(heightFt) ?? 0
            let inches = Double(heightIn) ?? 0
            let h = ft * 30.48 + inches * 2.54
            let a = Int(age)
            app.completeIntake(
                goal: goal, experience: experience, daysPerWeek: daysPerWeek,
                lifestyle: lifestyle, equipment: equipment,
                bodyweightKg: bw > 0 ? (bw * 10).rounded() / 10 : nil,
                heightCm: h > 0 ? (h * 10).rounded() / 10 : nil,
                age: (a ?? 0) > 0 ? a : nil
            )
        }
    }
}

#Preview {
    IntakeView().environment(AppModel())
}
