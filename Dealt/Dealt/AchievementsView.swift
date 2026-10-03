import SwiftUI

/// Every achievement, earned or not. Presented as a sheet from the start screen.
struct AchievementsView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var all: [Achievement] { Achievement.allCases }

    private var unlockedCount: Int {
        all.filter { store.achievements.contains($0) }.count
    }

    private var headerText: String {
        String(unlockedCount) + " of " + String(all.count) + " unlocked"
    }

    private var fraction: Double {
        let total = max(1, all.count)
        return Double(unlockedCount) / Double(total)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    header
                }
                Section {
                    ForEach(all, id: \.self) { item in
                        AchievementRow(achievement: item, unlocked: store.achievements.contains(item))
                    }
                } footer: {
                    Text("Achievements carry over between lives, even after a lineage reset.")
                }
            }
            .navigationTitle("Achievements")
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("🏅")
                    .font(.system(size: 34))
                Text(headerText)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Spacer(minLength: 0)
            }
            ProgressView(value: fraction)
                .tint(Color.orange)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Row

private struct AchievementRow: View {
    let achievement: Achievement
    let unlocked: Bool

    private var emojiOpacity: Double { unlocked ? 1 : 0.35 }
    private var emojiGrayscale: Double { unlocked ? 0 : 1 }
    private var nameColor: Color { unlocked ? Color.primary : Color.secondary }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(achievement.emoji)
                .font(.system(size: 30))
                .grayscale(emojiGrayscale)
                .opacity(emojiOpacity)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(unlocked ? 0.16 : 0.05),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                titleLine
                Text(achievement.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                unlockTag
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var titleLine: some View {
        HStack(spacing: 6) {
            Text(achievement.name)
                .font(.headline)
                .foregroundStyle(nameColor)
            Spacer(minLength: 4)
            if unlocked {
                Text("✅")
                    .font(.subheadline)
            } else {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    @ViewBuilder
    private var unlockTag: some View {
        if let ambition = achievement.unlocks {
            let def = ambition.def
            Chip(text: "Unlocks " + def.emoji + " " + def.name, color: Color.purple)
                .padding(.top, 2)
        }
    }
}
