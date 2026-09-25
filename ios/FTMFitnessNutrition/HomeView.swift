//
//  HomeView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Home dashboard: safety-first greeting, today's workout, nutrition summary,
/// weekly check-in prompt, and a rotating tip from Mason.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    @State private var showingProfile = false
    @State private var showingCheckIn = false

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    greetingCard
                    if !app.hasCheckedInThisWeek() {
                        checkInPromptCard
                    } else if let adjustment = app.weeklyAdjustment {
                        masonNoteCard(adjustment)
                    }
                    workoutCard
                    nutritionCard
                    masonTipCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(TF.blue)
                    }
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingCheckIn) {
                CheckInScreen()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Greeting

    private var firstName: String {
        let n = app.profile.name.trimmingCharacters(in: .whitespaces)
        return n.split(separator: " ").first.map(String.init) ?? n
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Hello"
        }
    }

    private var todayWorkout: WorkoutDay? {
        app.todayWorkout
    }

    @ViewBuilder
    private var greetingCard: some View {
        TFHomeBanner {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(greetingText), \(firstName.isEmpty ? "friend" : firstName)")
                    .font(.title2.weight(.bold))
                Text("This is your space. You don't have to explain yourself before you start training.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                HStack(spacing: 8) {
                    Label(app.profile.goal.rawValue, systemImage: "target")
                    Text("•")
                    Label("\(app.profile.daysPerWeek)d/wk", systemImage: "calendar")
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 4)
            }
        }
    }

    // MARK: Check-in prompt

    @ViewBuilder
    private var checkInPromptCard: some View {
        Button {
            showingCheckIn = true
        } label: {
            TFCard {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(TF.pink.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(TF.pink)
                            .font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Weekly check-in")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(TF.text)
                        Text("How are you doing this week? Take a minute to reflect.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Mason's weekly note (from the latest check-in)

    @ViewBuilder
    private func masonNoteCard(_ adjustment: PlanEngine.WeeklyAdjustment) -> some View {
        TFCard(background: TF.blue.opacity(0.12)) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(TF.blue)
                            .frame(width: 36, height: 36)
                        Image(systemName: "quote.bubble.fill")
                            .foregroundStyle(.white)
                            .font(.caption)
                    }
                    Text("Mason's note this week")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TF.blue)
                    Spacer()
                    Image(systemName: adjustment.symbol)
                        .foregroundStyle(TF.blue)
                }
                Text(adjustment.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.text)
                Text(adjustment.message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Today's workout

    @ViewBuilder
    private var workoutCard: some View {
        if let day = todayWorkout {
            Button {
                app.selectedTab = .train
            } label: {
                workoutCardContent(day)
            }
            .buttonStyle(.plain)
        } else {
            TFCard {
                HStack(spacing: 14) {
                    Image(systemName: "figure.cooldown")
                        .font(.system(size: 36))
                        .foregroundStyle(TF.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest day")
                            .font(.headline.weight(.bold))
                        Text("Recovery is part of the work. Move gently, hydrate, and fuel well.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private func workoutCardContent(_ day: WorkoutDay) -> some View {
        TFCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "dumbbell.fill")
                        .foregroundStyle(TF.blue)
                    Text("Today's Session")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .font(.caption)
                }
                Text(day.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                Text(day.focus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                let done = completedExercises(in: day)
                let total = day.exercises.count
                HStack(spacing: 10) {
                    Label("\(day.exercises.count) exercises", systemImage: "list.bullet")
                    Spacer()
                    if done > 0 {
                        Label("\(done)/\(total) done", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(TF.blue)
                    } else {
                        Label("Tap to start", systemImage: "play.circle")
                            .foregroundStyle(TF.blue)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                if done > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(TF.card).frame(height: 6)
                            Capsule()
                                .fill(TF.blue)
                                .frame(width: geo.size.width * (Double(done) / Double(total)), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
    }

    // MARK: Nutrition summary

    @ViewBuilder
    private var nutritionCard: some View {
        let totals = app.nutritionTotals()
        let calTarget = Double(app.profile.targetCalories)
        let calRemaining = max(0, calTarget - totals.cal)
        let progress = calTarget > 0 ? totals.cal / calTarget : 0

        TFCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Today's Nutrition")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("Today")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                HStack(alignment: .center, spacing: 16) {
                    ProgressRing(progress: progress, color: TF.blue, size: 72, label: "\(Int((progress * 100).rounded()))%")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(Int(calRemaining.rounded()))")
                            .font(.title.weight(.bold))
                            .foregroundStyle(TF.text)
                        Text("kcal remaining to fuel your day")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("\(Int(totals.cal.rounded())) / \(app.profile.targetCalories) kcal")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    Spacer()
                }
                Divider()
                VStack(spacing: 10) {
                    MacroBar(label: "Protein", value: totals.pro, target: Double(app.profile.targetProtein), color: TF.protein)
                    MacroBar(label: "Carbs", value: totals.carb, target: Double(app.profile.targetCarbs), color: TF.carbs)
                    MacroBar(label: "Fat", value: totals.fat, target: Double(app.profile.targetFat), color: TF.fat)
                }
            }
        }
    }

    // MARK: Mason's tip

    @ViewBuilder
    private var masonTipCard: some View {
        let tip = SampleData.dailyTip()
        TFCard(background: TF.blue.opacity(0.12)) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(TF.blue)
                        .frame(width: 40, height: 40)
                    Image(systemName: "quote.bubble.fill")
                        .foregroundStyle(.white)
                        .font(.caption)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mason's tip")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TF.blue)
                    Text(tip.text)
                        .font(.subheadline)
                        .foregroundStyle(TF.text)
                        .multilineTextAlignment(.leading)
                    Text(tip.category)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
                Spacer()
            }
        }
    }

    // MARK: Helpers

    private func completedExercises(in day: WorkoutDay) -> Int {
        day.exercises.filter { ex in
            !app.log(forExercise: ex.id).sets.isEmpty
        }.count
    }
}

#Preview {
    HomeView().environment(AppModel())
}
