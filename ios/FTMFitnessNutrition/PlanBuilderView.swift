//
//  PlanBuilderView.swift
//  FTMFitnessNutrition
//
//  Premium: the in-depth plan builder. Seven short steps about the person's
//  goals, schedule, life, experience, equipment, body and preferences, then
//  the AI builds a program around all of it.
//

import SwiftUI
import UIKit

struct PlanBuilderView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    private typealias O = PlanIntake.Option

    private enum Phase: Equatable {
        case questions
        case building
        case done
        case failed(String)
    }

    @State private var phase: Phase = .questions
    @State private var step = 0
    private let lastStep = 7

    // Answers
    @State private var intake = PlanIntake()
    @State private var goal: FitnessGoal = .buildMuscle
    @State private var experience: ExperienceLevel = .beginner
    @State private var lifestyle: Lifestyle = .mostlySitting
    @State private var equipment: EquipmentAccess = .fullGym
    @State private var weekdays: Set<Int> = []
    @State private var agreedToAI = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Group {
                switch phase {
                case .questions: questions
                case .building: buildingView
                case .done: doneView
                case .failed(let message): failedView(message)
                }
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Build your plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if phase != .building {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(phase == .done ? "Done" : "Close") { dismiss() }
                            .foregroundStyle(TF.blue)
                    }
                }
            }
        }
        .interactiveDismissDisabled(phase == .building)
        .onAppear(perform: prefill)
    }

    // MARK: - Questions

    private var questions: some View {
        VStack(spacing: 0) {
            progressBar
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    stepContent
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            navBar
        }
        .keyboardDoneBar()
    }

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text(stepName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(step + 1) of \(lastStep + 1)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(TF.card).frame(height: 6)
                    Capsule()
                        .fill(TF.blue)
                        .frame(width: geo.size.width * Double(step + 1) / Double(lastStep + 1), height: 6)
                        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private var stepName: String {
        ["Welcome", "Goals", "Schedule", "Your life", "Experience & equipment",
         "Body & safety", "Preferences", "Review"][step]
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: introStep
        case 1: goalStep
        case 2: scheduleStep
        case 3: lifeStep
        case 4: experienceStep
        case 5: bodyStep
        case 6: preferencesStep
        default: reviewStep
        }
    }

    private var navBar: some View {
        HStack(spacing: 12) {
            if step > 0 {
                TFButton(title: "Back", systemImage: nil, style: .secondary) {
                    withAnimation { step -= 1 }
                }
                .frame(maxWidth: 120)
            }
            if step < lastStep {
                TFButton(title: step == 0 ? "Let's go" : "Next", systemImage: "arrow.right",
                         style: .primary, disabled: !canContinue) {
                    dismissKeyboard()
                    withAnimation { step += 1 }
                }
            } else {
                TFButton(title: "Build my plan", systemImage: "sparkles", style: .primary,
                         disabled: !agreedToAI, action: build)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(TF.bg)
    }

    private var canContinue: Bool {
        switch step {
        case 2: (2...6).contains(weekdays.count)
        default: true
        }
    }

    // MARK: Step 0

    private var introStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(TF.blue)
            Text("A plan built around your actual life")
                .font(.title.weight(.bold))
                .foregroundStyle(TF.text)
            Text("Answer a few questions about your goals, schedule, job, sleep, body and what you like doing. Mason's coaching rules plus AI turn that into a program written for you, not a template.")
                .font(.subheadline)
                .foregroundStyle(TF.textSecondary)
            TFCard {
                VStack(alignment: .leading, spacing: 10) {
                    bullet("clock", "Takes about 3 minutes")
                    bullet("lock.shield", "Your answers stay on your phone. Personal questions are optional")
                    bullet("arrow.triangle.2.circlepath", "Rebuild any time your life changes")
                }
            }
        }
    }

    // MARK: Step 1: Goals

    private var goalStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            question("What's your main goal?")
            VStack(spacing: 10) {
                ForEach(FitnessGoal.allCases) { g in
                    TFChip(g.rawValue, subtitle: g.blurb, emoji: g.emoji, selected: goal == g) { goal = g }
                }
            }
            question("Where do you want to see the most change?", hint: "Pick up to 3")
            FlowChips(options: O.focusAreas, selected: Set(intake.focusAreas)) { area in
                toggle(area, in: &intake.focusAreas, max: 3)
            }
            question("What would success look like in 12 weeks?", hint: "Optional")
            field("e.g. my shirts fit across the shoulders, 10 pull-ups", text: $intake.successLooksLike, max: 300)
        }
    }

    // MARK: Step 2: Schedule

    private var scheduleStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            question("Which days can you train?", hint: "Pick 2 to 6 days")
            weekdayPicker
            if !(2...6).contains(weekdays.count) {
                Text("Choose between 2 and 6 days.")
                    .font(.caption)
                    .foregroundStyle(TF.warning)
            }
            question("How long can a session be?")
            FlowChips(options: O.sessionMinutes.map { "\($0) min" },
                      selected: ["\(intake.sessionMinutes) min"]) { label in
                intake.sessionMinutes = Int(label.prefix { $0.isNumber }) ?? 60
            }
            question("When do you usually train?")
            FlowChips(options: O.timeOfDay, selected: [intake.timeOfDay]) { intake.timeOfDay = $0 }
            question("What's your work or school schedule like?")
            FlowChips(options: O.workSchedule, selected: [intake.workSchedule]) { intake.workSchedule = $0 }
        }
    }

    private var weekdayPicker: some View {
        let order = [2, 3, 4, 5, 6, 7, 1] // Monday first; 1 = Sunday
        let symbols = Calendar.current.veryShortWeekdaySymbols
        return HStack(spacing: 8) {
            ForEach(order, id: \.self) { wd in
                let isOn = weekdays.contains(wd)
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    if isOn { weekdays.remove(wd) } else { weekdays.insert(wd) }
                } label: {
                    Text(symbols[wd - 1])
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(isOn ? TF.bg : TF.text)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Circle().fill(isOn ? TF.blue : TF.input))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Calendar.current.weekdaySymbols[wd - 1])
                .accessibilityAddTraits(isOn ? [.isSelected] : [])
            }
        }
    }

    // MARK: Step 3: Life

    private var lifeStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            question("What's your day-to-day like?")
            VStack(spacing: 10) {
                ForEach(Lifestyle.allCases) { l in
                    TFChip(l.rawValue, subtitle: l.blurb, emoji: l.emoji, selected: lifestyle == l) { lifestyle = l }
                }
            }
            question("Anything else active in your week?", hint: "Pick any")
            FlowChips(options: O.otherActivities, selected: Set(intake.otherActivities)) { activity in
                toggle(activity, in: &intake.otherActivities, max: 9)
            }
            field("Details, e.g. soccer Tuesdays, 10k steps a day (optional)", text: $intake.otherActivitiesNote, max: 200)
            question("How much do you usually sleep?")
            FlowChips(options: O.sleep, selected: [intake.sleep]) { intake.sleep = $0 }
            question("How's your stress lately?")
            FlowChips(options: O.stress, selected: [intake.stress]) { intake.stress = $0 }
        }
    }

    // MARK: Step 4: Experience & equipment

    private var experienceStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            question("How experienced are you with lifting?")
            VStack(spacing: 10) {
                ForEach(ExperienceLevel.allCases) { e in
                    TFChip(e.rawValue, subtitle: e.blurb, selected: experience == e) { experience = e }
                }
            }
            question("How long have you been training consistently?")
            FlowChips(options: O.trainingHistory, selected: [intake.trainingHistory]) { intake.trainingHistory = $0 }
            question("Where do you train?")
            VStack(spacing: 10) {
                ForEach(EquipmentAccess.allCases) { eq in
                    TFChip(eq.rawValue, subtitle: eq.blurb, emoji: eq.emoji, selected: equipment == eq) { equipment = eq }
                }
            }
            if equipment != .bodyweightOnly {
                question("What do you have access to?", hint: "Pick everything that applies")
                FlowChips(options: O.equipmentItems, selected: Set(intake.equipmentItems)) { item in
                    toggle(item, in: &intake.equipmentItems, max: O.equipmentItems.count)
                }
            }
        }
    }

    // MARK: Step 5: Body & safety

    private var bodyStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            TFCard(background: TF.blue.opacity(0.12)) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Why we ask", systemImage: "heart.text.square")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.blue)
                    Text("These answers only make your plan safer, like keeping your chest out of it while you heal. Every question is optional, and they stay on your phone.")
                        .font(.footnote)
                        .foregroundStyle(TF.text)
                }
            }
            question("Any injuries or pain to work around?", hint: "Pick any")
            FlowChips(options: O.injuries, selected: Set(intake.injuries)) { area in
                toggle(area, in: &intake.injuries, max: O.injuries.count)
            }
            field("Details, e.g. right shoulder clicks on overhead press (optional)", text: $intake.injuryNotes, max: 300)
            question("Do you bind?")
            FlowChips(options: O.binding, selected: [intake.binding]) { intake.binding = $0 }
            question("Top surgery")
            FlowChips(options: O.topSurgery, selected: [intake.topSurgery]) { intake.topSurgery = $0 }
            if intake.topSurgery.hasPrefix("Recovering") {
                Text("Your plan will keep your chest and upper body out of it. Always follow your surgeon's clearance before adding upper-body work.")
                    .font(.caption)
                    .foregroundStyle(TF.warning)
            }
            question("Testosterone")
            FlowChips(options: O.testosterone, selected: [intake.testosterone]) { intake.testosterone = $0 }
            TFHealthDisclaimer(compact: true)
        }
    }

    // MARK: Step 6: Preferences

    private var preferencesStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            question("What kind of training do you want?")
            FlowChips(options: O.style, selected: [intake.style]) { intake.style = $0 }
            question("How do you feel about cardio?")
            FlowChips(options: O.cardio, selected: [intake.cardio]) { intake.cardio = $0 }
            question("Gym comfort")
            FlowChips(options: O.gymComfort, selected: [intake.gymComfort]) { intake.gymComfort = $0 }
            question("Exercises you love", hint: "Optional")
            field("e.g. hip thrusts, lat pulldowns", text: $intake.likes, max: 200)
            question("Exercises you'd rather skip", hint: "Optional")
            field("e.g. burpees, barbell back squats", text: $intake.dislikes, max: 200)
        }
    }

    // MARK: Step 7: Review & consent

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            question("Ready to build")
            TFCard {
                VStack(alignment: .leading, spacing: 10) {
                    summaryRow("Goal", goal.rawValue)
                    summaryRow("Focus", intake.focusAreas.isEmpty ? "Balanced" : intake.focusAreas.joined(separator: ", "))
                    summaryRow("Schedule", "\(weekdays.count) days, \(intake.sessionMinutes) min")
                    summaryRow("Level", experience.rawValue)
                    summaryRow("Equipment", equipment.rawValue)
                    if !intake.injuries.isEmpty {
                        summaryRow("Working around", intake.injuries.joined(separator: ", "))
                    }
                }
            }
            TFCard(background: TF.input) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("How your plan is built", systemImage: "sparkles")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text("Your answers (not your name or email) are sent to our server and to an AI model from OpenAI, which writes your plan using Mason's coaching rules. We don't save your answers on our server, and they aren't used to train AI models.")
                        .font(.footnote)
                        .foregroundStyle(TF.textSecondary)
                    Toggle(isOn: $agreedToAI) {
                        Text("I agree to send my answers to build my plan")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(TF.text)
                    }
                    .tint(TF.blue)
                }
            }
            if app.personalProgram?.isAIBuilt == true {
                Text("This replaces your current AI plan. Sets you already logged stay in your history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Building / done / failed

    private var buildingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(TF.blue)
                .scaleEffect(1.4)
            Text("Building your plan…")
                .font(.headline.weight(.bold))
                .foregroundStyle(TF.text)
            Text("Fitting your schedule, equipment and body into a program. This can take up to a minute.")
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var doneView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let plan = app.personalProgram {
                    TFHeroBanner {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Your plan is ready", systemImage: "checkmark.seal.fill")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text(plan.name)
                                .font(.title2.weight(.bold))
                            Text(plan.summary)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    TFSectionHeader(title: "Your week")
                    ForEach(plan.days) { day in
                        TFCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(day.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(TF.text)
                                Text("\(day.focus) • \(day.exercises.count) exercises")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    if let notes = plan.coachNotes, !notes.isEmpty {
                        TFSectionHeader(title: "Coach notes")
                        TFCard {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(notes, id: \.self) { note in
                                    bullet("lightbulb", note)
                                }
                            }
                        }
                    }
                    TFButton(title: "Start training", systemImage: "figure.strengthtraining.traditional", style: .primary) {
                        app.selectedTab = .train
                        dismiss()
                    }
                    .padding(.top, 4)
                }
            }
            .padding(16)
        }
    }

    private func failedView(_ message: String) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundStyle(TF.blue)
            Text("Plan didn't build")
                .font(.headline.weight(.bold))
                .foregroundStyle(TF.text)
            Text(message)
                .font(.footnote)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
            Text("Your current plan hasn't changed, and your answers are saved.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 10) {
                TFButton(title: "Try again", systemImage: "arrow.clockwise", style: .primary, action: build)
                TFButton(title: "Not now", systemImage: nil, style: .ghost) { dismiss() }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func prefill() {
        guard !loaded else { return }
        loaded = true
        if let saved = app.planIntake { intake = saved }
        goal = app.profile.goal
        experience = app.profile.experience
        lifestyle = app.profile.lifestyle
        equipment = app.profile.equipment
        weekdays = Set(app.trainingWeekdays)
        if intake.equipmentItems.isEmpty {
            intake.equipmentItems = defaultItems(for: app.profile.equipment)
        }
    }

    private func defaultItems(for access: EquipmentAccess) -> [String] {
        switch access {
        case .fullGym:
            ["Barbell & plates", "Squat rack", "Flat/incline bench", "Dumbbells", "Cable machine",
             "Leg press", "Selectorized machines", "Pull-up bar", "Treadmill / bike / rower"]
        case .homeDumbbells:
            ["Dumbbells", "Flat/incline bench"]
        case .bodyweightOnly:
            []
        }
    }

    private func build() {
        dismissKeyboard()
        if equipment == .bodyweightOnly { intake.equipmentItems = [] }
        // Keep answers even if the build fails, so "Try again" is one tap.
        app.planIntake = intake
        app.save()
        withAnimation { phase = .building }
        Task { @MainActor in
            do {
                try await app.buildAIPlan(intake: intake, goal: goal, experience: experience,
                                          lifestyle: lifestyle, equipment: equipment, weekdays: weekdays)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                withAnimation { phase = .done }
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                withAnimation { phase = .failed(error.localizedDescription) }
            }
        }
    }

    private func toggle(_ value: String, in list: inout [String], max: Int) {
        if let i = list.firstIndex(of: value) {
            list.remove(at: i)
        } else if list.count < max {
            list.append(value)
        }
    }

    // MARK: - Small pieces

    private func question(_ title: String, hint: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(TF.text)
            if let hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func field(_ placeholder: String, text: Binding<String>, max: Int) -> some View {
        TextField(placeholder, text: text, axis: .vertical)
            .font(.subheadline)
            .foregroundStyle(TF.text)
            .lineLimit(1...4)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
            .onChange(of: text.wrappedValue) { _, newValue in
                if newValue.count > max { text.wrappedValue = String(newValue.prefix(max)) }
            }
    }

    private func bullet(_ icon: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(TF.blue)
                .frame(width: 18)
            Text(text)
                .font(.footnote)
                .foregroundStyle(TF.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
