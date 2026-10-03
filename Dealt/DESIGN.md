# DEALT — Design & Build Spec (iOS 17+, SwiftUI, zero deps)

**Bundle id:** `com.programmx.dealt`  **Target:** 13 Swift files, ~3,400 lines incl. content.

---

## 1. Pitch & Differentiators

**DEALT** — *Life deals you three cards a chapter. Play one. Live with it.*

Differentiators vs BitLife:
1. **Draft, don't click:** every turn you are dealt a hand of 3 life-cards and must play exactly one (or let the years drift). No "Age +1" button, no menus, no random popups. Choosing which card to *skip* is as strategic as the choice inside it.
2. **Chapters, not years:** a turn is 3-4 years. A full life is ~22-28 turns, so a run fits in 5-10 minutes and every decision matters.
3. **Ambition-shaped runs:** you pick one of 6 Ambitions at birth. It injects dedicated cards into your deck, has a concrete win condition, and dominates the final score and epitaph.
4. **Earned traits mutate the deck:** 16 traits gate/unlock cards and tweak per-turn drift and gamble odds. Two lives with different traits see visibly different decks.
5. **Legacy line:** at death you pick one Heirloom (a trait, cash, or a keepsake that unlocks secret cards) for the next generation, who shares your surname. A Hall of Fame keeps the lineage's best epitaphs.

---

## 2. Core Loop

**Life stages** (age bands drive turn length, theme color, deck pool, cost of living):

| Stage | Ages | Years/turn | Turns | Cost of living (k/yr) | Color |
|---|---|---|---|---|---|
| Dawn 🌱 | 0-11 | 4 | 3 (0,4,8) | 0 | mint `.green.opacity` tint |
| Bloom 🌸 | 12-23 | 3 | 4 (12,15,18,21) | 1 | coral/pink |
| Build 🏗️ | 24-47 | 4 | 6 (24..44) | 6 | blue |
| Harvest 🍂 | 48-67 | 4 | 5 (48..64) | 6 | amber/orange |
| Dusk 🕯️ | 68-104 | 3 | until death | 5 | indigo |

**One turn (what the player sees and taps):**
1. Header shows name, age, stage chip, ambition progress bar. Four stat rings (Body, Mind, Heart, Bonds) + money pill.
2. Bottom: a fan of **3 cards** (emoji + title + one-line teaser). A small text button "Let the years drift" sits under the fan.
3. Tap a card → it expands in place (spring) revealing the body text and 2-3 **choice buttons**. Gamble choices show odds as "🎲 60%". A back chevron collapses it.
4. Tap a choice → outcome resolves (gamble rolled with trait luck bonus) → **Outcome sheet** (medium detent): outcome text, delta chips (`+8 Heart`, `-$4k`, `✨ Charmer`), "Live on" button.
5. "Live on" → **time advances** (age ticks with numeric transition, stage color crossfades if it changed, drift applied, money settles) → mortality check → new hand slides in from the bottom. If dead → Summary screen.

**"Let the years drift":** no card played; Heart -3; time advances. Exists so a bad hand is a real decision, not a trap.

**Run end:** death from (a) Body ≤ 0, (b) a choice with `dies: true`, (c) old-age roll each Dusk turn: `risk% = (age - 64) * 2 + max(0, 50 - body) / 2`, clamped 0...95, (d) age ≥ 104 hard cap ("died of sheer stubbornness").

**Score:** `age*2 + stats.total + clamp(money/2, 0, 250) + traits.count*10 + (ambitionAchieved ? 300 : Int(progress*120))`. Rank: <300 "A Footnote", <500 "A Decent Run", <700 "A Life Well Lived", else "A Legend".

**Epitaph:** `"Here lies {name} {surname}, {age}. {causeLine} {ambitionLine} {traitLine}"` — causeLine from DeathCause, ambitionLine from `AmbitionDef.wonLine/lostLine`, traitLine from the last-earned trait's `epitaph`.

**Meta / Legacy:** on Summary, player picks 1 of 3 Heirlooms generated from the life: (1) one earned trait, (2) `max(10, money/4)` k, (3) a Keepsake chosen by the highest stat (body→medal, mind→ledger, heart→violin, bonds→letter). Next life: same surname, `generation += 1`, heirloom applied at birth. Keepsakes each unlock one secret card. Hall of Fame stores up to 30 `LifeRecord`s sorted by score.

---

## 3. Stats, Resources, Traits, Ambitions

**Stats** (Int, clamp 0...100). Start = base ± rng(0...10): Body 60, Mind 50, Heart 60, Bonds 60.
**Money** (Int, unit = $1k, displayed `$12k`, floor -999). Start 0. **Income** (Int k/yr, start 0, set by cards via `income:`).

**Per-turn drift** (applied in `advanceTime`, after card effect):
- Body: -2 if age ≥ 40; -5 if age ≥ 68. `.athlete` halves (integer division).
- Mind: -3 if age ≥ 72.
- Heart: -2 if Bonds < 30.
- Bonds: -2 if age ≥ 24 unless `.charmer`.
- Money: `+= (income - stage.costOfLiving + (frugal ? 3 : 0)) * yearsPerTurn`.
- Then each trait's `perTurn` delta. If money < -200, a `priority` "Debt" card is forced into slot 1 next hand.

**Traits** (`enum Trait`, 16). Birth pool (one random, shuffleable at Start): lucky, stubborn, bookworm, daredevil, kind, cynic.

| Trait | Emoji | perTurn | luck | Other |
|---|---|---|---|---|
| lucky | 🍀 | — | +10 | |
| stubborn | 🐗 | mind+1 | -5 | |
| bookworm | 📖 | mind+2, bonds-1 | — | unlocks study cards |
| daredevil | 🪂 | body-1 | — | unlocks risk cards |
| kind | 🧸 | bonds+1 | — | |
| cynic | 🙄 | heart-1, mind+1 | — | forbids some romance cards |
| charmer | 😏 | — | — | disables Bonds drift |
| frugal | 🪙 | — | — | cost of living -3 |
| workaholic | 💼 | heart-1 | — | income +5 applied when earned (one-time) |
| romantic | 💘 | heart+1 | — | unlocks love cards |
| loner | 🌑 | bonds-1, mind+1 | — | |
| artist | 🎨 | heart+1 | — | unlocks art cards |
| hustler | 🃏 | — | +5 on gambles with money ≠ 0 (simplify: +5 always) | |
| athlete | 🏃 | body+1 | — | halves Body drift |
| famous | 🌟 | bonds+1 | — | required by Renown; unlocks fame cards; +50 score handled via traits.count |
| haunted | 👻 | heart-2 | — | unlocks redemption cards; removed by them |

**Ambitions** (`enum Ambition`, 6). `achieved(Life) -> Bool`, `progress(Life) -> Double` (0...1):
1. **Fortune 💰** — money ≥ 500 at death. progress = money/500.
2. **Renown 🌟** — has `.famous` and Bonds ≥ 60. progress = (famous ? 0.5 : 0) + bonds/120.
3. **Hearth 🏡** — flags `married` + `kids` and Bonds ≥ 70. progress = conditions met / 3.
4. **Scholar 📚** — Mind ≥ 85 and flag `published`. progress = mind/170 + (published ? 0.5 : 0).
5. **Wanderer 🧭** — ≥ 4 flags with prefix `saw_` (saw_sea, saw_mountains, saw_city, saw_desert, saw_north, saw_ice). progress = n/4.
6. **Elder 🕯️** — age ≥ 90 at death with Heart ≥ 50. progress = age/90.

Each ambition has 4 dedicated cards (`cond.ambition`), 24 total.

**Flag conventions** (free strings, documented): `married, divorced, kids, degree, dropout, published, detention, debt, own_home, retired, famous_once, saw_*, lost_love, pet, heir_map, heir_violin, heir_ledger, heir_medal, heir_letter`.

---

## 4. Content Model

**Card** = id, age range, emoji, title, body (≤ 140 chars), weight 1-5, `once` (default true), `priority`, `filler`, `Cond`, 2-3 choices.
**Cond** = min/max stats, required/forbidden traits, required/forbidden flags, min/max money, ambition.
**Choice** = label + `Outcome`: `.sure(Effect)` or `.gamble(pct, win: Effect, lose: Effect)`. Gamble pct += trait luck, clamp 5...95.
**Effect** = stat deltas, money, optional income (sets, not adds), add/remove traits, set/clear flags, text, dies.

**Deck sizes** (104 total): Dawn 14, Bloom 18, Build 26, Harvest 18, Dusk 12, Ambition 24 (4 each), Keepsake 4, plus 3 **fillers per stage** (15, `filler: true`, `once: false`, no cond) used only to pad hands. Fillers are never shown unless < 3 real cards are eligible.

**Dealing:** eligible = all cards where `age ∈ range`, `cond` passes, not in `playedCardIDs` (if `once`), not in `cooldown` (ids skipped in the last 2 turns). Priority eligibles go first; remaining slots weighted-random without replacement; pad with stage fillers. Hand is always exactly 3 distinct ids.

**Sample cards (tone reference, written in the real builder syntax):**

```swift
.make("dawn_frog", 4...11, "🐸", "The Frog Situation",
  "You found a frog. It is now your frog. Your mother disagrees.", [
  .sure("Hide it in a shoebox", Effect(heart: 8, bonds: -3, set: ["pet"], text: "Three weeks of secret amphibian joy. Then: the smell.")),
  .sure("Release it, tearfully", Effect(heart: -2, mind: 4, add: [.kind], text: "It hopped away without looking back. Typical.")),
  .gamble("Sneak it into school", 50,
    win: Effect(bonds: 10, heart: 6, text: "Instant legend. Children chant your name."),
    lose: Effect(bonds: -5, heart: -4, set: ["detention"], text: "The frog landed in Mrs. Patel's tea. You are a cautionary tale now."))])

.make("bloom_band", 15...21, "🎸", "Garage Band",
  "Your friend owns a drum kit and no talent. He wants a bassist. You own neither bass nor talent.", weight: 4, [
  .sure("Join. Obviously.", Effect(heart: 10, bonds: 6, mind: -3, add: [.artist], text: "You are terrible together, and it is the best year of your life.")),
  .sure("Study instead", Effect(mind: 8, bonds: -4, text: "You ace the exam. Somewhere, a bassline goes unplayed."))])

.make("bloom_exam", 18...21, "🎓", "The Big Exam",
  "University wants a number. Your brain has a number. They may not be the same number.", priority: false, cond: Cond(noFlags: ["degree","dropout"]), [
  .gamble("Cram all night", 55, win: Effect(mind: 10, set: ["degree"], text: "You pass, powered by instant noodles and fear."),
    lose: Effect(heart: -8, body: -4, set: ["dropout"], text: "You fall asleep on the paper. The drool is graded.")),
  .sure("Skip it. Get a trade.", Effect(money: 10, income: 14, body: 3, set: ["dropout"], text: "Electrician's apprentice. Hands blistered, pockets lined.")),
  .sure("Bribe the bookworm", Effect(mind: 6, bonds: 4, money: -2, set: ["degree"], cond: nil, text: "Group study, you call it. Tutoring, she calls it."))])
// NOTE: Effect has no `cond` field — the last choice above should omit `cond: nil`. Shown here only to remind engineers that conditions live on Cards, never on Choices.

.make("build_offer", 24...40, "🏢", "The Offer",
  "A glass tower wants you. It pays well and smells like printer toner.", weight: 5, cond: Cond(needFlags: ["degree"]), [
  .sure("Take the desk", Effect(money: 5, income: 20, heart: -3, text: "You have a lanyard now. The lanyard has you.")),
  .sure("Take it and grind", Effect(income: 25, heart: -8, body: -4, add: [.workaholic], text: "Promoted twice. Nobody remembers your birthday, including you.")),
  .sure("Start your own thing", Effect(money: -15, income: 8, heart: 6, add: [.hustler], text: "A laptop, a logo, and the firm belief that this will work."))])

.make("build_dating", 24...44, "🥂", "Second Date",
  "They laughed at your joke. Not the good one. The one about the pelican.", cond: Cond(noTraits: [.cynic], noFlags: ["married"]), [
  .gamble("Propose. Wildly early.", 35, win: Effect(heart: 15, bonds: 12, set: ["married"], add: [.romantic], text: "They said yes. The pelican is in the vows."),
    lose: Effect(heart: -10, bonds: -6, set: ["lost_love"], text: "They said 'oh no'. The pelican is retired.")),
  .sure("Take it slow", Effect(heart: 5, bonds: 8, text: "Four years, one shared toothbrush holder. Progress."))])

.make("harvest_health", 48...64, "🩺", "The Check-Up",
  "The doctor says 'hmm' twice. That's one more hmm than you'd like.", weight: 5, cond: Cond(max: [.body: 45]), [
  .sure("Change everything", Effect(body: 14, heart: -4, money: -6, add: [.athlete], text: "Kale. Stairs. Smug 6am walks. It works, infuriatingly.")),
  .sure("Ignore it", Effect(heart: 4, body: -10, text: "You feel fine. 'Fine' is doing a lot of work in that sentence."))])

.make("dusk_grandkid", 68...95, "🧒", "The Visit",
  "A small person who shares your nose asks why you are so old.", cond: Cond(needFlags: ["kids"]), [
  .sure("Tell them everything", Effect(heart: 12, bonds: 8, mind: 2, text: "You lie about half of it. They will repeat all of it.")),
  .sure("Give them twenty bucks", Effect(money: -1, bonds: 3, text: "Transactional, but effective. They'll be back."))])

.make("amb_wander_boat", 18...60, "⛵", "A Leaky Boat, A Full Moon",
  "A stranger offers passage north. The boat has opinions about floating.", cond: Cond(ambition: .wanderer), [
  .gamble("Get in", 65, win: Effect(heart: 10, mind: 4, set: ["saw_north"], text: "Aurora overhead, bilge water underfoot. Worth it."),
    lose: Effect(body: -15, money: -5, set: ["saw_north"], text: "You arrive. Mostly. Your luggage didn't.")),
  .sure("Stay dry", Effect(heart: -4, text: "The moon sets. The stranger shrugs. You dream about it for a decade."))])
```

---

## 5. Swift Architecture (the contract)

### Files (13)
| File | Responsibility | ~Lines |
|---|---|---|
| `DealtApp.swift` | `@main`, creates `GameStore`, routes on `store.phase` | 40 |
| `Models.swift` | Stat, Stats, Stage, Trait, TraitDef, Ambition, AmbitionDef, Heirloom, Keepsake, Life, HistoryEntry, DeathCause, LifeRecord, Phase, OutcomeToast | 280 |
| `Cards.swift` | Card, Cond, Choice, Outcome, Effect, builders, `Content` registry | 170 |
| `GameStore.swift` | @Observable engine: deal, resolve, drift, death, score, epitaph, heirlooms, save triggers | 420 |
| `Support.swift` | `SeededRNG` (SplitMix64), `SaveData` + `Persistence`, `Haptic` helper, `Int.clamped` | 120 |
| `ContentCore.swift` | `TraitDef.all`, `AmbitionDef.all`, `Names`, `Epitaphs`, filler cards, keepsake cards | 260 |
| `ContentEarly.swift` | Dawn (14) + Bloom (18) cards | 420 |
| `ContentBuild.swift` | Build (26) cards | 340 |
| `ContentLate.swift` | Harvest (18) + Dusk (12) + Ambition (24) cards | 560 |
| `Theme.swift` | `Stage.palette`, `StatRing`, `DeltaChip`, `CardFace`, `PrimaryButton`, fonts | 200 |
| `StartView.swift` | New life setup + Hall of Fame sheet | 220 |
| `PlayView.swift` | Main screen: header, rings, hand, expanded card, outcome sheet | 330 |
| `SummaryView.swift` | Epitaph, timeline, score breakdown, heirloom pick | 220 |

### Models.swift
```swift
enum Stat: String, Codable, CaseIterable, Hashable { case body, mind, heart, bonds
  var label: String; var symbol: String /* SF: "figure.walk","brain.head.profile","heart.fill","person.2.fill" */; var color: Color }

struct Stats: Codable, Equatable {
  var body: Int, mind: Int, heart: Int, bonds: Int
  subscript(_ s: Stat) -> Int { get set }   // clamps 0...100 on set
  var total: Int
  mutating func apply(_ deltas: [Stat: Int])
  var highest: Stat
}

enum Stage: String, Codable, CaseIterable {
  case dawn, bloom, build, harvest, dusk
  static func of(age: Int) -> Stage
  var ages: ClosedRange<Int>          // 0...11, 12...23, 24...47, 48...67, 68...104
  var yearsPerTurn: Int               // 4,3,4,4,3
  var costOfLiving: Int               // 0,1,6,6,5
  var title: String; var emoji: String
}

enum Trait: String, Codable, CaseIterable, Hashable {
  case lucky, stubborn, bookworm, daredevil, kind, cynic, charmer, frugal,
       workaholic, romantic, loner, artist, hustler, athlete, famous, haunted
  static let birthPool: [Trait]
  var def: TraitDef { TraitDef.all[self]! }
}
struct TraitDef { let name: String; let emoji: String; let blurb: String
  let perTurn: [Stat: Int]; let luck: Int; let epitaph: String }

enum Ambition: String, Codable, CaseIterable, Hashable {
  case fortune, renown, hearth, scholar, wanderer, elder
  var def: AmbitionDef { AmbitionDef.all[self]! }
  func achieved(_ life: Life) -> Bool
  func progress(_ life: Life) -> Double   // 0...1
}
struct AmbitionDef { let name: String; let emoji: String; let blurb: String; let goalText: String
  let wonLine: String; let lostLine: String }

enum Keepsake: String, Codable, CaseIterable { case medal, ledger, violin, letter
  var emoji: String; var name: String; var flag: String /* "heir_medal" ... */ }
enum Heirloom: Codable, Hashable {
  case trait(Trait), money(Int), keepsake(Keepsake)
  var title: String; var emoji: String; var blurb: String }

struct HistoryEntry: Codable, Identifiable { let id: UUID; let age: Int; let emoji: String
  let title: String; let choice: String; let text: String }

enum DeathCause: String, Codable { case body, oldAge, card, cap
  var line: String }

struct Life: Codable {
  var name: String; var surname: String
  var age: Int; var stats: Stats; var money: Int; var income: Int
  var traits: [Trait]; var flags: Set<String>
  var ambition: Ambition
  var turn: Int
  var playedCardIDs: Set<String>
  var cooldown: [String: Int]        // cardID -> turn when it becomes eligible again
  var history: [HistoryEntry]
  var alive: Bool; var deathCause: DeathCause?
  var heirloomReceived: Heirloom?
  var generation: Int
  var stage: Stage { Stage.of(age: age) }
  func has(_ t: Trait) -> Bool; func has(flag: String) -> Bool
  var luck: Int                        // sum of traits' luck
  static func newborn(name: String, surname: String, ambition: Ambition, birthTrait: Trait,
                      heirloom: Heirloom?, generation: Int, rng: inout SeededRNG) -> Life
}

struct LifeRecord: Codable, Identifiable { let id: UUID; let name: String; let age: Int
  let ambition: Ambition; let achieved: Bool; let score: Int; let rank: String
  let epitaph: String; let generation: Int; let date: Date }

enum Phase: String, Codable { case start, playing, summary }

struct OutcomeToast: Identifiable, Equatable { let id = UUID(); let emoji: String; let title: String
  let text: String; let deltas: [String]; let died: Bool; let gambleWon: Bool? }
```

### Cards.swift
```swift
struct Cond {
  var min: [Stat: Int] = [:]; var max: [Stat: Int] = [:]
  var needTraits: [Trait] = []; var noTraits: [Trait] = []
  var needFlags: [String] = []; var noFlags: [String] = []
  var minMoney: Int? = nil; var maxMoney: Int? = nil
  var ambition: Ambition? = nil
  static let none = Cond()
  func passes(_ life: Life) -> Bool
}
struct Effect {
  var stats: [Stat: Int]; var money: Int; var income: Int?
  var add: [Trait]; var remove: [Trait]; var set: [String]; var clear: [String]
  var text: String; var dies: Bool
  init(body: Int = 0, mind: Int = 0, heart: Int = 0, bonds: Int = 0, money: Int = 0, income: Int? = nil,
       add: [Trait] = [], remove: [Trait] = [], set: [String] = [], clear: [String] = [],
       text: String, dies: Bool = false)
  var deltaChips: [String]     // "+8 Heart", "-$4k", "✨ Charmer", "Income $20k/yr"
}
enum Outcome { case sure(Effect); case gamble(pct: Int, win: Effect, lose: Effect) }
struct Choice { let label: String; let outcome: Outcome
  static func sure(_ label: String, _ e: Effect) -> Choice
  static func gamble(_ label: String, _ pct: Int, win: Effect, lose: Effect) -> Choice }
struct Card: Identifiable {
  let id: String; let ages: ClosedRange<Int>; let emoji: String; let title: String; let body: String
  let weight: Int; let once: Bool; let priority: Bool; let filler: Bool; let cond: Cond; let choices: [Choice]
  static func make(_ id: String, _ ages: ClosedRange<Int>, _ emoji: String, _ title: String, _ body: String,
                   weight: Int = 3, once: Bool = true, priority: Bool = false, filler: Bool = false,
                   cond: Cond = .none, _ choices: [Choice]) -> Card
  func eligible(for life: Life) -> Bool   // age ∈ ages && cond.passes && (!once || !played) && not cooling
}
enum Content {
  static let all: [Card]            // early + build + late + core.fillers + core.keepsakes, built lazily
  static let byID: [String: Card]
  static func fillers(for stage: Stage) -> [Card]
}
// Each content file exposes: `extension Content { static let dawn: [Card]; static let bloom: [Card] }` etc.
```

### Support.swift
```swift
struct SeededRNG: RandomNumberGenerator, Codable {
  var state: UInt64
  init(seed: UInt64); init()            // init() seeds from SystemRandomNumberGenerator
  mutating func next() -> UInt64        // SplitMix64
  mutating func roll(_ pct: Int) -> Bool
  mutating func pick<T>(_ a: [T]) -> T
  mutating func weighted<T>(_ items: [(T, Int)]) -> T
}
struct SaveData: Codable { var phase: Phase; var life: Life?; var handIDs: [String]
  var generation: Int; var surname: String; var pendingHeirloom: Heirloom?
  var hallOfFame: [LifeRecord]; var rng: SeededRNG }
enum Persistence {
  static let fileName = "dealt_save_v1.json"   // in .documentDirectory
  static func load() -> SaveData?              // nil on missing/corrupt
  static func save(_ data: SaveData)           // atomic write, ignores errors
  static func wipe() }
enum Haptic { static func tap(); static func success(); static func warning() }  // UIImpactFeedbackGenerator / UINotificationFeedbackGenerator
extension Comparable { func clamped(_ r: ClosedRange<Self>) -> Self }
```

### GameStore.swift
```swift
@Observable final class GameStore {
  var phase: Phase = .start
  var life: Life?
  var hand: [Card] = []
  var expandedCardID: String? = nil
  var toast: OutcomeToast? = nil
  var hallOfFame: [LifeRecord] = []
  var generation: Int = 1
  var surname: String
  var pendingHeirloom: Heirloom? = nil     // chosen at last death, applied to next birth
  var heirloomOptions: [Heirloom] = []     // computed at death
  var birthTraitPreview: Trait             // shown on StartView
  var suggestedName: String
  private(set) var rng: SeededRNG

  init()                                   // calls Persistence.load(); restores or defaults
  // Start
  func shuffleBirthTrait(); func shuffleName()
  func startLife(name: String, ambition: Ambition, seed: UInt64?)
  // Play
  func expand(_ card: Card?)               // nil collapses
  func choose(_ choiceIndex: Int)          // resolves outcome -> sets toast (does NOT advance time)
  func drift()                             // "let the years drift": Heart -3, then continueLife()
  func continueLife()                      // dismiss toast -> advanceTime -> death check -> dealHand or endLife
  // Summary
  func pickHeirloom(_ h: Heirloom)         // stores pendingHeirloom, phase = .start, generation += 1
  func resetLineage()                      // wipes save, generation = 1, new surname
  // Derived
  var score: Int; var rank: String; var epitaph: String
  var scoreBreakdown: [(String, Int)]
  // Internals (internal access, testable)
  func dealHand(); func advanceTime(); func checkDeath() -> DeathCause?
  func apply(_ e: Effect, to life: inout Life) -> [String]
  func endLife(cause: DeathCause); func makeHeirloomOptions() -> [Heirloom]
  func save()
}
```
Rules inside: `choose` appends a `HistoryEntry`, marks card played, puts the two unplayed ids on `cooldown = turn + 2`, applies effect, builds toast. `continueLife` is the only place time moves. `save()` after startLife, choose, continueLife, pickHeirloom, resetLineage. Seed: if `seed != nil` → `SeededRNG(seed:)`, else `SeededRNG()`; rng state is persisted so a restore continues deterministically.

---

## 6. UI Spec

**Global:** one `NavigationStack`-free root; `ZStack` switching on `phase` with `.transition(.opacity)`. Dark-mode friendly: backgrounds are `stage.palette.bg` (a `LinearGradient` of two tints over `Color(.systemBackground)`). Fonts: `.largeTitle.bold()` rounded design (`.fontDesign(.rounded)`) everywhere.

**StartView**
- Top: "DEALT" title + subtitle "Generation {n} · The {surname} line". Trophy button (top-right) opens Hall of Fame sheet.
- Name field with 🎲 shuffle. Birth trait chip (emoji + name, tap to shuffle). Heirloom card if `pendingHeirloom != nil`.
- Horizontal `ScrollView` of 6 ambition cards (emoji, name, goalText); selected = tinted border + scale 1.04.
- Optional "Seed" text field hidden behind a tiny gear icon (debug/replays).
- `PrimaryButton("Be born")`. Haptic.success on tap.
- Hall of Fame sheet: `List` of LifeRecords (rank, name, age, ambition emoji, score, epitaph), "Reset lineage" destructive button.

**PlayView (the one screen)**
- Header (HStack): name + surname, `Text(age).contentTransition(.numericText())`, stage chip (emoji + title in palette color).
- Ambition row: emoji + name + `ProgressView(value:)` tinted, small "goalText".
- Stat row: 4 `StatRing` (circular trim 0...1, value label, SF symbol), money pill (`$12k`, red if negative) + income (`+20/yr`).
- Hand: `HStack` of 3 `CardFace` (emoji 44pt, title, teaser = first sentence of body) with slight rotation (-6°, 0°, 6°) and y-offset; `.transition(.move(edge: .bottom).combined(with: .opacity))` keyed on `life.turn`.
- Tapping a card: `expandedCardID` set; expanded `CardFace` grows to full width with `.matchedGeometryEffect`, shows full body + `VStack` of choice buttons (gamble shows "🎲 60%"); the other two cards dim to 0.3 opacity. Chevron collapses.
- "Let the years drift" tertiary text button below the hand.
- Outcome: `.sheet(item: $store.toast)` with `.presentationDetents([.medium])`: emoji, title, text, `FlowLayout`-free `HStack`-wrapping delta chips (use `LazyVGrid` 3 columns), "Live on" button. If `died` → button reads "Rest". If gamble: green "Won the roll" / red "Lost the roll" caption.
- Haptics: `.sensoryFeedback(.impact(weight: .light), trigger: expandedCardID)`, `.sensoryFeedback(.success, trigger: toast?.gambleWon == true)`, `.sensoryFeedback(.warning, trigger: toast?.died)`, `.sensoryFeedback(.impact(weight: .medium), trigger: life?.turn)`.
- Animations: `withAnimation(.spring(duration: 0.45, bounce: 0.2))` for expand/collapse and hand swap; `.animation(.easeOut(duration: 0.6), value: stats)` on rings; `.animation(.easeInOut(duration: 0.8), value: stage)` on background.

**SummaryView**
- Tombstone card: rounded rect, 🪦, rank as headline, epitaph body, "{name} {surname} · {age}" footer; `scaleEffect` 0.8→1.0 spring on appear.
- Score breakdown rows (Age, Stats, Wealth, Traits, Ambition) with animated totals.
- Timeline: `ScrollView` of `HistoryEntry` rows ("{age} {emoji} {title} — {choice}").
- Heirloom pick: 3 option cards; tapping one is final → `pickHeirloom`. Title "Pass something on".
- Hall of Fame button.

**Theme.swift:** `extension Stage { var palette: (bg1: Color, bg2: Color, accent: Color) }` — dawn `.mint/.green`, bloom `.pink/.orange`, build `.blue/.cyan`, harvest `.orange/.yellow`, dusk `.indigo/.purple`. Components: `StatRing(stat:value:)`, `DeltaChip(text:)`, `CardFace(card:expanded:)`, `PrimaryButton(title:action:)`, `Chip(text:color:)`.

---

## 7. Xcode Project

```
Dealt/
  Dealt.xcodeproj/project.pbxproj     (objectVersion = 77, one PBXFileSystemSynchronizedRootGroup → "Dealt")
  Dealt/                              (all 13 .swift files flat, no subfolders needed)
```
Build settings: `IPHONEOS_DEPLOYMENT_TARGET = 17.0`, `SWIFT_VERSION = 5.9` (or 6.0 with `SWIFT_STRICT_CONCURRENCY = minimal`), `GENERATE_INFOPLIST_FILE = YES`, `INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait`, `PRODUCT_BUNDLE_IDENTIFIER = com.programmx.dealt`, `TARGETED_DEVICE_FAMILY = 1`, `ENABLE_PREVIEWS = YES`. No asset catalog is required (app icon absent is a warning, not an error); add an empty `Assets.xcassets` only if an icon is later wanted. No entitlements, no capabilities, no test target.

---

## 8. Balancing Notes & Edge Cases

**Balance targets:** average natural death ~78-86; Fortune reachable only with income ≥ 40 from Build onward or one big gamble; Elder ~25% success; Renown requires chaining 2 of the 4 fame cards. Card effect magnitudes: common ±4...±10 stat, gambles ±12...±18 with ≥ 55% odds unless clearly reckless. Money card range -20...+60 except two "jackpot" cards (+150, 20% odds). Fillers give ±2 and a flavor line only. Priority cards: `debt` (money < -200: income lost or body hit), `amb_*_final` for each ambition (fires once at Harvest to give a last shot), `dusk_fading` (Body < 20 in Dusk).

**Edge cases engineers must handle:**
1. Fewer than 3 eligible cards → pad with `Content.fillers(for: stage)`; never crash, never show duplicates (fillers are `once: false`).
2. `dies: true` or Body ≤ 0 from a card effect → toast shows "Rest" and `continueLife` goes straight to `endLife` without advancing time.
3. Money may go negative (floor -999); display red; `clamp(money/2, 0, 250)` in score prevents negative score.
4. Stats always clamped via `Stats` subscript setter; `Effect.apply` never writes directly.
5. `add` of an existing trait / `remove` of a missing trait is a no-op and produces no chip. `income:` sets, not adds.
6. Age cap 104 → `DeathCause.cap`. Mortality roll runs only at age ≥ 68, after drift, before dealing.
7. Restored save with stale `handIDs` (card id removed in a later build) → rebuild hand via `dealHand()`.
8. Corrupt or missing save → fresh state, no crash. `Persistence.save` is called off the main thread only if needed; file size is tiny, synchronous is acceptable.
9. Hall of Fame capped at 30, sorted by score desc; duplicate `LifeRecord.id` impossible (UUID).
10. Debug `assert(Set(Content.all.map(\.id)).count == Content.all.count)` to catch duplicate card ids across content files; prefix ids by file (`dawn_`, `bloom_`, `build_`, `harv_`, `dusk_`, `amb_`, `keep_`, `fill_`).
11. Gamble pct after luck must be clamped 5...95 so nothing is certain.
12. `expandedCardID` must reset to nil in `continueLife` and when phase changes.
13. Heirloom `.money(n)` adds to starting money; `.trait` must not duplicate the birth trait (if equal, upgrade to `.money(20)`); `.keepsake` sets its flag so its secret card becomes eligible.
14. Workaholic one-time income +5 applied in `apply()` when the trait is added (not per turn).

### Critical Files for Implementation
- /Dealt/Dealt/Models.swift — all shared types; must be written first and exactly as specified
- /Dealt/Dealt/Cards.swift — card schema, builders, `Content` registry that content files extend
- /Dealt/Dealt/GameStore.swift — the only mutable state owner; deal/resolve/drift/death/score
- /Dealt/Dealt/PlayView.swift — the single core screen
- /Dealt/Dealt/ContentCore.swift — trait/ambition tables, fillers, epitaph lines that everything else references

---

## 9. Implementation Contract Overrides (authoritative)

`Models.swift`, `Cards.swift` and `Support.swift` are already written and are the source of truth. Where they differ from the spec above, the code wins:

- **Swift argument order is strict.** `Effect(...)` labels must appear in exactly this order: `body, mind, heart, bonds, money, income, add, remove, set, clear, text, dies`. Several sample cards above are out of order (e.g. `Effect(heart: 8, bonds: -3, ...)` is fine, `Effect(heart: 10, bonds: 6, mind: -3, ...)` is NOT). `Cond(...)` order: `min, max, needTraits, noTraits, needFlags, noFlags, minMoney, maxMoney, ambition`. `Card.make` order: `id, ages, emoji, title, body, weight:, once:, priority:, filler:, cond:, [choices]`.
- Content pools are named: `Content.dawn`, `.bloom` (ContentEarly), `.build` (ContentBuild), `.harvest`, `.dusk`, `.ambitionCards` (ContentLate), `.fillerCards`, `.keepsakeCards` (ContentCore). Each declared as `extension Content { static let dawn: [Card] = [ ... ] }`.
- `ContentCore.swift` also declares `extension TraitDef { static let all: [Trait: TraitDef] }`, `extension AmbitionDef { static let all: [Ambition: AmbitionDef] }`, and `enum Names { static let first: [String]; static let surnames: [String] }`.
- `Ambition.progress` caps at 0.99 until achieved. `Keepsake.forStat(_:)` maps highest stat → keepsake. `Card.teaser` gives the first sentence. `Choice.odds` gives base gamble odds. `Life.fullName`.
- **Ages a hand is dealt at** (card `ages` ranges must cover at least one of these): Dawn 0, 4, 8 · Bloom 12, 15, 18, 21 · Build 24, 28, 32, 36, 40, 44 · Harvest 48, 52, 56, 60, 64 · Dusk 68, 71, 74, 77, 80, 83, 86, 89, 92, 95, 98, 101, 104.
- Swift language mode 5, iOS 17 deployment target.
