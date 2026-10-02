//
//  CommunityView.swift
//  FTMFitnessNutrition
//

import SwiftUI

/// Community tab: a feed of posts from FTMFitnessNutrition users — connection first,
/// moderation built in. Posts show a chosen display name, never an email.
struct CommunityView: View {
    @Environment(AppModel.self) private var app
    @Environment(StoreService.self) private var store

    @State private var posts: [SupabaseService.CommunityPost] = []
    @State private var isLoading: Bool = true
    @State private var loadError: String? = nil
    @State private var showingComposer = false
    @State private var showingGuidelines = false
    @State private var reportingPost: SupabaseService.CommunityPost? = nil
    @State private var deletingPost: SupabaseService.CommunityPost? = nil
    @State private var reportSubmitted = false
    @State private var coachCategory: CoachCategory? = nil
    @State private var showingCoachPaywall = false

    private let reportReasons = [
        "Harassment or hate",
        "Sharing private information",
        "Medical or dosage advice",
        "Spam or advertising",
        "Something else",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    coachSection
                    headerCard
                    guidelinesCard
                    if isLoading {
                        ProgressView()
                            .tint(TF.blue)
                            .padding(.vertical, 40)
                    } else if let loadError {
                        errorCard(loadError)
                    } else if posts.isEmpty {
                        emptyStateCard
                    } else {
                        ForEach(posts) { post in
                            postCard(post)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .refreshable { await load() }
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Community")
            .sheet(isPresented: $showingCoachPaywall) {
                PaywallView(context: .coachUpdates)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingComposer = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .font(.title3)
                            .foregroundStyle(TF.blue)
                    }
                }
            }
            .sheet(isPresented: $showingComposer, onDismiss: { Task { await load() } }) {
                ComposePostSheet()
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .confirmationDialog("Report this post?", isPresented: Binding(
                get: { reportingPost != nil },
                set: { if !$0 { reportingPost = nil } }
            ), titleVisibility: .visible) {
                ForEach(reportReasons, id: \.self) { reason in
                    Button(reason) { report(reason) }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("A moderator reviews every report. The poster isn't told who reported them.")
            }
            .confirmationDialog("Delete your post?", isPresented: Binding(
                get: { deletingPost != nil },
                set: { if !$0 { deletingPost = nil } }
            ), titleVisibility: .visible) {
                Button("Delete", role: .destructive) { deletePost() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes your post for everyone. This can't be undone.")
            }
            .alert("Report submitted", isPresented: $reportSubmitted) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Thanks for helping keep this space safe. A moderator will take a look.")
            }
        }
        .task {
            if posts.isEmpty { await load() }
        }
    }

    // MARK: Data

    private func load() async {
        do {
            posts = try await SupabaseService.shared.fetchCommunityPosts()
            loadError = nil
        } catch {
            print("Community load failed: \(error)")
            loadError = "Couldn't load the feed right now. Pull down to try again."
        }
        isLoading = false
    }

    private func report(_ reason: String) {
        guard let post = reportingPost else { return }
        reportingPost = nil
        Task { @MainActor in
            do {
                try await SupabaseService.shared.reportCommunityPost(postId: post.id, reason: reason)
                reportSubmitted = true
            } catch {
                print("Report failed: \(error)")
            }
        }
    }

    private func deletePost() {
        guard let post = deletingPost else { return }
        deletingPost = nil
        Task { @MainActor in
            do {
                try await SupabaseService.shared.deleteCommunityPost(id: post.id)
                posts.removeAll { $0.id == post.id }
            } catch {
                print("Delete failed: \(error)")
            }
        }
    }

    // MARK: From Coach Mason (pinned)

    private var allCoachCategories: [CoachCategory?] {
        [nil] + CoachCategory.allCases
    }

    private var filteredCoachUpdates: [CoachUpdate] {
        let updates = app.coachUpdates.sorted { $0.date > $1.date }
        if let cat = coachCategory {
            return updates.filter { $0.category == cat }
        }
        return updates
    }

    private var coachSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image("CoachMason")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("From Coach Mason")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TF.text)
                    Text("Updates from Mason, pinned to the top")
                        .font(.caption)
                        .foregroundStyle(TF.textSecondary)
                }
                Spacer()
            }
            coachCategoryFilter
            ForEach(filteredCoachUpdates) { update in
                coachUpdateCard(update)
            }
        }
    }

    @ViewBuilder
    private var coachCategoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(allCoachCategories, id: \.self) { cat in
                    coachCategoryChip(cat)
                }
            }
        }
    }

    private func coachCategoryLabel(_ cat: CoachCategory?) -> String {
        if let cat { "\(cat.emoji) \(cat.rawValue)" }
        else { "All" }
    }

    @ViewBuilder
    private func coachCategoryChip(_ cat: CoachCategory?) -> some View {
        let isSelected = coachCategory == cat
        Button {
            withAnimation(.spring(response: 0.3)) { coachCategory = cat }
        } label: {
            Text(coachCategoryLabel(cat))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? TF.bg : TF.text)
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

    @ViewBuilder
    private func coachUpdateCard(_ update: CoachUpdate) -> some View {
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
                if update.isPremium, !store.isPremium {
                    Button {
                        showingCoachPaywall = true
                    } label: {
                        VStack(spacing: 8) {
                            Text(update.body)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                                .blur(radius: 3)
                            HStack {
                                Image(systemName: "lock.fill")
                                Text("Premium members only — tap to unlock")
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
                } else {
                    Text(update.body)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    // MARK: Header

    private var headerCard: some View {
        TFHeroBanner {
            VStack(alignment: .leading, spacing: 8) {
                Text("This is where we shine, boys.")
                    .font(.title2.weight(.bold))
                Text("Community is what helps us win together. Introduce yourself, share a win, ask a question — you're not doing this alone.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                Text("Posts show your display name only — never your email.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)
            }
        }
    }

    // MARK: Guidelines

    private var guidelinesCard: some View {
        TFCard(background: TF.blue.opacity(0.12)) {
            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3)) { showingGuidelines.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .foregroundStyle(TF.blue)
                        Text("Community guidelines")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(TF.text)
                        Spacer()
                        Image(systemName: showingGuidelines ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                if showingGuidelines {
                    VStack(alignment: .leading, spacing: 8) {
                        guideline("1", "Support over judgement — everyone here is at a different point in their journey.")
                        guideline("2", "No medical or dosage advice, including hormones. Share experience, point to professionals.")
                        guideline("3", "No sharing anyone's private information — including yours. No real names, no locations.")
                        guideline("4", "This is a body-shame-free zone. No 'before/after' policing of yourself or others.")
                        Text("Report anything that breaks these — a moderator reviews every report.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private func guideline(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(TF.blue))
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Post card

    private func isOwnPost(_ post: SupabaseService.CommunityPost) -> Bool {
        post.userId == SupabaseService.shared.currentUserID
    }

    @ViewBuilder
    private func postCard(_ post: SupabaseService.CommunityPost) -> some View {
        TFCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(TF.blue)
                            .frame(width: 38, height: 38)
                        Text(avatarInitials(post.displayName))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(TF.text)
                        Text(post.createdAt.relativeDescription)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Menu {
                        if isOwnPost(post) {
                            Button(role: .destructive) {
                                deletingPost = post
                            } label: {
                                Label("Delete post", systemImage: "trash")
                            }
                        } else {
                            Button {
                                reportingPost = post
                            } label: {
                                Label("Report", systemImage: "exclamationmark.bubble")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                }
                Text(post.body)
                    .font(.subheadline)
                    .foregroundStyle(TF.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func avatarInitials(_ name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let initials = parts.compactMap { $0.first.map(String.init) }.joined()
        return initials.isEmpty ? "?" : initials.uppercased()
    }

    // MARK: Empty / error states

    private var emptyStateCard: some View {
        TFCard {
            VStack(spacing: 12) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(TF.blue.opacity(0.7))
                Text("No posts yet — be the first")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TF.text)
                Text("Introduce yourself. First day or thousandth day, everyone started somewhere.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                TFButton(title: "Write a post", systemImage: "square.and.pencil", style: .secondary) {
                    showingComposer = true
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }

    private func errorCard(_ message: String) -> some View {
        TFCard {
            VStack(spacing: 10) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.title2)
                    .foregroundStyle(TF.pink)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Composer sheet

struct ComposePostSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var displayName: String = ""
    @State private var postText: String = ""
    @State private var error: String? = nil
    @State private var isPosting: Bool = false

    private let maxLength = 500

    /// Modest baseline filter — reports catch what the filter misses.
    private static let blockedTerms: [String] = [
        "fuck", "shit", "bitch", "cunt", "asshole", "dickhead",
        "retard", "faggot", "tranny", "fagg", "nigger", "kike",
    ]

    private var trimmedText: String {
        postText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canPost: Bool {
        !trimmedText.isEmpty && trimmedText.count <= maxLength && !displayName.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    TFCard(background: TF.blue.opacity(0.12)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Posting as", systemImage: "person.crop.circle")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(TF.blue)
                            TextField("Display name", text: $displayName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(TF.text)
                                .submitLabel(.done)
                                .onSubmit { dismissKeyboard() }
                                .padding(10)
                                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                            Text("Your email is never shown. You can use any name you like.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your post")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TF.text)
                        TextEditor(text: $postText)
                            .font(.subheadline)
                            .frame(minHeight: 140)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                            .overlay(
                                RoundedRectangle(cornerRadius: TF.cornerS)
                                    .stroke(TF.border, lineWidth: 0.5)
                            )
                            .onChange(of: postText) { _, newValue in
                                if newValue.count > maxLength {
                                    postText = String(newValue.prefix(maxLength))
                                }
                            }
                        Text("\(trimmedText.count)/\(maxLength)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if let error {
                        Text(error)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    TFButton(title: "Post to the community", systemImage: "paperplane.fill",
                             style: .primary, isLoading: isPosting, disabled: !canPost, action: post)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("New post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(TF.blue)
                }
            }
        }
        .onAppear {
            if displayName.isEmpty {
                displayName = app.profile.name.isEmpty ? "" : app.profile.name
            }
        }
    }

    private func post() {
        error = nil
        let text = trimmedText
        let name = displayName.trimmingCharacters(in: .whitespaces)

        // Baseline content filter — keeps the feed kind between moderator passes.
        let lowered = text.lowercased()
        if Self.blockedTerms.contains(where: { lowered.contains($0) }) {
            error = "Please rephrase — this space stays supportive, and that language doesn't fit it. Reach support@transfit.app if you think this is a mistake."
            return
        }

        isPosting = true
        Task { @MainActor in
            defer { isPosting = false }
            do {
                try await SupabaseService.shared.createCommunityPost(displayName: name, body: text)
                dismiss()
            } catch let err {
                error = SupabaseService.friendlyMessage(for: err)
            }
        }
    }
}

#Preview {
    CommunityView()
        .environment(AppModel())
        .environment(StoreService.shared)
}
