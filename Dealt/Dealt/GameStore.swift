import SwiftUI
import Observation

/// The single owner of mutable game state. Views read it from the environment and call its methods.
@Observable final class GameStore {
    var phase: Phase = .start
    var life: Life? = nil
    var hand: [Card] = []
    var expandedCardID: String? = nil
    var toast: OutcomeToast? = nil
    var hallOfFame: [LifeRecord] = []
    var generation: Int = 1
    var surname: String
    var pendingHeirloom: Heirloom? = nil      // chosen at last death, applied to next birth
    var heirloomOptions: [Heirloom] = []      // computed at death
    var birthTraitPreview: Trait
    var suggestedName: String
    private(set) var rng: SeededRNG

    // MARK: - Init / restore

    init() {
        let saved = Persistence.load()
        self.birthTraitPreview = GameStore.randomBirthTrait(excluding: nil)
        self.suggestedName = GameStore.randomFirstName(excluding: nil)
        if let s = saved {
            let trimmedSurname = s.surname.trimmingCharacters(in: .whitespacesAndNewlines)
            self.surname = trimmedSurname.isEmpty ? GameStore.randomSurname(excluding: nil) : trimmedSurname
            self.rng = s.rng
            self.generation = max(1, s.generation)
            self.hallOfFame = s.hallOfFame
            self.pendingHeirloom = s.pendingHeirloom
            self.life = s.life
            self.phase = s.phase
            var restored: [Card] = []
            for id in s.handIDs {
                if let c = Content.byID[id] { restored.append(c) }
            }
            self.hand = restored
        } else {
            self.surname = GameStore.randomSurname(excluding: nil)
            self.rng = SeededRNG()
        }
        restoreConsistency()
    }

    /// Repairs any inconsistent restored state. Never crashes.
    private func restoreConsistency() {
        toast = nil
        expandedCardID = nil
        switch phase {
        case .start:
            life = nil
            hand = []
            heirloomOptions = []
        case .summary:
            hand = []
            if life == nil {
                phase = .start
                heirloomOptions = []
            } else {
                heirloomOptions = makeHeirloomOptions()
            }
        case .playing:
            guard let l = life else {
                phase = .start
                hand = []
                heirloomOptions = []
                return
            }
            if !l.alive || l.deathCause != nil || l.stats.body <= 0 {
                // A death was pending (card death or Body hit 0) when the app quit.
                endLife(cause: l.deathCause ?? .body)
                return
            }
            if GameStore.resolvedThisTurn(l) {
                // A card was resolved this turn but time never advanced (toast lost on quit).
                continueLife()
                return
            }
            let ids = hand.map { $0.id }
            let valid = hand.count == 3
                && Set(ids).count == 3
                && hand.allSatisfy { $0.filler || $0.eligible(for: l) }
            if !valid {
                dealHand()
                save()
            }
        }
    }

    /// True when a card was already played at the current age (time has not advanced yet).
    private static func resolvedThisTurn(_ l: Life) -> Bool {
        guard let last = l.history.last else { return false }
        return last.age == l.age
    }

    // MARK: - Random helpers (static so they can run before init completes)

    private static func randomFirstName(excluding: String?) -> String {
        let pool = Names.first.filter { $0 != excluding }
        return pool.randomElement() ?? Names.first.randomElement() ?? "Alex"
    }

    private static func randomSurname(excluding: String?) -> String {
        let pool = Names.surnames.filter { $0 != excluding }
        return pool.randomElement() ?? Names.surnames.randomElement() ?? "Doe"
    }

    private static func randomBirthTrait(excluding: Trait?) -> Trait {
        let pool = Trait.birthPool.filter { $0 != excluding }
        return pool.randomElement() ?? Trait.birthPool.randomElement() ?? .lucky
    }

    // MARK: - Start

    func shuffleBirthTrait() {
        birthTraitPreview = GameStore.randomBirthTrait(excluding: birthTraitPreview)
    }

    func shuffleName() {
        suggestedName = GameStore.randomFirstName(excluding: suggestedName)
    }

    func startLife(name: String, ambition: Ambition, seed: UInt64?) {
        if let seed = seed {
            rng = SeededRNG(seed: seed)
        } else {
            rng = SeededRNG()
        }
        var first = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if first.isEmpty { first = suggestedName.trimmingCharacters(in: .whitespacesAndNewlines) }
        if first.isEmpty { first = "Alex" }

        var r = rng
        let newLife = Life.newborn(name: first, surname: surname, ambition: ambition,
                                   birthTrait: birthTraitPreview, heirloom: pendingHeirloom,
                                   generation: generation, rng: &r)
        rng = r

        life = newLife
        pendingHeirloom = nil
        heirloomOptions = []
        toast = nil
        expandedCardID = nil
        phase = .playing
        dealHand()
        save()
    }

    // MARK: - Play

    var expandedCard: Card? {
        guard let id = expandedCardID else { return nil }
        return hand.first { $0.id == id }
    }

    func expand(_ card: Card?) {
        guard let card = card else {
            expandedCardID = nil
            return
        }
        guard phase == .playing, toast == nil, hand.contains(where: { $0.id == card.id }) else { return }
        expandedCardID = card.id
    }

    /// Gamble odds after trait luck, clamped 5...95. nil for sure choices.
    func effectiveOdds(_ choice: Choice) -> Int? {
        guard let pct = choice.odds else { return nil }
        let luck = life?.luck ?? 0
        return (pct + luck).clamped(5...95)
    }

    /// Resolves a choice of the expanded card and shows the outcome toast. Does not advance time.
    func choose(_ choiceIndex: Int) {
        guard phase == .playing, toast == nil else { return }
        guard var l = life, l.alive, l.deathCause == nil else { return }
        guard !GameStore.resolvedThisTurn(l) else { return }   // one card per chapter
        guard let card = expandedCard else { return }
        guard choiceIndex >= 0, choiceIndex < card.choices.count else { return }

        let choice = card.choices[choiceIndex]
        let effect: Effect
        var gambleWon: Bool? = nil
        switch choice.outcome {
        case .sure(let e):
            effect = e
        case .gamble(_, let win, let lose):
            let odds = effectiveOdds(choice) ?? 50
            let won = rng.roll(odds)
            gambleWon = won
            effect = won ? win : lose
        }

        l.history.append(HistoryEntry(age: l.age, emoji: card.emoji, title: card.title,
                                      choice: choice.label, text: effect.text))
        l.playedCardIDs.insert(card.id)
        for other in hand where other.id != card.id && !other.filler {
            l.cooldown[other.id] = l.turn + 2
        }

        let chips = apply(effect, to: &l)

        if effect.dies {
            l.deathCause = .card
        } else if l.stats.body <= 0 {
            l.deathCause = .body
        }
        let died = l.deathCause != nil
        life = l

        toast = OutcomeToast(emoji: card.emoji, title: card.title, text: effect.text,
                             deltas: chips, died: died, gambleWon: gambleWon)
        expandedCardID = nil
        save()
    }

    /// "Let the years drift": no card played, Heart -3, then time advances.
    func drift() {
        guard phase == .playing, toast == nil else { return }
        guard var l = life, l.alive, l.deathCause == nil else { return }
        if GameStore.resolvedThisTurn(l) {
            // Outcome sheet was dismissed without "Live on": just move time, no extra penalty.
            continueLife()
            return
        }
        l.stats[.heart] -= 3
        l.history.append(HistoryEntry(age: l.age, emoji: "🍃", title: "Drifted",
                                      choice: "Let the years drift",
                                      text: "Nothing much happened. That was the point."))
        for c in hand where !c.filler {
            l.cooldown[c.id] = l.turn + 2
        }
        life = l
        continueLife()
    }

    /// Dismisses the toast and moves time forward: the only place time advances.
    func continueLife() {
        toast = nil
        expandedCardID = nil
        guard phase == .playing, let l = life else { return }
        if let pending = l.deathCause {
            endLife(cause: pending)
            return
        }
        if l.stats.body <= 0 || !l.alive {
            endLife(cause: .body)
            return
        }
        advanceTime()
        if let cause = checkDeath() {
            endLife(cause: cause)
            return
        }
        dealHand()
        save()
    }

    // MARK: - Engine internals

    /// Deals exactly 3 distinct cards: priority eligibles, then weighted picks, then stage fillers.
    func dealHand() {
        guard let l = life else {
            hand = []
            return
        }
        var chosen: [Card] = []
        var chosenIDs = Set<String>()

        let eligible = Content.all.filter { !$0.filler && $0.eligible(for: l) }

        // 1. Priority cards first.
        let priority = eligible.filter { $0.priority }.shuffled(using: &rng)
        for c in priority {
            if chosen.count >= 3 { break }
            if chosenIDs.contains(c.id) { continue }
            chosen.append(c)
            chosenIDs.insert(c.id)
        }

        // 2. Weighted random without replacement.
        var pool = eligible.filter { !chosenIDs.contains($0.id) }
        while chosen.count < 3 && !pool.isEmpty {
            let items: [(Int, Int)] = pool.indices.map { ($0, pool[$0].weight) }
            let index: Int = rng.weighted(items)
            let c = pool.remove(at: index)
            if chosenIDs.contains(c.id) { continue }
            chosen.append(c)
            chosenIDs.insert(c.id)
        }

        // 3. Pad with fillers: age-matched stage fillers, then any stage filler, then any filler.
        if chosen.count < 3 {
            let stageFillers = Content.fillers(for: l.stage)
            let ageFillers = stageFillers.filter { $0.ages.contains(l.age) }
            let anyFillers = Content.all.filter { $0.filler }
            let tiers: [[Card]] = [ageFillers, stageFillers, anyFillers]
            for tier in tiers {
                if chosen.count >= 3 { break }
                let shuffledTier = tier.shuffled(using: &rng)
                for c in shuffledTier {
                    if chosen.count >= 3 { break }
                    if chosenIDs.contains(c.id) { continue }
                    chosen.append(c)
                    chosenIDs.insert(c.id)
                }
            }
        }

        hand = chosen
        expandedCardID = nil
    }

    /// One chapter passes: drift, trait upkeep, money settles, age and turn tick.
    func advanceTime() {
        guard var l = life else { return }
        let stage = l.stage
        let years = stage.yearsPerTurn
        let age = l.age

        // Body drift (not cumulative).
        var bodyDrift = 0
        if age >= 68 {
            bodyDrift = -5
        } else if age >= 40 {
            bodyDrift = -2
        }
        if l.has(.athlete) { bodyDrift = bodyDrift / 2 }
        if bodyDrift != 0 { l.stats[.body] += bodyDrift }

        // Mind drift.
        if age >= 72 { l.stats[.mind] -= 3 }

        // Heart drift when lonely.
        if l.stats.bonds < 30 { l.stats[.heart] -= 2 }

        // Bonds drift for adults, unless charming.
        if age >= 24 && !l.has(.charmer) { l.stats[.bonds] -= 2 }

        // Trait upkeep.
        for t in l.traits {
            for (stat, delta) in t.def.perTurn where delta != 0 {
                l.stats[stat] += delta
            }
        }

        // Money settles.
        let frugalBonus = l.has(.frugal) ? 3 : 0
        let net = (l.income - stage.costOfLiving + frugalBonus) * years
        l.money = max(-999, l.money + net)

        // Time moves.
        l.age = min(104, l.age + years)
        l.turn += 1

        // Drop expired cooldowns.
        let turnNow = l.turn
        l.cooldown = l.cooldown.filter { $0.value > turnNow }

        life = l
    }

    /// Mortality check, run after drift and before dealing.
    func checkDeath() -> DeathCause? {
        guard let l = life else { return nil }
        if l.stats.body <= 0 { return .body }
        if l.age >= 104 { return .cap }
        if l.age >= 68 {
            let risk = ((l.age - 72) * 2 + max(0, 40 - l.stats.body) / 2).clamped(0...95)
            if rng.roll(risk) { return .oldAge }
        }
        return nil
    }

    /// Applies an effect through the clamping Stats subscript. Returns chips for the ACTUAL changes.
    func apply(_ e: Effect, to life: inout Life) -> [String] {
        var chips: [String] = []

        // Stats.
        for stat in Stat.allCases {
            guard let delta = e.stats[stat], delta != 0 else { continue }
            let before = life.stats[stat]
            life.stats[stat] = before + delta
            let actual = life.stats[stat] - before
            if actual != 0 { chips.append(Effect.statChip(stat, actual)) }
        }

        // Money.
        if e.money != 0 {
            let before = life.money
            life.money = max(-999, life.money + e.money)
            let actual = life.money - before
            if actual != 0 { chips.append(Effect.moneyChip(actual)) }
        }

        // Income (sets, does not add). Chip is emitted after traits so it reflects workaholic.
        let incomeBefore = life.income
        if let i = e.income {
            life.income = max(0, i)
        }

        // Traits.
        var traitChips: [String] = []
        for t in e.add {
            if life.has(t) { continue }
            life.traits.append(t)
            traitChips.append("✨ \(t.def.name)")
            if t == .workaholic { life.income += 5 }
        }
        for t in e.remove {
            if !life.has(t) { continue }
            life.traits.removeAll { $0 == t }
            traitChips.append("✖️ \(t.def.name)")
        }

        if e.income != nil || life.income != incomeBefore {
            chips.append("Income $\(life.income)k/yr")
        }
        chips.append(contentsOf: traitChips)

        // Flags (no chips).
        for f in e.set { life.flags.insert(f) }
        for f in e.clear { life.flags.remove(f) }

        if e.dies { chips.append("🪦 Fatal") }
        return chips
    }

    func endLife(cause: DeathCause) {
        guard var l = life, phase != .summary else { return }
        l.alive = false
        l.deathCause = cause
        life = l

        heirloomOptions = makeHeirloomOptions()

        let record = LifeRecord(name: l.fullName, age: l.age, ambition: l.ambition,
                                achieved: l.ambition.achieved(l), score: score, rank: rank,
                                epitaph: epitaph, generation: l.generation, date: Date())
        hallOfFame.append(record)
        hallOfFame.sort { $0.score > $1.score }
        if hallOfFame.count > 30 {
            hallOfFame = Array(hallOfFame.prefix(30))
        }

        toast = nil
        expandedCardID = nil
        hand = []
        phase = .summary
        save()
    }

    /// Up to 3 distinct heirlooms: an earned trait, cash, and a keepsake. Always at least 2.
    func makeHeirloomOptions() -> [Heirloom] {
        guard let l = life else {
            return [.money(10), .keepsake(.medal)]
        }
        var options: [Heirloom] = []

        let birthTrait = l.traits.first
        var inheritedTrait: Trait? = nil
        if case .trait(let t)? = l.heirloomReceived { inheritedTrait = t }
        var earned: Trait? = l.traits.last(where: { $0 != birthTrait && $0 != inheritedTrait })
        if earned == nil { earned = l.traits.last(where: { $0 != birthTrait }) }
        if earned == nil { earned = l.traits.last }
        if let t = earned {
            options.append(.trait(t))
        }

        options.append(.money(max(10, l.money / 4)))
        options.append(.keepsake(Keepsake.forStat(l.stats.highest)))

        // Ensure distinctness (cases differ, but stay defensive).
        var unique: [Heirloom] = []
        for o in options where !unique.contains(o) { unique.append(o) }
        return unique
    }

    // MARK: - Summary

    func pickHeirloom(_ h: Heirloom) {
        pendingHeirloom = h
        generation += 1
        life = nil
        hand = []
        heirloomOptions = []
        toast = nil
        expandedCardID = nil
        phase = .start
        shuffleBirthTrait()
        shuffleName()
        save()
    }

    func resetLineage() {
        Persistence.wipe()
        generation = 1
        surname = GameStore.randomSurname(excluding: surname)
        hallOfFame = []
        pendingHeirloom = nil
        life = nil
        hand = []
        heirloomOptions = []
        toast = nil
        expandedCardID = nil
        phase = .start
        rng = SeededRNG()
        shuffleBirthTrait()
        shuffleName()
        save()
    }

    // MARK: - Derived

    var scoreBreakdown: [(String, Int)] {
        guard let l = life else { return [] }
        let ambitionPoints = l.ambition.achieved(l) ? 300 : Int(l.ambition.progress(l) * 120)
        return [
            ("Age", l.age * 2),
            ("Stats", l.stats.total),
            ("Wealth", (l.money / 2).clamped(0...250)),
            ("Traits", l.traits.count * 10),
            ("Ambition", ambitionPoints),
        ]
    }

    var score: Int {
        scoreBreakdown.reduce(0) { $0 + $1.1 }
    }

    var rank: String {
        let s = score
        if s < 300 { return "A Footnote" }
        if s < 500 { return "A Decent Run" }
        if s < 700 { return "A Life Well Lived" }
        return "A Legend"
    }

    var epitaph: String {
        guard let l = life else { return "" }
        var parts: [String] = ["Here lies \(l.fullName), \(l.age)."]
        if let cause = l.deathCause { parts.append(cause.line) }
        let def = l.ambition.def
        parts.append(l.ambition.achieved(l) ? def.wonLine : def.lostLine)
        if let last = l.traits.last { parts.append(last.def.epitaph) }
        let words = parts.joined(separator: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.joined(separator: " ")
    }

    // MARK: - Persistence

    func save() {
        Persistence.save(SaveData(phase: phase, life: life, handIDs: hand.map { $0.id },
                                  generation: generation, surname: surname,
                                  pendingHeirloom: pendingHeirloom, hallOfFame: hallOfFame,
                                  rng: rng))
    }
}
