import Foundation

// MARK: - Traits

extension TraitDef {
    static let all: [Trait: TraitDef] = [
        .lucky: TraitDef(name: "Lucky", emoji: "🍀",
                         blurb: "The dice like you. Nobody knows why, least of all the dice.",
                         perTurn: [:], luck: 10,
                         epitaph: "Never once checked the odds, and never once needed to."),
        .stubborn: TraitDef(name: "Stubborn", emoji: "🐗",
                            blurb: "Wrong sometimes. Uncertain never.",
                            perTurn: [.mind: 1], luck: -5,
                            epitaph: "Never once read the instructions."),
        .bookworm: TraitDef(name: "Bookworm", emoji: "📖",
                            blurb: "Has a favorite footnote. Will tell you about it.",
                            perTurn: [.mind: 2, .bonds: -1], luck: 0,
                            epitaph: "Died as they lived: three chapters ahead of everyone else."),
        .daredevil: TraitDef(name: "Daredevil", emoji: "🪂",
                             blurb: "Hold my drink. Hold my other drink.",
                             perTurn: [.body: -1], luck: 0,
                             epitaph: "Said 'watch this' far more often than any doctor advised."),
        .kind: TraitDef(name: "Kind", emoji: "🧸",
                        blurb: "Remembers your dog's name. And your dog's birthday.",
                        perTurn: [.bonds: 1], luck: 0,
                        epitaph: "Left every room a little warmer than they found it."),
        .cynic: TraitDef(name: "Cynic", emoji: "🙄",
                         blurb: "Expects the worst and is rarely surprised, which is its own small reward.",
                         perTurn: [.mind: 1, .heart: -1], luck: 0,
                         epitaph: "Saw it all coming. Was not thrilled about it."),
        .charmer: TraitDef(name: "Charmer", emoji: "😏",
                           blurb: "Could sell a lighthouse to a fish.",
                           perTurn: [:], luck: 0,
                           epitaph: "Talked their way into everything, including this plot."),
        .frugal: TraitDef(name: "Frugal", emoji: "🪙",
                          blurb: "Still has the receipt. From 1994.",
                          perTurn: [:], luck: 0,
                          epitaph: "Took the cheaper coffin. Would have wanted it that way."),
        .workaholic: TraitDef(name: "Workaholic", emoji: "💼",
                              blurb: "Answers emails at weddings. Including their own.",
                              perTurn: [.heart: -1], luck: 0,
                              epitaph: "Finally took a day off."),
        .romantic: TraitDef(name: "Romantic", emoji: "💘",
                            blurb: "Falls hard, often, and in slow motion.",
                            perTurn: [.heart: 1], luck: 0,
                            epitaph: "Loved like it was a competitive sport."),
        .loner: TraitDef(name: "Loner", emoji: "🌑",
                         blurb: "Prefers the company of a locked door.",
                         perTurn: [.mind: 1, .bonds: -1], luck: 0,
                         epitaph: "Would have preferred a smaller funeral."),
        .artist: TraitDef(name: "Artist", emoji: "🎨",
                          blurb: "Sees colors that haven't been invoiced yet.",
                          perTurn: [.heart: 1], luck: 0,
                          epitaph: "Made beautiful things out of spite and glue."),
        .hustler: TraitDef(name: "Hustler", emoji: "🃏",
                           blurb: "Has a guy. Is also, somehow, the guy.",
                           perTurn: [:], luck: 5,
                           epitaph: "Got a great deal on the headstone."),
        .athlete: TraitDef(name: "Athlete", emoji: "🏃",
                           blurb: "Takes the stairs. Talks about taking the stairs.",
                           perTurn: [.body: 1], luck: 0,
                           epitaph: "Outran everything but the calendar."),
        .famous: TraitDef(name: "Famous", emoji: "🌟",
                          blurb: "Recognized in supermarkets, mostly by mistake.",
                          perTurn: [.bonds: 1], luck: 0,
                          epitaph: "Strangers wept. The family mostly checked their phones."),
        .haunted: TraitDef(name: "Haunted", emoji: "👻",
                           blurb: "Carries something heavy that nobody else can see.",
                           perTurn: [.heart: -2], luck: 0,
                           epitaph: "Finally put it down.")
    ]
}

// MARK: - Ambitions

extension AmbitionDef {
    static let all: [Ambition: AmbitionDef] = [
        .fortune: AmbitionDef(name: "Fortune", emoji: "💰",
                              blurb: "Money can't buy happiness, but it can rent a very convincing imitation.",
                              goalText: "Die with $500k+",
                              wonLine: "Died rich, exactly as planned.",
                              lostLine: "Died chasing a number that never picked up the phone."),
        .renown: AmbitionDef(name: "Renown", emoji: "🌟",
                             blurb: "Be known. Be liked. Ideally both, in that order.",
                             goalText: "Be famous with Bonds 60+",
                             wonLine: "The funeral sold out.",
                             lostLine: "Almost famous. The 'almost' did most of the work."),
        .hearth: AmbitionDef(name: "Hearth", emoji: "🏡",
                             blurb: "A full table, a loud house, somebody else's socks on the radiator.",
                             goalText: "Marry, raise kids, Bonds 70+",
                             wonLine: "Died surrounded, and slightly deafened, by family.",
                             lostLine: "Wanted a full house. Kept finding empty chairs."),
        .scholar: AmbitionDef(name: "Scholar", emoji: "📚",
                              blurb: "Know everything. Publish some of it. Correct the rest.",
                              goalText: "Mind 85+ and get published",
                              wonLine: "Died mid-footnote, and the footnote was correct.",
                              lostLine: "Knew a great deal. Wrote down too little of it."),
        .wanderer: AmbitionDef(name: "Wanderer", emoji: "🧭",
                               blurb: "Home is wherever the luggage got lost this time.",
                               goalText: "See 4 far-flung places",
                               wonLine: "Died with sand in every pocket.",
                               lostLine: "Had the map. Never quite caught the bus."),
        .elder: AmbitionDef(name: "Elder", emoji: "🕯️",
                            blurb: "Outlive your enemies, your rivals, and ideally your warranty.",
                            goalText: "Reach 90 with Heart 50+",
                            wonLine: "Died old, warm, and insufferably smug about it.",
                            lostLine: "Planned to see ninety. The calendar had other ideas.")
    ]
}

// MARK: - Names

enum Names {
    static let first: [String] = [
        "Amara", "Mateo", "Yuki", "Priya", "Tomasz", "Zainab", "Kwame", "Ingrid",
        "Rafael", "Mei", "Ezra", "Fatima", "Luca", "Nia", "Hiroshi", "Soraya",
        "Dmitri", "Aisha", "Kofi", "Elena", "Jun", "Leila", "Oscar", "Ananya",
        "Sven", "Imani", "Diego", "Sakura", "Tariq", "Freya", "Ravi", "Maya",
        "Emeka", "Hana", "Niall", "Rosa", "Arjun", "Beatriz", "Yusuf", "Wren"
    ]

    static let surnames: [String] = [
        "Okafor", "Nakamura", "Lindqvist", "Delgado", "Haddad", "Kowalski",
        "Mensah", "Fitzgerald", "Reyes", "Ivanova", "Bhattacharya", "Moreau",
        "Tanaka", "Osei", "Petrov", "Castellano", "Abernathy", "Nguyen",
        "Olufemi", "Brightwater", "Sorensen", "Quintero", "Marsh", "Adeyemi",
        "Walsh", "Kaur", "Ferreira", "Novak", "Blackwood", "Oyelaran"
    ]
}

// MARK: - Fillers (3 per stage, only ever used to pad a thin hand)

extension Content {
    static let fillerCards: [Card] = [
        // Dawn
        .make("fill_dawn_1", 0...11, "🌧️", "Rainy Afternoon",
              "Nothing happens. Rain on the window, a jigsaw with one piece missing, a very long Sunday.",
              weight: 1, once: false, filler: true, [
            .sure("Finish the jigsaw anyway", Effect(mind: 2, text: "Three hundred pieces of a lighthouse. Nearly. Close enough.")),
            .sure("Nap on the rug", Effect(body: 2, text: "You wake up with carpet on your face and no regrets."))]),
        .make("fill_dawn_2", 0...11, "🚗", "The Long Car Ride",
              "Four hours to an aunt's house. The back seat is warm, the radio is terrible, your sibling is touching you.",
              weight: 1, once: false, filler: true, [
            .sure("Count red cars", Effect(mind: 1, heart: 1, text: "Forty-one red cars. You will remember this number for no reason.")),
            .sure("Ask if we are there yet", Effect(heart: 2, bonds: -1, text: "You are not there yet. You ask again. Strategy."))]),
        .make("fill_dawn_3", 0...11, "🍪", "Grandma's Kitchen",
              "Flour everywhere, the radio humming, a bowl of batter that is technically not for you.",
              weight: 1, once: false, filler: true, [
            .sure("Steal a spoonful", Effect(body: -1, heart: 3, text: "Caught. Forgiven. Given a second spoonful. Grandmothers are like that.")),
            .sure("Help stir", Effect(bonds: 2, text: "Your arm aches. The cake is slightly lopsided and entirely yours."))]),
        // Bloom
        .make("fill_bloom_1", 12...23, "😑", "A Tuesday",
              "Nothing is happening and it is happening slowly. The ceiling has a crack shaped like a dog.",
              weight: 1, once: false, filler: true, [
            .sure("Scroll until midnight", Effect(mind: -1, heart: 1, text: "You learn nothing and feel vaguely seen. The dog crack remains.")),
            .sure("Go for a walk", Effect(body: 2, text: "Around the block twice. The second lap, you notice a cat. Progress."))]),
        .make("fill_bloom_2", 12...23, "💇", "The Haircut",
              "The hairdresser asks what you want. You have no idea. She is already cutting.",
              weight: 1, once: false, filler: true, [
            .sure("Something daring", Effect(heart: 2, bonds: -1, text: "It is a lot of fringe. It grows out. Eventually.")),
            .sure("The usual", Effect(bonds: 1, text: "Same as always. Your mother approves. A small, warm defeat."))]),
        .make("fill_bloom_3", 12...23, "📱", "The Group Chat",
              "Two hundred messages since lunch. Someone has changed the group name again.",
              weight: 1, once: false, filler: true, [
            .sure("Reply to everything", Effect(mind: -1, bonds: 2, text: "You are extremely present and slightly behind on homework.")),
            .sure("Mute it for a week", Effect(mind: 2, bonds: -1, text: "Silence. Then 900 messages. You read none of them. Freedom."))]),
        // Build
        .make("fill_build_1", 24...47, "🚇", "The Commute",
              "Same train, same carriage, same stranger reading the same unfinished novel.",
              weight: 1, once: false, filler: true, [
            .sure("Read over their shoulder", Effect(mind: 2, text: "Page 212 for a month now. You begin to suspect it is a prop.")),
            .sure("Stare out the window", Effect(heart: 2, text: "Backs of houses, a fox, a man waving at the train. You wave back."))]),
        .make("fill_build_2", 24...47, "🪛", "Flat-Pack Furniture",
              "A bookcase in forty pieces, an Allen key, and a diagram drawn by someone who hates you.",
              weight: 1, once: false, filler: true, [
            .sure("Follow the instructions", Effect(mind: 2, heart: -1, text: "Six hours. Two spare screws. It stands. It leans. It is yours.")),
            .sure("Wing it", Effect(mind: -1, heart: 2, text: "Done in ninety minutes and only one shelf is upside down."))]),
        .make("fill_build_3", 24...47, "🍝", "The Dinner Party",
              "You said you would host. You own four plates and one chair that wobbles.",
              weight: 1, once: false, filler: true, [
            .sure("Cook the ambitious thing", Effect(heart: 2, money: -1, text: "The sauce splits, the guests are kind, and the wine covers everything.")),
            .sure("Order in, decant it", Effect(bonds: 2, text: "Nobody is fooled. Everybody is fed. A good evening by any measure."))]),
        // Harvest
        .make("fill_harvest_1", 48...67, "🌻", "The Garden",
              "A patch of ground has become, without your consent, the thing you care most about.",
              weight: 1, once: false, filler: true, [
            .sure("Fight the slugs", Effect(body: 1, heart: 2, text: "The slugs lose this week. The slugs are patient. The slugs will return.")),
            .sure("Let it grow wild", Effect(mind: 1, heart: 1, text: "Bees arrive. A neighbor tuts. You decide the bees have the vote."))]),
        .make("fill_harvest_2", 48...67, "👓", "Reading Glasses",
              "The menu has become suspiciously blurry. The optician has a drawer with your name on it.",
              weight: 1, once: false, filler: true, [
            .sure("Get the sensible pair", Effect(mind: 2, money: -1, text: "Tortoiseshell. Dignified. You look like someone who owns a boat.")),
            .sure("Hold the menu further away", Effect(mind: -1, heart: 2, text: "Your arms are not getting longer. You order the special. It is fine."))]),
        .make("fill_harvest_3", 48...67, "🖼️", "Old Photographs",
              "A shoebox falls off the wardrobe. Inside: haircuts you have paid dearly to forget.",
              weight: 1, once: false, filler: true, [
            .sure("Go through them slowly", Effect(heart: 3, bonds: -1, text: "An entire evening gone. Half of these people you should call.")),
            .sure("Put the lid back on", Effect(mind: 1, heart: -1, text: "Not today. The box goes back up. It will fall again. They always do."))]),
        // Dusk
        .make("fill_dusk_1", 68...104, "🧩", "The Crossword",
              "Seven across has been staring at you since breakfast. It knows what it did.",
              weight: 1, once: false, filler: true, [
            .sure("Finish it unaided", Effect(mind: 3, text: "ANAGRAM. Of course. You say it out loud to nobody, triumphantly.")),
            .sure("Phone someone for a clue", Effect(mind: 1, bonds: 2, text: "They did not know either. You talked for an hour anyway."))]),
        .make("fill_dusk_2", 68...104, "🪑", "The Bench",
              "Your bench. Facing the pond. Someone else is sitting on it, which is simply not done.",
              weight: 1, once: false, filler: true, [
            .sure("Sit beside them anyway", Effect(bonds: 2, text: "They have opinions about the ducks. So do you. A friendship, of sorts.")),
            .sure("Glare from a distance", Effect(body: -1, heart: 1, text: "They leave eventually. You sit. The pond is exactly as you left it."))]),
        .make("fill_dusk_3", 68...104, "☕", "Afternoon Tea",
              "The kettle, the good cup, the biscuit tin with the lid that fights back.",
              weight: 1, once: false, filler: true, [
            .sure("Two biscuits", Effect(body: -1, heart: 2, text: "Three, actually. Nobody counts. The afternoon stretches warm and long.")),
            .sure("Just the tea", Effect(body: 1, heart: 1, text: "Restraint. The tin sulks. You win a small, quiet victory over sugar."))])
    ]
}

// MARK: - Keepsakes (secret heirloom cards; unlocked by heir_* flags)

extension Content {
    static let keepsakeCards: [Card] = [
        .make("keep_medal", 12...30, "🏅", "The Old Medal",
              "In a drawer: a medal, a date, and your surname on the back. Someone before you ran at something and won.",
              weight: 5, priority: true, cond: Cond(needFlags: ["heir_medal"]), [
            .sure("Train the way they did", Effect(body: 12, heart: 5, add: [.athlete], clear: ["heir_medal"],
                                                 text: "Dawn runs with a photo on the fridge. You get their stride before you get their time.")),
            .gamble("Enter the same race", 60,
                win: Effect(body: 8, heart: 8, bonds: 8, set: ["famous_once"], clear: ["heir_medal"],
                            text: "You finish. Not first, but the crowd knows the name. The medal gets a sibling."),
                lose: Effect(body: -5, heart: 6, bonds: 4, clear: ["heir_medal"],
                             text: "You come last with a cramp and a grin. The medal, you decide, was for showing up.")),
            .sure("Pin it on and tell the story", Effect(mind: 3, heart: 6, bonds: 10, add: [.charmer], clear: ["heir_medal"],
                                                        text: "You tell it so well people assume it is yours. You stop correcting them."))]),
        .make("keep_ledger", 12...30, "📒", "The Dusty Ledger",
              "A grandparent's ledger: every penny of a lifetime in pencil. The last page is a plan nobody finished.",
              weight: 5, priority: true, cond: Cond(needFlags: ["heir_ledger"]), [
            .sure("Finish the plan", Effect(mind: 6, heart: 4, money: 25, add: [.frugal], clear: ["heir_ledger"],
                                           text: "Column by column, you close it out. The last line reads: enough. It is.")),
            .sure("Study every page", Effect(mind: 12, bonds: 2, add: [.bookworm], clear: ["heir_ledger"],
                                            text: "Prices, debts, a bad year in pencil. You learn a family by its arithmetic.")),
            .gamble("Invest like they would have", 55,
                win: Effect(mind: 6, money: 45, clear: ["heir_ledger"],
                            text: "Slow, boring, relentless. Years later a boring number has become a loud one."),
                lose: Effect(mind: 8, heart: -3, money: -10, clear: ["heir_ledger"],
                             text: "The market disagrees with your grandmother. So, historically, did everyone."))]),
        .make("keep_violin", 12...30, "🎻", "The Worn Violin",
              "A violin with a chin-shaped shadow on the wood. Someone before you played every wedding in the valley.",
              weight: 5, priority: true, cond: Cond(needFlags: ["heir_violin"]), [
            .sure("Learn it, badly, then well", Effect(mind: 4, heart: 12, add: [.artist], clear: ["heir_violin"],
                                                     text: "Two years of cats-in-pain. Then one evening a tune arrives, already old, already yours.")),
            .gamble("Play a family wedding", 60,
                win: Effect(heart: 10, bonds: 12, set: ["famous_once"], clear: ["heir_violin"],
                            text: "Aunts weep. An uncle dances badly. Someone says it sounded just like them."),
                lose: Effect(heart: 6, bonds: -3, clear: ["heir_violin"],
                             text: "A string snaps on the first waltz. You finish on three. Grandparents would approve.")),
            .sure("Hang it on the wall", Effect(mind: 3, heart: 6, bonds: 4, clear: ["heir_violin"],
                                               text: "Not played, but seen daily. Visitors ask. You tell the story. It still sings a little."))]),
        .make("keep_letter", 12...30, "✉️", "The Sealed Letter",
              "An envelope, never opened, addressed in a hand you don't know: 'To whoever comes next.' That is you.",
              weight: 5, priority: true, cond: Cond(needFlags: ["heir_letter"]), [
            .sure("Open it", Effect(mind: 4, heart: 10, bonds: 10, add: [.kind], clear: ["heir_letter"],
                                    text: "Three pages. Advice, a recipe, an apology to no one in particular. You keep all three.")),
            .gamble("Find who it mentions", 55,
                win: Effect(heart: 8, bonds: 15, clear: ["heir_letter"],
                            text: "A stranger in a doorway reads it and weeps. You are family now, apparently. There is cake."),
                lose: Effect(mind: 6, heart: 4, bonds: 4, clear: ["heir_letter"],
                             text: "The address is a car park now. You read it aloud there anyway. The pigeons listen.")),
            .sure("Keep it sealed", Effect(mind: 6, heart: 6, add: [.loner], clear: ["heir_letter"],
                                          text: "Some things are better unopened. It sits in your desk, a small unanswered question."))])
    ]
}
