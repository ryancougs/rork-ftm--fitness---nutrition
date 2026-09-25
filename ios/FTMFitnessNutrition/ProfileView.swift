//
//  ProfileView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Profile tab: user goal, stats, editable targets, settings.
struct ProfileView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditProfile = false
    @State private var showingEditTargets = false
    @State private var showingPrivacy = false
    @State private var showingAbout = false
    @State private var showingDeleteConfirmation = false
    @State private var showingDeleteError = false
    @State private var deletionErrorMessage = ""

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    goalCard
                    statsCard
                    targetsCard
                    settingsSection
                    developerSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TF.blue)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingEditTargets) {
                EditTargetsSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingPrivacy) {
                PrivacySheet()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingAbout) {
                AboutSheet()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: Header

    @ViewBuilder
    private var headerCard: some View {
        TFHeroBanner {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.18))
                        .frame(width: 60, height: 60)
                    Text(initials)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.profile.name.isEmpty ? "Your name" : app.profile.name)
                        .font(.title3.weight(.bold))
                    Text(app.profile.email.isEmpty ? "—" : app.profile.email)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.85))
                    HStack(spacing: 6) {
                        Text(app.profile.goal.emoji)
                        Text(app.profile.goal.rawValue)
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 2)
                }
                Spacer()
                Button {
                    showingEditProfile = true
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(.white.opacity(0.18)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var initials: String {
        let parts = app.profile.name.split(separator: " ")
        if parts.isEmpty { return "🙂" }
        let firsts = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return firsts.joined().uppercased()
    }

    // MARK: Goal

    @ViewBuilder
    private var goalCard: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "target")
                        .foregroundStyle(TF.blue)
                    Text("Current goal")
                        .font(.headline.weight(.bold))
                }
                HStack(spacing: 10) {
                    Text(app.profile.goal.emoji).font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(app.profile.goal.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TF.text)
                        Text(app.profile.goal.blurb)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Divider()
                HStack {
                    Label(app.profile.experience.rawValue, systemImage: "chart.bar.fill")
                    Spacer()
                    Label("\(app.profile.daysPerWeek) days/week", systemImage: "calendar")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(TF.blue)
            }
        }
    }

    // MARK: Stats

    @ViewBuilder
    private var statsCard: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "ruler")
                        .foregroundStyle(TF.blue)
                    Text("Your stats")
                        .font(.headline.weight(.bold))
                }
                HStack(spacing: 10) {
                    statTile("Bodyweight", value: app.profile.bodyweightKg.map { String(format: "%.0f lbs", $0 * 2.20462) } ?? "—")
                    statTile("Height", value: app.profile.heightCm.map { heightLabel(cm: $0) } ?? "—")
                    statTile("Age", value: app.profile.age.map { "\($0)" } ?? "—")
                }
                Text("Update these any time — they help refine your targets.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Displays stored cm as feet + inches, e.g. "5 ft 11 in".
    private func heightLabel(cm: Double) -> String {
        let totalInches = Int((cm / 2.54).rounded())
        let ft = totalInches / 12
        let inches = totalInches % 12
        return inches == 0 ? "\(ft) ft" : "\(ft) ft \(inches) in"
    }

    @ViewBuilder
    private func statTile(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TF.text)
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(TF.input))
    }

    // MARK: Targets

    @ViewBuilder
    private var targetsCard: some View {
        TFCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(TF.pink)
                    Text("Nutrition targets")
                        .font(.headline.weight(.bold))
                    Spacer()
                    Button {
                        showingEditTargets = true
                    } label: {
                        Text("Edit")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TF.blue)
                    }
                    .buttonStyle(.plain)
                }
                targetRow("Calories", value: "\(app.profile.targetCalories)", unit: "kcal", color: TF.blue)
                targetRow("Protein", value: "\(app.profile.targetProtein)", unit: "g", color: TF.protein)
                targetRow("Carbs", value: "\(app.profile.targetCarbs)", unit: "g", color: TF.carbs)
                targetRow("Fat", value: "\(app.profile.targetFat)", unit: "g", color: TF.fat)
                Text(PlanEngine.targets(for: app.profile).rationale)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }

    @ViewBuilder
    private func targetRow(_ label: String, value: String, unit: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(TF.text)
            Spacer()
            Text("\(value) \(unit)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
        }
    }

    // MARK: Developer (hidden testing tools)

    private var developerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TFSectionHeader(title: "Developer")
                .padding(.horizontal, 4)
                .padding(.top, 8)
            TFCard(padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(icon: "arrow.uturn.backward.circle", title: "Reset onboarding", color: TF.pink) {
                        app.resetOnboarding()
                    }
                }
            }
            Text("Testing tool — brings back the first-run setup screen. Your data stays untouched.")
                .font(.caption2)
                .foregroundStyle(TF.textSecondary)
                .padding(.horizontal, 4)
        }
    }

    // MARK: Settings

    @ViewBuilder
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            TFSectionHeader(title: "Settings")
                .padding(.horizontal, 4)
                .padding(.top, 8)
            TFCard(padding: 0) {
                VStack(spacing: 0) {
                    settingsRow(icon: "shield.fill", title: "Privacy", color: TF.blue) {
                        showingPrivacy = true
                    }
                    Divider().padding(.leading, 48)
                    settingsRow(icon: "info.circle.fill", title: "About FTMFitnessNutrition", color: TF.blue) {
                        showingAbout = true
                    }
                }
            }
            TFButton(title: "Rebuild my training plan", systemImage: "arrow.triangle.2.circlepath", style: .secondary) {
                app.regeneratePlan()
            }
            .padding(.top, 8)
            TFButton(title: "Log out", systemImage: "arrow.right.square", style: .ghost) {
                app.logOut()
            }
            .padding(.top, 8)
            Button {
                showingDeleteConfirmation = true
            } label: {
                Text("Delete account")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.8))
                    .underline()
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .confirmationDialog("Delete your account?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    Task { @MainActor in
                        do {
                            try await app.deleteAccount()
                        } catch let err {
                            deletionErrorMessage = SupabaseService.friendlyMessage(for: err)
                            showingDeleteError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This permanently removes your profile, workouts, food logs, and check-ins from this device and our servers. This can't be undone.")
            }
            .alert("Couldn't delete your account", isPresented: $showingDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deletionErrorMessage)
            }
            TFHealthDisclaimer()
                .padding(.top, 12)
            Text("FTMFitnessNutrition — the only FTM fitness app you'll need.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
        }
    }

    private func settingsRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.18))
                        .frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .foregroundStyle(color)
                        .font(.footnote)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(TF.text)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Privacy sheet

struct PrivacySheet: View {
    @Environment(\.dismiss) private var dismiss

    private let policyURL = URL(string: "https://2gxfo9qxolcyjgbzbeaoj-web.rork.live/privacy")!
    private let supportURL = URL(string: "mailto:support@transfit.app")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TFCard(background: TF.blue.opacity(0.12)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("The short version", systemImage: "checkmark.seal.fill")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(TF.blue)
                            Text("Your account needs only a display name and an email. FTMFitnessNutrition never asks for your legal name, gender marker, or location. Your workout logs, food logs, and check-ins stay yours — no ads, no data selling, ever.")
                                .font(.subheadline)
                                .foregroundStyle(TF.text)
                        }
                    }
                    TFCard {
                        VStack(alignment: .leading, spacing: 12) {
                            privacyPoint("person.crop.circle", "What we store",
                                         "Account email, display name, and the fitness and wellbeing data you log — workouts, food, check-ins.")
                            privacyPoint("lock.shield", "How it's protected",
                                         "Passwords are hashed. Data is encrypted in transit and at rest, and plan generation happens on your device.")
                            privacyPoint("trash", "Your control",
                                         "You can delete everything yourself — Profile → Delete account — or email us and we'll handle it within 30 days.")
                        }
                    }
                    VStack(spacing: 10) {
                        Link(destination: policyURL) {
                            Label("Read the full Privacy Policy", systemImage: "safari")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TF.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(TF.blue.opacity(0.18)))
                        }
                        Link(destination: supportURL) {
                            Label("Email support@transfit.app", systemImage: "envelope")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TF.blue)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Capsule().fill(TF.blue.opacity(0.18)))
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TF.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func privacyPoint(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(TF.blue)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.text)
                Text(body)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - About sheet

struct AboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer()
                ZStack {
                    Circle()
                        .fill(TF.blue)
                        .frame(width: 84, height: 84)
                        .shadow(color: TF.blue.opacity(0.3), radius: 16, y: 8)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Text("FTMFitnessNutrition")
                    .font(.title.weight(.bold))
                    .foregroundStyle(TF.blue)
                Text("The only FTM fitness app you'll need. A space where you don't have to explain yourself before you start training.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text("Version 1.0.0 — Free at launch")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TF.blue)
                Text("Made for the trans masculine community, with input from a coach who lives it.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Spacer()
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(TF.blue)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Edit profile sheet

struct EditProfileSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var bodyweightLbs: String = ""
    @State private var heightFt: String = ""
    @State private var heightIn: String = ""
    @State private var age: String = ""
    @State private var goal: FitnessGoal = .buildMuscle
    @State private var experience: ExperienceLevel = .beginner
    @State private var daysPerWeek: Int = 4
    @State private var lifestyle: Lifestyle = .mostlySitting
    @State private var equipment: EquipmentAccess = .fullGym

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    section("Name") {
                        TextField("Your name", text: $name)
                            .foregroundStyle(TF.text)
                            .padding(12)
                            .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                    }
                    section("Goal") {
                        VStack(spacing: 8) {
                            ForEach(FitnessGoal.allCases) { g in
                                TFChip(g.rawValue, subtitle: g.blurb, emoji: g.emoji, selected: goal == g) { goal = g }
                            }
                        }
                    }
                    section("Experience") {
                        VStack(spacing: 8) {
                            ForEach(ExperienceLevel.allCases) { lvl in
                                TFChip(lvl.rawValue, subtitle: lvl.blurb, selected: experience == lvl) { experience = lvl }
                            }
                        }
                    }
                    section("Days per week") {
                        HStack(spacing: 12) {
                            ForEach([3, 4, 5, 6], id: \.self) { d in
                                dayButton(d)
                            }
                        }
                    }
                    section("Day-to-day activity") {
                        VStack(spacing: 8) {
                            ForEach(Lifestyle.allCases) { l in
                                TFChip(l.rawValue, subtitle: l.blurb, emoji: l.emoji, selected: lifestyle == l) { lifestyle = l }
                            }
                        }
                    }
                    section("Equipment") {
                        VStack(spacing: 8) {
                            ForEach(EquipmentAccess.allCases) { e in
                                TFChip(e.rawValue, subtitle: e.blurb, emoji: e.emoji, selected: equipment == e) { equipment = e }
                            }
                        }
                    }
                    section("Body stats (optional)") {
                        VStack(spacing: 10) {
                            statField("Bodyweight (lbs)", text: $bodyweightLbs)
                            HStack(spacing: 10) {
                                statField("Height (ft)", text: $heightFt)
                                statField("Height (in)", text: $heightIn)
                            }
                            statField("Age", text: $age)
                        }
                    }
                    TFButton(title: "Save changes", systemImage: "checkmark", style: .primary) {
                        app.updateProfile { p in
                            p.name = name.trimmingCharacters(in: .whitespaces)
                            p.goal = goal
                            p.experience = experience
                            p.daysPerWeek = daysPerWeek
                            p.lifestyle = lifestyle
                            p.equipment = equipment
                            if let lbs = Double(bodyweightLbs), lbs > 0 { p.bodyweightKg = (lbs * 0.453592 * 10).rounded() / 10 }
                            let ft = Double(heightFt) ?? 0
                            let inches = Double(heightIn) ?? 0
                            if ft > 0 { p.heightCm = ((ft * 30.48 + inches * 2.54) * 10).rounded() / 10 }
                            if let a = Int(age), a > 0 { p.age = a }
                        }
                        dismiss()
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneBar()
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(TF.blue)
                }
            }
        }
        .onAppear { syncFromProfile() }
    }

    private func syncFromProfile() {
        name = app.profile.name
        goal = app.profile.goal
        experience = app.profile.experience
        daysPerWeek = app.profile.daysPerWeek
        lifestyle = app.profile.lifestyle
        equipment = app.profile.equipment
        bodyweightLbs = app.profile.bodyweightKg.map { String(format: "%.0f", $0 / 0.453592) } ?? ""
        if let cm = app.profile.heightCm {
            let totalInches = cm / 2.54
            let ft = Int(totalInches / 12)
            let inches = Int((totalInches - Double(ft) * 12).rounded())
            heightFt = String(ft)
            heightIn = inches > 0 ? String(inches) : ""
        } else {
            heightFt = ""
            heightIn = ""
        }
        age = app.profile.age.map { String($0) } ?? ""
    }

    @ViewBuilder
    private func dayButton(_ d: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { daysPerWeek = d }
        } label: {
            Text("\(d)")
                .font(.title3.weight(.bold))
                .foregroundStyle(daysPerWeek == d ? TF.bg : TF.text)
                .frame(width: 52, height: 52)
                .background {
                    if daysPerWeek == d {
                        Circle().fill(TF.blue)
                    } else {
                        Circle().fill(TF.input)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.text)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func statField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .foregroundStyle(TF.text)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
        }
    }
}

// MARK: - Edit targets sheet

struct EditTargetsSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fat: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TFHeroBanner {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tune your targets")
                                .font(.headline.weight(.bold))
                            Text("These set the goals you'll see on Home and Nutrition. Adjust them as you learn what works for your body.")
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }
                    numberField("Daily calories (kcal)", text: $calories)
                    numberField("Protein (g)", text: $protein)
                    numberField("Carbs (g)", text: $carbs)
                    numberField("Fat (g)", text: $fat)
                    Button {
                        app.updateProfile { p in
                            p.applyDefaultTargets()
                        }
                        syncFromProfile()
                    } label: {
                        Label("Reset to recommended", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TF.blue)
                    }
                    .buttonStyle(.plain)
                    TFButton(title: "Save targets", systemImage: "checkmark", style: .primary) {
                        app.updateProfile { p in
                            if let c = Int(calories), c > 0 { p.targetCalories = c }
                            if let pr = Int(protein), pr > 0 { p.targetProtein = pr }
                            if let ca = Int(carbs), ca > 0 { p.targetCarbs = ca }
                            if let f = Int(fat), f > 0 { p.targetFat = f }
                        }
                        dismiss()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneBar()
            .navigationTitle("Nutrition targets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(TF.blue)
                }
            }
        }
        .onAppear { syncFromProfile() }
    }

    private func syncFromProfile() {
        calories = String(app.profile.targetCalories)
        protein = String(app.profile.targetProtein)
        carbs = String(app.profile.targetCarbs)
        fat = String(app.profile.targetFat)
    }

    @ViewBuilder
    private func numberField(_ label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(TF.text)
            TextField("", text: text)
                .keyboardType(.numberPad)
                .foregroundStyle(TF.text)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
        }
    }
}

#Preview {
    ProfileView().environment(AppModel())
}
