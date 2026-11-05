//
//  FeedbackSheet.swift
//  FTMFitnessNutrition
//

import SwiftUI
import UIKit

/// Profile > Help & feedback. Sends a message to the team (stored in the
/// support_messages table). Replaces the old support email address.
struct FeedbackSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    private static let topics = ["Something's broken", "Idea or request", "My account or data", "Subscription", "Other"]
    private let maxLength = 2000

    @State private var topic: String = "Something's broken"
    @State private var message: String = ""
    @State private var includeEmail: Bool = true
    @State private var isSending = false
    @State private var error: String? = nil
    @State private var sent = false

    private var trimmed: String { message.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if sent {
                        sentCard
                    } else {
                        form
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(TF.bg.ignoresSafeArea())
            .navigationTitle("Help & feedback")
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

    @ViewBuilder
    private var form: some View {
        Text("Tell us what's going on. A real person reads every message.")
            .font(.subheadline)
            .foregroundStyle(TF.textSecondary)

        VStack(alignment: .leading, spacing: 8) {
            Text("Topic")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.text)
            FlowChips(options: Self.topics, selected: [topic]) { topic = $0 }
        }

        VStack(alignment: .leading, spacing: 8) {
            Text("Message")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TF.text)
            TextEditor(text: $message)
                .font(.subheadline)
                .frame(minHeight: 160)
                .padding(8)
                .scrollContentBackground(.hidden)
                .background(RoundedRectangle(cornerRadius: TF.cornerS).fill(TF.input))
                .onChange(of: message) { _, newValue in
                    if newValue.count > maxLength { message = String(newValue.prefix(maxLength)) }
                }
            Text("If something broke, say which screen and what you tapped. Error codes like S503 help too.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }

        if !app.profile.email.isEmpty {
            Toggle(isOn: $includeEmail) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Let us reply by email")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(TF.text)
                    Text(app.profile.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(TF.blue)
        }

        if let error {
            Text(error)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.red)
        }

        TFButton(title: "Send", systemImage: "paperplane.fill", style: .primary,
                 isLoading: isSending, disabled: trimmed.isEmpty, action: send)
    }

    private var sentCard: some View {
        TFCard(background: TF.blue.opacity(0.12)) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Message sent", systemImage: "checkmark.circle.fill")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(TF.blue)
                Text("Thanks for telling us. If you asked for a reply, it'll come to your email.")
                    .font(.subheadline)
                    .foregroundStyle(TF.text)
            }
        }
    }

    private func send() {
        error = nil
        isSending = true
        let email = includeEmail && !app.profile.email.isEmpty ? app.profile.email : nil
        Task { @MainActor in
            defer { isSending = false }
            do {
                try await SupabaseService.shared.sendFeedback(topic: topic, message: trimmed, replyEmail: email)
                withAnimation { sent = true }
            } catch let err {
                error = SupabaseService.friendlyMessage(for: err)
            }
        }
    }
}

/// Wrapping row of selectable chips (single or multi select is up to the caller).
struct FlowChips: View {
    let options: [String]
    let selected: Set<String>
    let onTap: (String) -> Void

    init(options: [String], selected: Set<String>, onTap: @escaping (String) -> Void) {
        self.options = options
        self.selected = selected
        self.onTap = onTap
    }

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isOn = selected.contains(option)
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    onTap(option)
                } label: {
                    Text(option)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(isOn ? TF.bg : TF.text)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(isOn ? TF.blue : TF.input))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Simple left-aligned wrapping layout.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
