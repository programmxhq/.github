import SwiftUI

// MARK: - Stage palette

extension Stage {
    /// Two soft background tints plus a saturated accent. The tints are low-opacity so
    /// primary/secondary text stays readable over them in both light and dark mode.
    var palette: (bg1: Color, bg2: Color, accent: Color) {
        switch self {
        case .dawn:
            return (Color.mint.opacity(0.30), Color.green.opacity(0.10), Color.green)
        case .bloom:
            return (Color.pink.opacity(0.26), Color.orange.opacity(0.12), Color.pink)
        case .build:
            return (Color.blue.opacity(0.24), Color.cyan.opacity(0.12), Color.blue)
        case .harvest:
            return (Color.orange.opacity(0.26), Color.yellow.opacity(0.14), Color.orange)
        case .dusk:
            return (Color.indigo.opacity(0.30), Color.purple.opacity(0.14), Color.indigo)
        }
    }
}

// MARK: - Shared helpers

enum Theme {
    /// Money is stored in $1k units: 12 -> "$12k", -4 -> "-$4k", 1500 -> "$1.5M".
    static func money(_ k: Int) -> String {
        let sign = k < 0 ? "-" : ""
        let amount = abs(k)
        if amount >= 1000 {
            let millions = Double(amount) / 1000
            return sign + "$" + String(format: "%.1fM", millions)
        }
        return sign + "$" + String(amount) + "k"
    }

    /// "+12" / "-4" / "0".
    static func signed(_ v: Int) -> String {
        v > 0 ? "+" + String(v) : String(v)
    }

    /// Color for gamble odds: likely green, coin-flip orange, long shot red.
    static func oddsColor(_ pct: Int) -> Color {
        if pct >= 65 { return .green }
        if pct >= 40 { return .orange }
        return .red
    }
}

extension Animation {
    /// The one spring used for dealing, expanding and collapsing cards.
    static let dealtSpring = Animation.spring(duration: 0.45, bounce: 0.2)
}

// MARK: - Background

struct StageBackground: View {
    let stage: Stage

    var body: some View {
        let p = stage.palette
        return ZStack {
            Color(uiColor: .systemBackground)
            LinearGradient(colors: [p.bg1, p.bg2], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Button styles

/// Subtle press-down scale used for cards and tappable tiles.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(duration: 0.2, bounce: 0.3), value: configuration.isPressed)
    }
}

// MARK: - Stat ring

struct StatRing: View {
    let stat: Stat
    let value: Int

    private var fraction: CGFloat {
        CGFloat(value.clamped(0...100)) / 100
    }

    private var valueColor: Color {
        value <= 20 ? Color.red : Color.primary
    }

    var body: some View {
        VStack(spacing: 2) {
            ring
            Text(String(value))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(valueColor)
                .contentTransition(.numericText(value: Double(value)))
            Text(stat.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .animation(.easeOut(duration: 0.6), value: value)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stat.label + " " + String(value))
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(stat.color.opacity(0.18), lineWidth: 5)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(stat.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: stat.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(stat.color)
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Chips

struct DeltaChip: View {
    let text: String

    private var tint: Color {
        if text.hasPrefix("+") || text.hasPrefix("✨") || text.hasPrefix("Income") {
            return .green
        }
        if text.hasPrefix("-") || text.hasPrefix("−") || text.hasPrefix("✖️") || text.hasPrefix("🪦") {
            return .red
        }
        return .gray
    }

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .foregroundStyle(tint)
            .background(tint.opacity(0.15), in: Capsule())
    }
}

struct Chip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .foregroundStyle(color)
            .background(color.opacity(0.15), in: Capsule())
    }
}

// MARK: - Primary button

struct PrimaryButton: View {
    let title: String
    let tint: Color
    let action: () -> Void

    init(title: String, tint: Color = .accentColor, action: @escaping () -> Void) {
        self.title = title
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(Color.white)
                .background(tint, in: Capsule())
                .shadow(color: tint.opacity(0.35), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PressableStyle())
    }
}

// MARK: - Card face

struct CardFace: View {
    let card: Card
    let expanded: Bool
    var tint: Color = .accentColor

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: expanded ? 26 : 20, style: .continuous)
    }

    private var hasGamble: Bool {
        card.choices.contains { $0.odds != nil }
    }

    private var borderColor: Color {
        card.priority ? Color.red.opacity(0.8) : tint.opacity(0.28)
    }

    private var fixedHeight: CGFloat? {
        expanded ? nil : 176
    }

    var body: some View {
        content
            .padding(expanded ? 20 : 10)
            .frame(maxWidth: .infinity)
            .frame(height: fixedHeight)
            .background { background }
            .overlay { shape.strokeBorder(borderColor, lineWidth: card.priority ? 2 : 1) }
            .shadow(color: Color.black.opacity(0.14), radius: expanded ? 16 : 8, x: 0, y: expanded ? 8 : 4)
            .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var content: some View {
        if expanded {
            expandedContent
        } else {
            collapsedContent
        }
    }

    private var collapsedContent: some View {
        VStack(spacing: 6) {
            Text(card.emoji)
                .font(.system(size: 44))
                .padding(.top, 6)
            Text(card.title)
                .font(.subheadline.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
            Text(card.teaser)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.9)
            Spacer(minLength: 0)
            if hasGamble {
                Text("🎲")
                    .font(.caption)
                    .opacity(0.8)
            }
        }
        .foregroundStyle(Color.primary)
    }

    private var expandedContent: some View {
        VStack(spacing: 10) {
            Text(card.emoji)
                .font(.system(size: 60))
            Text(card.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text(card.body)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
        .foregroundStyle(Color.primary)
    }

    private var background: some View {
        ZStack {
            shape.fill(.regularMaterial)
            shape.fill(
                LinearGradient(colors: [tint.opacity(0.20), tint.opacity(0.04)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
    }
}
