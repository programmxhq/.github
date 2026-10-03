import SwiftUI

struct StartView: View {
    @Environment(GameStore.self) private var store

    @State private var name: String = ""
    @State private var ambition: Ambition = Ambition.allCases.first ?? .fortune
    @State private var showSeed = false
    @State private var seedText = ""
    @State private var sheet: StartSheet?
    @FocusState private var nameFocused: Bool

    private var accent: Color { Stage.dawn.palette.accent }

    private var lineageText: String {
        "Generation \(store.generation) · The \(store.surname) line"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                titleBlock
                nameSection
                traitSection
                if let heirloom = store.pendingHeirloom {
                    InheritanceCard(heirloom: heirloom, parentName: heirParentName)
                }
                DailyCard(dayKey: store.todayKey, best: store.todayBest, accent: accent) {
                    startDaily()
                }
                ambitionSection
                seedSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom) { bornBar }
        .background { StageBackground(stage: .dawn) }
        .fontDesign(.rounded)
        .sheet(item: $sheet) { which in
            sheetContent(which)
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

    // MARK: Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            toolbarRow
            titleRow
        }
    }

    private var toolbarRow: some View {
        HStack(spacing: 10) {
            Spacer(minLength: 0)
            achievementsButton
            if !store.lineage.isEmpty {
                familyButton
            }
            trophyButton
        }
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
                Text(lineageText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(accent)
                    .padding(.top, 2)
            }
            Spacer(minLength: 8)
            DecorFan()
                .padding(.top, 8)
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

    // MARK: Name

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
                    .layoutPriority(1)
                Button {
                    Haptic.tap()
                    store.shuffleName()
                    name = store.suggestedName
                } label: {
                    Text("🎲")
                        .font(.title2)
                        .frame(width: 40, height: 40)
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

    // MARK: Birth trait

    private var traitSection: some View {
        let def = store.birthTraitPreview.def
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

    // MARK: Ambition

    private var ambitionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Ambition")
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(Ambition.allCases, id: \.self) { item in
                        ambitionButton(item)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .scrollIndicators(.hidden)
            .padding(.horizontal, -16)

            Text(ambition.def.blurb)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .id(ambition)
                .transition(.opacity)
        }
    }

    private func ambitionButton(_ item: Ambition) -> some View {
        let unlocked: Bool = store.isUnlocked(item)
        return Button {
            guard unlocked else { return }
            Haptic.tap()
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) { ambition = item }
        } label: {
            AmbitionTile(ambition: item, selected: unlocked && item == ambition,
                         locked: !unlocked, accent: accent)
        }
        .buttonStyle(PressableStyle())
        .disabled(!unlocked)
    }

    // MARK: Seed

    private var seedSection: some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                Spacer()
                Button {
                    withAnimation(.snappy) { showSeed.toggle() }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 32, height: 32)
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

    // MARK: Be born

    private var bornBar: some View {
        PrimaryButton(title: "Be born", tint: accent) {
            beBorn()
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

private struct AmbitionTile: View {
    let ambition: Ambition
    let selected: Bool
    let locked: Bool
    let accent: Color

    private var borderColor: Color {
        selected ? accent : Color.primary.opacity(0.08)
    }

    private var emojiOpacity: Double { locked ? 0.35 : 1 }
    private var emojiGrayscale: Double { locked ? 1 : 0 }
    private var nameColor: Color { locked ? Color.secondary : Color.primary }
    private var hintText: String { locked ? lockHint : "" }

    /// "🔒 Dynasty: Reach the third generation." for a locked ambition.
    private var lockHint: String {
        guard let needed = ambition.unlockedBy else { return "🔒 Locked" }
        return "🔒 " + needed.name + ": " + needed.detail
    }

    var body: some View {
        let def = ambition.def
        return VStack(alignment: .leading, spacing: 6) {
            Text(def.emoji)
                .font(.system(size: 34))
                .grayscale(emojiGrayscale)
                .opacity(emojiOpacity)
            Text(def.name)
                .font(.headline)
                .foregroundStyle(nameColor)
                .lineLimit(1)
            detailText(def)
            Spacer(minLength: 0)
        }
        .foregroundStyle(Color.primary)
        .frame(width: 136, height: 150, alignment: .topLeading)
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(borderColor, lineWidth: selected ? 2.5 : 1)
        }
        .shadow(color: selected ? accent.opacity(0.25) : Color.clear, radius: 10, x: 0, y: 4)
        .scaleEffect(selected ? 1.04 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityHint(hintText)
    }

    @ViewBuilder
    private func detailText(_ def: AmbitionDef) -> some View {
        if locked {
            Text(lockHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(5)
                .minimumScaleFactor(0.85)
        } else {
            Text(def.goalText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
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
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }
        .accessibilityLabel(label)
    }
}

/// The Daily Challenge: one seeded life per day, outside the family line.
private struct DailyCard: View {
    let dayKey: String
    let best: Int?
    let accent: Color
    let onPlay: () -> Void

    private var bestText: String {
        if let b = best { return "Best: " + String(b) }
        return "Not played yet"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Daily Challenge")
            VStack(alignment: .leading, spacing: 12) {
                header
                playButton
            }
            .padding(12)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.orange.opacity(0.45), lineWidth: 1.5)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Text("📅")
                .font(.system(size: 34))
                .frame(width: 52, height: 52)
                .background(Color.orange.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text("Today's life")
                    .font(.headline)
                Text(dayKey)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text(bestText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(best == nil ? Color.secondary : Color.orange)
            }
            Spacer(minLength: 0)
        }
    }

    private var playButton: some View {
        Button {
            onPlay()
        } label: {
            Text("Play today's life")
                .font(.subheadline.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .foregroundStyle(Color.orange)
                .background(Color.orange.opacity(0.15), in: Capsule())
        }
        .buttonStyle(PressableStyle())
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
