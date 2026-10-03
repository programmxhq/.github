import Foundation

/// Meta-progress that survives across lives and lineage resets.
enum Achievement: String, Codable, CaseIterable, Hashable {
    case firstLife, centenarian, millionaire, fullHouse, householdName, polymath,
         dicey, dynasty, dreamCameTrue, wentOutSwinging, globetrotter, dailyGrind

    var name: String {
        switch self {
        case .firstLife: return "First Breath"
        case .centenarian: return "Centenarian"
        case .millionaire: return "Millionaire"
        case .fullHouse: return "Full House"
        case .householdName: return "Household Name"
        case .polymath: return "Polymath"
        case .dicey: return "Dicey"
        case .dynasty: return "Dynasty"
        case .dreamCameTrue: return "Dream Come True"
        case .wentOutSwinging: return "Went Out Swinging"
        case .globetrotter: return "Globetrotter"
        case .dailyGrind: return "Daily Grind"
        }
    }

    var emoji: String {
        switch self {
        case .firstLife: return "🌱"
        case .centenarian: return "💯"
        case .millionaire: return "💎"
        case .fullHouse: return "🏡"
        case .householdName: return "🌟"
        case .polymath: return "🧠"
        case .dicey: return "🎲"
        case .dynasty: return "🌳"
        case .dreamCameTrue: return "🏆"
        case .wentOutSwinging: return "🥊"
        case .globetrotter: return "🌍"
        case .dailyGrind: return "📅"
        }
    }

    /// How to earn it, shown while locked.
    var detail: String {
        switch self {
        case .firstLife: return "Live a whole life."
        case .centenarian: return "Reach 100."
        case .millionaire: return "Die with $1M or more."
        case .fullHouse: return "Be married with kids when you die."
        case .householdName: return "Die famous."
        case .polymath: return "Die with every stat at 70+."
        case .dicey: return "Win 5 gambles in one life. Unlocks the Thrill ambition."
        case .dynasty: return "Reach the third generation. Unlocks the Legacy ambition."
        case .dreamCameTrue: return "Achieve your ambition."
        case .wentOutSwinging: return "Die on a card's gamble."
        case .globetrotter: return "See all 6 far corners in one life."
        case .dailyGrind: return "Finish a Daily Challenge."
        }
    }

    /// The ambition this unlocks, if any.
    var unlocks: Ambition? {
        Ambition.allCases.first { $0.unlockedBy == self }
    }

    /// Everything a finished life earns. Called once, at death.
    static func earned(by life: Life) -> [Achievement] {
        var out: [Achievement] = [.firstLife]
        if life.age >= 100 { out.append(.centenarian) }
        if life.money >= 1000 { out.append(.millionaire) }
        if life.has(flag: "married") && life.has(flag: "kids") { out.append(.fullHouse) }
        if life.has(.famous) { out.append(.householdName) }
        if Stat.allCases.allSatisfy({ life.stats[$0] >= 70 }) { out.append(.polymath) }
        if life.gamblesWon >= 5 { out.append(.dicey) }
        if !life.isDaily && life.generation >= 3 { out.append(.dynasty) }
        if life.ambition.achieved(life) { out.append(.dreamCameTrue) }
        if life.deathCause == .card { out.append(.wentOutSwinging) }
        if life.flags.filter({ $0.hasPrefix("saw_") }).count >= 6 { out.append(.globetrotter) }
        if life.isDaily { out.append(.dailyGrind) }
        return out
    }
}

/// The Daily Challenge: one seeded life per calendar day, the same for every player.
enum Daily {
    /// Today's key in the device's calendar, e.g. "2026-10-03".
    static func key(for date: Date = Date()) -> String {
        let c = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        let y = c.year ?? 2000, m = c.month ?? 1, d = c.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    /// Stable FNV-1a hash of the key, so the seed is identical on every device.
    static func seed(for key: String) -> UInt64 {
        var h: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in key.utf8 {
            h ^= UInt64(byte)
            h = h &* 0x0000_0100_0000_01B3
        }
        return h
    }
}
