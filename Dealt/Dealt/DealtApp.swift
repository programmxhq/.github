import SwiftUI

@main
struct DealtApp: App {
    @State private var store: GameStore

    init() {
        // UI tests launch with -uiTestReset to start from a fresh install.
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            Persistence.wipe()
            UserDefaults.standard.removeObject(forKey: "dealt.tutorialSeen")
        }
        _store = State(initialValue: GameStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}

/// Routes between the three screens on `store.phase`.
struct RootView: View {
    @Environment(GameStore.self) private var store

    var body: some View {
        ZStack {
            switch store.phase {
            case .start:
                StartView()
                    .transition(.opacity)
            case .playing:
                PlayView()
                    .transition(.opacity)
            case .summary:
                SummaryView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: store.phase)
    }
}
