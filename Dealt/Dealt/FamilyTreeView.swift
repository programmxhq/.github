import SwiftUI

/// The current family as a vertical tree, oldest generation at the top.
/// Each connector between two generations shows the heirloom that was passed down.
struct FamilyTreeView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var accent: Color { Stage.harvest.palette.accent }

    private var titleText: String { "The " + store.surname + " line" }

    private var subtitleText: String {
        let n = store.lineage.count
        return n == 1 ? "1 life so far" : String(n) + " lives so far"
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(titleText)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
        .fontDesign(.rounded)
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private var content: some View {
        if store.lineage.isEmpty {
            ContentUnavailableView("No family yet",
                                   systemImage: "person.3",
                                   description: Text("Finish a life and pass on an heirloom to grow the family tree."))
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 14)
                    tree
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
            .background { StageBackground(stage: .harvest) }
        }
    }

    private var tree: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(store.lineage.enumerated()), id: \.element.id) { index, record in
                TreeNode(record: record, isFirst: index == 0, accent: accent)
                TreeConnector(heirloom: record.heirloomPassed, accent: accent)
            }
            NextHeirNode(generation: nextGeneration, surname: store.surname,
                         detail: nextDetail, accent: accent)
        }
    }

    // MARK: - Next heir

    private var nextGeneration: Int {
        let last: Int = store.lineage.last?.generation ?? 0
        return last + 1
    }

    private var nextDetail: String {
        if let heirloom = store.pendingHeirloom {
            return "Inherits " + heirloom.emoji + " " + heirloom.title
        }
        if store.phase == .summary && !store.isDailyLife {
            return "Waiting for an heirloom"
        }
        return "Not born yet"
    }
}

// MARK: - Layout constants

private enum TreeMetrics {
    static let rail: CGFloat = 52
    static let line: CGFloat = 3
    /// Leading inset that centres the line under the generation circle.
    static var lineInset: CGFloat { (rail - line) / 2 }
}

/// The vertical line drawn behind a row, through the centre of the rail.
private struct RailLine: View {
    let color: Color
    var topInset: CGFloat = 0
    var height: CGFloat? = nil

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: TreeMetrics.line, height: height)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, topInset)
            .padding(.leading, TreeMetrics.lineInset)
    }
}

// MARK: - Generation circle

private struct GenCircle: View {
    let generation: Int
    let color: Color
    var dashed: Bool = false

    private var strokeStyle: StrokeStyle {
        dashed ? StrokeStyle(lineWidth: 2, dash: [5, 4]) : StrokeStyle(lineWidth: 2.5)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(uiColor: .systemBackground))
            Circle()
                .fill(color.opacity(dashed ? 0.06 : 0.18))
            Circle()
                .strokeBorder(color, style: strokeStyle)
            VStack(spacing: -2) {
                Text("Gen")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(String(generation))
                    .font(.headline.weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(color)
            }
        }
        .frame(width: TreeMetrics.rail, height: TreeMetrics.rail)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Generation " + String(generation))
    }
}

// MARK: - A life in the tree

private struct TreeNode: View {
    let record: LifeRecord
    let isFirst: Bool
    let accent: Color

    private var ambitionText: String {
        let def = record.ambition.def
        let mark = record.achieved ? "✅" : "❌"
        return def.emoji + " " + def.name + " " + mark
    }

    private var scoreText: String {
        String(record.score) + " · " + record.rank
    }

    private var kids: [String] { record.kidNames ?? [] }

    private var hasFamily: Bool {
        record.spouseName != nil || !kids.isEmpty
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GenCircle(generation: record.generation, color: accent)
            card
        }
        .background(alignment: .topLeading) {
            RailLine(color: accent.opacity(0.5), topInset: isFirst ? TreeMetrics.rail / 2 : 0)
        }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(record.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Text("age " + String(record.age))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Text(ambitionText)
                .font(.subheadline)
            Text(scoreText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .monospacedDigit()
            if hasFamily {
                familyChips
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var familyChips: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let spouse = record.spouseName {
                Chip(text: "💍 " + spouse, color: Color.pink)
            }
            if !kids.isEmpty {
                Chip(text: "👶 " + kids.joined(separator: ", "), color: Color.teal)
            }
        }
        .padding(.top, 2)
    }
}

// MARK: - Connector with the heirloom passed down

private struct TreeConnector: View {
    let heirloom: Heirloom?
    let accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Color.clear
                .frame(width: TreeMetrics.rail, height: 1)
            label
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .frame(minHeight: 28)
        .background(alignment: .topLeading) {
            RailLine(color: accent.opacity(0.5))
        }
    }

    @ViewBuilder
    private var label: some View {
        if let h = heirloom {
            HStack(spacing: 6) {
                Image(systemName: "arrow.down")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(h.emoji + " " + h.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.yellow.opacity(0.22), in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.yellow.opacity(0.6), lineWidth: 1)
            }
            .accessibilityLabel("Passed down " + h.title)
        }
    }
}

// MARK: - The heir still to come

private struct NextHeirNode: View {
    let generation: Int
    let surname: String
    let detail: String
    let accent: Color

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            GenCircle(generation: generation, color: accent, dashed: true)
            VStack(alignment: .leading, spacing: 4) {
                Text("Next: " + surname + " heir")
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay {
                shape.strokeBorder(accent.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
        }
        .background(alignment: .topLeading) {
            RailLine(color: accent.opacity(0.5), height: TreeMetrics.rail / 2)
        }
    }
}
