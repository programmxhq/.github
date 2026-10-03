import SwiftUI

struct StartView: View {
    @Environment(GameStore.self) private var store

    /// 1 = "Who are you?", 2 = "What do you want from life?"
    @State private var step: Int = 1
    @State private var name: String = ""
    @State private var ambition: Ambition = Ambition.allCases.first ?? .fortune
    @State private var showSeed: Bool = false
    @State private var seedText: String = ""
    @State private var sheet: StartSheet?
    @State private var confirmDaily: Bool = false
    @FocusState private var nameFocused: Bool

    private let stepCount: Int = 2

    private var accent: Color { Stage.dawn.palette.accent }

    private var lineageText: String {
        "Generation \(store.generation) · The \(store.surname) line"
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
            stepContainer
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .background { StageBackground(stage: .dawn) }
        .fontDesign(.rounded)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .sheet(item: $sheet) { which in
            sheetContent(which)
        }
        .confirmationDialog("Play today's life?", isPresented: $confirmDaily, titleVisibility: .visible) {
            Button("Play today's life") {
                startDaily()
            }
            Button("Not now", role: .cancel) {}
        } message: {
            Text(dailyMessage)
        }
        .onAppear {
            if name.isEmpty { name = store.suggestedName }
            ensureUnlockedAmbition()
        }
        .onChange(of: store.achievements) { _, _ in
            ensureUnlockedAmbition()
        }
        .onChange(of: store.suggestedName) { _, newValue in
            name = newValue
        }
        .onChange(of: name) { _, newValue in
            if newValue.count > 20 { name = String(newValue.prefix(20)) }
        }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(_ which: StartSheet) -> some View {
        switch which {
        case .hall:
            HallOfFameSheet(allowsReset: true)
                .environment(store)
        case .achievements:
            AchievementsView()
                .environment(store)
        case .family:
            FamilyTreeView()
                .environment(store)
        }
    }

    /// The parent named on the inheritance card, when the heir is one of their kids.
    private var heirParentName: String? {
        guard store.pendingHeirloom != nil, let last = store.lineage.last else { return nil }
        let kids: [String] = last.kidNames ?? []
        return kids.isEmpty ? nil : last.name
    }

    /// The picker must never sit on a locked ambition.
    private func ensureUnlockedAmbition() {
        if !store.isUnlocked(ambition) {
            ambition = Ambition.base.first ?? .fortune
        }
    }

    // MARK: Top bar (both steps)

    private var topBar: some View {
        HStack(spacing: 10) {
            DailyButton(best: store.todayBest) {
                nameFocused = false
                confirmDaily = true
            }
            .layoutPriority(1)
            Spacer(minLength: 0)
            achievementsButton
            if !store.lineage.isEmpty {
                familyButton
            }
            trophyButton
        }
    }

    private var trophyButton: some View {
        ToolbarCircleButton(symbol: "trophy.fill", color: Color.orange, label: "Hall of Fame") {
            sheet = .hall
        }
    }

    private var achievementsButton: some View {
        ToolbarCircleButton(symbol: "rosette", color: Color.purple, label: "Achievements") {
            sheet = .achievements
        }
    }

    private var familyButton: some View {
        ToolbarCircleButton(symbol: "tree.fill", color: Color.green, label: "Family tree") {
            sheet = .family
        }
    }

    private var dailyMessage: String {
        let intro: String = "Everyone plays the same life today, from the same first hand."
        let apart: String = "It stands apart from your family: your line, generation and inheritance wait here untouched."
        var text: String = intro + " " + apart
        if let best = store.todayBest {
            text += " Your best today: " + String(best) + "."
        }
        return text
    }

    // MARK: Steps

    /// Step 1 leaves and enters on the leading edge, step 2 on the trailing edge,
    /// so the slide direction is right both ways without extra state.
    private var stepOneTransition: AnyTransition {
        AnyTransition.move(edge: .leading).combined(with: .opacity)
    }

    private var stepTwoTransition: AnyTransition {
        AnyTransition.move(edge: .trailing).combined(with: .opacity)
    }

    private var stepContainer: some View {
        ZStack {
            if step == 1 {
                stepOne
                    .transition(stepOneTransition)
            } else {
                stepTwo
                    .transition(stepTwoTransition)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func goToStep(_ target: Int) {
        guard target != step else { return }
        nameFocused = false
        Haptic.tap()
        withAnimation(.dealtSpring) {
            step = target
        }
    }

    // MARK: Step 1 — Who are you?

    private var stepOne: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleRow
                StepHeading(title: "Who are you?",
                            subtitle: "Pick a name. Your birth trait is luck of the draw.")
                nameSection
                traitSection
                if let heirloom = store.pendingHeirloom {
                    InheritanceCard(heirloom: heirloom, parentName: heirParentName)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var titleRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("DEALT")
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .tracking(6)
                Text("Life deals you three cards. Play one.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(lineageText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(accent)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            Spacer(minLength: 8)
            DecorFan()
                .padding(.top, 8)
        }
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Name")
            HStack(spacing: 10) {
                TextField("First name", text: $name)
                    .font(.title3.weight(.semibold))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($nameFocused)
                Text(store.surname)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .layoutPriority(1)
                Button {
                    Haptic.tap()
                    store.shuffleName()
                    name = store.suggestedName
                } label: {
                    Text("🎲")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(accent.opacity(0.15), in: Circle())
                }
                .accessibilityLabel("Random name")
            }
            .padding(.leading, 16)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var traitSection: some View {
        let def: TraitDef = store.birthTraitPreview.def
        return VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Born with")
            Button {
                Haptic.tap()
                withAnimation(.snappy) { store.shuffleBirthTrait() }
            } label: {
                HStack(spacing: 14) {
                    Text(def.emoji)
                        .font(.system(size: 34))
                        .frame(width: 52, height: 52)
                        .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(def.name)
                            .font(.headline)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(def.blurb)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(accent)
                }
                .foregroundStyle(Color.primary)
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .contentTransition(.opacity)
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint("Tap to reroll your birth trait")
        }
    }

    // MARK: Step 2 — What do you want from life?

    private var stepTwo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                backButton
                StepHeading(title: "What do you want from life?",
                            subtitle: "Your ambition shapes the cards you're dealt and most of your score.")
                ambitionGrid
                ambitionBlurb
                seedSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var backButton: some View {
        Button {
            goToStep(1)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.subheadline.weight(.bold))
                Text("Who are you?")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(accent)
            .padding(.vertical, 8)
            .padding(.trailing, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Back")
        .accessibilityHint("Return to name and birth trait")
    }

    private var gridColumns: [GridItem] {
        [GridItem(.flexible(), spacing: 12, alignment: .top),
         GridItem(.flexible(), spacing: 12, alignment: .top)]
    }

    private var ambitionGrid: some View {
        LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
            ForEach(Ambition.allCases, id: \.self) { item in
                ambitionButton(item)
            }
        }
    }

    private func ambitionButton(_ item: Ambition) -> some View {
        let unlocked: Bool = store.isUnlocked(item)
        let isSelected: Bool = unlocked && item == ambition
        return Button {
            guard unlocked else { return }
            Haptic.tap()
            withAnimation(.dealtSpring) { ambition = item }
        } label: {
            AmbitionTile(ambition: item, selected: isSelected, locked: !unlocked, accent: accent)
        }
        .buttonStyle(PressableStyle())
        .disabled(!unlocked)
    }

    private var ambitionBlurb: some View {
        let def: AmbitionDef = ambition.def
        return HStack(alignment: .top, spacing: 12) {
            Text(def.emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(def.name)
                    .font(.headline)
                Text(def.blurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .id(ambition)
        .transition(.opacity)
    }

    private var seedSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Spacer()
                Button {
                    withAnimation(.snappy) { showSeed.toggle() }
                } label: {
                    Label("Advanced", systemImage: "gearshape")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.vertical, 8)
                        .padding(.leading, 8)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Advanced options")
            }
            if showSeed {
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                    TextField("Seed (optional)", text: $seedText)
                        .keyboardType(.numberPad)
                        .font(.body.monospacedDigit())
                }
                .padding(12)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // MARK: Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 10) {
            StepIndicator(step: step, total: stepCount, accent: accent)
            primaryAction
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            LinearGradient(colors: [Color(uiColor: .systemBackground).opacity(0),
                                    Color(uiColor: .systemBackground).opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var primaryAction: some View {
        if step == 1 {
            PrimaryButton(title: "Next: choose an ambition", tint: accent) {
                goToStep(2)
            }
            .accessibilityIdentifier("start.next")
        } else {
            PrimaryButton(title: "Be born", tint: accent) {
                beBorn()
            }
            .accessibilityIdentifier("start.beBorn")
        }
    }

    // MARK: Actions

    private func startDaily() {
        nameFocused = false
        Haptic.success()
        withAnimation(.easeInOut(duration: 0.4)) {
            store.startDaily()
        }
    }

    private func beBorn() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? store.suggestedName : trimmed
        let seedString = seedText.trimmingCharacters(in: .whitespacesAndNewlines)
        let seed: UInt64? = showSeed ? UInt64(seedString) : nil
        nameFocused = false
        Haptic.success()
        withAnimation(.easeInOut(duration: 0.4)) {
            store.startLife(name: finalName, ambition: ambition, seed: seed)
        }
    }
}

// MARK: - Small pieces

private struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.2)
            .foregroundStyle(.secondary)
    }
}

/// The big question at the top of each step.
private struct StepHeading: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title2.weight(.bold))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// Dots plus "1 of 2".
private struct StepIndicator: View {
    let step: Int
    let total: Int
    let accent: Color

    private func dotColor(_ index: Int) -> Color {
        if index == step { return accent }
        return Color.primary.opacity(0.18)
    }

    private func dotWidth(_ index: Int) -> CGFloat {
        if index == step { return 18 }
        return 7
    }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...total, id: \.self) { index in
                Capsule()
                    .fill(dotColor(index))
                    .frame(width: dotWidth(index), height: 7)
            }
            Text(String(step) + " of " + String(total))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
        }
        .animation(.dealtSpring, value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step " + String(step) + " of " + String(total))
    }
}

/// Three tiny fanned cards next to the title.
private struct DecorFan: View {
    let faces: [String] = ["🌱", "🎲", "🕯️"]

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Text(faces[i])
                    .font(.system(size: 14))
                    .frame(width: 24, height: 34)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                    }
                    .rotationEffect(.degrees(Double(i - 1) * 14), anchor: .bottom)
                    .offset(x: CGFloat(i - 1) * 8)
            }
        }
        .frame(width: 52, height: 40)
        .accessibilityHidden(true)
    }
}

/// One ambition in the 2-column grid. Grows with Dynamic Type instead of clipping.
private struct AmbitionTile: View {
    let ambition: Ambition
    let selected: Bool
    let locked: Bool
    let accent: Color

    /// Not private: a private stored property would make the memberwise init private.
    @ScaledMetric(relativeTo: .caption) var minTileHeight: CGFloat = 112

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }

    private var borderColor: Color {
        if selected { return accent }
        return Color.primary.opacity(0.08)
    }

    private var borderWidth: CGFloat {
        if selected { return 2.5 }
        return 1
    }

    private var fillTint: Color {
        if selected { return accent.opacity(0.14) }
        return Color.clear
    }

    private var shadowColor: Color {
        if selected { return accent.opacity(0.25) }
        return Color.clear
    }

    private var emojiOpacity: Double { locked ? 0.35 : 1 }
    private var emojiGrayscale: Double { locked ? 1 : 0 }
    private var nameColor: Color { locked ? Color.secondary : Color.primary }

    private var selectedTraits: AccessibilityTraits {
        if selected { return .isSelected }
        return []
    }

    /// "Earn Dynasty: Reach the third generation." for a locked ambition.
    private var lockHint: String {
        guard let needed = ambition.unlockedBy else { return "Locked" }
        let firstSentence: String = needed.detail.components(separatedBy: ". ").first ?? needed.detail
        let trimmed: String = firstSentence.hasSuffix(".") ? firstSentence : firstSentence + "."
        return "Earn " + needed.name + ": " + trimmed
    }

    var body: some View {
        let def: AmbitionDef = ambition.def
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 4) {
                Text(def.emoji)
                    .font(.system(size: 32))
                    .grayscale(emojiGrayscale)
                    .opacity(emojiOpacity)
                Spacer(minLength: 0)
                statusBadge
            }
            Text(def.name)
                .font(.headline)
                .foregroundStyle(nameColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            detailText(def)
        }
        .foregroundStyle(Color.primary)
        .frame(maxWidth: .infinity, minHeight: minTileHeight, alignment: .topLeading)
        .padding(12)
        .background {
            ZStack {
                shape.fill(.regularMaterial)
                shape.fill(fillTint)
            }
        }
        .overlay {
            shape.strokeBorder(borderColor, lineWidth: borderWidth)
        }
        .shadow(color: shadowColor, radius: 8, x: 0, y: 3)
        .contentShape(shape)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selectedTraits)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if locked {
            Text("🔒")
                .font(.subheadline)
                .accessibilityLabel("Locked")
        } else if selected {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(accent)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func detailText(_ def: AmbitionDef) -> some View {
        if locked {
            Text(lockHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(def.goalText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct InheritanceCard: View {
    let heirloom: Heirloom
    var parentName: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Inheritance")
            HStack(spacing: 14) {
                Text(heirloom.emoji)
                    .font(.system(size: 34))
                    .frame(width: 52, height: 52)
                    .background(Color.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    if let parent = parentName {
                        Text("Born to " + parent)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.orange)
                    }
                    Text(heirloom.title)
                        .font(.headline)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(heirloom.blurb)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.yellow.opacity(0.6), lineWidth: 1.5)
            }
        }
    }
}

/// Which sheet the start screen is showing.
private enum StartSheet: String, Identifiable {
    case hall, achievements, family

    var id: String { rawValue }
}

/// A round material button used in the start screen's top row.
private struct ToolbarCircleButton: View {
    let symbol: String
    let color: Color
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptic.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }
        .accessibilityLabel(label)
    }
}

/// The compact Daily Challenge entry in the top bar: "📅 Daily · Best 512".
private struct DailyButton: View {
    let best: Int?
    let action: () -> Void

    private var title: String {
        if let b = best { return "📅 Daily · Best " + String(b) }
        return "📅 Daily"
    }

    private var spokenLabel: String {
        if let b = best { return "Daily challenge, today's best " + String(b) }
        return "Daily challenge"
    }

    var body: some View {
        Button {
            Haptic.tap()
            action()
        } label: {
            Text(title)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(Color.orange)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(.regularMaterial, in: Capsule())
                .overlay {
                    Capsule().strokeBorder(Color.orange.opacity(0.45), lineWidth: 1)
                }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(spokenLabel)
        .accessibilityHint("Same life for every player today. Does not affect your family.")
    }
}

// MARK: - Hall of Fame

struct HallOfFameSheet: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    let allowsReset: Bool

    init(allowsReset: Bool = true) {
        self.allowsReset = allowsReset
    }

    var body: some View {
        NavigationStack {
            List {
                recordsSection
                if allowsReset {
                    Section {
                        Button(role: .destructive) {
                            confirmReset = true
                        } label: {
                            Label("Reset lineage", systemImage: "trash")
                        }
                    } footer: {
                        Text("Forgets every past life and starts a brand-new family.")
                    }
                }
            }
            .navigationTitle("Hall of Fame")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Reset the whole lineage?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Reset lineage", role: .destructive) {
                    store.resetLineage()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Every recorded life and the family name will be forgotten. This can't be undone.")
            }
        }
        .fontDesign(.rounded)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var recordsSection: some View {
        if store.hallOfFame.isEmpty {
            Section {
                ContentUnavailableView("No lives yet",
                                       systemImage: "trophy",
                                       description: Text("Finish a life and it will be remembered here."))
            }
        } else {
            Section("Best lives") {
                ForEach(Array(store.hallOfFame.enumerated()), id: \.element.id) { index, record in
                    HallRow(index: index, record: record)
                }
            }
        }
    }
}

/// One Hall of Fame entry. Shared with SummaryView.
struct HallRow: View {
    let index: Int
    let record: LifeRecord
    var showEpitaph: Bool = true

    private var detailText: String {
        let base = "\(record.rank) · age \(record.age) · Gen \(record.generation)"
        return record.daily == true ? base + " · 📅" : base
    }

    private var ambitionText: String {
        record.ambition.def.emoji + (record.achieved ? " ✅" : "")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("#" + String(index + 1))
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .leading)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(record.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(ambitionText)
                        .font(.subheadline)
                    Spacer(minLength: 4)
                    Text(String(record.score))
                        .font(.headline)
                        .monospacedDigit()
                }
                Text(detailText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if showEpitaph {
                    Text(record.epitaph)
                        .font(.footnote)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
