//
//  HomeView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Home dashboard, redesigned Oct 2026: one focal point (calories left today),
/// a weekly training streak row, today's session, one primary action, then the
/// weekly check-in / Mason's note and Mason's tip.
struct HomeView: View {
    @Environment(AppModel.self) private var app
    @State private var showingCheckIn = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    weekRow
                    calorieHero
                    VStack(spacing: 12) {
                        sessionRow
                        primaryButton
                    }
                    if !app.hasCheckedInThisWeek() {
                        checkInPromptCard
                    } else if let adjustment = app.weeklyAdjustment {
                        masonNoteCard(adjustment)
                    }
                    masonTipCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(TF.bg.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingCheckIn) {
                CheckInScreen()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Header

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

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                Text("\(greetingText), \(firstName.isEmpty ? "friend" : firstName)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(TF.textSecondary)
                Spacer()
                Button {
                    app.selectedTab = .profile
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(TF.textSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profile")
            }
            Text("You've trained \(trainedThisWeek) / \(app.profile.daysPerWeek) days this week")
                .font(.system(size: 30, weight: .heavy))
                .tracking(-0.6)
                .foregroundStyle(TF.text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Week row

    private struct WeekDayCell: Identifiable {
        let id: Int
        let letter: String
        let dayNumber: Int
        let trained: Bool
        let isToday: Bool
        let isPlanned: Bool
    }

    private var weekCells: [WeekDayCell] {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Monday
        let today = cal.startOfDay(for: Date())
        guard let start = cal.dateInterval(of: .weekOfYear, for: today)?.start else { return [] }
        let planned = app.trainingWeekdays
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        return (0..<7).compactMap { i in
            guard let date = cal.date(byAdding: .day, value: i, to: start) else { return nil }
            let key = AppModel.dateKey(date)
            let trained = (app.exerciseLogs[key] ?? [:]).values.contains { !$0.sets.isEmpty }
            return WeekDayCell(
                id: i,
                letter: letters[i],
                dayNumber: cal.component(.day, from: date),
                trained: trained,
                isToday: cal.isDate(date, inSameDayAs: today),
                isPlanned: planned.contains(cal.component(.weekday, from: date))
            )
        }
    }

    private var trainedThisWeek: Int {
        weekCells.filter { $0.trained }.count
    }

    private var weekRow: some View {
        HStack(spacing: 6) {
            ForEach(weekCells) { day in
                weekCell(day)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Trained \(trainedThisWeek) of \(app.profile.daysPerWeek) planned days this week")
    }

    private func weekCell(_ day: WeekDayCell) -> some View {
        VStack(spacing: 6) {
            Text(day.letter)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(TF.textSecondary)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(day.trained ? TF.blue : TF.card)
                if day.isToday && !day.trained {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(TF.blue, lineWidth: 2)
                }
                if day.trained {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundStyle(TF.bg)
                } else {
                    Text("\(day.dayNumber)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(day.isToday ? TF.text : TF.textSecondary.opacity(day.isPlanned ? 1 : 0.45))
                }
            }
            .frame(height: 42)
            Circle()
                .fill(day.isPlanned && !day.trained ? TF.pink : Color.clear)
                .frame(width: 4, height: 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Calorie hero

    private var calorieHero: some View {
        let totals = app.nutritionTotals()
        let target = Double(app.profile.targetCalories)
        let remaining = max(0, target - totals.cal)
        let over = max(0, totals.cal - target)
        let isOver = target > 0 && over >= 1
        let progress = target > 0 ? min(totals.cal / target, 1) : 0
        let proLeft = max(0, Double(app.profile.targetProtein) - totals.pro)
        let carbLeft = max(0, Double(app.profile.targetCarbs) - totals.carb)
        let fatLeft = max(0, Double(app.profile.targetFat) - totals.fat)

        return Button {
            app.selectedTab = .eat
        } label: {
            ZStack {
                Circle()
                    .stroke(TF.input, lineWidth: 16)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(isOver ? TF.warning : TF.blue, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
                VStack(spacing: 4) {
                    Text("\(Int((isOver ? over : remaining).rounded()))")
                        .font(.system(size: 60, weight: .heavy))
                        .tracking(-2)
                        .foregroundStyle(TF.text)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(isOver ? "kcal over today" : "kcal left today")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(TF.textSecondary)
                    HStack(spacing: 12) {
                        macroLeft("P", proLeft, TF.protein)
                        macroLeft("C", carbLeft, TF.carbs)
                        macroLeft("F", fatLeft, TF.fat)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: 250, height: 250)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isOver
            ? "\(Int(over.rounded())) calories over today. Open nutrition."
            : "\(Int(remaining.rounded())) calories left today. Open nutrition.")
    }

    private func macroLeft(_ letter: String, _ grams: Double, _ color: Color) -> some View {
        Text("\(letter) \(Int(grams.rounded()))g")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(color)
    }

    // MARK: Session row

    private var sessionSubtitle: String {
        guard let day = todayWorkout else {
            return "Recover, hydrate and fuel well"
        }
        let done = completedExercises(in: day)
        let total = day.exercises.count
        if done > 0 { return "\(done) of \(total) exercises done" }
        return "\(total) exercises · \(day.focus)"
    }

    private var sessionRow: some View {
        Button {
            app.selectedTab = .train
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(todayWorkout == nil ? "Today" : "Today's session")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(TF.textSecondary)
                    Text(todayWorkout?.title ?? "Rest day")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(TF.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                    Text(sessionSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(TF.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(TF.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(TF.card)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Primary action

    private var primaryTitle: String {
        guard let day = todayWorkout else { return "Log today's food" }
        let done = completedExercises(in: day)
        if done == 0 { return "Start session" }
        if done >= day.exercises.count { return "Session complete" }
        return "Continue session"
    }

    private var primaryButton: some View {
        Button {
            app.selectedTab = todayWorkout == nil ? .eat : .train
        } label: {
            Text(primaryTitle)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(TF.bg)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(Capsule().fill(TF.blue))
        }
        .buttonStyle(.plain)
    }

    // MARK: Check-in prompt

    private var checkInPromptCard: some View {
        Button {
            showingCheckIn = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(TF.input)
                        .frame(width: 48, height: 48)
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(TF.pink)
                        .font(.title3)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Weekly check-in")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(TF.text)
                    Text("How are you doing this week? Take a minute to reflect.")
                        .font(.system(size: 13))
                        .foregroundStyle(TF.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(TF.textSecondary)
            }
            .homeCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: Mason's weekly note (from the latest check-in)

    private func masonNoteCard(_ adjustment: PlanEngine.WeeklyAdjustment) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: adjustment.symbol)
                    .foregroundStyle(TF.blue)
                Text("Mason's note this week")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(TF.blue)
            }
            Text(adjustment.title)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(TF.text)
            Text(adjustment.message)
                .font(.system(size: 14))
                .foregroundStyle(TF.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .homeCard()
    }

    // MARK: Mason's tip

    private var masonTipCard: some View {
        let tip = SampleData.dailyTip()
        return VStack(alignment: .leading, spacing: 8) {
            Text("Mason's tip · \(tip.category)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(TF.pink)
            Text(tip.text)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(TF.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .homeCard()
    }

    // MARK: Helpers

    private func completedExercises(in day: WorkoutDay) -> Int {
        day.exercises.filter { ex in
            !app.log(forExercise: ex.id).sets.isEmpty
        }.count
    }
}

private extension View {
    /// Flat rounded card used across the redesigned Home screen.
    func homeCard() -> some View {
        self
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous).fill(TF.card)
            )
    }
}

#Preview {
    HomeView().environment(AppModel())
}
