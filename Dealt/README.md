# Dealt

**Life deals you three cards a chapter. Play one. Live with it.**

A small life-simulation game for iPhone, built with SwiftUI. No dependencies, no image assets, no network.

## How it plays

- **Start a life:** pick a name, reroll your birth trait and choose one of six **Ambitions**: Fortune, Renown, Hearth, Scholar, Wanderer or Elder. The ambition shapes your deck and most of your final score.
- **Each chapter (3–4 years):** you're dealt **three cards**. Open one to see its 2–3 choices; gamble choices show their odds (🎲 60%). Play exactly one card, or **let the years drift** (−3 Heart).
- **Stats:** Body, Mind, Heart and Bonds (0–100), plus money and yearly income. Age, loneliness and your traits wear them down each chapter.
- **Traits** (16 of them) are earned through choices. They unlock or lock cards, shift the per-chapter drift and change gamble luck, so two lives see different decks.
- **Life stages:** Dawn 🌱 → Bloom 🌸 → Build 🏗️ → Harvest 🍂 → Dusk 🕯️. Each stage has its own colour theme and card pool.
- **Death and legacy:** a life ends with a tombstone, an epitaph, a score and a rank. You then pass one **heirloom** to your heir: a trait, some cash, or a keepsake that unlocks a secret card. The family name carries on, and the Hall of Fame keeps your best lives.
- **A named family:** marry and you get a spouse with a name; have kids and they're named too. Family cards use those names, and your heir defaults to one of your kids. The **family tree** shows every generation and what each one passed down.
- **Achievements:** 12 to collect. **Dynasty** (reach the third generation) unlocks the **Legacy** 🌳 ambition, and **Dicey** (win 5 gambles in one life) unlocks **Thrill** 🎢.
- **Daily challenge:** one seeded life per day, the same for every player. It sits outside your family line, and your best score for the day is saved.
- **Share your epitaph:** the tombstone renders to an image you can share from the summary screen.

A full run takes 5–10 minutes. The game saves automatically after every action. A 3-step tutorial runs on your first life, and the **?** button on the Play screen reopens it.

## How it differs from BitLife

| BitLife | Dealt |
|---|---|
| "Age +1" button, one year per tap | Chapters of 3–4 years; one decision per chapter |
| Menus for jobs, assets, activities | No menus: everything arrives as a card |
| Random popups | You pick which card to play, and which to skip |
| Open-ended sandbox | An Ambition gives each run a goal, a score and an epitaph |
| Each life stands alone | Lives form a lineage linked by heirlooms |

## Build

Requirements: Xcode 16 or later, iOS 17 or later.

1. Open `Dealt/Dealt.xcodeproj`.
2. Choose your Team under *Signing & Capabilities* (bundle id `com.programmx.dealt`).
3. Run on an iPhone or a simulator.
4. Run the tests with ⌘U (scheme *Dealt*). `DealtTests/` holds the engine tests; `DealtUITests/` holds a UI smoke test that plays a whole life through the real screens.

CI (`.github/workflows/dealt-ios.yml`) builds and runs both test targets on Xcode 16 / iOS 18 and Xcode 26 / iOS 26. Each run uploads the UI test's screenshots as an artifact.

The project uses a synchronized folder, so any `.swift` file added to `Dealt/Dealt/` is compiled automatically.

## Code map

| File | Role |
|---|---|
| `Models.swift` | Stats, stages, traits, ambitions, heirlooms, `Life`, records |
| `Cards.swift` | Card / Cond / Choice / Effect schema and the `Content` registry |
| `Support.swift` | Seeded RNG (SplitMix64), JSON save file, haptics |
| `GameStore.swift` | `@Observable` engine: deal, resolve, time, death, score, legacy |
| `DealtApp.swift` | App entry point and root router |
| `Theme.swift` | Stage palettes and shared components (stat ring, card face, chips) |
| `StartView.swift` / `PlayView.swift` / `SummaryView.swift` | The three screens, plus the Hall of Fame sheet |
| `Achievements.swift` | The 12 achievements, unlock rules, Daily Challenge key and seed |
| `AchievementsView.swift` / `FamilyTreeView.swift` | Achievements sheet and family tree sheet |
| `ContentCore.swift` | Trait and ambition tables, names, filler cards, keepsake cards |
| `ContentEarly.swift` / `ContentBuild.swift` / `ContentLate.swift` / `ContentExtra.swift` | 167 cards across all stages, family events and 8 ambitions |
| `DealtTests/DealtTests.swift` | 40 engine tests (Swift Testing), run with ⌘U |
| `DealtUITests/DealtUITests.swift` | UI smoke test: start → tutorial → play until death → heirloom → next generation |

`DESIGN.md` has the full design spec and the balance notes.

## Adding cards

```swift
.make("build_example", 24...40, "🎯", "Title", "Body text, under 140 characters.",
      weight: 3, cond: Cond(min: [.mind: 60], noFlags: ["married"]), [
    .sure("Safe choice", Effect(heart: 5, money: -2, text: "What happened.")),
    .gamble("Risky choice", 55,
        win: Effect(mind: 10, set: ["published"], text: "It worked."),
        lose: Effect(heart: -8, text: "It did not."))]),
```

Card text can use `{spouse}`, `{kid}`, `{kids}` and `{name}`; the engine fills them in from the current life. Swift requires arguments in declaration order. For `Effect` that order is `body, mind, heart, bonds, money, income, add, remove, set, clear, text, dies`. Hands are only dealt at certain ages (see `DESIGN.md` §9), so each card's age range must include at least one of them.

## Tooling (no Mac needed)

```sh
pip install tree-sitter tree-sitter-language-pack
python3 tools/swiftcheck.py Dealt      # Swift syntax check (tree-sitter)
python3 tools/argcheck.py Dealt        # argument-order check for Effect / Cond / make
python3 tools/contentlint.py Dealt     # ids, age coverage, flags, traits
python3 tools/simulate.py Dealt 3000   # balance: plays thousands of lives with the real content
```
