import SwiftUI

struct SummaryView: View {
    @Environment(GameStore.self) private var store

    @State private var appeared = false
    @State private var shownScore = 0
    @State private var sheet: SummarySheet?
    @State private var picked: Heirloom?
    @State private var bannerShown = false
    @State private var shareImage: Image?
    @State private var timelineOpen: Bool = false

    var body: some View {
        Group {
            if let life = store.life {
                screen(life)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fontDesign(.rounded)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Decision first: the heirloom choice (or the daily result) sits right under the
    /// tombstone; the reading material follows.
    private func screen(_ life: Life) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                header(life)
                primarySection(life)
                achievementsBanner
                epitaphCard(life)
                scoreCard
                TimelineCard(history: life.history, isExpanded: $timelineOpen)
                if !store.isDailyLife {
                    hallSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background { StageBackground(stage: .dusk) }
        .sheet(item: $sheet) { which in
            sheetContent(which)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.35)) { appeared = true }
            withAnimation(.easeOut(duration: 0.9).delay(0.35)) { shownScore = store.score }
            withAnimation(.spring(duration: 0.6, bounce: 0.5).delay(0.6)) { bannerShown = true }
            renderShareImage(life)
        }
    }

    @ViewBuilder
    private func sheetContent(_ which: SummarySheet) -> some View {
        switch which {
        case .hall:
            HallOfFameSheet(allowsReset: false)
                .environment(store)
        case .family:
            FamilyTreeView()
                .environment(store)
        }
    }

    // MARK: - Header

    private func header(_ life: Life) -> some View {
        TombstoneHeader(life: life, rank: store.rank)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
    }

    // MARK: - Primary action (heirloom or daily result)

    @ViewBuilder
    private func primarySection(_ life: Life) -> some View {
        if store.isDailyLife {
            dailyPanel(life)
        } else {
            heirloomSection
        }
    }

    private func dailyPanel(_ life: Life) -> some View {
        let key: String = life.dailyKey ?? store.todayKey
        let score: Int = store.score
        let best: Int = max(store.dailyBest[key] ?? score, score)
        return DailyResultPanel(dayKey: key, score: score, best: best) {
            Haptic.tap()
            withAnimation(.easeInOut(duration: 0.4)) {
                store.finishDaily()
            }
        }
    }

    // MARK: - Epitaph, share & family

    private var showsFamilyButton: Bool {
        !store.isDailyLife && !store.lineage.isEmpty
    }

    private func epitaphCard(_ life: Life) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeading(text: "Epitaph")
            Text(store.epitaph)
                .font(.body)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            actionRow(life)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func actionRow(_ life: Life) -> some View {
        if shareImage != nil || showsFamilyButton {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    actionButtons
                }
                VStack(spacing: 10) {
                    actionButtons
                }
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if let image = shareImage {
            ShareLink(item: image, preview: SharePreview("My life in Dealt", image: image)) {
                PillLabel(title: "Share epitaph", symbol: "square.and.arrow.up", color: Color.indigo)
            }
            .buttonStyle(PressableStyle())
        }
        if showsFamilyButton {
            Button {
                Haptic.tap()
                sheet = .family
            } label: {
                PillLabel(title: "Family tree", symbol: "tree.fill", color: Color.green)
            }
            .buttonStyle(PressableStyle())
        }
    }

    /// Renders the shareable tombstone card once, off-screen, at 3x.
    @MainActor
    private func renderShareImage(_ life: Life) {
        guard shareImage == nil else { return }
        let card = TombstoneShareCard(life: life, rank: store.rank, epitaph: store.epitaph,
                                      score: store.score)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        if let uiImage = renderer.uiImage {
            shareImage = Image(uiImage: uiImage)
        }
    }

    // MARK: - New achievements

    @ViewBuilder
    private var achievementsBanner: some View {
        if !store.newAchievements.isEmpty {
            NewAchievementsBanner(achievements: store.newAchievements)
                .scaleEffect(bannerShown ? 1 : 0.6)
                .opacity(bannerShown ? 1 : 0)
                .sensoryFeedback(.success, trigger: bannerShown)
        }
    }

    // MARK: - Score

    private var scoreCard: some View {
        VStack(spacing: 10) {
            CardHeading(text: "Score")
            ForEach(Array(store.scoreBreakdown.enumerated()), id: \.offset) { _, row in
                ScoreLine(label: row.0, value: row.1)
            }
            Divider()
            HStack {
                Text("Total")
                    .font(.headline)
                Spacer()
                Text(String(shownScore))
                    .font(.title.weight(.heavy))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(shownScore)))
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Heirlooms

    private var heirloomSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Pass something on")
                    .font(.title2.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Text("Your heir carries one of these into the next life.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if store.heirloomOptions.isEmpty {
                fallbackHeirloom
            } else {
                ForEach(store.heirloomOptions, id: \.self) { heirloom in
                    Button {
                        pick(heirloom)
                    } label: {
                        HeirloomTile(heirloom: heirloom, chosen: picked == heirloom)
                    }
                    .buttonStyle(PressableStyle())
                    .disabled(picked != nil)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Never strand the player: if the store produced no options, offer a small cash gift.
    private var fallbackHeirloom: some View {
        let gift = Heirloom.money(10)
        return Button {
            pick(gift)
        } label: {
            HeirloomTile(heirloom: gift, chosen: picked == gift)
        }
        .buttonStyle(PressableStyle())
        .disabled(picked != nil)
    }

    private func pick(_ heirloom: Heirloom) {
        guard picked == nil else { return }
        picked = heirloom
        Haptic.success()
        withAnimation(.easeInOut(duration: 0.4)) {
            store.pickHeirloom(heirloom)
        }
    }

    // MARK: - Hall of Fame

    @ViewBuilder
    private var hallSection: some View {
        if !store.hallOfFame.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    CardHeading(text: "Hall of Fame")
                    Spacer()
                    Button("See all") {
                        sheet = .hall
                    }
                    .font(.subheadline.weight(.semibold))
                }
                ForEach(Array(store.hallOfFame.prefix(5).enumerated()), id: \.element.id) { index, record in
                    HallRow(index: index, record: record, showEpitaph: false)
                    if index < min(store.hallOfFame.count, 5) - 1 {
                        Divider()
                    }
                }
            }
            .padding(16)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }
}

// MARK: - Pieces

/// Which sheet the summary screen is showing.
private enum SummarySheet: String, Identifiable {
    case hall, family

    var id: String { rawValue }
}

/// A capsule label for the secondary buttons in the epitaph card.
private struct PillLabel: View {
    let title: String
    let symbol: String
    let color: Color

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.subheadline.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
            .overlay {
                Capsule().strokeBorder(color.opacity(0.35), lineWidth: 1)
            }
    }
}

/// Celebrates achievements earned for the first time by this life.
private struct NewAchievementsBanner: View {
    let achievements: [Achievement]

    private var heading: String {
        achievements.count == 1 ? "New achievement!" : "New achievements!"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("🎉")
                    .font(.title2)
                Text(heading)
                    .font(.headline)
                Spacer(minLength: 0)
            }
            ForEach(achievements, id: \.self) { item in
                AchievementLine(achievement: item)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LinearGradient(colors: [Color.yellow.opacity(0.30), Color.orange.opacity(0.18)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.5), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct AchievementLine: View {
    let achievement: Achievement

    private var unlockText: String? {
        guard let ambition = achievement.unlocks else { return nil }
        return "Unlocks " + ambition.def.emoji + " " + ambition.def.name
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(achievement.emoji)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.subheadline.weight(.bold))
                if let text = unlockText {
                    Text(text)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.purple)
                }
            }
            Spacer(minLength: 0)
        }
    }
}

/// Replaces the heirloom choice for a Daily Challenge life.
private struct DailyResultPanel: View {
    let dayKey: String
    let score: Int
    let best: Int
    let onDone: () -> Void

    private var isBest: Bool { score >= best }

    private var verdict: String {
        isBest ? "🎉 Today's best so far!" : "Beat " + String(best) + " to top today."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("📅")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Challenge")
                        .font(.title3.weight(.bold))
                    Text(dayKey)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            HStack(spacing: 10) {
                scoreTile(title: "Today", value: score, color: Color.indigo)
                scoreTile(title: "Best", value: best, color: Color.orange)
            }
            Text(verdict)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Daily lives stand apart from your family. Come back tomorrow for a new one.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Back to start", tint: Color.indigo) {
                onDone()
            }
            .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func scoreTile(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .tracking(1)
                .foregroundStyle(.secondary)
            Text(String(value))
                .font(.title.weight(.heavy))
                .monospacedDigit()
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// A fixed-size card rendered to an image for sharing. Uses only solid colours and gradients,
/// since materials do not render through `ImageRenderer`.
struct TombstoneShareCard: View {
    let life: Life
    let rank: String
    let epitaph: String
    let score: Int

    private var achieved: Bool { life.ambition.achieved(life) }

    private var ambitionText: String {
        let def = life.ambition.def
        let mark = achieved ? "✅ " : "❌ "
        return mark + def.emoji + " " + def.name
    }

    private var nameLine: String {
        life.fullName + " · " + String(life.age)
    }

    private var stoneShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 80, bottomLeadingRadius: 18,
                               bottomTrailingRadius: 18, topTrailingRadius: 80,
                               style: .continuous)
    }

    private var background: LinearGradient {
        LinearGradient(colors: [Color(red: 0.20, green: 0.16, blue: 0.45),
                                Color(red: 0.36, green: 0.20, blue: 0.52),
                                Color(red: 0.10, green: 0.07, blue: 0.22)],
                       startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 14) {
                stone
                footer
            }
            .padding(22)
        }
        .frame(width: 360, height: 480)
        .fontDesign(.rounded)
        .environment(\.colorScheme, .dark)
    }

    private var stone: some View {
        VStack(spacing: 10) {
            Text("🪦")
                .font(.system(size: 56))
            Text(rank)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            Text(epitaph)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .italic()
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .lineLimit(7)
                .minimumScaleFactor(0.6)
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, 30)
            Text(nameLine)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(ambitionText)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.9))
        }
        .padding(.horizontal, 20)
        .padding(.top, 28)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.white.opacity(0.10), in: stoneShape)
        .overlay { stoneShape.stroke(Color.white.opacity(0.25), lineWidth: 1) }
    }

    private var footer: some View {
        HStack(alignment: .lastTextBaseline) {
            Text("DEALT")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.75))
            Spacer(minLength: 8)
            Text("Score " + String(score))
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.white)
        }
        .padding(.horizontal, 6)
    }
}


private struct CardHeading: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The compact tombstone at the top of the summary: rank, name and age, ambition result.
/// The full epitaph lives in its own card further down.
private struct TombstoneHeader: View {
    let life: Life
    let rank: String

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 64, bottomLeadingRadius: 20,
                               bottomTrailingRadius: 20, topTrailingRadius: 64,
                               style: .continuous)
    }

    private var nameLine: String {
        life.fullName + " · " + String(life.age)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("🪦")
                .font(.system(size: 48))
                .accessibilityHidden(true)
            Text(rank)
                .font(.title.weight(.heavy))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text(nameLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            AmbitionBadge(life: life)
                .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: shape)
        .overlay { shape.stroke(Color.primary.opacity(0.10), lineWidth: 1) }
        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
}

private struct AmbitionBadge: View {
    let life: Life

    private var achieved: Bool { life.ambition.achieved(life) }

    private var tint: Color {
        if achieved { return Color.green }
        return Color.red
    }

    private var title: String {
        let def = life.ambition.def
        let mark: String = achieved ? "✅ " : "❌ "
        let verdict: String = achieved ? "achieved" : "unfulfilled"
        return mark + def.emoji + " " + def.name + " · " + verdict
    }

    private var spoken: String {
        let verdict: String = achieved ? "achieved" : "unfulfilled"
        return "Ambition " + life.ambition.def.name + ", " + verdict
    }

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(tint)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityLabel(spoken)
    }
}

private struct ScoreLine: View {
    let label: String
    let value: Int

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(Theme.signed(value))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }
}

private struct HeirloomTile: View {
    let heirloom: Heirloom
    let chosen: Bool

    private var borderColor: Color {
        if chosen { return Color.yellow }
        return Color.primary.opacity(0.08)
    }

    private var borderWidth: CGFloat {
        if chosen { return 2 }
        return 1
    }

    private var symbol: String {
        if chosen { return "checkmark.circle.fill" }
        return "chevron.right"
    }

    private var symbolColor: Color {
        if chosen { return Color.yellow }
        return Color.secondary
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(heirloom.emoji)
                .font(.system(size: 34))
                .frame(width: 56, height: 56)
                .background(Color.yellow.opacity(0.18), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(heirloom.title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(heirloom.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(symbolColor)
        }
        .foregroundStyle(Color.primary)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderWidth)
        }
    }
}

/// "A life in chapters", collapsed by default so the decision above stays in view.
private struct TimelineCard: View {
    let history: [HistoryEntry]
    @Binding var isExpanded: Bool

    private var countText: String {
        if history.count == 1 { return "1 chapter" }
        return String(history.count) + " chapters"
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            entries
                .padding(.top, 12)
        } label: {
            headerLabel
        }
        .tint(Stage.dusk.palette.accent)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// The DisclosureGroup itself toggles on tap; no inner Button, so a tap can't toggle twice.
    private var headerLabel: some View {
        HStack(spacing: 8) {
            Text("A life in chapters")
                .font(.headline)
                .foregroundStyle(Color.primary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            Text(countText)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var entries: some View {
        if history.isEmpty {
            Text("The years drifted by, quietly.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(history) { entry in
                    TimelineLine(entry: entry)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct TimelineLine: View {
    let entry: HistoryEntry

    private var headline: String {
        entry.title + " — " + entry.choice
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(String(entry.age))
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
            Text(entry.emoji)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text(headline)
                    .font(.subheadline.weight(.semibold))
                if !entry.text.isEmpty {
                    Text(entry.text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
