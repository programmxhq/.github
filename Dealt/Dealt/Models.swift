import SwiftUI

// MARK: - Stats

enum Stat: String, Codable, CaseIterable, Hashable {
    case body, mind, heart, bonds

    var label: String {
        switch self {
        case .body: return "Body"
        case .mind: return "Mind"
        case .heart: return "Heart"
        case .bonds: return "Bonds"
        }
    }

    var symbol: String {
        switch self {
        case .body: return "figure.walk"
        case .mind: return "brain.head.profile"
        case .heart: return "heart.fill"
        case .bonds: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .body: return .green
        case .mind: return .blue
        case .heart: return .pink
        case .bonds: return .orange
        }
    }
}

struct Stats: Codable, Equatable {
    var body: Int
    var mind: Int
    var heart: Int
    var bonds: Int

    /// Always clamps to 0...100 on write.
    subscript(_ s: Stat) -> Int {
        get {
            switch s {
            case .body: return body
            case .mind: return mind
            case .heart: return heart
            case .bonds: return bonds
            }
        }
        set {
            let v = newValue.clamped(0...100)
            switch s {
            case .body: body = v
            case .mind: mind = v
            case .heart: heart = v
            case .bonds: bonds = v
            }
        }
    }

    var total: Int { body + mind + heart + bonds }

    mutating func apply(_ deltas: [Stat: Int]) {
        for (stat, delta) in deltas { self[stat] += delta }
    }

    var highest: Stat {
        Stat.allCases.max { self[$0] < self[$1] } ?? .body
    }
}

// MARK: - Stages

enum Stage: String, Codable, CaseIterable {
    case dawn, bloom, build, harvest, dusk

    static func of(age: Int) -> Stage {
        switch age {
        case ..<12: return .dawn
        case 12...23: return .bloom
        case 24...47: return .build
        case 48...67: return .harvest
        default: return .dusk
        }
    }

    var ages: ClosedRange<Int> {
        switch self {
        case .dawn: return 0...11
        case .bloom: return 12...23
        case .build: return 24...47
        case .harvest: return 48...67
        case .dusk: return 68...104
        }
    }

    var yearsPerTurn: Int {
        switch self {
        case .dawn: return 4
        case .bloom: return 3
        case .build: return 4
        case .harvest: return 4
        case .dusk: return 3
        }
    }

    /// In $1k per year.
    var costOfLiving: Int {
        switch self {
        case .dawn: return 0
        case .bloom: return 1
        case .build: return 8
        case .harvest: return 8
        case .dusk: return 6
        }
    }

    var title: String {
        switch self {
        case .dawn: return "Dawn"
        case .bloom: return "Bloom"
        case .build: return "Build"
        case .harvest: return "Harvest"
        case .dusk: return "Dusk"
        }
    }

    var emoji: String {
        switch self {
        case .dawn: return "🌱"
        case .bloom: return "🌸"
        case .build: return "🏗️"
        case .harvest: return "🍂"
        case .dusk: return "🕯️"
        }
    }
}

// MARK: - Traits

enum Trait: String, Codable, CaseIterable, Hashable {
    case lucky, stubborn, bookworm, daredevil, kind, cynic, charmer, frugal,
         workaholic, romantic, loner, artist, hustler, athlete, famous, haunted

    static let birthPool: [Trait] = [.lucky, .stubborn, .bookworm, .daredevil, .kind, .cynic]

    /// Definitions live in `TraitDef.all` (ContentCore.swift).
    var def: TraitDef {
        TraitDef.all[self] ?? TraitDef(name: rawValue.capitalized, emoji: "✨", blurb: "",
                                       perTurn: [:], luck: 0, epitaph: "")
    }
}

struct TraitDef {
    let name: String
    let emoji: String
    let blurb: String
    let perTurn: [Stat: Int]
    let luck: Int
    let epitaph: String
}

// MARK: - Ambitions

enum Ambition: String, Codable, CaseIterable, Hashable {
    case fortune, renown, hearth, scholar, wanderer, elder

    /// Definitions live in `AmbitionDef.all` (ContentCore.swift).
    var def: AmbitionDef {
        AmbitionDef.all[self] ?? AmbitionDef(name: rawValue.capitalized, emoji: "⭐️", blurb: "",
                                             goalText: "", wonLine: "", lostLine: "")
    }

    func achieved(_ life: Life) -> Bool {
        switch self {
        case .fortune:
            return life.money >= 1000
        case .renown:
            return life.has(.famous) && life.stats.bonds >= 60
        case .hearth:
            return life.has(flag: "married") && life.has(flag: "kids") && life.stats.bonds >= 70
        case .scholar:
            return life.stats.mind >= 85 && life.has(flag: "published")
        case .wanderer:
            return life.flags.filter { $0.hasPrefix("saw_") }.count >= 5
        case .elder:
            return life.age >= 90 && life.stats.heart >= 50
        }
    }

    func progress(_ life: Life) -> Double {
        if achieved(life) { return 1 }
        let p: Double
        switch self {
        case .fortune:
            p = Double(life.money) / 1000
        case .renown:
            p = (life.has(.famous) ? 0.5 : 0) + Double(life.stats.bonds) / 120
        case .hearth:
            let met = [life.has(flag: "married"), life.has(flag: "kids"), life.stats.bonds >= 70]
                .filter { $0 }.count
            p = Double(met) / 3
        case .scholar:
            p = Double(life.stats.mind) / 170 + (life.has(flag: "published") ? 0.5 : 0)
        case .wanderer:
            p = Double(life.flags.filter { $0.hasPrefix("saw_") }.count) / 5
        case .elder:
            p = Double(life.age) / 90
        }
        // Never show a full bar for an unmet goal.
        return min(max(p, 0), 0.99)
    }
}

struct AmbitionDef {
    let name: String
    let emoji: String
    let blurb: String
    let goalText: String
    let wonLine: String
    let lostLine: String
}

// MARK: - Legacy

enum Keepsake: String, Codable, CaseIterable {
    case medal, ledger, violin, letter

    var emoji: String {
        switch self {
        case .medal: return "🏅"
        case .ledger: return "📒"
        case .violin: return "🎻"
        case .letter: return "✉️"
        }
    }

    var name: String {
        switch self {
        case .medal: return "Old Medal"
        case .ledger: return "Dusty Ledger"
        case .violin: return "Worn Violin"
        case .letter: return "Sealed Letter"
        }
    }

    /// Flag set on the heir at birth; unlocks one secret `keep_` card.
    var flag: String { "heir_\(rawValue)" }

    /// The keepsake a life leaves behind, chosen by its strongest stat.
    static func forStat(_ s: Stat) -> Keepsake {
        switch s {
        case .body: return .medal
        case .mind: return .ledger
        case .heart: return .violin
        case .bonds: return .letter
        }
    }
}

enum Heirloom: Codable, Hashable {
    case trait(Trait)
    case money(Int)
    case keepsake(Keepsake)

    var title: String {
        switch self {
        case .trait(let t): return t.def.name
        case .money(let n): return "$\(n)k Inheritance"
        case .keepsake(let k): return k.name
        }
    }

    var emoji: String {
        switch self {
        case .trait(let t): return t.def.emoji
        case .money: return "💰"
        case .keepsake(let k): return k.emoji
        }
    }

    var blurb: String {
        switch self {
        case .trait(let t): return "Your heir is born \(t.def.name.lowercased()). \(t.def.blurb)"
        case .money(let n): return "Your heir starts life with $\(n)k in the bank."
        case .keepsake(let k): return "The \(k.name.lowercased()) holds a story your heir may one day live."
        }
    }
}

// MARK: - Life

struct HistoryEntry: Codable, Identifiable {
    var id: UUID = UUID()
    let age: Int
    let emoji: String
    let title: String
    let choice: String
    let text: String
}

enum DeathCause: String, Codable {
    case body, oldAge, card, cap

    var line: String {
        switch self {
        case .body: return "The body simply clocked out."
        case .oldAge: return "Slipped away peacefully, mid-anecdote."
        case .card: return "Went out exactly as they lived: on a choice."
        case .cap: return "Died of sheer stubbornness."
        }
    }
}

struct Life: Codable {
    var name: String
    var surname: String
    var age: Int
    var stats: Stats
    var money: Int          // $1k units, floor -999
    var income: Int         // $1k per year
    var traits: [Trait]
    var flags: Set<String>
    var ambition: Ambition
    var turn: Int
    var playedCardIDs: Set<String>
    var cooldown: [String: Int]   // cardID -> turn when it becomes eligible again
    var history: [HistoryEntry]
    var alive: Bool
    var deathCause: DeathCause?
    var heirloomReceived: Heirloom?
    var generation: Int

    var stage: Stage { Stage.of(age: age) }
    var fullName: String { "\(name) \(surname)" }

    func has(_ t: Trait) -> Bool { traits.contains(t) }
    func has(flag: String) -> Bool { flags.contains(flag) }

    /// Sum of every trait's luck bonus, added to gamble odds.
    var luck: Int { traits.reduce(0) { $0 + $1.def.luck } }

    static func newborn(name: String, surname: String, ambition: Ambition, birthTrait: Trait,
                        heirloom: Heirloom?, generation: Int, rng: inout SeededRNG) -> Life {
        func roll(_ base: Int) -> Int { (base + Int.random(in: -10...10, using: &rng)).clamped(0...100) }
        var life = Life(
            name: name, surname: surname, age: 0,
            stats: Stats(body: roll(60), mind: roll(50), heart: roll(60), bonds: roll(60)),
            money: 0, income: 0, traits: [birthTrait], flags: [], ambition: ambition, turn: 0,
            playedCardIDs: [], cooldown: [:], history: [], alive: true, deathCause: nil,
            heirloomReceived: heirloom, generation: generation)
        switch heirloom {
        case .trait(let t)?:
            if life.traits.contains(t) {
                life.money += 20
            } else {
                life.traits.append(t)
                if t == .workaholic { life.income += 5 }
            }
        case .money(let n)?:
            life.money += n
        case .keepsake(let k)?:
            life.flags.insert(k.flag)
        case nil:
            break
        }
        return life
    }
}

// MARK: - Records & UI state

struct LifeRecord: Codable, Identifiable {
    var id: UUID = UUID()
    let name: String
    let age: Int
    let ambition: Ambition
    let achieved: Bool
    let score: Int
    let rank: String
    let epitaph: String
    let generation: Int
    let date: Date
}

enum Phase: String, Codable {
    case start, playing, summary
}

struct OutcomeToast: Identifiable, Equatable {
    let id = UUID()
    let emoji: String
    let title: String
    let text: String
    let deltas: [String]
    let died: Bool
    let gambleWon: Bool?
}
