import SwiftUI

struct SummaryView: View {
    @Environment(GameStore.self) private var store

    @State private var appeared = false
    @State private var shownScore = 0
    @State private var showHall = false
    @State private var picked: Heirloom?

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
    }

    private func screen(_ life: Life) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                Tombstone(life: life, rank: store.rank, epitaph: store.epitaph)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)
                AmbitionBadge(life: life)
                scoreCard
                heirloomSection
                TimelineCard(history: life.history)
                hallSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
        .background { StageBackground(stage: .dusk) }
        .sheet(isPresented: $showHall) {
            HallOfFameSheet(allowsReset: false)
                .environment(store)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.35)) { appeared = true }
            withAnimation(.easeOut(duration: 0.9).delay(0.35)) { shownScore = store.score }
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
            Text("Pass something on")
                .font(.title3.weight(.bold))
            Text("Your heir carries one thing into the next life. Choose carefully.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                        showHall = true
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

private struct Tombstone: View {
    let life: Life
    let rank: String
    let epitaph: String

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 90, bottomLeadingRadius: 20,
                               bottomTrailingRadius: 20, topTrailingRadius: 90,
                               style: .continuous)
    }

    private var footer: String {
        life.fullName + " · " + String(life.age)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("🪦")
                .font(.system(size: 64))
            Text(rank)
                .font(.title.weight(.heavy))
                .multilineTextAlignment(.center)
            Text(epitaph)
                .font(.body)
                .italic()
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
                .padding(.horizontal, 24)
            Text(footer)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 36)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: shape)
        .overlay { shape.stroke(Color.primary.opacity(0.10), lineWidth: 1) }
        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
}

private struct AmbitionBadge: View {
    let life: Life

    private var achieved: Bool { life.ambition.achieved(life) }
    private var tint: Color { achieved ? Color.green : Color.red }

    private var title: String {
        let def = life.ambition.def
        return (achieved ? "✅ " : "❌ ") + def.emoji + " " + def.name
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(tint)
            Text(achieved ? "Ambition achieved" : "Ambition unfulfilled")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: Capsule())
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
        chosen ? Color.yellow : Color.primary.opacity(0.08)
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
                Text(heirloom.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            Image(systemName: chosen ? "checkmark.circle.fill" : "chevron.right")
                .font(.body.weight(.semibold))
                .foregroundStyle(chosen ? Color.yellow : Color.secondary)
        }
        .foregroundStyle(Color.primary)
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(borderColor, lineWidth: chosen ? 2 : 1)
        }
    }
}

private struct TimelineCard: View {
    let history: [HistoryEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardHeading(text: "A life in chapters")
            if history.isEmpty {
                Text("The years drifted by, quietly.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(history) { entry in
                    TimelineLine(entry: entry)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
