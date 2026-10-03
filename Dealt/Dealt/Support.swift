import Foundation
import UIKit

// MARK: - RNG

/// SplitMix64. Codable so a restored save continues the same sequence.
struct SeededRNG: RandomNumberGenerator, Codable {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    init() {
        var sys = SystemRandomNumberGenerator()
        state = sys.next()
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// True with probability pct/100.
    mutating func roll(_ pct: Int) -> Bool {
        Int.random(in: 0..<100, using: &self) < pct
    }

    /// Precondition: `a` is not empty.
    mutating func pick<T>(_ a: [T]) -> T {
        a[Int.random(in: 0..<a.count, using: &self)]
    }

    /// Weighted pick. Weights below 1 count as 1. Precondition: `items` is not empty.
    mutating func weighted<T>(_ items: [(T, Int)]) -> T {
        let total = items.reduce(0) { $0 + max(1, $1.1) }
        var r = Int.random(in: 0..<total, using: &self)
        for (item, w) in items {
            r -= max(1, w)
            if r < 0 { return item }
        }
        return items[items.count - 1].0
    }
}

// MARK: - Persistence

struct SaveData: Codable {
    var phase: Phase
    var life: Life?
    var handIDs: [String]
    var generation: Int
    var surname: String
    var pendingHeirloom: Heirloom?
    var hallOfFame: [LifeRecord]
    var rng: SeededRNG
}

enum Persistence {
    static let fileName = "dealt_save_v1.json"

    private static var url: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return dir.appendingPathComponent(fileName)
    }

    /// nil on missing or corrupt save.
    static func load() -> SaveData? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SaveData.self, from: data)
    }

    static func save(_ data: SaveData) {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        try? encoded.write(to: url, options: .atomic)
    }

    static func wipe() {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Haptics

enum Haptic {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

// MARK: - Helpers

extension Comparable {
    func clamped(_ r: ClosedRange<Self>) -> Self {
        min(max(self, r.lowerBound), r.upperBound)
    }
}
