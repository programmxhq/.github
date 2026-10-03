import SwiftUI

struct StartView: View {
    @Environment(GameStore.self) private var store

    @State private var name: String = ""
    @State private var ambition: Ambition = Ambition.allCases.first ?? .fortune
    @State private var showSeed = false
    @State private var seedText = ""
    @State private var showHall = false
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
                    InheritanceCard(heirloom: heirloom)
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
        .sheet(isPresented: $showHall) {
            HallOfFameSheet(allowsReset: true)
                .environment(store)
        }
        .onAppear {
            if name.isEmpty { name = store.suggestedName }
        }
        .onChange(of: store.suggestedName) { _, newValue in
            name = newValue
        }
        .onChange(of: name) { _, newValue in
            if newValue.count > 20 { name = String(newValue.prefix(20)) }
        }
    }

    // MARK: Title

    private var titleBlock: some View {
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
            VStack(spacing: 14) {
                trophyButton
                DecorFan()
            }
        }
    }

    private var trophyButton: some View {
        Button {
            Haptic.tap()
            showHall = true
        } label: {
            Image(systemName: "trophy.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.orange)
                .frame(width: 44, height: 44)
                .background(.regularMaterial, in: Circle())
        }
        .accessibilityLabel("Hall of Fame")
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
                        Button {
                            Haptic.tap()
                            withAnimation(.spring(duration: 0.3, bounce: 0.3)) { ambition = item }
                        } label: {
                            AmbitionTile(ambition: item, selected: item == ambition, accent: accent)
                        }
                        .buttonStyle(PressableStyle())
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
    let accent: Color

    private var borderColor: Color {
        selected ? accent : Color.primary.opacity(0.08)
    }

    var body: some View {
        let def = ambition.def
        return VStack(alignment: .leading, spacing: 6) {
            Text(def.emoji)
                .font(.system(size: 34))
            Text(def.name)
                .font(.headline)
                .lineLimit(1)
            Text(def.goalText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
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
    }
}

private struct InheritanceCard: View {
    let heirloom: Heirloom

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "Inheritance")
            HStack(spacing: 14) {
                Text(heirloom.emoji)
                    .font(.system(size: 34))
                    .frame(width: 52, height: 52)
                    .background(Color.yellow.opacity(0.2), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
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
        "\(record.rank) · age \(record.age) · Gen \(record.generation)"
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
