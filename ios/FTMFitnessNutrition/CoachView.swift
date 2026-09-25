//
//  CoachView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Coach tab: Mason's profile, credentials, philosophy, updates feed
/// (filterable), and what's next. The weekly check-in lives on its own
/// screen, opened from the Home prompt card.
struct CoachView: View {
    @Environment(AppModel.self) private var app
    @Environment(StoreService.self) private var store
    @State private var selectedCategory: CoachCategory? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    masonHeader
                    credentialsRow
                    philosophyCard
                    categoryFilter
                    updatesFeed
                    comingSoonSection
                    footerCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Coach")
        }
    }

    // MARK: Mason's header

    private var masonHeader: some View {
        TFHeroBanner {
            VStack(spacing: 14) {
                Image("CoachMason")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 84, height: 84)
                    .clipShape(Circle())
                VStack(spacing: 4) {
                    Text("Mason")
                        .font(.title2.weight(.bold))
                    Text("Your Coach — A coach who lives it")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Credentials

    private var credentialsList: [(String, String)] {
        [
            ("BSc", "graduationcap.fill"),
            ("MSc", "graduationcap.fill"),
            ("Functional Health Coach", "heart.text.clipboard"),
            ("Type 1 Diabetic", "cross.case.fill"),
            ("Transgender", "person.crop.circle.badge.checkmark"),
            ("Bodybuilding Competitor", "trophy.fill"),
        ]
    }

    private var credentialsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(credentialsList, id: \.0) { cred in
                    HStack(spacing: 6) {
                        Image(systemName: cred.1)
                            .font(.caption)
                        Text(cred.0)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(TF.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(TF.blue.opacity(0.18)))
                }
            }
        }
    }

    // MARK: Philosophy

    private var philosophyCard: some View {
        TFCard(background: TF.blue.opacity(0.10)) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(TF.pink)
                    Text("A coach who lives it")
                        .font(.headline.weight(.bold))
                }
                Text("I built this space because I always felt alone growing up and like I never fit in. So I wanted to merge my knowledge and experience in nutrition and training into a community group where no one will feel alone. I want you to all know you're supported. As a trans man who's competed in bodybuilding, lives with T1D, and has been through the hormone timeline — I understand testosterone, surgeries, and what it means to build an X-frame on a trans masculine body. You shouldn't have to explain yourself before you start training. This is your space.")
                    .font(.subheadline)
                    .foregroundStyle(TF.text)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    // MARK: Category filter

    private var allCategories: [CoachCategory?] {
        [nil] + CoachCategory.allCases
    }

    @ViewBuilder
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allCategories, id: \.self) { cat in
                    categoryChip(cat)
                }
            }
        }
    }

    private func categoryLabel(_ cat: CoachCategory?) -> String {
        if let cat { "\(cat.emoji) \(cat.rawValue)" }
        else { "All" }
    }

    @ViewBuilder
    private func categoryChip(_ cat: CoachCategory?) -> some View {
        let isSelected = selectedCategory == cat
        Button {
            withAnimation(.spring(response: 0.3)) { selectedCategory = cat }
        } label: {
            Text(categoryLabel(cat))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : TF.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule().fill(TF.blue)
                    } else {
                        Capsule().fill(TF.input)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: Updates feed

    private var filteredUpdates: [CoachUpdate] {
        let updates = app.coachUpdates.sorted { $0.date > $1.date }
        if let cat = selectedCategory {
            return updates.filter { $0.category == cat }
        }
        return updates
    }

    @ViewBuilder
    private var updatesFeed: some View {
        TFSectionHeader(title: "Mason's Updates", subtitle: "\(filteredUpdates.count) post\(filteredUpdates.count == 1 ? "" : "s")")
            .padding(.top, 4)
        ForEach(filteredUpdates) { update in
            updateCard(update)
        }
    }

    @ViewBuilder
    private func updateCard(_ update: CoachUpdate) -> some View {
        TFCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(update.category.emoji) \(update.category.rawValue)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TF.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(TF.blue.opacity(0.18)))
                    Spacer()
                    Text(update.date.relativeDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(update.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TF.text)
                if update.isPremium {
                    if store.isPremium {
                        Text(update.body)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    } else {
                        Button {
                            app.selectedTab = .prep
                        } label: {
                            VStack(spacing: 8) {
                                Text(update.body)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                                    .blur(radius: 3)
                                HStack {
                                    Image(systemName: "lock.fill")
                                    Text("Prep Team members only — tap to unlock")
                                        .multilineTextAlignment(.leading)
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(TF.pink)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(RoundedRectangle(cornerRadius: 8).fill(TF.pink.opacity(0.10)))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text(update.body)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    // MARK: Coming soon

    @ViewBuilder
    private var comingSoonSection: some View {
        TFSectionHeader(title: "What's Coming", subtitle: "Free and paid features in development")
            .padding(.top, 8)
        VStack(spacing: 10) {
            ForEach(SampleData.comingSoon) { feature in
                comingSoonCard(feature)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: TF.cornerL).fill(TF.card.opacity(0.45)))
    }

    @ViewBuilder
    private func comingSoonCard(_ feature: ComingSoonFeature) -> some View {
        TFCard {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(TF.blue.opacity(0.18))
                        .frame(width: 44, height: 44)
                    Image(systemName: feature.icon)
                        .foregroundStyle(TF.blue)
                }
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(feature.title)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(TF.text)
                        Spacer()
                        Text("Soon")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(TF.pink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(TF.pink.opacity(0.12)))
                    }
                    Text(feature.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    // MARK: Footer

    private var footerCard: some View {
        VStack(spacing: 12) {
            TFHealthDisclaimer()
            Text("FTMFitnessNutrition is free at launch.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.blue)
            Text("Premium features and community tools are coming. Be upfront about costs — no surprises, ever.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }
}

#Preview {
    CoachView().environment(AppModel())
}
