import Foundation

// MARK: - Conditions

/// Eligibility rules for a card. Conditions live on Cards, never on Choices.
/// Memberwise init: arguments must appear in declaration order.
struct Cond {
    var min: [Stat: Int] = [:]
    var max: [Stat: Int] = [:]
    var needTraits: [Trait] = []
    var noTraits: [Trait] = []
    var needFlags: [String] = []
    var noFlags: [String] = []
    var minMoney: Int? = nil
    var maxMoney: Int? = nil
    var ambition: Ambition? = nil

    static let none = Cond()

    func passes(_ life: Life) -> Bool {
        for (stat, v) in min where life.stats[stat] < v { return false }
        for (stat, v) in max where life.stats[stat] > v { return false }
        if needTraits.contains(where: { !life.has($0) }) { return false }
        if noTraits.contains(where: { life.has($0) }) { return false }
        if needFlags.contains(where: { !life.has(flag: $0) }) { return false }
        if noFlags.contains(where: { life.has(flag: $0) }) { return false }
        if let m = minMoney, life.money < m { return false }
        if let m = maxMoney, life.money > m { return false }
        if let a = ambition, life.ambition != a { return false }
        return true
    }
}

// MARK: - Effects

struct Effect {
    var stats: [Stat: Int]
    var money: Int
    var income: Int?        // sets yearly income, does not add
    var add: [Trait]
    var remove: [Trait]
    var set: [String]
    var clear: [String]
    var text: String
    var dies: Bool

    /// Arguments must appear in this exact order (Swift rule for defaulted parameters):
    /// body, mind, heart, bonds, money, income, add, remove, set, clear, text, dies
    init(body: Int = 0, mind: Int = 0, heart: Int = 0, bonds: Int = 0, money: Int = 0, income: Int? = nil,
         add: [Trait] = [], remove: [Trait] = [], set: [String] = [], clear: [String] = [],
         text: String, dies: Bool = false) {
        var s: [Stat: Int] = [:]
        if body != 0 { s[.body] = body }
        if mind != 0 { s[.mind] = mind }
        if heart != 0 { s[.heart] = heart }
        if bonds != 0 { s[.bonds] = bonds }
        self.stats = s
        self.money = money
        self.income = income
        self.add = add
        self.remove = remove
        self.set = set
        self.clear = clear
        self.text = text
        self.dies = dies
    }

    /// Nominal chips for this effect, e.g. "+8 Heart", "-$4k", "✨ Charmer", "Income $20k/yr".
    var deltaChips: [String] {
        var chips: [String] = []
        for stat in Stat.allCases {
            if let d = stats[stat], d != 0 { chips.append(Effect.statChip(stat, d)) }
        }
        if money != 0 { chips.append(Effect.moneyChip(money)) }
        if let i = income { chips.append("Income $\(i)k/yr") }
        for t in add { chips.append("✨ \(t.def.name)") }
        for t in remove { chips.append("✖️ \(t.def.name)") }
        if dies { chips.append("🪦 Fatal") }
        return chips
    }

    static func statChip(_ stat: Stat, _ d: Int) -> String {
        "\(d > 0 ? "+" : "")\(d) \(stat.label)"
    }

    static func moneyChip(_ m: Int) -> String {
        m >= 0 ? "+$\(m)k" : "-$\(-m)k"
    }
}

// MARK: - Choices

enum Outcome {
    case sure(Effect)
    case gamble(pct: Int, win: Effect, lose: Effect)
}

struct Choice {
    let label: String
    let outcome: Outcome

    static func sure(_ label: String, _ e: Effect) -> Choice {
        Choice(label: label, outcome: .sure(e))
    }

    static func gamble(_ label: String, _ pct: Int, win: Effect, lose: Effect) -> Choice {
        Choice(label: label, outcome: .gamble(pct: pct, win: win, lose: lose))
    }

    /// Base odds for gambles, nil for sure choices.
    var odds: Int? {
        if case .gamble(let pct, _, _) = outcome { return pct }
        return nil
    }
}

// MARK: - Cards

struct Card: Identifiable {
    let id: String
    let ages: ClosedRange<Int>
    let emoji: String
    let title: String
    let body: String
    let weight: Int
    let once: Bool
    let priority: Bool
    let filler: Bool
    let cond: Cond
    let choices: [Choice]

    static func make(_ id: String, _ ages: ClosedRange<Int>, _ emoji: String, _ title: String, _ body: String,
                     weight: Int = 3, once: Bool = true, priority: Bool = false, filler: Bool = false,
                     cond: Cond = .none, _ choices: [Choice]) -> Card {
        Card(id: id, ages: ages, emoji: emoji, title: title, body: body, weight: weight, once: once,
             priority: priority, filler: filler, cond: cond, choices: choices)
    }

    /// First sentence of the body, used as the teaser on a collapsed card.
    var teaser: String {
        if let r = body.range(of: ". ") { return String(body[..<r.lowerBound]) + "." }
        return body
    }

    func eligible(for life: Life) -> Bool {
        guard ages.contains(life.age) else { return false }
        if once && life.playedCardIDs.contains(id) { return false }
        if let until = life.cooldown[id], life.turn < until { return false }
        return cond.passes(life)
    }
}

// MARK: - Registry

/// Card pools are declared in the content files as `extension Content { static let x: [Card] }`:
/// - ContentCore.swift: `fillerCards`, `keepsakeCards`
/// - ContentEarly.swift: `dawn`, `bloom`
/// - ContentBuild.swift: `build`
/// - ContentLate.swift: `harvest`, `dusk`, `ambitionCards`
enum Content {
    static let all: [Card] = {
        let pools: [[Card]] = [dawn, bloom, build, harvest, dusk, ambitionCards, keepsakeCards, fillerCards]
        let cards = pools.flatMap { $0 }
        assert(Set(cards.map(\.id)).count == cards.count, "Duplicate card ids in content")
        return cards
    }()

    static let byID: [String: Card] = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

    /// Filler cards whose age range overlaps the stage. Used only to pad a hand.
    static func fillers(for stage: Stage) -> [Card] {
        fillerCards.filter { $0.ages.overlaps(stage.ages) }
    }
}
