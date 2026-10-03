import SwiftUI

struct PlayView: View {
    @Environment(GameStore.self) private var store
    @Namespace private var cardNS
    @State private var infoTrait: Trait?
    /// The card (and choice) just played. `choose()` collapses the store's expanded card at once,
    /// so we keep showing it locally behind the outcome sheet until "Live on".
    @State private var playedCard: Card?
    @State private var playedIndex: Int?

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

    // MARK: - Haptic triggers

    private var wonTrigger: Bool { store.toast?.gambleWon == true }
    private var diedTrigger: Bool { store.toast?.died == true }

    /// The card shown full-width: the expanded one, or the one just played while its outcome is up.
    private var shownCard: Card? {
        if let card = store.expandedCard { return card }
        if store.toast != nil { return playedCard }
        return nil
    }

    // MARK: - Toast binding

    /// Only `continueLife()` should clear the toast. The sheet cannot be swiped away, but if it is
    /// ever dismissed by the system we still route through `continueLife()` so the game never stalls.
    private var toastBinding: Binding<OutcomeToast?> {
        Binding(
            get: { store.toast },
            set: { newValue in
                if newValue == nil && store.toast != nil {
                    finishTurn()
                }
            }
        )
    }

    // MARK: - Screen

    private func screen(_ life: Life) -> some View {
        let accent = life.stage.palette.accent
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    Color.clear
                        .frame(height: 0)
                        .id("top")
                    PlayHeader(life: life, accent: accent)
                    AmbitionRow(life: life, accent: accent)
                    StatsRow(life: life)
                    traitRow(life, accent: accent)
                    FamilyRow(life: life)
                    handSection(life, accent: accent)
                    Color.clear
                        .frame(height: 1)
                        .id("handBottom")
                    if shownCard == nil {
                        RecentRow(history: life.history)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .onChange(of: store.expandedCardID) { _, newValue in
                guard newValue != nil else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo("handBottom", anchor: .bottom)
                    }
                }
            }
            .onChange(of: life.turn) { _, _ in
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
        .background { backgroundLayer(life.stage) }
        .sheet(item: toastBinding) { toast in
            OutcomeSheet(toast: toast, accent: accent) {
                finishTurn()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: store.expandedCardID) { _, _ in
            store.toast == nil
        }
        .sensoryFeedback(.success, trigger: wonTrigger) { _, newValue in newValue }
        .sensoryFeedback(.warning, trigger: diedTrigger) { _, newValue in newValue }
        .sensoryFeedback(.impact(weight: .medium), trigger: life.turn)
    }

    private func backgroundLayer(_ stage: Stage) -> some View {
        ZStack {
            StageBackground(stage: stage)
                .id(stage)
                .transition(.opacity)
        }
        .animation(.easeInOut(duration: 0.8), value: stage)
    }

    // MARK: - Traits

    @ViewBuilder
    private func traitRow(_ life: Life, accent: Color) -> some View {
        if !life.traits.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(life.traits, id: \.self) { trait in
                            traitChip(trait, accent: accent)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal, -16)

                if let trait = infoTrait, life.traits.contains(trait) {
                    Text(verbatim: "\(trait.def.emoji) \(trait.def.name) — \(trait.def.blurb)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
        }
    }

    private func traitChip(_ trait: Trait, accent: Color) -> some View {
        let selected = infoTrait == trait
        let color: Color = selected ? accent : Color.secondary
        return Button {
            withAnimation(.snappy) {
                infoTrait = selected ? nil : trait
            }
        } label: {
            Chip(text: trait.def.emoji + " " + trait.def.name, color: color)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hand

    private func handSection(_ life: Life, accent: Color) -> some View {
        VStack(spacing: 12) {
            handContent(life, accent: accent)
        }
        .id(life.turn)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    @ViewBuilder
    private func handContent(_ life: Life, accent: Color) -> some View {
        if let card = shownCard {
            expandedCard(card, accent: accent)
        } else if let played = resolvedEntry(life) {
            resolvedPanel(played, accent: accent)
        } else {
            handCaption(life)
            fan(accent: accent)
            driftButton
        }
    }

    /// A card was already played at this age but its outcome sheet is gone (e.g. the app was
    /// relaunched before "Live on"). The store's `drift()` then just advances time, no penalty.
    private func resolvedEntry(_ life: Life) -> HistoryEntry? {
        guard store.toast == nil, life.alive, let last = life.history.last else { return nil }
        return last.age == life.age ? last : nil
    }

    private func resolvedPanel(_ entry: HistoryEntry, accent: Color) -> some View {
        VStack(spacing: 10) {
            Text(entry.emoji)
                .font(.system(size: 44))
            Text(entry.title)
                .font(.headline)
            Text(entry.text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "Live on", tint: accent) {
                Haptic.tap()
                withAnimation(.dealtSpring) { store.drift() }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func handCaption(_ life: Life) -> some View {
        let years = life.stage.yearsPerTurn
        let caption = "The next \(years) years · play one"
        return HStack {
            Text("Your hand")
                .font(.headline)
            Spacer()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    private func fan(accent: Color) -> some View {
        let cards = store.hand
        let count = cards.count
        return HStack(alignment: .top, spacing: 8) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                Button {
                    openCard(card)
                } label: {
                    CardFace(card: card, expanded: false, tint: accent)
                }
                .buttonStyle(PressableStyle())
                .matchedGeometryEffect(id: card.id, in: cardNS)
                .rotationEffect(.degrees(fanAngle(index, count)), anchor: .bottom)
                .offset(y: fanDrop(index, count))
                .zIndex(fanZ(index, count))
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
        .padding(.bottom, 14)
    }

    private func fanAngle(_ index: Int, _ count: Int) -> Double {
        let mid = Double(count - 1) / 2
        return (Double(index) - mid) * 6
    }

    private func fanDrop(_ index: Int, _ count: Int) -> CGFloat {
        let mid = Double(count - 1) / 2
        return CGFloat(abs(Double(index) - mid) * 12)
    }

    private func fanZ(_ index: Int, _ count: Int) -> Double {
        let mid = Double(count - 1) / 2
        return 10 - abs(Double(index) - mid)
    }

    private var driftButton: some View {
        Button {
            Haptic.tap()
            withAnimation(.dealtSpring) { store.drift() }
        } label: {
            VStack(spacing: 2) {
                Label("Let the years drift", systemImage: "hourglass")
                    .font(.subheadline.weight(.semibold))
                Text("Play nothing · Heart −3")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(store.toast != nil)
    }

    // MARK: - Expanded card

    private func expandedCard(_ card: Card, accent: Color) -> some View {
        VStack(spacing: 12) {
            CardFace(card: card, expanded: true, tint: accent)
                .matchedGeometryEffect(id: card.id, in: cardNS)
                .overlay(alignment: .topLeading) {
                    backButton
                }
            VStack(spacing: 10) {
                ForEach(Array(card.choices.enumerated()), id: \.offset) { index, choice in
                    choiceButton(index: index, choice: choice, accent: accent,
                                 highlighted: store.toast != nil && playedIndex == index)
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    private var backButton: some View {
        Button {
            close()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())
        }
        .padding(10)
        .disabled(store.toast != nil)
        .accessibilityLabel("Back to hand")
    }

    private func choiceButton(index: Int, choice: Choice, accent: Color, highlighted: Bool) -> some View {
        Button {
            pick(index)
        } label: {
            ChoiceLabel(label: choice.label, odds: store.effectiveOdds(choice), accent: accent,
                        highlighted: highlighted)
        }
        .buttonStyle(PressableStyle())
        .disabled(store.toast != nil)
    }

    // MARK: - Actions

    private func openCard(_ card: Card) {
        guard store.toast == nil else { return }
        withAnimation(.dealtSpring) {
            infoTrait = nil
            store.expand(card)
        }
    }

    private func close() {
        withAnimation(.dealtSpring) {
            store.expand(nil)
        }
    }

    private func pick(_ index: Int) {
        guard store.toast == nil, let card = store.expandedCard else { return }
        playedCard = card
        playedIndex = index
        store.choose(index)
    }

    /// The single path that moves time forward after an outcome. Guarded against double taps.
    private func finishTurn() {
        guard store.toast != nil else { return }
        withAnimation(.dealtSpring) {
            store.continueLife()
            playedCard = nil
            playedIndex = nil
        }
    }
}

// MARK: - Header

private struct PlayHeader: View {
    let life: Life
    let accent: Color

    private var stageText: String { life.stage.emoji + " " + life.stage.title }
    private var genText: String { "Gen " + String(life.generation) }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(life.fullName)
                    .font(.title2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                HStack(spacing: 6) {
                    Chip(text: stageText, color: accent)
                    if life.isDaily {
                        Chip(text: "📅 Daily", color: Color.orange)
                    } else {
                        Chip(text: genText, color: Color.secondary)
                    }
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: -4) {
                Text(String(life.age))
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(life.age)))
                    .animation(.dealtSpring, value: life.age)
                Text("years old")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Family

/// Spouse and kids, once the life has them.
private struct FamilyRow: View {
    let life: Life

    private var hasFamily: Bool {
        life.spouseName != nil || !life.kidNames.isEmpty
    }

    private var kidsText: String {
        "👶 " + life.kidNames.joined(separator: ", ")
    }

    var body: some View {
        if hasFamily {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    if let spouse = life.spouseName {
                        Chip(text: "💍 " + spouse, color: Color.pink)
                    }
                    if !life.kidNames.isEmpty {
                        Chip(text: kidsText, color: Color.teal)
                    }
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
        }
    }

    private var accessibilityText: String {
        var parts: [String] = []
        if let spouse = life.spouseName { parts.append("Married to " + spouse) }
        if !life.kidNames.isEmpty { parts.append("Kids: " + life.kidNames.joined(separator: ", ")) }
        return parts.joined(separator: ". ")
    }
}

// MARK: - Ambition

private struct AmbitionRow: View {
    let life: Life
    let accent: Color

    private var progress: Double { life.ambition.progress(life) }
    private var achieved: Bool { life.ambition.achieved(life) }

    private var percentText: String {
        achieved ? "✅ Achieved" : String(Int(progress * 100)) + "%"
    }

    var body: some View {
        let def = life.ambition.def
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(def.emoji)
                Text(def.name)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text(percentText)
                    .font(.caption.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            ProgressView(value: progress)
                .tint(achieved ? Color.green : accent)
                .animation(.easeOut(duration: 0.6), value: progress)
            Text(def.goalText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Stats

private struct StatsRow: View {
    let life: Life

    private var moneyColor: Color { life.money < 0 ? Color.red : Color.primary }

    private var incomeText: String {
        life.income > 0 ? "+" + Theme.money(life.income) + "/yr" : "No income"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Stat.allCases, id: \.self) { stat in
                StatRing(stat: stat, value: life.stats[stat])
                    .frame(maxWidth: .infinity)
            }
            moneyPill
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var moneyPill: some View {
        VStack(spacing: 4) {
            Image(systemName: "banknote.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.green)
                .frame(height: 22)
            Text(Theme.money(life.money))
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(moneyColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText(value: Double(life.money)))
                .animation(.easeOut(duration: 0.6), value: life.money)
            Text(incomeText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .frame(minWidth: 72)
        .background(Color.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Choices

private struct ChoiceLabel: View {
    let label: String
    let odds: Int?
    let accent: Color
    let highlighted: Bool

    private var fillOpacity: Double { highlighted ? 0.18 : 0 }
    private var strokeOpacity: Double { highlighted ? 1 : 0.35 }
    private var strokeWidth: CGFloat { highlighted ? 2 : 1 }
    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: 16, style: .continuous) }

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            ZStack {
                shape.fill(.regularMaterial)
                shape.fill(accent.opacity(fillOpacity))
            }
        }
        .overlay {
            shape.strokeBorder(accent.opacity(strokeOpacity), lineWidth: strokeWidth)
        }
        .contentShape(shape)
    }

    @ViewBuilder
    private var trailing: some View {
        if let pct = odds {
            let color = Theme.oddsColor(pct)
            Text("🎲 " + String(pct) + "%")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(color.opacity(0.15), in: Capsule())
        } else {
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Recent history

private struct RecentRow: View {
    let history: [HistoryEntry]

    private var recent: [HistoryEntry] {
        Array(history.suffix(3).reversed())
    }

    var body: some View {
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("RECENTLY")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                ForEach(recent) { entry in
                    RecentLine(entry: entry)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

private struct RecentLine: View {
    let entry: HistoryEntry

    private var line: String {
        entry.title + " — " + entry.choice
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(entry.age))
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)
            Text(entry.emoji)
                .font(.subheadline)
            Text(line)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }
}

// MARK: - Outcome sheet

private struct OutcomeSheet: View {
    let toast: OutcomeToast
    let accent: Color
    let onContinue: () -> Void

    @State private var appeared = false

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var buttonTitle: String { toast.died ? "Rest" : "Live on" }
    private var buttonTint: Color { toast.died ? Color(uiColor: .systemGray) : accent }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text(toast.emoji)
                    .font(.system(size: 64))
                    .scaleEffect(appeared ? 1 : 0.4)
                    .opacity(appeared ? 1 : 0)
                Text(toast.title)
                    .font(.title2.weight(.bold))
                    .multilineTextAlignment(.center)
                gambleCaption
                Text(toast.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                if !toast.deltas.isEmpty {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(toast.deltas.enumerated()), id: \.offset) { _, delta in
                            DeltaChip(text: delta)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: buttonTitle, tint: buttonTint) {
                onContinue()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .fontDesign(.rounded)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
        .interactiveDismissDisabled()
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.45)) { appeared = true }
        }
    }

    @ViewBuilder
    private var gambleCaption: some View {
        if let won = toast.gambleWon {
            let color: Color = won ? Color.green : Color.red
            Text(won ? "🎲 Won the roll" : "🎲 Lost the roll")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(color.opacity(0.14), in: Capsule())
        }
    }
}
