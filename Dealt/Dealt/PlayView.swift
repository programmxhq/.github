import SwiftUI

struct PlayView: View {
    @Environment(GameStore.self) private var store
    @AppStorage("dealt.tutorialSeen") private var tutorialSeen = false
    @State private var showTutorial = false
    @State private var infoTrait: Trait?
    /// The card (and choice) just played. `choose()` collapses the store's expanded card at once,
    /// so we keep showing it locally behind the outcome sheet until "Live on".
    @State private var playedCard: Card?
    @State private var playedIndex: Int?
    /// The turn whose hand has already played its deal-in animation, so closing a card
    /// does not re-deal the rows.
    @State private var dealtTurn: Int?

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
        .onAppear {
            maybeShowTutorial()
        }
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
                    PlayHeader(life: life, accent: accent) {
                        openTutorial()
                    }
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
        .overlay { tutorialLayer(accent: accent) }
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

    // MARK: - Tutorial

    @ViewBuilder
    private func tutorialLayer(accent: Color) -> some View {
        if showTutorial {
            TutorialOverlay(accent: accent) {
                finishTutorial()
            }
            .transition(.opacity)
        }
    }

    /// First run only: show the coach marks on a brand-new life.
    private func maybeShowTutorial() {
        guard !tutorialSeen, let life = store.life, life.turn == 0 else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            showTutorial = true
        }
    }

    private func openTutorial() {
        guard store.toast == nil else { return }
        Haptic.tap()
        withAnimation(.easeInOut(duration: 0.25)) {
            showTutorial = true
        }
    }

    private func finishTutorial() {
        tutorialSeen = true
        withAnimation(.easeInOut(duration: 0.25)) {
            showTutorial = false
        }
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
        .transition(.opacity)
    }

    private var expandTransition: AnyTransition {
        AnyTransition.scale(scale: 0.96, anchor: .top).combined(with: .opacity)
    }

    @ViewBuilder
    private func handContent(_ life: Life, accent: Color) -> some View {
        if let card = shownCard {
            expandedCard(card, accent: accent)
                .transition(expandTransition)
        } else if let played = resolvedEntry(life) {
            resolvedPanel(played, accent: accent)
                .transition(.opacity)
        } else {
            handList(life, accent: accent)
                .transition(.opacity)
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
                .multilineTextAlignment(.center)
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

    private func handList(_ life: Life, accent: Color) -> some View {
        VStack(spacing: 12) {
            handCaption(life)
            cardRows(life, accent: accent)
            driftButton
        }
        .onAppear {
            dealtTurn = life.turn
        }
    }

    private func handCaption(_ life: Life) -> some View {
        let years = life.stage.yearsPerTurn
        let caption = "The next \(years) years · play one"
        return HStack(alignment: .firstTextBaseline) {
            Text("Your hand")
                .font(.headline)
            Spacer(minLength: 8)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.top, 4)
    }

    private func cardRows(_ life: Life, accent: Color) -> some View {
        let cards = store.hand
        let animateIn = dealtTurn != life.turn
        return VStack(spacing: 10) {
            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                DealtCardRow(card: card, index: index, accent: accent, animateIn: animateIn) {
                    openCard(card)
                }
            }
        }
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
                .overlay(alignment: .topLeading) {
                    backButton
                }
            VStack(spacing: 10) {
                ForEach(Array(card.choices.enumerated()), id: \.offset) { index, choice in
                    choiceButton(index: index, choice: choice, accent: accent,
                                 highlighted: store.toast != nil && playedIndex == index)
                }
            }
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

// MARK: - Hand row

/// A hand row that deals in (slides up and fades) with a small per-index delay.
private struct DealtCardRow: View {
    let card: Card
    let index: Int
    let accent: Color
    let onTap: () -> Void

    @State private var shown: Bool

    init(card: Card, index: Int, accent: Color, animateIn: Bool, onTap: @escaping () -> Void) {
        self.card = card
        self.index = index
        self.accent = accent
        self.onTap = onTap
        self._shown = State(initialValue: !animateIn)
    }

    private var rowOffset: CGFloat { shown ? 0 : 36 }
    private var rowOpacity: Double { shown ? 1 : 0 }

    var body: some View {
        Button {
            onTap()
        } label: {
            CardRow(card: card, tint: accent)
        }
        .buttonStyle(PressableStyle())
        .offset(y: rowOffset)
        .opacity(rowOpacity)
        .onAppear {
            dealIn()
        }
    }

    private func dealIn() {
        guard !shown else { return }
        let delay: Double = Double(index) * 0.06
        withAnimation(Animation.dealtSpring.delay(delay)) {
            shown = true
        }
    }
}

// MARK: - Header

private struct PlayHeader: View {
    let life: Life
    let accent: Color
    let onHelp: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var ageSize: CGFloat = 46

    init(life: Life, accent: Color, onHelp: @escaping () -> Void) {
        self.life = life
        self.accent = accent
        self.onHelp = onHelp
    }

    private var stageText: String { life.stage.emoji + " " + life.stage.title }
    private var genText: String { "Gen " + String(life.generation) }
    /// Grows with Dynamic Type, but not without bound.
    private var ageFontSize: CGFloat { min(ageSize, 66) }

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
                    helpButton
                }
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: -4) {
                Text(String(life.age))
                    .font(.system(size: ageFontSize, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText(value: Double(life.age)))
                    .animation(.dealtSpring, value: life.age)
                Text("years old")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            .accessibilityElement(children: .combine)
        }
    }

    private var helpButton: some View {
        Button {
            onHelp()
        } label: {
            Image(systemName: "questionmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(7)
                .background(.thinMaterial, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("How to play")
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
                .fixedSize(horizontal: false, vertical: true)
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

    @ScaledMetric(relativeTo: .caption) private var ageColumn: CGFloat = 28

    init(entry: HistoryEntry) {
        self.entry = entry
    }

    private var line: String {
        entry.title + " — " + entry.choice
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(String(entry.age))
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(minWidth: ageColumn, alignment: .trailing)
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

    init(toast: OutcomeToast, accent: Color, onContinue: @escaping () -> Void) {
        self.toast = toast
        self.accent = accent
        self.onContinue = onContinue
    }

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
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
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

// MARK: - Tutorial

private struct TutorialStep {
    let emoji: String
    let title: String
    let text: String
}

/// First-run coach marks: a dimmed screen with a three-step card at the bottom.
/// Also reopened from the "?" button in the header.
private struct TutorialOverlay: View {
    let accent: Color
    let onFinish: () -> Void

    @State private var step: Int = 0

    init(accent: Color, onFinish: @escaping () -> Void) {
        self.accent = accent
        self.onFinish = onFinish
    }

    private static let steps: [TutorialStep] = [
        TutorialStep(emoji: "📖", title: "Your life, in chapters",
                     text: "Every few years, life deals you three cards. Each hand is one chapter of your story."),
        TutorialStep(emoji: "🃏", title: "Play one, skip two",
                     text: "Tap a card to see its choices. 🎲 choices are gambles, and their odds are shown. Cards you skip may come back later."),
        TutorialStep(emoji: "🎯", title: "Your stats & ambition",
                     text: "Body, Mind, Heart and Bonds drift with age. Chase your ambition bar. When the life ends, pass an heirloom on.")
    ]

    private var lastIndex: Int { TutorialOverlay.steps.count - 1 }
    private var isLast: Bool { step >= lastIndex }
    private var current: TutorialStep { TutorialOverlay.steps[min(max(step, 0), lastIndex)] }
    private var nextTitle: String { isLast ? "Got it" : "Next" }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { }
                .accessibilityHidden(true)
            ViewThatFits(in: .vertical) {
                coachCard
                ScrollView {
                    coachCard
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            .padding(.bottom, 12)
        }
        .accessibilityAddTraits(.isModal)
    }

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                stepDots
                Spacer()
                skipButton
            }
            stepContent
                .id(step)
                .transition(.opacity)
            PrimaryButton(title: nextTitle, tint: accent) {
                advance()
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 8)
    }

    private var stepContent: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(current.emoji)
                .font(.system(size: 36))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(current.title)
                    .font(.title3.weight(.bold))
                    .fixedSize(horizontal: false, vertical: true)
                Text(current.text)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    private var stepDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<TutorialOverlay.steps.count, id: \.self) { index in
                TutorialDot(active: index == step, accent: accent)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step " + String(step + 1) + " of " + String(TutorialOverlay.steps.count))
    }

    private var skipButton: some View {
        Button {
            onFinish()
        } label: {
            Text("Skip")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func advance() {
        if isLast {
            onFinish()
            return
        }
        Haptic.tap()
        withAnimation(.easeInOut(duration: 0.2)) {
            step += 1
        }
    }
}

private struct TutorialDot: View {
    let active: Bool
    let accent: Color

    private var fill: Color { active ? accent : Color.secondary.opacity(0.3) }
    private var width: CGFloat { active ? 18 : 7 }

    var body: some View {
        Capsule()
            .fill(fill)
            .frame(width: width, height: 7)
    }
}
