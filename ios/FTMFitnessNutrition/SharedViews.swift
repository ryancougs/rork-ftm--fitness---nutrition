//
//  SharedViews.swift
//  FTMFitnessNutrition
//

import SwiftUI

// MARK: - Health disclaimer

/// Required App Store safety notice. Shown wherever training, nutrition,
/// supplement, or hormone-adjacent guidance is presented.
struct TFHealthDisclaimer: View {
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "cross.case.fill")
                .font(.footnote)
                .foregroundStyle(TF.blue)
                .padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) {
                Text("Not medical advice")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(TF.text)
                Text(compact
                     ? "General fitness and nutrition education only. Talk to your doctor before changing how you train or eat."
                     : "FTMFitnessNutrition offers general fitness and nutrition education — it isn't medical advice, diagnosis, or treatment. Anything touching hormones, surgery recovery, diabetes, or PEDs is informational only. Always talk to your own healthcare provider before making a decision, and stop training if you feel unwell.")
                    .font(.caption2)
                    .foregroundStyle(TF.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: TF.cornerS)
                .fill(TF.card)
        }
        .overlay {
            RoundedRectangle(cornerRadius: TF.cornerS)
                .stroke(TF.border, lineWidth: 1)
        }
    }
}

// MARK: - Brand button

struct TFButton: View {
    let title: String
    let systemImage: String?
    var style: Style = .primary
    var isLoading: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    enum Style {
        case primary, secondary, ghost, danger
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(style == .primary ? TF.bg : TF.blue)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(.rect(cornerRadius: TF.cornerM))
            .overlay {
                if style == .secondary {
                    RoundedRectangle(cornerRadius: TF.cornerM)
                        .strokeBorder(TF.blue.opacity(0.6), lineWidth: 1.5)
                }
            }
            .opacity(disabled ? 0.55 : 1)
        }
        .disabled(disabled || isLoading)
        .animation(.easeOut(duration: 0.15), value: disabled)
    }

    @ViewBuilder private var backgroundColor: some View {
        switch style {
        case .primary:   TF.blue
        case .secondary: Color.clear
        case .ghost:     Color.clear
        case .danger:    TF.danger.opacity(0.12)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:   TF.bg
        case .secondary, .ghost: TF.blue
        case .danger:    TF.danger
        }
    }
}

// MARK: - Chip / Option button

struct TFChip: View {
    let title: String
    let subtitle: String?
    let emoji: String?
    let selected: Bool
    let action: () -> Void

    init(_ title: String, subtitle: String? = nil, emoji: String? = nil, selected: Bool, action: @escaping () -> Void) {
        self.title = title; self.subtitle = subtitle; self.emoji = emoji
        self.selected = selected; self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let emoji {
                    Text(emoji).font(.title2)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(TF.text)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(TF.textSecondary)
                            .multilineTextAlignment(.leading)
                    }
                }
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? TF.blue : TF.textSecondary)
                    .font(.title3)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .fill(selected ? TF.blue.opacity(0.14) : TF.input)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerM)
                    .strokeBorder(selected ? TF.blue : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section header

struct TFSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(TF.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(TF.textSecondary)
                }
            }
            Spacer()
            if let trailing { trailing }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    let progress: Double          // 0...1
    let color: Color
    var lineWidth: CGFloat = 9
    var size: CGFloat = 64
    var label: String? = nil

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)
            if let label {
                Text(label)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(color)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Macro bar

struct MacroBar: View {
    let label: String
    let value: Double
    let target: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TF.textSecondary)
                Spacer()
                Text("\(Int(value.rounded())) / \(Int(target))g")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(TF.text)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.18))
                        .frame(height: 8)
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(max(target > 0 ? value/target : 0, 0), 1), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: value)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Card container

struct TFCard<Content: View>: View {
    var padding: CGFloat = 16
    var background: Color = TF.card
    let content: () -> Content

    init(padding: CGFloat = 16, background: Color = TF.card, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding; self.background = background; self.content = content
    }

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: TF.cornerL)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerL)
                    .strokeBorder(TF.border, lineWidth: 1)
            )
    }
}

// MARK: - Empty state

struct TFEmptyState: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(TF.blue.opacity(0.7))
            Text(title)
                .font(.headline)
                .foregroundStyle(TF.text)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(TF.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Header card

/// Elevated header card with a subtle blue tint. The one blue+pink gradient
/// lives only on the Home greeting (see HomeView.greetingCard).
struct TFHeroBanner: View {
    let content: () -> AnyView

    init(@ViewBuilder content: @escaping () -> some View) {
        self.content = { AnyView(content()) }
    }

    var body: some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: TF.cornerL)
                    .fill(TF.blue.opacity(0.10))
            )
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerL)
                    .strokeBorder(TF.blue.opacity(0.22), lineWidth: 1)
            )
            .foregroundStyle(TF.text)
    }
}

// MARK: - Home banner

/// The Home greeting card — the one place the blue+pink gradient appears
/// (alongside the logo elsewhere). Sits on a solid card so the gradient
/// stays a subtle wash, never a loud block.
struct TFHomeBanner: View {
    let content: () -> AnyView

    init(@ViewBuilder content: @escaping () -> some View) {
        self.content = { AnyView(content()) }
    }

    var body: some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: TF.cornerL)
                        .fill(TF.card)
                    TF.accentGradient
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: TF.cornerL)
                    .strokeBorder(TF.border, lineWidth: 1)
            )
            .foregroundStyle(TF.text)
    }
}
