import Foundation
import Testing
@testable import Dealt

// Engine tests for Dealt. Every store is built with `persist: false`, so nothing touches disk,
// and every random path is driven by an explicit seed, so each test is deterministic.
//
// Note: Swift Testing also declares a `Trait` protocol, so the game's trait enum is written
// `Dealt.Trait` wherever it has to be named.

// MARK: - Fixtures

/// Every age at which a hand is dealt (DESIGN.md §9): Dawn steps 4, Bloom 3, Build 4, Harvest 4, Dusk 3.
private let dealtAges: [Int] = {
    var ages: [Int] = [0, 4, 8, 12, 15, 18, 21]
    ages.append(contentsOf: stride(from: 24, through: 44, by: 4))
    ages.append(contentsOf: stride(from: 48, through: 64, by: 4))
    ages.append(contentsOf: stride(from: 68, through: 104, by: 3))
    return ages
}()

/// A newborn built from a fixed seed, outside any store.
private func makeLife(seed: UInt64 = 1, name: String = "Tess", ambition: Ambition = .fortune,
                      trait: Dealt.Trait = .kind, generation: Int = 1) -> Life {
    var rng = SeededRNG(seed: seed)
    return Life.newborn(name: name, surname: "Tester", ambition: ambition, birthTrait: trait,
                        heirloom: nil, generation: generation, rng: &rng)
}

/// An in-memory store with a seeded life already started. Surname and birth trait are pinned
/// because the store otherwise picks them with the system RNG.
private func makeStore(seed: UInt64, ambition: Ambition = .fortune) -> GameStore {
    let store = GameStore(persist: false)
    store.surname = "Tester"
    store.birthTraitPreview = .kind
    store.startLife(name: "Tess", ambition: ambition, seed: seed)
    return store
}

/// Plays the current life to its end: open the first card, play a choice, live on.
/// Returns the number of chapters played. Stops after `maxTurns` even if the life is not over.
@discardableResult
private func playToEnd(_ store: GameStore, maxTurns: Int = 45,
                       pick: (Card, Int) -> Int = { _, _ in 0 }) -> Int {
    var turns = 0
    while store.phase != .summary && turns < maxTurns {
        if let card = store.hand.first {
            store.expand(card)
            store.choose(pick(card, turns))
        }
        store.continueLife()
        turns += 1
    }
    return turns
}

// MARK: - Stats

@Suite("Stats")
struct StatsTests {
    @Test func subscriptClampsTo0Through100() {
        var s = Stats(body: 50, mind: 50, heart: 50, bonds: 50)
        s[.body] = 150
        s[.mind] = -20
        s[.heart] += 30
        s[.bonds] -= 51
        #expect(s.body == 100)
        #expect(s.mind == 0)
        #expect(s.heart == 80)
        #expect(s.bonds == 0)
        #expect(s.total == 180)
    }

    @Test func applyAddsDeltasWithClamping() {
        var s = Stats(body: 95, mind: 40, heart: 70, bonds: 10)
        s.apply([.body: 10, .mind: 5, .heart: 40, .bonds: -70])
        #expect(s == Stats(body: 100, mind: 45, heart: 100, bonds: 0))
        s.apply([:])
        #expect(s == Stats(body: 100, mind: 45, heart: 100, bonds: 0))
    }

    @Test func highestPicksTheStrongestStat() {
        let s = Stats(body: 10, mind: 90, heart: 20, bonds: 30)
        #expect(s.highest == .mind)
    }
}

// MARK: - RNG

@Suite("SeededRNG")
struct RNGTests {
    @Test func sameSeedSameSequence() {
        var a = SeededRNG(seed: 42)
        var b = SeededRNG(seed: 42)
        var c = SeededRNG(seed: 43)
        var seqA: [UInt64] = []
        var seqB: [UInt64] = []
        var seqC: [UInt64] = []
        for _ in 0..<100 {
            seqA.append(a.next())
            seqB.append(b.next())
            seqC.append(c.next())
        }
        #expect(seqA == seqB)
        #expect(seqA != seqC)
    }

    @Test func isSplitMix64() {
        // Reference values for SplitMix64 from seed 0. Pins the algorithm so old saves replay identically.
        var r = SeededRNG(seed: 0)
        let expected: [UInt64] = [0xE220_A839_7B1D_CDAF, 0x6E78_9E6A_A1B9_65F4]
        var actual: [UInt64] = []
        for _ in expected { actual.append(r.next()) }
        #expect(actual == expected)
    }

    @Test func rollHonoursItsBounds() {
        var r = SeededRNG(seed: 7)
        var zeroHits = 0
        var hundredMisses = 0
        for _ in 0..<2000 {
            if r.roll(0) { zeroHits += 1 }
            if !r.roll(100) { hundredMisses += 1 }
        }
        #expect(zeroHits == 0)
        #expect(hundredMisses == 0)
    }

    @Test func weightedOnlyReturnsPresentItems() {
        var r = SeededRNG(seed: 9)
        let items: [(String, Int)] = [("a", 1), ("b", 5), ("c", 0), ("d", -3)]
        let allowed: Set<String> = ["a", "b", "c", "d"]
        var counts: [String: Int] = [:]
        for _ in 0..<4000 {
            let pick: String = r.weighted(items)
            counts[pick, default: 0] += 1
        }
        #expect(Set(counts.keys).isSubset(of: allowed))
        // Weight 5 should clearly beat weight 1.
        #expect((counts["b"] ?? 0) > (counts["a"] ?? 0))

        let single: [(Int, Int)] = [(17, 3)]
        for _ in 0..<50 {
            let pick: Int = r.weighted(single)
            #expect(pick == 17)
        }
    }

    @Test func codableRoundTripContinuesTheSequence() throws {
        var r = SeededRNG(seed: 123)
        _ = r.next()
        let data = try JSONEncoder().encode(r)
        var restored = try JSONDecoder().decode(SeededRNG.self, from: data)
        let fromRestored = restored.next()
        let fromOriginal = r.next()
        #expect(fromRestored == fromOriginal)
    }
}

// MARK: - Content integrity

@Suite("Content")
struct ContentTests {
    @Test func cardIDsAreUnique() {
        let ids = Content.all.map(\.id)
        #expect(!ids.isEmpty)
        #expect(Set(ids).count == ids.count)
        #expect(Content.byID.count == ids.count)
    }

    @Test func everyRealCardHasAtLeastTwoChoices() {
        for card in Content.all {
            if card.filler {
                #expect(!card.choices.isEmpty, "\(card.id) has no choices")
            } else {
                #expect(card.choices.count >= 2, "\(card.id) has \(card.choices.count) choice(s)")
            }
        }
    }

    @Test func ageRangesAreSane() {
        for card in Content.all {
            #expect(card.ages.lowerBound <= card.ages.upperBound, "\(card.id)")
            #expect(card.ages.lowerBound >= 0, "\(card.id) starts before birth")
            #expect(card.ages.upperBound <= 104, "\(card.id) ends after 104")
        }
    }

    @Test func gambleOddsAreBetween1And99() {
        for card in Content.all {
            for choice in card.choices {
                if let pct = choice.odds {
                    #expect((1...99).contains(pct), "\(card.id) / \(choice.label): \(pct)%")
                }
            }
        }
    }

    @Test func everyCardCoversADealtAge() {
        #expect(dealtAges.count == 31)
        #expect(dealtAges.last == 104)
        for card in Content.all {
            let covered = dealtAges.contains { card.ages.contains($0) }
            #expect(covered, "\(card.id) ages \(card.ages) are never dealt")
        }
    }

    @Test func everyAmbitionHasADefinition() {
        for ambition in Ambition.allCases {
            #expect(AmbitionDef.all.keys.contains(ambition), "missing AmbitionDef for .\(ambition.rawValue)")
        }
    }

    @Test func everyTraitHasADefinition() {
        for trait in Dealt.Trait.allCases {
            #expect(TraitDef.all.keys.contains(trait), "missing TraitDef for .\(trait.rawValue)")
        }
    }

    @Test func fillersExistForEveryStage() {
        for stage in Stage.allCases {
            #expect(!Content.fillers(for: stage).isEmpty, "no fillers for \(stage.rawValue)")
        }
    }
}

// MARK: - Effects and rendering

@Suite("Effects and text")
struct EffectTests {
    @Test func deltaChipsFollowArgumentOrder() {
        let e = Effect(body: 5, heart: -3, money: -4, income: 20, add: [.charmer], remove: [.loner],
                       text: "x", dies: true)
        #expect(e.deltaChips == [
            "+5 Body", "-3 Heart", "-$4k", "Income $20k/yr",
            "✨ \(Dealt.Trait.charmer.def.name)", "✖️ \(Dealt.Trait.loner.def.name)", "🪦 Fatal",
        ])
        #expect(Effect(money: 7, text: "").deltaChips == ["+$7k"])
        #expect(Effect(body: 0, text: "").stats.isEmpty)
        #expect(Effect(text: "").deltaChips.isEmpty)
    }

    @Test func applyReportsActualClampedChanges() {
        let store = makeStore(seed: 7)
        var life = makeLife()
        life.stats = Stats(body: 98, mind: 3, heart: 50, bonds: 50)
        life.money = -995
        life.income = 10
        let chips = store.apply(Effect(body: 10, mind: -10, money: -10, text: "x"), to: &life)
        #expect(chips == ["+2 Body", "-3 Mind", "-$4k"])
        #expect(life.stats.body == 100)
        #expect(life.stats.mind == 0)
        #expect(life.money == -999)
    }

    @Test func incomeIsSetAndWorkaholicAddsFive() {
        let store = makeStore(seed: 8)
        var life = makeLife()
        life.income = 10
        let chips = store.apply(Effect(add: [.workaholic], text: ""), to: &life)
        #expect(life.income == 15)
        #expect(chips == ["Income $15k/yr", "✨ \(Dealt.Trait.workaholic.def.name)"])

        let set = store.apply(Effect(income: 30, text: ""), to: &life)
        #expect(life.income == 30)
        #expect(set == ["Income $30k/yr"])

        _ = store.apply(Effect(income: -5, text: ""), to: &life)
        #expect(life.income == 0)
    }

    @Test func renderFillsPlaceholders() {
        var life = Life(name: "Tess", surname: "Tester", age: 30,
                        stats: Stats(body: 50, mind: 50, heart: 50, bonds: 50),
                        money: 0, income: 0, traits: [], flags: [], ambition: .hearth, turn: 0,
                        playedCardIDs: [], cooldown: [:], history: [], alive: true, deathCause: nil,
                        heirloomReceived: nil, generation: 1)
        #expect(life.render("No placeholders here.") == "No placeholders here.")
        #expect(life.render("Hi {name}.") == "Hi Tess.")
        #expect(life.render("{spouse}") == "your partner")
        #expect(life.render("{kid}") == "the kid")
        #expect(life.render("{kids}") == "the kids")

        life.spouseName = "Mei"
        life.kidNames = ["Ezra"]
        #expect(life.render("{spouse} and {name}") == "Mei and Tess")
        #expect(life.render("{kid}") == "Ezra")
        #expect(life.render("{kids}") == "Ezra")

        life.kidNames = ["Ezra", "Nia", "Luca"]
        #expect(life.render("{kids}") == "Ezra, Nia and Luca")
        #expect(life.render("{kid} leads {kids}") == "Ezra leads Ezra, Nia and Luca")
    }

    @Test func renderedCardKeepsIdentityAndFillsText() {
        let card = Card.make("test_render", 20...30, "🎯", "{name}'s day", "{spouse} waits.", [
            .sure("Call {kid}", Effect(heart: 1, text: "{kids} answer.")),
            .sure("Stay in", Effect(text: "Quiet.")),
        ])
        var life = makeLife()
        life.spouseName = "Mei"
        life.kidNames = ["Ezra", "Nia"]
        let r = card.rendered { life.render($0) }
        #expect(r.id == "test_render")
        #expect(r.ages == 20...30)
        #expect(r.title == "Tess's day")
        #expect(r.body == "Mei waits.")
        #expect(r.choices[0].label == "Call Ezra")
        if case .sure(let e) = r.choices[0].outcome {
            #expect(e.text == "Ezra and Nia answer.")
            #expect(e.stats[.heart] == 1)
        } else {
            Issue.record("rendered choice lost its outcome kind")
        }
    }
}

// MARK: - Dealing

@Suite("Dealing")
struct DealTests {
    @Test func dealHandAlwaysYieldsThreeDistinctCards() {
        let ages = [0, 4, 8, 12, 21, 24, 44, 48, 64, 68, 89, 101, 104]
        let ambitions = Ambition.allCases
        let traits = Dealt.Trait.allCases
        for seed in 0..<200 {
            let store = makeStore(seed: UInt64(seed))
            for age in ages {
                var life = makeLife(seed: UInt64(seed), ambition: ambitions[seed % ambitions.count],
                                    trait: traits[seed % traits.count])
                life.age = age
                store.life = life
                store.dealHand()
                let ids = store.hand.map(\.id)
                #expect(ids.count == 3, "seed \(seed), age \(age): \(ids)")
                #expect(Set(ids).count == ids.count, "seed \(seed), age \(age): duplicate in \(ids)")
                let playable = store.hand.allSatisfy { $0.filler || $0.eligible(for: life) }
                #expect(playable, "seed \(seed), age \(age): ineligible card in \(ids)")
            }
        }
    }

    @Test func startLifeDealsAFirstHand() throws {
        let store = makeStore(seed: 1)
        let life = try #require(store.life)
        #expect(store.phase == .playing)
        #expect(life.age == 0)
        #expect(life.name == "Tess")
        #expect(life.surname == "Tester")
        #expect(life.traits.first == .kind)
        #expect(store.hand.count == 3)
    }

    @Test func blankNameFallsBackToSuggestedName() throws {
        let store = GameStore(persist: false)
        store.suggestedName = "Wren"
        store.startLife(name: "   ", ambition: .elder, seed: 4)
        let life = try #require(store.life)
        #expect(life.name == "Wren")
    }
}

// MARK: - Whole lives

@Suite("Lives")
struct LifeTests {
    @Test func fullLivesTerminateCleanly() {
        for seed in 0..<100 {
            let store = makeStore(seed: UInt64(seed), ambition: Ambition.base[seed % Ambition.base.count])
            let turns = playToEnd(store)
            #expect(store.phase == .summary, "seed \(seed): still alive after \(turns) turns")
            #expect(turns <= 45)
            guard let life = store.life else {
                Issue.record("seed \(seed): no life on the summary screen")
                continue
            }
            #expect(!life.alive, "seed \(seed)")
            #expect(life.deathCause != nil, "seed \(seed)")
            #expect(life.age <= 104, "seed \(seed): age \(life.age)")
            #expect(store.score >= 0, "seed \(seed): score \(store.score)")
            #expect(!store.epitaph.isEmpty, "seed \(seed)")
            #expect((2...3).contains(store.heirloomOptions.count), "seed \(seed): \(store.heirloomOptions)")
            #expect(store.lineage.count == 1, "seed \(seed)")
            #expect(store.hallOfFame.count == 1, "seed \(seed)")
            #expect(store.hand.isEmpty, "seed \(seed)")
            #expect(store.achievements.contains(.firstLife), "seed \(seed)")
        }
    }

    @Test func sameSeedAndChoicesGiveTheSameLife() throws {
        let pattern: (Card, Int) -> Int = { card, turn in turn % max(1, card.choices.count) }
        for seed: UInt64 in [3, 99, 2026] {
            let a = makeStore(seed: seed)
            let b = makeStore(seed: seed)
            #expect(a.hand.map(\.id) == b.hand.map(\.id))
            playToEnd(a, pick: pattern)
            playToEnd(b, pick: pattern)
            let la = try #require(a.life)
            let lb = try #require(b.life)
            #expect(la.age == lb.age, "seed \(seed)")
            #expect(a.score == b.score, "seed \(seed)")
            #expect(la.history.map(\.title) == lb.history.map(\.title), "seed \(seed)")
            #expect(la.history.map(\.choice) == lb.history.map(\.choice), "seed \(seed)")
            #expect(la.stats == lb.stats, "seed \(seed)")
            #expect(la.money == lb.money, "seed \(seed)")
            #expect(la.deathCause == lb.deathCause, "seed \(seed)")
        }
    }

    @Test func driftAdvancesTimeWithoutACard() throws {
        let store = makeStore(seed: 31)
        let before = try #require(store.life)
        store.drift()
        let after = try #require(store.life)
        #expect(after.age == before.age + Stage.dawn.yearsPerTurn)
        #expect(after.turn == before.turn + 1)
        #expect(after.history.last?.title == "Drifted")
        #expect(store.hand.count == 3)
    }
}

// MARK: - Daily Challenge

@Suite("Daily")
struct DailyTests {
    @Test func dailyIsTheSameForEveryone() throws {
        let a = GameStore(persist: false)
        let b = GameStore(persist: false)
        a.startDaily()
        b.startDaily()
        let la = try #require(a.life)
        let lb = try #require(b.life)
        #expect(la.name == lb.name)
        #expect(la.surname == lb.surname)
        #expect(la.ambition == lb.ambition)
        #expect(la.traits == lb.traits)
        #expect(la.stats == lb.stats)
        #expect(a.hand.map(\.id) == b.hand.map(\.id))
        #expect(a.hand.count == 3)
        #expect(la.isDaily)
        #expect(la.dailyKey == a.todayKey)
        #expect(Ambition.base.contains(la.ambition))
        #expect(la.traits.count == 1)
    }

    @Test func dailyLifeStaysOutOfTheFamilyLine() throws {
        let store = GameStore(persist: false)
        store.startDaily()
        let key = try #require(store.life?.dailyKey)
        playToEnd(store)
        #expect(store.phase == .summary)
        #expect(store.heirloomOptions.isEmpty)
        #expect(store.lineage.isEmpty)
        #expect(store.generation == 1)
        let best = try #require(store.dailyBest[key])
        #expect(best == store.score)
        #expect(store.achievements.contains(.dailyGrind))
        #expect(store.hallOfFame.first?.daily == true)

        // Heirlooms are ignored for a daily life.
        store.pickHeirloom(.money(10))
        #expect(store.phase == .summary)
        #expect(store.pendingHeirloom == nil)

        store.finishDaily()
        #expect(store.phase == .start)
        #expect(store.life.map { _ in true } == nil)
        #expect(store.hand.isEmpty)
        #expect(store.generation == 1)
        #expect(store.lineage.isEmpty)
    }

    @Test func dailyKeyAndSeedAreStable() throws {
        let cal = Calendar(identifier: .gregorian)
        let date = try #require(cal.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 12)))
        #expect(Daily.key(for: date) == "2026-03-07")
        // FNV-1a 64-bit reference values.
        let offsetBasis: UInt64 = 0xCBF2_9CE4_8422_2325
        let hashOfA: UInt64 = 0xAF63_DC4C_8601_EC8C
        #expect(Daily.seed(for: "") == offsetBasis)
        #expect(Daily.seed(for: "a") == hashOfA)
        #expect(Daily.seed(for: "2026-03-07") != Daily.seed(for: "2026-03-08"))
    }
}

// MARK: - Family

@Suite("Family")
struct FamilyTests {
    @Test func marriageNamesASpouseAndDivorceClearsIt() throws {
        let store = makeStore(seed: 11)
        var life = makeLife()
        #expect(life.spouseName == nil)

        let chips = store.apply(Effect(set: ["married"], text: "Wed."), to: &life)
        let spouse = try #require(life.spouseName)
        #expect(spouse != life.name)
        #expect(Names.first.contains(spouse))
        #expect(chips.contains("💍 \(spouse)"))

        // Marrying again while married keeps the same spouse and emits no ring chip.
        let again = store.apply(Effect(set: ["married"], text: ""), to: &life)
        let ringAgain = again.contains { $0.hasPrefix("💍") }
        #expect(life.spouseName == spouse)
        #expect(!ringAgain)

        _ = store.apply(Effect(clear: ["married"], text: "Divorced."), to: &life)
        #expect(!life.has(flag: "married"))
        #expect(life.spouseName == nil)
    }

    @Test func kidsGetOneToThreeDistinctNames() throws {
        for seed: UInt64 in 0..<30 {
            let store = makeStore(seed: seed)
            var life = makeLife(seed: seed)
            _ = store.apply(Effect(set: ["married"], text: ""), to: &life)
            let spouse = try #require(life.spouseName)
            let chips = store.apply(Effect(set: ["kids"], text: ""), to: &life)
            #expect((1...3).contains(life.kidNames.count), "seed \(seed): \(life.kidNames)")
            #expect(Set(life.kidNames).count == life.kidNames.count, "seed \(seed): \(life.kidNames)")
            #expect(!life.kidNames.contains(life.name), "seed \(seed)")
            #expect(!life.kidNames.contains(spouse), "seed \(seed)")
            #expect(chips.contains("👶 " + life.kidNames.joined(separator: ", ")), "seed \(seed): \(chips)")

            // A second "kids" effect does not rename them.
            let names = life.kidNames
            _ = store.apply(Effect(set: ["kids"], text: ""), to: &life)
            #expect(life.kidNames == names, "seed \(seed)")
        }
    }
}

// MARK: - Achievements

@Suite("Achievements")
struct AchievementTests {
    @Test func firstLifeIsAlwaysEarned() {
        var life = makeLife()
        life.stats = Stats(body: 10, mind: 10, heart: 10, bonds: 10)
        let earned = Achievement.earned(by: life)
        #expect(earned.contains(.firstLife))
        #expect(!earned.contains(.polymath))
        #expect(!earned.contains(.dailyGrind))
    }

    @Test func dynastyNeedsTheThirdGenerationOutsideTheDaily() {
        var life = makeLife()
        for generation in 1...2 {
            life.generation = generation
            #expect(!Achievement.earned(by: life).contains(.dynasty), "generation \(generation)")
        }
        life.generation = 3
        #expect(Achievement.earned(by: life).contains(.dynasty))
        life.generation = 5
        #expect(Achievement.earned(by: life).contains(.dynasty))

        life.dailyKey = "2026-01-01"
        let daily = Achievement.earned(by: life)
        #expect(!daily.contains(.dynasty))
        #expect(daily.contains(.dailyGrind))
    }

    @Test func otherMilestones() {
        var life = makeLife()
        life.age = 100
        life.money = 1000
        life.deathCause = .card
        life.stats = Stats(body: 70, mind: 70, heart: 70, bonds: 70)
        let earned = Achievement.earned(by: life)
        #expect(earned.contains(.centenarian))
        #expect(earned.contains(.millionaire))
        #expect(earned.contains(.wentOutSwinging))
        #expect(earned.contains(.polymath))
        #expect(earned.contains(.dreamCameTrue))   // Fortune: $1M+
    }

    @Test func unlockingAmbitions() {
        let store = GameStore(persist: false)
        for ambition in Ambition.base {
            #expect(store.isUnlocked(ambition), "\(ambition.rawValue)")
        }
        #expect(!store.isUnlocked(.legacy))
        #expect(!store.isUnlocked(.thrill))
        store.achievements.insert(.dynasty)
        #expect(store.isUnlocked(.legacy))
        #expect(!store.isUnlocked(.thrill))
        #expect(Achievement.dynasty.unlocks == .legacy)
        #expect(Achievement.dicey.unlocks == .thrill)
        #expect(Achievement.firstLife.unlocks == nil)
    }

    @Test func lockedAmbitionFallsBackToFortune() throws {
        let locked = GameStore(persist: false)
        locked.startLife(name: "Tess", ambition: .legacy, seed: 5)
        let lockedLife = try #require(locked.life)
        #expect(lockedLife.ambition == .fortune)

        let unlocked = GameStore(persist: false)
        unlocked.achievements.insert(.dynasty)
        unlocked.startLife(name: "Tess", ambition: .legacy, seed: 5)
        let unlockedLife = try #require(unlocked.life)
        #expect(unlockedLife.ambition == .legacy)
    }
}

// MARK: - Heirlooms

@Suite("Heirlooms")
struct HeirloomTests {
    @Test func pickingAnHeirloomStartsTheNextGeneration() throws {
        let store = makeStore(seed: 21)
        var life = try #require(store.life)
        life.flags.insert("kids")
        life.kidNames = ["Ezra", "Nia"]
        store.life = life
        store.endLife(cause: .oldAge)
        #expect(store.phase == .summary)

        let options = store.heirloomOptions
        #expect((2...3).contains(options.count))
        #expect(Set(options).count == options.count)
        let pick = try #require(options.first)

        store.pickHeirloom(pick)
        #expect(store.phase == .start)
        #expect(store.generation == 2)
        #expect(store.pendingHeirloom == pick)
        #expect(store.lineage.count == 1)
        #expect(store.lineage.last?.heirloomPassed == pick)
        #expect(store.lineage.last?.kidNames == ["Ezra", "Nia"])
        #expect(store.life.map { _ in true } == nil)
        #expect(["Ezra", "Nia"].contains(store.suggestedName))

        // The heir is born with the heirloom, and it is consumed.
        store.startLife(name: "", ambition: .fortune, seed: 22)
        let heir = try #require(store.life)
        #expect(["Ezra", "Nia"].contains(heir.name))
        #expect(heir.generation == 2)
        #expect(heir.heirloomReceived == pick)
        #expect(store.pendingHeirloom == nil)
        switch pick {
        case .trait(let t):
            #expect(heir.has(t))
        case .money(let n):
            #expect(heir.money == n)
        case .keepsake(let k):
            #expect(heir.has(flag: k.flag))
        }
    }

    @Test func heirloomOptionsCoverEachKind() throws {
        let store = makeStore(seed: 41)
        var life = try #require(store.life)
        life.traits.append(.artist)
        life.money = 400
        life.stats = Stats(body: 20, mind: 90, heart: 30, bonds: 40)
        store.life = life
        store.endLife(cause: .body)
        let expected: [Heirloom] = [.trait(.artist), .money(100), .keepsake(.ledger)]
        #expect(store.heirloomOptions == expected)
    }
}

// MARK: - Save format

@Suite("Save format")
struct SaveFormatTests {
    @Test func lifeDecodesSavesFromBeforeFamilyFields() throws {
        var life = makeLife()
        life.spouseName = "Mei"
        life.kidNames = ["Ezra"]
        life.gamblesWon = 4
        life.dailyKey = "2026-01-01"
        let data = try JSONEncoder().encode(life)

        let full = try JSONDecoder().decode(Life.self, from: data)
        #expect(full.spouseName == "Mei")
        #expect(full.kidNames == ["Ezra"])
        #expect(full.gamblesWon == 4)
        #expect(full.dailyKey == "2026-01-01")
        #expect(full.stats == life.stats)

        let object = try JSONSerialization.jsonObject(with: data)
        var dict = try #require(object as? [String: Any])
        for key in ["spouseName", "kidNames", "gamblesWon", "dailyKey"] { dict[key] = nil }
        let old = try JSONSerialization.data(withJSONObject: dict)
        let legacy = try JSONDecoder().decode(Life.self, from: old)
        #expect(legacy.spouseName == nil)
        #expect(legacy.kidNames.isEmpty)
        #expect(legacy.gamblesWon == 0)
        #expect(legacy.dailyKey == nil)
        #expect(legacy.name == life.name)
    }
}
