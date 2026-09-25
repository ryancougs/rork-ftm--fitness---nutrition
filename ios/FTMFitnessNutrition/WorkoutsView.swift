//
//  WorkoutsView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Train tab: today's workout with inline set logging, plus program browsing.
/// Designed for 1-2 tap logging — no deep navigation needed to log sets.
struct TrainView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    todaySection
                    yourPlanSection
                    browseProgramsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneBar()
            .navigationTitle("Train")
            .navigationDestination(for: WorkoutProgram.self) { program in
                ProgramDetailView(program: program)
            }
            .navigationDestination(for: WorkoutDay.self) { day in
                WorkoutDayBrowserView(day: day)
            }
        }
    }

    // MARK: Today's section

    private var todayWorkout: WorkoutDay? {
        app.todayWorkout
    }

    @ViewBuilder
    private var todaySection: some View {
        if let day = todayWorkout {
            todayHeader(day)
            ForEach(day.exercises) { exercise in
                InlineExerciseCard(exercise: exercise)
            }
        } else {
            restDayCard
        }
    }

    @ViewBuilder
    private func todayHeader(_ day: WorkoutDay) -> some View {
        TFHeroBanner {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Session")
                        .font(.title2.weight(.bold))
                    Spacer()
                    Text(day.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(.white.opacity(0.2)))
                }
                Text(day.focus)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Log your sets inline below — no menus, just lift.")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
    }

    private var restDayCard: some View {
        TFHeroBanner {
            VStack(alignment: .leading, spacing: 8) {
                Text("Rest Day")
                    .font(.title2.weight(.bold))
                Text("Recovery is part of the work. Move gently, hydrate, and fuel well. Your body grows when you rest.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
    }

    // MARK: Your personalized plan

    @ViewBuilder
    private var yourPlanSection: some View {
        if let plan = app.personalProgram {
            TFSectionHeader(title: "Your Plan", subtitle: "Built around your goal, experience, and schedule — regenerated whenever your profile changes")
                .padding(.top, 8)
            NavigationLink(value: plan) {
                ProgramRow(program: plan)
            }
            .buttonStyle(.plain)
            if let adjustment = app.weeklyAdjustment, adjustment.isDeload {
                Text(adjustment.title)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }

    // MARK: Browse programs

    @ViewBuilder
    private var browseProgramsSection: some View {
        TFSectionHeader(title: "Browse Programs", subtitle: "Sample plans to explore")
            .padding(.top, 8)
        ForEach(app.programs) { program in
            NavigationLink(value: program) {
                ProgramRow(program: program)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Inline exercise card (streamlined 1-2 tap logging)

struct InlineExerciseCard: View {
    @Environment(AppModel.self) private var app
    let exercise: Exercise

    @State private var weightInput: String = ""
    @State private var repsInput: String = ""
    @State private var showingDescription: Bool = false
    @FocusState private var weightFocused: Bool

    var body: some View {
        let log = app.log(forExercise: exercise.id)
        let completed = !log.sets.isEmpty

        TFCard {
            VStack(alignment: .leading, spacing: 12) {
                // Header row — tap name for description
                Button {
                    withAnimation(.spring(response: 0.3)) { showingDescription.toggle() }
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(completed ? TF.blue.opacity(0.22) : TF.input)
                                .frame(width: 36, height: 36)
                            Image(systemName: completed ? "checkmark" : "figure.strengthtraining.traditional")
                                .foregroundStyle(completed ? TF.blue : .secondary)
                                .font(.callout)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(exercise.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TF.text)
                                .multilineTextAlignment(.leading)
                            HStack(spacing: 6) {
                                Text("\(exercise.sets) sets × \(exercise.reps)")
                                Text("•")
                                Text(exercise.muscleGroup)
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if completed {
                            Text("\(log.sets.count) logged")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(TF.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(TF.blue.opacity(0.18)))
                        }
                        Image(systemName: showingDescription ? "chevron.up" : "info.circle")
                            .foregroundStyle(.tertiary)
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)

                // Inline description (toggle)
                if showingDescription {
                    Text(exercise.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Inline set logging — weight + reps + add button
                HStack(spacing: 10) {
                    inputField("kg", text: $weightInput)
                        .keyboardType(.decimalPad)
                        .focused($weightFocused)
                    inputField("reps", text: $repsInput)
                        .keyboardType(.numberPad)
                    Button {
                        logSet()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(weightInput.isEmpty || repsInput.isEmpty ? TF.blue.opacity(0.3) : TF.blue)
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                    .disabled(weightInput.isEmpty || repsInput.isEmpty)
                }

                // Logged sets
                if !log.sets.isEmpty {
                    VStack(spacing: 6) {
                        ForEach(Array(log.sets.enumerated()), id: \.element.id) { idx, s in
                            HStack {
                                Text("Set \(idx + 1)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(TF.text)
                                Spacer()
                                Text("\(String(format: "%g", s.weight)) kg × \(s.reps)")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.secondary)
                                Button {
                                    app.removeSet(s.id, fromExercise: exercise.id)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red.opacity(0.6))
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(TF.input))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func inputField(_ placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: text)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
        .foregroundStyle(TF.text)
    }

    private func logSet() {
        guard let w = Double(weightInput.replacingOccurrences(of: ",", with: ".")),
              let r = Int(repsInput), r > 0, w >= 0 else { return }
        app.addSet(toExercise: exercise.id, weight: w, reps: r)
        weightInput = ""
        repsInput = ""
        weightFocused = true
    }
}

// MARK: - Program row

private struct ProgramRow: View {
    let program: WorkoutProgram

    var body: some View {
        TFCard {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(TF.blue)
                        .frame(width: 48, height: 48)
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.name)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text(program.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        tag(program.level.rawValue)
                        tag(program.goal.rawValue)
                        tag("\(program.daysPerWeek)d/wk")
                    }
                    .padding(.top, 2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func tag(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(TF.blue.opacity(0.30)))
    }
}

// MARK: - Program detail (browsing)

private struct ProgramDetailView: View {
    let program: WorkoutProgram

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                TFCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(program.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: 8) {
                            Label(program.level.rawValue, systemImage: "chart.bar.fill")
                            Label("\(program.daysPerWeek) days/week", systemImage: "calendar")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TF.blue)
                    }
                }
                TFSectionHeader(title: "Training days", subtitle: "\(program.days.count) days")
                    .padding(.top, 6)
                ForEach(program.days) { day in
                    NavigationLink(value: day) {
                        dayRow(day)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(TF.bg.ignoresSafeArea())
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func dayRow(_ day: WorkoutDay) -> some View {
        TFCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(TF.blue)
                        .frame(width: 52, height: 52)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(day.title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text(day.focus)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("\(day.exercises.count) exercises")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(TF.blue)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Workout day browser (read-only, for browsing programs)

private struct WorkoutDayBrowserView: View {
    @Environment(AppModel.self) private var app
    let day: WorkoutDay

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                focusCard
                TFSectionHeader(title: "Exercises", subtitle: "\(day.exercises.count) total")
                    .padding(.top, 6)
                ForEach(day.exercises) { exercise in
                    exerciseRow(exercise)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(TF.bg.ignoresSafeArea())
        .navigationTitle(day.title)
        .navigationBarTitleDisplayMode(.large)
    }

    private var focusCard: some View {
        TFCard {
            HStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundStyle(TF.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(day.focus)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                }
                Spacer()
            }
        }
    }

    @ViewBuilder
    private func exerciseRow(_ ex: Exercise) -> some View {
        let log = app.log(forExercise: ex.id)
        let completed = !log.sets.isEmpty
        return TFCard {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(completed ? TF.blue.opacity(0.22) : TF.input)
                        .frame(width: 36, height: 36)
                    Image(systemName: completed ? "checkmark" : "figure.strengthtraining.traditional")
                        .foregroundStyle(completed ? TF.blue : .secondary)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(ex.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    HStack(spacing: 6) {
                        Text("\(ex.sets) × \(ex.reps)")
                        Text("•")
                        Text(ex.muscleGroup)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                if completed {
                    Text("\(log.sets.count) logged")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(TF.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(TF.blue.opacity(0.18)))
                }
            }
        }
    }
}

#Preview {
    TrainView().environment(AppModel())
}
