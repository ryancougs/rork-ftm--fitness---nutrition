//
//  NutritionView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Nutrition tab: daily food log grouped by meal, add-food sheet, live macro totals.
struct NutritionView: View {
    @Environment(AppModel.self) private var app
    @Environment(StoreService.self) private var store
    @State private var historyRange: Int = 7
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var addFoodRequest: AddFoodRequest? = nil
    @State private var editingItem: LoggedFood? = nil
    @State private var lastDeleted: LoggedFood? = nil

    /// What the Add Food sheet should open with.
    private struct AddFoodRequest: Identifiable {
        let id = UUID()
        var meal: MealType? = nil
        var scanner: Bool = false
    }

    private var isToday: Bool { Calendar.current.isDateInToday(selectedDate) }

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    dateHeader
                    summaryCard
                    scanMealCard
                    ForEach(MealType.allCases) { meal in
                        mealSection(meal)
                    }
                    historySection
                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addFoodRequest = AddFoodRequest()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(TF.blue)
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(item: $addFoodRequest) { request in
            AddFoodSheet(date: selectedDate, initialMeal: request.meal, startWithScanner: request.scanner)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $editingItem) { item in
            EditLoggedFoodSheet(item: item, date: selectedDate)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .bottom) { undoBar }
    }

    // MARK: Undo

    @ViewBuilder
    private var undoBar: some View {
        if let item = lastDeleted {
            HStack(spacing: 12) {
                Text("Removed \(item.food.displayName)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                    .lineLimit(1)
                Spacer()
                Button("Undo") {
                    app.restoreFood(item, on: selectedDate)
                    withAnimation { lastDeleted = nil }
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TF.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
            .overlay(RoundedRectangle(cornerRadius: TF.cornerM).strokeBorder(TF.border, lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .task(id: item.id) {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { return }
                withAnimation { if lastDeleted?.id == item.id { lastDeleted = nil } }
            }
        }
    }

    private func delete(_ item: LoggedFood) {
        app.removeFood(item.id, on: selectedDate)
        withAnimation { lastDeleted = item }
    }

    // MARK: Scan a meal (headline feature, one tap from the tab)

    private var scanMealCard: some View {
        Button {
            addFoodRequest = AddFoodRequest(scanner: true)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(TF.blue.opacity(0.16))
                        .frame(width: 44, height: 44)
                    Image(systemName: "camera.viewfinder")
                        .font(.title3)
                        .foregroundStyle(TF.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scan a meal")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text("Snap your plate, AI fills in calories and macros")
                        .font(.caption)
                        .foregroundStyle(TF.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TF.textSecondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.blue.opacity(0.10)))
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .strokeBorder(TF.blue.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Summary card

    private var totals: (cal: Double, pro: Double, carb: Double, fat: Double) {
        app.nutritionTotals(on: selectedDate)
    }

    @ViewBuilder
    private var summaryCard: some View {
        let t = totals
        let calTarget = Double(app.profile.targetCalories)
        let progress = calTarget > 0 ? t.cal / calTarget : 0

        TFCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(isToday ? "Today's Nutrition" : "Nutrition")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Text("\(Int(t.cal.rounded())) / \(app.profile.targetCalories) kcal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                }
                HStack(alignment: .center, spacing: 16) {
                    ProgressRing(progress: progress, color: TF.blue, size: 72, label: "\(Int((progress*100).rounded()))%")
                    VStack(alignment: .leading, spacing: 4) {
                        let remaining = max(0, calTarget - t.cal)
                        let over = t.cal - calTarget
                        if calTarget > 0 && over >= 1 {
                            Text("\(Int(over.rounded())) kcal over")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(TF.warning)
                            Text("No stress. One day doesn't make a trend.")
                                .font(.caption)
                                .foregroundStyle(TF.textSecondary)
                        } else {
                            Text("\(Int(remaining.rounded())) kcal left")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(TF.blue)
                            Text("Fuel your body well today.")
                                .font(.caption)
                                .foregroundStyle(TF.textSecondary)
                        }
                    }
                    Spacer()
                }
                Divider()
                HStack(spacing: 12) {
                    macroPill("Protein", value: t.pro, target: Double(app.profile.targetProtein), color: TF.protein)
                    macroPill("Carbs", value: t.carb, target: Double(app.profile.targetCarbs), color: TF.carbs)
                    macroPill("Fat", value: t.fat, target: Double(app.profile.targetFat), color: TF.fat)
                }
            }
        }
    }

    @ViewBuilder
    private func macroPill(_ label: String, value: Double, target: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(Int(value.rounded()))g")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TF.textSecondary)
            Text("/ \(Int(target))g")
                .font(.caption2)
                .foregroundStyle(TF.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.10)))
    }

    // MARK: History: last 7 days (free), 30 / 90 days (Premium)

    private var historySection: some View {
        VStack(spacing: 10) {
            TFCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Last \(historyRange) days")
                            .font(.headline.weight(.bold))
                        Spacer()
                        if store.isPremium {
                            Picker("Range", selection: $historyRange) {
                                Text("7D").tag(7)
                                Text("30D").tag(30)
                                Text("90D").tag(90)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 150)
                        } else {
                            Text("calories vs goal")
                                .font(.caption)
                                .foregroundStyle(TF.textSecondary)
                        }
                    }
                    historyBars
                    historyAverages
                }
            }
            if !store.isPremium {
                LockedFeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "30 and 90 day trends",
                    message: "See your calorie and protein averages across the last month and quarter, not just this week.",
                    context: .fullHistory
                )
            }
        }
    }

    private struct HistoryDay {
        let date: Date
        let cal: Double
        let pro: Double
    }

    private var historyDays: [HistoryDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let range = store.isPremium ? historyRange : 7
        var result: [HistoryDay] = []
        for offset in stride(from: range - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let t = app.nutritionTotals(on: date)
            result.append(HistoryDay(date: date, cal: t.cal, pro: t.pro))
        }
        return result
    }

    /// Calorie bars vs goal. Day letters only on the 7-day view.
    private var historyBars: some View {
        let cal = Calendar.current
        let target = max(Double(app.profile.targetCalories), 1)
        let days = historyDays
        let spacing: CGFloat = days.count <= 7 ? 8 : (days.count <= 30 ? 3 : 1)
        return HStack(alignment: .bottom, spacing: spacing) {
            ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                VStack(spacing: 4) {
                    ZStack(alignment: .bottom) {
                        Capsule().fill(TF.input)
                        Capsule()
                            .fill(day.cal > target * 1.05 ? TF.warning : (day.cal > 0 ? TF.blue : Color.clear))
                            .frame(height: max(day.cal > 0 ? 5 : 0, 56 * min(day.cal / target, 1)))
                    }
                    .frame(height: 56)
                    if days.count <= 7 {
                        let weekday = cal.component(.weekday, from: day.date)
                        Text(String(cal.veryShortWeekdaySymbols[weekday - 1].prefix(1)))
                            .font(.caption2.weight(idx == days.count - 1 ? .bold : .regular))
                            .foregroundStyle(idx == days.count - 1 ? TF.text : TF.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: days.count <= 7 ? 78 : 60)
    }

    /// Averages over days that have anything logged.
    private var historyAverages: some View {
        let logged = historyDays.filter { $0.cal > 0 }
        let n = Double(max(logged.count, 1))
        let avgCal = logged.reduce(0) { $0 + $1.cal } / n
        let avgPro = logged.reduce(0) { $0 + $1.pro } / n
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(logged.isEmpty ? "—" : "\(Int(avgCal.rounded()))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.text)
                Text("avg kcal")
                    .font(.caption2)
                    .foregroundStyle(TF.textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(logged.isEmpty ? "—" : "\(Int(avgPro.rounded()))g")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.protein)
                Text("avg protein")
                    .font(.caption2)
                    .foregroundStyle(TF.textSecondary)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(logged.count)/\(historyDays.count)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.text)
                Text("days logged")
                    .font(.caption2)
                    .foregroundStyle(TF.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: Date header (switch days to log yesterday etc.)

    private var dateHeader: some View {
        HStack(spacing: 12) {
            Button {
                shiftDay(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(TF.input))
            }
            .buttonStyle(.plain)
            .foregroundStyle(TF.text)
            .accessibilityLabel("Previous day")

            VStack(spacing: 2) {
                Text(dayTitle)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TF.text)
                Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()))
                    .font(.caption)
                    .foregroundStyle(TF.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .onTapGesture { withAnimation { selectedDate = Calendar.current.startOfDay(for: Date()) } }

            Button {
                shiftDay(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(TF.input))
            }
            .buttonStyle(.plain)
            .foregroundStyle(isToday ? TF.textSecondary.opacity(0.4) : TF.text)
            .disabled(isToday)
            .accessibilityLabel("Next day")
        }
    }

    private var dayTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(selectedDate) { return "Today" }
        if cal.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.formatted(.dateTime.month(.abbreviated).day())
    }

    private func shiftDay(_ delta: Int) {
        let cal = Calendar.current
        guard let next = cal.date(byAdding: .day, value: delta, to: selectedDate) else { return }
        guard next <= cal.startOfDay(for: Date()) else { return }
        lastDeleted = nil
        withAnimation(.easeOut(duration: 0.15)) { selectedDate = next }
    }

    // MARK: Meal section

    @ViewBuilder
    private func mealSection(_ meal: MealType) -> some View {
        let items = app.foods(on: selectedDate).filter { $0.meal == meal }
        TFCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Text(meal.emoji)
                    Text(meal.rawValue)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Spacer()
                    if !items.isEmpty {
                        Text("\(Int(items.reduce(0) { $0 + $1.calories }.rounded())) kcal")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(TF.textSecondary)
                    }
                    Button {
                        addFoodRequest = AddFoodRequest(meal: meal)
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TF.blue)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(TF.blue.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                }

                if items.isEmpty {
                    Text("Nothing logged yet.")
                        .font(.footnote)
                        .foregroundStyle(TF.textSecondary)
                        .padding(.vertical, 4)
                } else {
                    VStack(spacing: 8) {
                        ForEach(items) { item in
                            foodRow(item)
                                .contentShape(Rectangle())
                                .onTapGesture { editingItem = item }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func foodRow(_ item: LoggedFood) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.food.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                Text(portionText(item))
                    .font(.caption)
                    .foregroundStyle(TF.textSecondary)
                HStack(spacing: 6) {
                    mini("P", value: Int(item.protein.rounded()), color: TF.protein)
                    mini("C", value: Int(item.carbs.rounded()), color: TF.carbs)
                    mini("F", value: Int(item.fat.rounded()), color: TF.fat)
                }
                .padding(.top, 2)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(Int(item.calories.rounded())) kcal")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.blue)
                Button {
                    delete(item)
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(TF.danger.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
    }

    private func portionText(_ item: LoggedFood) -> String {
        if let label = item.portionLabel { return label }
        return "\(formatServings(item.servings)) × \(item.food.serving)"
    }

    @ViewBuilder
    private func mini(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(color)
            Text("\(value)g")
                .font(.caption2)
                .foregroundStyle(TF.textSecondary)
        }
    }

    private func formatServings(_ s: Double) -> String {
        s == s.rounded() ? String(Int(s)) : String(format: "%.1f", s)
    }
}

// MARK: - Add food sheet
//
// Search flows through three sources: the bundled database (instant, offline),
// Open Food Facts, and USDA FoodData Central (when a key is configured).
// Favorites, recents, barcode scanning, and custom foods are one tap away.

struct AddFoodSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(StoreService.self) private var store
    @Environment(\.dismiss) private var dismiss

    /// Day the food is logged to (Nutrition's selected day).
    var date: Date = Date()
    /// Meal to preselect, e.g. when opened from that meal's "+".
    var initialMeal: MealType? = nil
    /// Open straight into the meal scanner.
    var startWithScanner: Bool = false

    private enum Mode { case search, configure, custom, quickAdd }
    @State private var mode: Mode = .search

    @State private var query: String = ""
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var remoteResults: [FoodItem] = []
    @State private var failedSources: [String] = []
    @State private var isSearching: Bool = false
    @State private var hasSearchedRemote: Bool = false

    @State private var selectedFood: FoodItem? = nil
    @State private var selectedPortionID: String = "listed"
    @State private var quantityText: String = "1"
    @State private var meal: MealType = .breakfast

    @State private var showingScanner: Bool = false
    @State private var showingMealScanner: Bool = false
    @State private var showingLimitPaywall: Bool = false
    @State private var scanRemaining: Int? = nil
    @State private var scanNotice: String? = nil
    @State private var didAutoOpenScanner = false

    // Custom food form
    @State private var customName: String = ""
    @State private var customBrand: String = ""
    @State private var customServing: String = "1 serving"
    @State private var customCalories: String = ""
    @State private var customProtein: String = ""
    @State private var customCarbs: String = ""
    @State private var customFat: String = ""

    // Quick-add form (Premium)
    @State private var quickName: String = ""
    @State private var quickCalories: String = ""
    @State private var quickProtein: String = ""
    @State private var quickCarbs: String = ""
    @State private var quickFat: String = ""

    var body: some View {
        NavigationStack {
            Group {
                switch mode {
                case .search:
                    searchView
                case .configure:
                    if let food = selectedFood {
                        configureView(for: food)
                    }
                case .custom:
                    customFoodForm
                case .quickAdd:
                    quickAddForm
                }
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TF.blue)
                }
                if mode != .search {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Back") {
                            dismissKeyboard()
                            withAnimation(.easeOut(duration: 0.15)) { mode = .search }
                        }
                        .foregroundStyle(TF.blue)
                    }
                }
            }
            .keyboardDoneBar()
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { code in
                    Task { await lookupBarcode(code) }
                }
            }
            .sheet(isPresented: $showingMealScanner) {
                MealScannerView { foods, meal in
                    for food in foods {
                        app.addFood(food, servings: 1, meal: meal, on: date)
                    }
                }
            }
            .sheet(isPresented: $showingLimitPaywall) {
                PaywallView(context: .scanLimit)
            }
            .task {
                guard !store.isPremium else { return }
                scanRemaining = await MealScanService.shared.remainingScans()
            }
            .onAppear {
                meal = initialMeal ?? Self.suggestedMeal()
                if startWithScanner, !didAutoOpenScanner {
                    didAutoOpenScanner = true
                    showingMealScanner = true
                }
            }
            .onChange(of: showingMealScanner) { _, isShowing in
                // Opened straight into the scanner from Nutrition: closing the
                // scanner closes this sheet too, back to the day's log.
                if !isShowing && startWithScanner {
                    dismiss()
                    return
                }
                guard !isShowing, !store.isPremium else { return }
                Task { scanRemaining = await MealScanService.shared.remainingScans() }
            }
        }
    }

    private var title: String {
        switch mode {
        case .search: "Add food"
        case .configure: "Log serving"
        case .custom: "Custom food"
        case .quickAdd: "Quick add"
        }
    }

    // MARK: Search view

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespaces)
    }

    private var localMatches: [FoodItem] {
        let q = trimmedQuery.lowercased()
        if q.isEmpty { return app.foodDatabase }
        return app.foodDatabase.filter { $0.name.lowercased().contains(q) }
    }

    private var searchView: some View {
        VStack(spacing: 12) {
            searchField
            quickActions
            if let scanNotice {
                Label(scanNotice, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(TF.warning)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
            }
            foodList
        }
        .onChange(of: query) { _, _ in scheduleSearch() }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(TF.textSecondary)
            TextField("Search foods or brands…", text: $query)
                .submitLabel(.search)
                .autocorrectionDisabled()
                .onSubmit { runSearchNow() }
            if !query.isEmpty {
                Button {
                    query = ""
                    remoteResults = []
                    failedSources = []
                    hasSearchedRemote = false
                    scanNotice = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(TF.textSecondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
        .overlay(
            RoundedRectangle(cornerRadius: TF.cornerS)
                .strokeBorder(TF.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var quickActions: some View {
        VStack(spacing: 10) {
            scanMealButton
            HStack(spacing: 10) {
                GatedButton(requiredTier: .premium, context: .barcodeScanner) {
                    scanNotice = nil
                    showingScanner = true
                } label: {
                    quickLabel("Barcode", systemImage: "viewfinder")
                }
                GatedButton(requiredTier: .premium, context: .quickAdd) {
                    dismissKeyboard()
                    withAnimation(.easeOut(duration: 0.15)) { mode = .quickAdd }
                } label: {
                    quickLabel("Quick add", systemImage: "bolt.fill")
                }
                quickButton("Custom food", systemImage: "square.and.pencil") {
                    dismissKeyboard()
                    withAnimation(.easeOut(duration: 0.15)) { mode = .custom }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    /// Free-tier AI meal scan entry: shows remaining weekly scans and opens
    /// the paywall with scan-limit context once the allotment is used.
    private var scanMealButton: some View {
        Button {
            scanNotice = nil
            if !store.isPremium && scanRemaining == 0 {
                showingLimitPaywall = true
            } else {
                showingMealScanner = true
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(TF.blue.opacity(0.16))
                        .frame(width: 40, height: 40)
                    Image(systemName: "camera.viewfinder")
                        .foregroundStyle(TF.blue)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Scan a meal")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text(scanMealSubtitle)
                        .font(.caption2)
                        .foregroundStyle(TF.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(TF.textSecondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.blue.opacity(0.10)))
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .strokeBorder(TF.blue.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var scanMealSubtitle: String {
        if store.isPremium { return "Unlimited — AI reads calories & macros from a photo" }
        if let remaining = scanRemaining {
            if remaining == 0 { return "Free scans used this week — go unlimited" }
            return "\(remaining) free scan\(remaining == 1 ? "" : "s") left this week"
        }
        return "3 free scans a week — AI reads the plate for you"
    }

    /// Compact label style shared by the three quick-action buttons.
    private func quickLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(TF.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .fill(TF.input)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .strokeBorder(TF.border, lineWidth: 1)
            )
    }

    private func quickButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TF.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: TF.cornerM)
                        .fill(TF.input)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: TF.cornerM)
                        .strokeBorder(TF.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var foodList: some View {
        ScrollView {
            LazyVStack(spacing: 8, pinnedViews: []) {
                if trimmedQuery.isEmpty {
                    if !app.favoriteFoods.isEmpty {
                        listHeader("Favorites")
                        ForEach(app.favoriteFoods) { food in
                            foodRow(food)
                        }
                    }
                    if !app.recentFoods.isEmpty {
                        listHeader("Recent")
                        ForEach(app.recentFoods) { food in
                            foodRow(food)
                        }
                    }
                    listHeader("All foods")
                    ForEach(app.foodDatabase) { food in
                        foodRow(food)
                    }
                } else {
                    if !localMatches.isEmpty {
                        listHeader("Your foods")
                        ForEach(Array(localMatches.prefix(30))) { food in
                            foodRow(food)
                        }
                    }
                    if !remoteResults.isEmpty {
                        listHeader("Online results")
                        ForEach(remoteResults) { food in
                            foodRow(food)
                        }
                    }
                    if isSearching {
                        HStack(spacing: 10) {
                            ProgressView().tint(TF.blue)
                            Text("Searching Open Food Facts…")
                                .font(.footnote)
                                .foregroundStyle(TF.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    if hasSearchedRemote, !failedSources.isEmpty {
                        Text("\(failedSources.joined(separator: " and ")) couldn't be reached — showing your foods.")
                            .font(.caption)
                            .foregroundStyle(TF.warning)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                    if localMatches.isEmpty && remoteResults.isEmpty && !isSearching && hasSearchedRemote {
                        TFEmptyState(
                            systemImage: "magnifyingglass",
                            title: "No matches yet",
                            message: "Try a shorter search, scan the barcode, or add it as a custom food."
                        )
                        .padding(.top, 24)
                    }
                }
                Button {
                    dismissKeyboard()
                    withAnimation(.easeOut(duration: 0.15)) { mode = .custom }
                } label: {
                    Label("Add a custom food", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: TF.cornerM)
                                .fill(TF.input)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: TF.cornerM)
                                .strokeBorder(TF.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func listHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(TF.textSecondary)
            .textCase(.uppercase)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    @ViewBuilder
    private func foodRow(_ food: FoodItem) -> some View {
        Button {
            dismissKeyboard()
            select(food)
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(TF.blue.opacity(0.14))
                        .frame(width: 40, height: 40)
                    Image(systemName: "fork.knife")
                        .foregroundStyle(TF.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(food.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        if let badge = food.source.badge {
                            Text(badge)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(TF.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(TF.blue.opacity(0.14)))
                        }
                        Text(food.serving)
                            .font(.caption)
                            .foregroundStyle(TF.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(food.calories)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(TF.blue)
                    Text("kcal")
                        .font(.caption2)
                        .foregroundStyle(TF.textSecondary)
                }
                Button {
                    app.toggleFavorite(food)
                } label: {
                    Image(systemName: app.isFavorite(food) ? "star.fill" : "star")
                        .foregroundStyle(app.isFavorite(food) ? TF.pink : TF.textSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: TF.cornerM).fill(TF.card))
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .strokeBorder(TF.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: Search plumbing

    /// Debounced remote search — fires 300 ms after typing pauses.
    private func scheduleSearch() {
        searchTask?.cancel()
        scanNotice = nil
        let q = trimmedQuery
        guard q.count >= 2 else {
            remoteResults = []
            failedSources = []
            hasSearchedRemote = false
            isSearching = false
            return
        }
        isSearching = true
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await runSearch(q)
        }
    }

    /// Return-key (Search) path — skips the debounce.
    private func runSearchNow() {
        searchTask?.cancel()
        scanNotice = nil
        let q = trimmedQuery
        guard q.count >= 2 else { return }
        isSearching = true
        searchTask = Task { await runSearch(q) }
    }

    private func runSearch(_ q: String) async {
        let outcome = await FoodSearchService.shared.search(query: q)
        guard !Task.isCancelled else { return }
        remoteResults = outcome.results
        failedSources = outcome.failedSources
        hasSearchedRemote = true
        isSearching = false
    }

    private func lookupBarcode(_ code: String) async {
        isSearching = true
        if let food = await FoodSearchService.shared.lookupBarcode(code) {
            select(food)
        } else {
            scanNotice = "No product found for that barcode. Try searching by name."
        }
        isSearching = false
    }

    private func select(_ food: FoodItem) {
        selectedFood = food
        selectedPortionID = food.portionOptions.first?.id ?? "listed"
        quantityText = "1"
        meal = initialMeal ?? Self.suggestedMeal()
        withAnimation(.easeOut(duration: 0.15)) { mode = .configure }
    }

    private static func suggestedMeal() -> MealType {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<11: .breakfast
        case 11..<15: .lunch
        case 15..<18: .snack
        default: .dinner
        }
    }

    // MARK: Configure serving

    private var selectedPortion: PortionOption? {
        guard let food = selectedFood else { return nil }
        return food.portionOptions.first { $0.id == selectedPortionID }
            ?? food.portionOptions.first
    }

    private var quantity: Double {
        let parsed = Double(quantityText.replacingOccurrences(of: ",", with: "."))
        return max(parsed ?? 1, 0)
    }

    private var totalGrams: Double? {
        guard let grams = selectedPortion?.grams else { return nil }
        return quantity * grams
    }

    private func portionTotals(_ food: FoodItem) -> (cal: Double, pro: Double, carb: Double, fat: Double) {
        if food.isPer100g, let grams = totalGrams {
            let f = grams / 100
            return (
                (food.kcalPer100g ?? 0) * f,
                (food.proteinPer100g ?? 0) * f,
                (food.carbsPer100g ?? 0) * f,
                (food.fatPer100g ?? 0) * f
            )
        }
        return (
            Double(food.calories) * quantity,
            Double(food.protein) * quantity,
            Double(food.carbs) * quantity,
            Double(food.fat) * quantity
        )
    }

    @ViewBuilder
    private func configureView(for food: FoodItem) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                foodHeader(food)
                portionCard(food)
                mealPicker
                summaryCard(food)
                TFButton(title: "Add to log", systemImage: "plus.circle.fill", style: .primary) {
                    addToLog(food)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    @ViewBuilder
    private func foodHeader(_ food: FoodItem) -> some View {
        TFCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(food.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TF.text)
                    Spacer()
                    if let badge = food.source.badge {
                        Text(badge)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(TF.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(TF.blue.opacity(0.14)))
                    }
                }
                if let brand = food.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.footnote)
                        .foregroundStyle(TF.textSecondary)
                }
                Text("Per serving: \(food.serving)")
                    .font(.footnote)
                    .foregroundStyle(TF.textSecondary)
                HStack(spacing: 14) {
                    miniStat("kcal", value: food.calories)
                    miniStat("P", value: food.protein)
                    miniStat("C", value: food.carbs)
                    miniStat("F", value: food.fat)
                }
                .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private func miniStat(_ label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TF.text)
            Text(label)
                .font(.caption2)
                .foregroundStyle(TF.textSecondary)
        }
    }

    @ViewBuilder
    private func portionCard(_ food: FoodItem) -> some View {
        let options = food.portionOptions
        TFCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Amount")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TF.text)
                if options.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(options, id: \.self) { option in
                                Button {
                                    selectedPortionID = option.id
                                } label: {
                                    Text(option.label)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(selectedPortionID == option.id ? TF.bg : TF.text)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background {
                                            Capsule().fill(selectedPortionID == option.id ? TF.blue : TF.input)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } else if let only = options.first {
                    Text(only.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(TF.textSecondary)
                }
                HStack(spacing: 16) {
                    stepperButton("minus") {
                        quantityText = formatQuantity(max(quantity - 0.5, 0.5))
                    }
                    TextField("1", text: $quantityText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(TF.blue)
                        .frame(maxWidth: 72)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                    stepperButton("plus") {
                        quantityText = formatQuantity(quantity + 0.5)
                    }
                }
                .frame(maxWidth: .infinity)
                if let grams = totalGrams {
                    Text("≈ \(Int(grams.rounded())) g")
                        .font(.caption)
                        .foregroundStyle(TF.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func stepperButton(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "\(systemImage).circle.fill")
                .font(.title2)
                .foregroundStyle(TF.blue)
        }
        .buttonStyle(.plain)
    }

    private func formatQuantity(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.1f", value)
    }

    private var mealPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.text)
                .padding(.horizontal, 16)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(MealType.allCases) { m in
                        mealChip(m)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    @ViewBuilder
    private func mealChip(_ m: MealType) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { meal = m }
        } label: {
            HStack(spacing: 6) {
                Text(m.emoji)
                Text(m.rawValue)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(meal == m ? TF.bg : TF.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background {
                Capsule().fill(meal == m ? TF.blue : TF.input)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func summaryCard(_ food: FoodItem) -> some View {
        let t = portionTotals(food)
        TFCard {
            VStack(spacing: 10) {
                Text("This adds")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TF.textSecondary)
                HStack(spacing: 16) {
                    bigStat("\(Int(t.cal.rounded()))", "kcal", TF.blue)
                    bigStat("\(Int(t.pro.rounded()))", "P g", TF.protein)
                    bigStat("\(Int(t.carb.rounded()))", "C g", TF.carbs)
                    bigStat("\(Int(t.fat.rounded()))", "F g", TF.fat)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func bigStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TF.textSecondary)
        }
    }

    private func addToLog(_ food: FoodItem) {
        if food.isPer100g, let grams = totalGrams {
            app.addFood(
                food,
                servings: grams / 100,
                meal: meal,
                portionLabel: portionLabel(for: food),
                on: date
            )
        } else {
            app.addFood(food, servings: max(quantity, 0.5), meal: meal, on: date)
        }
        dismiss()
    }

    private func portionLabel(for food: FoodItem) -> String? {
        guard let portion = selectedPortion, portion.grams != nil else { return nil }
        switch portion.id {
        case "oz":
            return "\(formatQuantity(quantity)) oz"
        case "100g":
            return "\(Int((totalGrams ?? 0).rounded())) g"
        default:
            return nil
        }
    }

    // MARK: Custom food form

    private var customFoodIsValid: Bool {
        !customName.trimmingCharacters(in: .whitespaces).isEmpty
            && (Double(customCalories) ?? 0) > 0
    }

    private var customFoodForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                TFCard {
                    VStack(alignment: .leading, spacing: 12) {
                        customField("Name", text: $customName, placeholder: "Mom's chili")
                            .submitLabel(.next)
                        customField("Brand (optional)", text: $customBrand, placeholder: "House brand")
                            .submitLabel(.next)
                        customField("Serving name", text: $customServing, placeholder: "1 bowl")
                            .submitLabel(.next)
                    }
                }
                TFCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Per serving")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TF.text)
                        HStack(spacing: 10) {
                            customNumberField("kcal", text: $customCalories)
                            customNumberField("P g", text: $customProtein)
                            customNumberField("C g", text: $customCarbs)
                            customNumberField("F g", text: $customFat)
                        }
                    }
                }
                mealPicker
                TFButton(title: "Add to log", systemImage: "plus.circle.fill", style: .primary) {
                    addCustomFood()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func customField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(TF.textSecondary)
            TextField(placeholder, text: text)
                .foregroundStyle(TF.text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
        }
    }

    private func customNumberField(_ label: String, text: Binding<String>) -> some View {
        VStack(spacing: 4) {
            TextField("0", text: text)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TF.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(TF.textSecondary)
        }
    }

    private func addCustomFood() {
        guard customFoodIsValid else { return }
        let food = FoodItem(
            name: customName.trimmingCharacters(in: .whitespaces),
            serving: customServing.trimmingCharacters(in: .whitespaces).isEmpty
                ? "1 serving"
                : customServing.trimmingCharacters(in: .whitespaces),
            calories: Int(Double(customCalories) ?? 0),
            protein: Int(Double(customProtein) ?? 0),
            carbs: Int(Double(customCarbs) ?? 0),
            fat: Int(Double(customFat) ?? 0),
            brand: customBrand.trimmingCharacters(in: .whitespaces).isEmpty
                ? nil
                : customBrand.trimmingCharacters(in: .whitespaces),
            source: .custom
        )
        app.addFood(food, servings: 1, meal: meal, on: date)
        dismiss()
    }

    // MARK: Quick add (Premium)

    private var quickAddIsValid: Bool {
        (Double(quickCalories) ?? 0) > 0 || (Double(quickProtein) ?? 0) > 0
    }

    private var quickAddForm: some View {
        ScrollView {
            VStack(spacing: 16) {
                TFCard {
                    VStack(alignment: .leading, spacing: 12) {
                        customField("Name (optional)", text: $quickName, placeholder: "Quick add")
                        Text("Log calories and macros directly — no food lookup needed.")
                            .font(.caption)
                            .foregroundStyle(TF.textSecondary)
                    }
                }
                TFCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Macros")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TF.text)
                        HStack(spacing: 10) {
                            customNumberField("kcal", text: $quickCalories)
                            customNumberField("P g", text: $quickProtein)
                            customNumberField("C g", text: $quickCarbs)
                            customNumberField("F g", text: $quickFat)
                        }
                    }
                }
                mealPicker
                TFButton(title: "Add to log", systemImage: "plus.circle.fill", style: .primary) {
                    addQuickAdd()
                }
                .disabled(!quickAddIsValid)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func addQuickAdd() {
        let name = quickName.trimmingCharacters(in: .whitespaces)
        let food = FoodItem(
            name: name.isEmpty ? "Quick add" : name,
            serving: "1 entry",
            calories: Int(Double(quickCalories) ?? 0),
            protein: Int(Double(quickProtein) ?? 0),
            carbs: Int(Double(quickCarbs) ?? 0),
            fat: Int(Double(quickFat) ?? 0),
            source: .custom
        )
        app.addFood(food, servings: 1, meal: meal, on: date)
        dismiss()
    }
}

#Preview {
    NutritionView().environment(AppModel())
}

// MARK: - Edit a logged item

/// Change the meal or amount of something already logged, or remove it.
struct EditLoggedFoodSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    let item: LoggedFood
    let date: Date

    @State private var meal: MealType = .breakfast
    @State private var amount: Double = 1

    /// Weighed entries ("150 g") keep their label, so scale them as a
    /// multiple of the logged portion; others edit servings directly.
    private var isPortion: Bool { item.portionLabel != nil }

    private var newServings: Double {
        isPortion ? item.servings * amount : amount
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.food.displayName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text("\(Int((Double(item.food.calories) * newServings).rounded())) kcal · P \(Int((Double(item.food.protein) * newServings).rounded()))g · C \(Int((Double(item.food.carbs) * newServings).rounded()))g · F \(Int((Double(item.food.fat) * newServings).rounded()))g")
                        .font(.caption)
                        .foregroundStyle(TF.textSecondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(isPortion ? "Amount (× \(item.portionLabel ?? "portion"))" : "Servings (\(item.food.serving))")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    Stepper(value: $amount, in: 0.25...20, step: 0.25) {
                        Text(Self.format(amount))
                            .font(.title3.weight(.bold))
                            .foregroundStyle(TF.text)
                            .monospacedDigit()
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Meal")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    Picker("Meal", selection: $meal) {
                        ForEach(MealType.allCases) { m in
                            Text(m.rawValue).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Spacer(minLength: 0)

                TFButton(title: "Save", systemImage: "checkmark", style: .primary) {
                    app.updateFood(item.id, on: date, servings: newServings, meal: meal)
                    dismiss()
                }
            }
            .padding(16)
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(TF.blue)
                }
            }
        }
        .onAppear {
            meal = item.meal
            amount = isPortion ? 1 : min(max(item.servings, 0.25), 20)
        }
    }

    private static func format(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(format: "%g", v)
    }
}
