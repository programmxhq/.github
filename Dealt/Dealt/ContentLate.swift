import Foundation

// MARK: - Harvest (ages 48-67)
// Check-ups, inheritances, second acts, and the gold watch.
// Hands are dealt at 48, 52, 56, 60, 64.

extension Content {
    static let harvest: [Card] = [

        .make("harv_retire", 60...71, "⏳", "The Gold Watch",
              "They've bought a cake and a card with a golf joke in it. You have never golfed. The door is open, if you want it.",
              weight: 5, once: false, priority: true, cond: Cond(noFlags: ["retired"]), [
            .sure("Hand in the badge", Effect(body: 2, heart: 8, bonds: 4, income: 8, set: ["retired"], text: "Mornings are yours. You discover what a Tuesday is for.")),
            .sure("Take the golden handshake", Effect(heart: 4, money: 25, income: 6, set: ["retired"], text: "A lump sum and a smaller pension. You buy the good coffee machine.")),
            .sure("One more chapter", Effect(body: -3, heart: -5, money: 8, text: "You eat the cake anyway. The golf joke follows you to your desk."))]),

        .make("harv_checkup", 48...64, "🩺", "The Check-Up",
              "The doctor says 'hmm' twice. That's one more hmm than you'd like.",
              weight: 5, cond: Cond(max: [.body: 45]), [
            .sure("Change everything", Effect(body: 14, heart: -4, money: -6, add: [.athlete], text: "Kale. Stairs. Smug 6am walks. It works, infuriatingly.")),
            .sure("Ignore it", Effect(body: -10, heart: 4, text: "You feel fine. 'Fine' is doing a lot of work in that sentence.")),
            .sure("Pills, no kale", Effect(body: 6, money: -4, text: "A pill organiser with the days on it. Progress, of a kind."))]),

        .make("harv_red_car", 48...56, "🏎️", "The Red Car",
              "It's red. It's low. It has two seats and no practical purpose, which is, you suspect, the purpose.", [
            .sure("Buy it", Effect(heart: 10, bonds: -3, money: -25, text: "The neighbours talk. You drive past them slowly, with the top down.")),
            .sure("Buy a kayak instead", Effect(body: 5, heart: 5, money: -4, text: "Cheaper, wetter, and you can't park it at a wedding. Still, a thrill.")),
            .sure("Have a quiet think", Effect(mind: 6, heart: -2, text: "You decide it isn't about the car. You're right, which helps nobody."))]),

        .make("harv_empty_nest", 48...60, "🪹", "The Empty Nest",
              "{kids}: gone, with a van, a houseplant, and your good scissors. The house echoes.",
              cond: Cond(needFlags: ["kids"]), [
            .sure("Call every single day", Effect(heart: 4, bonds: 6, money: -2, text: "{kid} answers two times in three. The third time you talk to the houseplant.")),
            .sure("Convert the room", Effect(mind: 4, heart: 6, bonds: -4, money: -6, text: "A studio. A gym. A room with a chair in it. Yours, anyway."))]),

        .make("harv_parent", 48...60, "👵", "The Phone Call",
              "Your mother has fallen. She says she's fine. The nurse on the line says otherwise, very gently.",
              weight: 4, [
            .sure("Move her in", Effect(body: -4, heart: 4, bonds: 10, money: -10, add: [.kind], text: "She rearranges your kitchen and your patience. You'd do it again.")),
            .sure("Pay for proper care", Effect(heart: -2, bonds: 3, money: -30, text: "A good place with a garden. You visit on Sundays and feel it anyway.")),
            .sure("Let your sibling handle it", Effect(heart: -6, bonds: -8, money: 2, text: "They do. They never let you forget it."))]),

        .make("harv_memoir", 52...64, "📖", "The Memoir",
              "You've started writing it all down. Chapter one is good. Chapter one has been good for two years.",
              cond: Cond(min: [.mind: 55]), [
            .gamble("Send it to an agent", 55,
                win: Effect(mind: 5, heart: 6, money: 10, set: ["published"], text: "An agent with a scarf says yes. A small, real book with your name on it."),
                lose: Effect(mind: 2, heart: -6, money: -3, text: "Three readers. One was your mother. One was your mother again.")),
            .sure("Print it for the family", Effect(mind: 3, heart: 8, bonds: 4, money: -5, set: ["published"], text: "Twenty copies. The grandchildren skip to the embarrassing parts.")),
            .sure("Leave it at chapter one", Effect(mind: 2, heart: -2, text: "A perfect opening and nothing after it. Like some lives."))]),

        .make("harv_scandal", 52...64, "📰", "The Tabloid",
              "A photo, an old quote, a headline with the word SHAME. Half of it is true. The true half is worse.",
              weight: 4, cond: Cond(needTraits: [.famous]), [
            .gamble("Deny everything", 50,
                win: Effect(heart: 2, bonds: 4, text: "It blows over by Thursday. You never learn who sold the photo."),
                lose: Effect(heart: -8, bonds: -10, remove: [.famous], text: "A second photo. The denial ages badly. So, briefly, does your face.")),
            .sure("Confess, tearfully", Effect(heart: 4, bonds: 6, money: -15, text: "The public forgives. The lawyers invoice.")),
            .sure("Vanish", Effect(mind: 3, heart: 6, bonds: -8, add: [.loner], remove: [.famous], text: "A cottage, no phone, a beard. The headlines find someone else."))]),

        .make("harv_tv", 48...60, "📺", "The Panel Show",
              "A producer saw you at a wedding and wants that energy on television, Thursdays, after the news.",
              cond: Cond(needTraits: [.charmer]), [
            .gamble("Say yes", 60,
                win: Effect(bonds: 8, money: 12, add: [.famous], set: ["famous_once"], text: "You're the one with the eyebrows. Taxi drivers quote you."),
                lose: Effect(heart: -6, bonds: -3, money: 3, text: "Cancelled after four episodes. The eyebrows did their best.")),
            .sure("Decline", Effect(mind: 2, heart: 3, text: "You stay funny at weddings, where it's safer."))]),

        .make("harv_coach", 48...60, "🏅", "The Veterans' League",
              "The old club needs a captain for the over-fifties. Knees are optional. Pride is not.",
              cond: Cond(needTraits: [.athlete]), [
            .gamble("Captain the side", 50,
                win: Effect(body: 4, bonds: 8, add: [.famous], set: ["famous_once"], text: "A cup, a local paper, a nickname you did not choose and will not lose."),
                lose: Effect(body: -10, heart: -3, text: "A hamstring, a stretcher, polite applause.")),
            .sure("Coach the kids instead", Effect(heart: 6, bonds: 8, text: "Twelve small people call you Coach. One of them means it."))]),

        .make("harv_will", 48...64, "💼", "The Reading of the Will",
              "An uncle you met twice has left 'the estate' to 'the family'. Your cousins have brought a lawyer.",
              weight: 4, [
            .sure("Split it fairly", Effect(bonds: 4, money: 20, text: "Everyone gets a slice and a sad lunch. Civilised.")),
            .gamble("Contest it", 45,
                win: Effect(bonds: -8, money: 45, text: "You win the house. You lose the cousins. The house is nicer."),
                lose: Effect(heart: -6, bonds: -12, money: -10, text: "The lawyer gets the house, somehow. The cousins get the story.")),
            .sure("Walk away from all of it", Effect(mind: 3, heart: 5, bonds: 2, text: "Not worth the cousins. You keep the uncle's hat."))]),

        .make("harv_pivot", 48...56, "🔄", "The Pivot",
              "Your industry has been 'disrupted'. The disruptors are twenty-six and wear the same fleece.",
              cond: Cond(noFlags: ["retired"]), [
            .sure("Retrain", Effect(mind: 8, heart: 6, money: -15, income: 18, text: "Youngest in the class by thirty years. You finish top of it.")),
            .gamble("Open the café", 50,
                win: Effect(bonds: 8, money: -20, income: 24, text: "Flat whites and regulars. You know everyone's dog by name."),
                lose: Effect(heart: -8, money: -35, income: 8, text: "Eighteen months, then a sign in the window. You serve at someone else's now.")),
            .sure("Ride it out", Effect(mind: 2, heart: -4, money: 6, text: "You outlast two rounds of layoffs by being quiet near the printer."))]),

        .make("harv_sail", 48...64, "⛵", "Learn to Sail",
              "A friend has a boat and a theory that anyone can sail. The theory has not been tested on you.", [
            .gamble("Take the tiller", 70,
                win: Effect(body: 4, heart: 10, money: -8, set: ["saw_sea"], text: "Wind, salt, a harbour at dusk. You buy a hat with a rope on it."),
                lose: Effect(body: -8, heart: 2, money: -10, set: ["saw_sea"], text: "The boat is fine. The friend is fine. Your shoulder is a conversation.")),
            .sure("Rent a cottage by the shore", Effect(heart: 6, bonds: 2, money: -6, set: ["saw_sea"], text: "You watch the boats from a deckchair. Correct."))]),

        .make("harv_north", 52...64, "🧊", "The Far North",
              "A cruise to the ice, or a berth on a research ship with a cook who can't. The ice doesn't care which.", [
            .sure("Book the cruise", Effect(heart: 8, bonds: 3, money: -12, set: ["saw_ice"], text: "Glaciers from a warm deck with a blanket. The buffet is also a glacier.")),
            .gamble("The research ship", 55,
                win: Effect(mind: 6, heart: 8, money: -3, set: ["saw_ice", "saw_north"], text: "Aurora, whales, a scientist who explains both. The cook improves."),
                lose: Effect(body: -10, heart: 2, money: -5, set: ["saw_north"], text: "Seasick for nine days. You see the aurora once, through a porthole, sideways.")),
            .sure("Watch a documentary", Effect(mind: 2, text: "Narrated beautifully. The sofa is very warm."))]),

        .make("harv_amends", 48...64, "🕯️", "The Letter",
              "There's a name you don't say and a letter you've written forty times. Tonight you have a stamp.",
              weight: 4, cond: Cond(needTraits: [.haunted]), [
            .gamble("Send it", 60,
                win: Effect(heart: 12, bonds: 6, remove: [.haunted], text: "A reply, in pencil. Two lines. Enough."),
                lose: Effect(mind: 2, heart: -4, text: "Returned unopened. You keep the stamp. You keep the ghost.")),
            .sure("Burn it, make your own peace", Effect(mind: 4, heart: 6, remove: [.haunted], text: "Ash in the sink. You sleep through the night for the first time in years."))]),

        .make("harv_tip", 52...64, "🎰", "The Tip",
              "A man at the club knows a man who knows a stock. He says 'guaranteed' with his whole face.", [
            .gamble("Go in big", 40,
                win: Effect(heart: 4, money: 40, text: "It doubles. You tell everyone it was research."),
                lose: Effect(heart: -5, money: -20, text: "The man at the club is no longer at the club.")),
            .sure("Index funds, like a grown-up", Effect(mind: 3, money: 8, add: [.frugal], text: "Boring, steady, correct. You read the statements for fun.")),
            .sure("Keep it under the mattress", Effect(heart: 2, money: 2, text: "It's a lumpy mattress. You sleep well on it."))]),

        .make("harv_allotment", 52...64, "🌱", "The Allotment",
              "A patch of earth, a shed, and a feud with the man in plot nine about courgettes. You have never felt so alive.", [
            .sure("Dig with the neighbours", Effect(body: 6, heart: 6, bonds: 4, money: -2, text: "Mud, tea, gossip. The courgettes win a rosette.")),
            .sure("Dig alone, gloriously", Effect(body: 5, mind: 4, heart: 8, bonds: -5, add: [.loner], text: "Just you, the shed, the radio. Plot nine can keep his courgettes.")),
            .sure("Pay someone to dig", Effect(bonds: 2, money: -8, text: "The vegetables arrive. The feeling doesn't."))]),

        .make("harv_summit", 48...60, "🧗", "One Last Summit",
              "A mountain you've circled for years. The guide says the weather window is 'probably' open.",
              cond: Cond(needTraits: [.daredevil]), [
            .gamble("Climb", 80,
                win: Effect(body: 4, heart: 12, money: -10, set: ["saw_mountains", "saw_ice"], text: "The top, at dawn, alone with the guide and the whole sky."),
                lose: Effect(money: -10, text: "The window closed. The mountain kept you.", dies: true)),
            .sure("Base camp only", Effect(body: 2, heart: 6, money: -8, set: ["saw_mountains"], text: "You watch the summit from a tent and feel, mostly, relieved."))]),

        .make("harv_late_bloom", 48...60, "💐", "Late Bloom",
              "Someone at the pottery class laughs at your jokes. All of them. Even the pelican one.",
              cond: Cond(noFlags: ["married"]), [
            .sure("Say the big word", Effect(heart: 10, bonds: 8, money: -8, set: ["married"], text: "A registry office, {spouse}, two witnesses, one lopsided bowl as a gift.")),
            .sure("Keep it to Tuesdays", Effect(heart: 5, bonds: 3, text: "Pottery, dinner, home by ten. A good arrangement. Nobody's lonely.")),
            .sure("Panic and switch classes", Effect(mind: 2, heart: -5, text: "Woodwork. Nobody laughs at anything. You miss the pelican."))])
    ]

    // MARK: - Dusk (ages 68-104)
    // Hips, pensions, grandchildren, and the long goodbye.
    // Hands are dealt every 3 years from 68 (68, 71, 74 ... 101).

    static let dusk: [Card] = [

        .make("dusk_fading", 68...104, "🕊️", "Making Peace",
              "The body is tired in a way sleep doesn't fix. You know it. The cat knows it. There are calls to make.",
              weight: 5, priority: true, cond: Cond(max: [.body: 20]), [
            .sure("Call everyone", Effect(body: -2, heart: 12, bonds: 10, text: "Old friends, old grudges, all forgiven by teatime.")),
            .gamble("Fight it", 50,
                win: Effect(body: 12, heart: 4, text: "A new doctor, a new drug, a new spring. Not done yet."),
                lose: Effect(body: -6, heart: -4, money: -10, text: "The treatment takes more than it gives. You stop, and sit in the sun.")),
            .sure("Sit in the garden", Effect(mind: 3, heart: 8, text: "No calls. Just birds. It turns out that was the point."))]),

        .make("dusk_grandkid", 68...95, "🧒", "The Visit",
              "A small person with your nose asks why you are so old. {kid} tells them not to be rude, grinning.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Tell them everything", Effect(mind: 2, heart: 12, bonds: 8, text: "You lie about half of it. They will repeat all of it.")),
            .sure("Give them twenty bucks", Effect(bonds: 3, money: -1, text: "Transactional, but effective. They'll be back.")),
            .sure("Teach them the card trick", Effect(mind: 3, heart: 6, bonds: 5, text: "They get it wrong for a year, then perfectly, forever."))]),

        .make("dusk_hip", 68...92, "🦴", "The Hip",
              "The hip has opinions now. Stairs are a negotiation. The waiting list is eleven months and a prayer.",
              weight: 4, [
            .sure("Go private", Effect(body: 8, heart: 2, money: -25, text: "A titanium hip and a surgeon who whistles. You take the stairs to show off.")),
            .gamble("Wait for the list", 55,
                win: Effect(body: 4, money: -3, text: "Eleven months, then a decent hip. The whistling surgeon was busy."),
                lose: Effect(body: -12, heart: -4, money: -5, text: "The list grows. So does the limp. The stairs win.")),
            .sure("Live downstairs", Effect(body: -4, heart: 3, money: -2, text: "A bed in the front room. You know the postman by his knock."))]),

        .make("dusk_widowed", 71...98, "⚰️", "The Empty Chair",
              "{spouse} went first. There's a chair nobody sits in and a mug you can't wash.",
              weight: 4, cond: Cond(needFlags: ["married"]), [
            .sure("Grieve, properly", Effect(heart: -10, bonds: 6, set: ["lost_love"], clear: ["married"], text: "You cry in supermarkets. People are kinder than you expected.")),
            .sure("Lose yourself in the garden", Effect(body: 4, heart: -6, bonds: -3, set: ["lost_love"], clear: ["married"], text: "The roses have never been better. You talk to them. They don't mind.")),
            .sure("Scatter the ashes far away", Effect(heart: -4, money: -8, set: ["lost_love", "saw_sea"], clear: ["married"], text: "A cliff, a wind, the wrong direction. You both laugh, in a way."))]),

        .make("dusk_will", 74...98, "📜", "The Will",
              "A solicitor with a cold asks where it should all go. 'All' is a generous word. Still, someone has to decide.", [
            .sure("Charity, the lot", Effect(heart: 10, bonds: 2, money: -20, add: [.kind], text: "A ward gets a wing. You get a plaque with a typo. Worth it.")),
            .sure("The family, carefully", Effect(mind: 4, bonds: 6, text: "Everyone gets something and a letter explaining why. The letters take a week.")),
            .sure("Leave it to the cat", Effect(heart: 6, bonds: -6, money: -2, text: "The cat is unmoved. The nephews are not."))]),

        .make("dusk_pension", 68...86, "🏦", "The Pension Letter",
              "The fund has 'restructured'. The letter uses the word 'regrettably' twice and 'you' not at all.", [
            .gamble("Join the class action", 55,
                win: Effect(bonds: 5, money: 20, text: "Four years, a settlement, a cheque that almost covers the lawyers."),
                lose: Effect(heart: -5, money: -5, text: "The fund folds. The lawyers don't. You keep the letter as evidence.")),
            .sure("Tighten the belt", Effect(mind: 2, heart: -3, add: [.frugal], text: "Own-brand everything. You find a coupon drawer. You become the coupon drawer.")),
            .sure("Sell the good things", Effect(heart: -4, money: 15, text: "The watch, the ring, the painting nobody liked. A tidy sum and an empty wall."))]),

        .make("dusk_swim", 74...98, "🏊", "The Cold Swim",
              "The sea at dawn, in January, with the swimming club. They are all eighty and furious with health.", [
            .gamble("Dive in", 75,
                win: Effect(body: 10, heart: 10, bonds: 4, text: "Blue lips, loud laughter, bacon after. You join. You never miss a Tuesday."),
                lose: Effect(text: "The cold took your breath and didn't give it back. The sea kept you.", dies: true)),
            .sure("Paddle to the knees", Effect(body: 2, heart: 4, bonds: 2, text: "Enough to say you did. The bacon is still yours."))]),

        .make("dusk_old_flame", 68...92, "💌", "The Old Flame",
              "A name from fifty years ago, in the paper. Not theirs. Their spouse's. You still know the address.",
              cond: Cond(noFlags: ["married"]), [
            .gamble("Write", 60,
                win: Effect(heart: 12, bonds: 6, set: ["married"], text: "Tea, then dinner, then a quiet wedding to {spouse}, with two walking sticks."),
                lose: Effect(mind: 2, heart: -5, text: "A kind reply. 'Too late, I think.' You frame the envelope anyway.")),
            .sure("Leave the past where it is", Effect(mind: 3, heart: 2, text: "Some doors are better as doors. You do the crossword instead."))]),

        .make("dusk_bucket", 68...89, "✈️", "The Bucket List",
              "A list on the fridge in your handwriting, from a decade ago. Three things uncrossed. Your knees have read it too.", [
            .sure("The northern lights", Effect(body: -4, heart: 10, money: -15, set: ["saw_north", "saw_ice"], text: "Green fire over black snow. You weep, then complain about the coach.")),
            .sure("The desert", Effect(body: -2, heart: 8, money: -10, set: ["saw_desert"], text: "A camel with contempt. Stars by the bucket. You cross it off twice.")),
            .sure("The pub down the road", Effect(heart: 4, bonds: 6, money: -1, text: "It was on the list. You'd forgotten. Best of the three, honestly."))]),

        .make("dusk_birthday", 80...104, "🎂", "The Big One",
              "A birthday with a zero in it. Someone has ordered a cake the size of a tyre and invited people you thought were dead.", [
            .sure("Throw the party", Effect(body: -4, heart: 8, bonds: 12, money: -10, text: "Dancing, a speech, a fall that becomes a story. Everyone stays late.")),
            .sure("Just the family", Effect(heart: 6, bonds: 6, money: -2, text: "Cake, candles, a photo where everyone blinks. Perfect.")),
            .sure("Ignore it entirely", Effect(mind: 3, heart: 2, bonds: -4, text: "A quiet day and a big slice of tyre, alone, in the good chair."))]),

        .make("dusk_haunted", 68...95, "👻", "The Ghost at the Table",
              "There's a story you've never told at a dinner table. Tonight the table is full and the wine is open.",
              weight: 4, cond: Cond(needTraits: [.haunted]), [
            .sure("Tell it, all of it", Effect(heart: 12, bonds: 6, remove: [.haunted], text: "The room goes quiet. Then someone squeezes your hand. Lighter, at last.")),
            .sure("Carry it a little longer", Effect(mind: 3, heart: -4, text: "You pour more wine and ask about the grandchildren. The ghost sits down too."))]),

        .make("dusk_ladder", 86...104, "🪜", "The Ladder",
              "The gutters are full and the ladder is in the shed. You are, by any measure, too old for this. The gutters disagree.", [
            .gamble("Up you go", 70,
                win: Effect(body: 3, heart: 8, text: "Clear gutters, a view of the whole street, a feeling of total triumph."),
                lose: Effect(text: "The ladder was fine. The lawn was closer than you remembered.", dies: true)),
            .sure("Pay the lad next door", Effect(bonds: 4, money: -2, text: "He does it in ten minutes and calls you 'sir'. You give him a biscuit."))])
    ]

    // MARK: - Ambition cards (4 per ambition)
    // Three mid-life pushes toward the win condition, plus one priority `_final` last shot at 56-67.

    static let ambitionCards: [Card] = [

        // MARK: Fortune

        .make("amb_fortune_grand", 18...32, "📒", "The First Grand",
              "Everyone your age is spending. You're reading about compound interest in a bath. The bath is cold. The maths is hot.",
              weight: 4, cond: Cond(ambition: .fortune), [
            .sure("Save every penny", Effect(heart: -3, money: 15, add: [.frugal], text: "A jar, then a bank, then a spreadsheet with tabs. You are insufferable and solvent.")),
            .gamble("Flip sneakers online", 60,
                win: Effect(money: 25, add: [.hustler], text: "Limited editions, unlimited margins. Your bedroom is a warehouse."),
                lose: Effect(heart: -4, money: -8, text: "The sneakers were fakes. So, it turns out, was the supplier."))]),

        .make("amb_fortune_lot", 28...48, "🏗️", "The Lot by the Highway",
              "An ugly field next to a road that is about to become a bigger road. The seller hasn't heard about the road.",
              weight: 4, cond: Cond(minMoney: 30, ambition: .fortune), [
            .gamble("Buy it all", 55,
                win: Effect(mind: 3, money: 60, text: "A retail park, three years later. The field never looked better."),
                lose: Effect(heart: -5, money: -30, text: "The road goes the other way. You own a very quiet field.")),
            .sure("Go halves with a friend", Effect(bonds: 4, money: 12, text: "A modest return and a friend who now says 'partner' with a wink.")),
            .sure("Walk away", Effect(mind: 2, text: "Someone else buys it. You drive past the retail park for the rest of your life."))]),

        .make("amb_fortune_board", 36...56, "🏦", "The Boardroom",
              "A seat at the long table. The chairs are leather, the coffee is terrible, the numbers are enormous.",
              weight: 4, cond: Cond(ambition: .fortune), [
            .sure("Take the seat", Effect(heart: -8, bonds: -2, income: 42, add: [.workaholic], text: "You stop seeing daylight and start seeing dividends. A fair trade, you tell the dog.")),
            .sure("Consult from the outside", Effect(heart: -2, money: 25, income: 30, text: "Same meetings, half the hours, a fee that makes the chairman wince."))]),

        .make("amb_fortune_final", 56...67, "🎲", "All In",
              "One last play. A friend of a friend, a deal with a short window, and a number that would change everything.",
              weight: 5, priority: true, cond: Cond(ambition: .fortune), [
            .gamble("Everything on it", 20,
                win: Effect(heart: 8, bonds: 2, money: 150, text: "It lands. You buy the terrible coffee company and fix the coffee."),
                lose: Effect(heart: -10, money: -60, text: "The window was shorter than the handshake. You are much lighter.")),
            .gamble("Half, and a prayer", 50,
                win: Effect(money: 50, text: "A good return and most of a night's sleep."),
                lose: Effect(heart: -4, money: -25, text: "Half of it gone. You frame the prayer.")),
            .sure("Steady as she goes", Effect(mind: 3, heart: 2, money: 30, text: "Bonds, boring and beautiful. The friend of a friend stops calling."))]),

        // MARK: Renown

        .make("amb_renown_mic", 18...32, "🎤", "Open Mic",
              "A pub with a microphone and nine people who want you to fail. One of them is your best friend.",
              weight: 4, cond: Cond(ambition: .renown), [
            .gamble("Get up there", 55,
                win: Effect(heart: 6, bonds: 8, add: [.charmer], text: "They laugh. On purpose. The barman gives you a free one and a Tuesday slot."),
                lose: Effect(heart: -6, bonds: -2, text: "Silence, then a cough, then your friend clapping alone. Character-building.")),
            .sure("Heckle instead", Effect(mind: 3, heart: 2, bonds: -3, text: "Funnier from the back, you decide. The microphone disagrees, quietly."))]),

        .make("amb_renown_break", 28...48, "🎬", "The Big Break",
              "A casting call, a demo tape, a stranger who says 'kid' at you. The door is open, for about a week.",
              weight: 4, cond: Cond(ambition: .renown), [
            .gamble("Walk through it", 50,
                win: Effect(bonds: 8, money: 20, add: [.famous], set: ["famous_once"], text: "Your face on a bus. You take a photo of the bus. Strangers take photos of you."),
                lose: Effect(heart: -8, money: -5, text: "They went with someone taller. You are, forever, 'the other one'.")),
            .sure("Take the safe gig", Effect(bonds: 4, money: 10, text: "Steady work, small rooms, a following you could fit in a van."))]),

        .make("amb_renown_tour", 40...60, "🚌", "The Tour",
              "Forty cities, one bus, a crew who call you by your surname. Your body has opinions about the bus.",
              weight: 4, cond: Cond(ambition: .renown), [
            .gamble("Every city", 65,
                win: Effect(body: -8, bonds: 10, money: 20, add: [.famous], set: ["famous_once"], text: "Sold out in Dundee. They chant. You cry on the bus, happily."),
                lose: Effect(body: -10, heart: -6, money: -5, text: "Half-empty halls and a bus with no heating. Dundee was lovely, though.")),
            .sure("Just the home town", Effect(heart: 6, bonds: 6, money: 4, text: "One night, full house, everyone you've ever met. The best gig of your life."))]),

        .make("amb_renown_final", 56...67, "🏆", "The Lifetime Award",
              "They're giving out a lifetime award. You are, technically, a lifetime. The shortlist has your name and three enemies.",
              weight: 5, priority: true, cond: Cond(ambition: .renown), [
            .gamble("Campaign for it", 60,
                win: Effect(heart: 8, bonds: 15, add: [.famous], set: ["famous_once"], text: "A trophy shaped like a swan. Your speech is cut off, but the first half was great."),
                lose: Effect(heart: -6, bonds: -5, text: "It goes to your rival. Their speech thanks you. Somehow that's worse.")),
            .sure("Host the ceremony instead", Effect(heart: 4, bonds: 10, text: "You present every award and steal every laugh. The swan can wait."))]),

        // MARK: Hearth

        .make("amb_hearth_hall", 18...28, "💐", "Across the Hall",
              "Someone across the hall keeps borrowing sugar. You have, at this point, bought sugar specifically.",
              weight: 4, cond: Cond(noFlags: ["married"], ambition: .hearth), [
            .gamble("Ask them to dinner", 55,
                win: Effect(heart: 10, bonds: 8, set: ["married"], text: "Dinner became breakfast became a lease became a ring. {spouse} admits the sugar was a ruse."),
                lose: Effect(heart: -6, set: ["lost_love"], text: "They were seeing the baker. The baker had better sugar. You move out.")),
            .sure("Just friends, for now", Effect(heart: 2, bonds: 5, text: "Years of sugar and takeaways. Not nothing. Not quite the thing either."))]),

        .make("amb_hearth_table", 28...44, "🍲", "Sunday Dinner",
              "You have a table. It seats four. Lately there are six people, two dogs, and a cousin on a stool.",
              weight: 4, cond: Cond(ambition: .hearth), [
            .sure("Build the big table", Effect(heart: 4, bonds: 12, money: -8, text: "Oak, twelve seats, a scratch from the first argument. Every Sunday, forever.")),
            .sure("Make them take turns", Effect(mind: 2, heart: 2, bonds: 4, text: "A rota. It works, sort of. The cousin keeps the stool."))]),

        .make("amb_hearth_more", 28...44, "🧦", "Room for One More",
              "There's a drawer of tiny socks {spouse} bought 'just in case'. The case has arrived.",
              weight: 4, cond: Cond(needFlags: ["married"], noFlags: ["kids"], ambition: .hearth), [
            .sure("The whole adventure", Effect(body: -3, heart: 8, bonds: 8, money: -10, set: ["kids"], text: "{kid} arrives and laughs at the dog. The socks fit for a week.")),
            .sure("Foster", Effect(heart: 6, bonds: 10, money: -6, add: [.kind], set: ["kids"], text: "{kid}, nine, with a suitcase and a stare. The stare softens. So do you.")),
            .sure("Not us, not now", Effect(heart: -4, bonds: -2, text: "The socks stay in the drawer. You check on them sometimes."))]),

        .make("amb_hearth_final", 56...67, "🏡", "The Whole Clan",
              "One big gathering, everyone, under one roof. The roof is yours. So is the catering bill and the seating plan.",
              weight: 5, priority: true, cond: Cond(ambition: .hearth), [
            .gamble("Invite absolutely everyone", 65,
                win: Effect(heart: 8, bonds: 18, money: -8, text: "Forty people, three generations, one photo with nobody blinking. Legend."),
                lose: Effect(heart: -6, bonds: 4, money: -8, text: "Two no-shows and a row about gravy. Still family. Still a photo.")),
            .sure("Small and quiet", Effect(heart: 4, bonds: 8, money: -3, text: "The ones who matter, a pot of something, the good blanket. Enough."))]),

        // MARK: Scholar

        .make("amb_scholar_card", 18...28, "📚", "The Library Card",
              "A library with a basement nobody uses. The librarian gives you a key and a look that says 'don't'.",
              weight: 4, cond: Cond(ambition: .scholar), [
            .sure("Read everything, in order", Effect(mind: 10, bonds: -3, add: [.bookworm], text: "You emerge in spring, pale and fluent in two dead languages.")),
            .gamble("The forbidden shelf", 60,
                win: Effect(mind: 14, heart: 4, text: "Marginalia from a genius. You copy it all. The librarian pretends not to see."),
                lose: Effect(mind: 3, heart: -5, bonds: -2, text: "Mostly mould and a very old sandwich. The key is confiscated."))]),

        .make("amb_scholar_thesis", 24...44, "🔬", "The Thesis",
              "Four years, one question, a supervisor who answers emails on a lunar cycle. The defence is Tuesday.",
              weight: 4, cond: Cond(min: [.mind: 55], ambition: .scholar), [
            .gamble("Defend it", 60,
                win: Effect(mind: 8, heart: 6, money: -5, set: ["published"], text: "Passed. Printed. Cited once, by yourself. A start."),
                lose: Effect(mind: 4, heart: -8, text: "Rejected. Reviewer two is, you suspect, a goose with a grudge.")),
            .sure("Teach instead", Effect(mind: 5, bonds: 4, income: 16, text: "Three classes, forty essays, one student who gets it. That one's enough."))]),

        .make("amb_scholar_year", 40...60, "🏛️", "The Sabbatical",
              "A year off to think. The university agrees, provided you think somewhere cheaper.",
              weight: 4, cond: Cond(ambition: .scholar), [
            .sure("Take the year", Effect(mind: 12, heart: 4, money: -15, text: "An attic in a cold city, a desk by the window. The book writes itself. Slowly.")),
            .gamble("Debate your great rival", 55,
                win: Effect(mind: 10, bonds: 6, text: "A packed hall, a knockout argument, a handshake that means it."),
                lose: Effect(mind: 2, heart: -6, text: "They had slides. You had conviction. Slides won."))]),

        .make("amb_scholar_final", 56...67, "🖋️", "The Great Work",
              "Everything you know, in one book. The publisher wants it by spring. You have a title and a headache.",
              weight: 5, priority: true, cond: Cond(ambition: .scholar), [
            .gamble("Finish it properly", 55,
                win: Effect(mind: 15, heart: 6, set: ["published"], text: "Six hundred pages. Reviewed, argued over, taught. Your name on a spine."),
                lose: Effect(mind: 6, heart: -8, money: -5, text: "Spring comes. The book doesn't. The publisher sends a very polite plant.")),
            .sure("Publish the notes as-is", Effect(mind: 6, money: -8, set: ["published"], text: "Unfinished, honest, oddly loved. Students call it 'the fragments'."))]),

        // MARK: Wanderer

        .make("amb_wander_boat", 18...60, "⛵", "A Leaky Boat, A Full Moon",
              "A stranger offers passage north. The boat has opinions about floating.",
              weight: 4, cond: Cond(ambition: .wanderer), [
            .gamble("Get in", 65,
                win: Effect(mind: 4, heart: 10, set: ["saw_north"], text: "Aurora overhead, bilge water underfoot. Worth it."),
                lose: Effect(body: -15, money: -5, set: ["saw_north"], text: "You arrive. Mostly. Your luggage didn't.")),
            .sure("Stay dry", Effect(heart: -4, text: "The moon sets. The stranger shrugs. You dream about it for a decade."))]),

        .make("amb_wander_thumb", 18...36, "🎒", "The Thumb",
              "A rucksack, a road, a thumb. Your mother has opinions. The road does not.",
              weight: 4, cond: Cond(ambition: .wanderer), [
            .gamble("Stick it out", 60,
                win: Effect(body: -2, heart: 10, set: ["saw_desert", "saw_mountains"], text: "A trucker, a goat farmer, a nun on a motorbike. Two ranges and a desert."),
                lose: Effect(body: -10, money: -6, set: ["saw_desert"], text: "Three days in a lay-by, then a lift the wrong way. You see sand, at least.")),
            .sure("Take the bus", Effect(heart: 4, money: -5, set: ["saw_city"], text: "Fourteen hours and a city at the end of it. The bus had a toilet. Luxury."))]),

        .make("amb_wander_ice", 32...60, "🧊", "The Ice Road",
              "A road that exists only in winter, over a lake, for trucks and the brave. A trucker named Bev needs a co-driver.",
              weight: 4, cond: Cond(ambition: .wanderer), [
            .gamble("Ride with Bev", 55,
                win: Effect(mind: 4, heart: 8, money: -8, set: ["saw_ice"], text: "Cracking ice, Bev's playlist, a sunrise like a struck match."),
                lose: Effect(body: -14, money: -10, set: ["saw_ice"], text: "The ice held. The truck didn't. Bev is fine. Your ribs will be, eventually.")),
            .sure("Postcards only", Effect(mind: 2, heart: -3, text: "Bev sends one. It says 'you'd have loved it'. You would have."))]),

        .make("amb_wander_final", 56...67, "🌊", "The Last Voyage",
              "A cargo ship takes six passengers north and round the top of the world. No doctor, no wifi, one very good cook.",
              weight: 5, priority: true, cond: Cond(ambition: .wanderer), [
            .gamble("Book the cabin", 60,
                win: Effect(heart: 12, money: -15, set: ["saw_sea", "saw_north"], text: "Icebergs at breakfast. The cook teaches you bread. You come back someone else."),
                lose: Effect(body: -12, heart: 2, money: -20, set: ["saw_sea"], text: "A storm, a broken wrist, a port you never meant to see. Still the sea.")),
            .sure("A ferry, one quiet weekend", Effect(heart: 6, money: -8, set: ["saw_sea"], text: "Grey water, hot chips, a deckchair. The horizon is the horizon anywhere."))]),

        // MARK: Elder

        .make("amb_elder_habit", 18...36, "🥣", "The Habit",
              "Your grandmother lived to ninety-eight on porridge and spite. You have inherited the spite. The porridge is a choice.",
              weight: 4, cond: Cond(ambition: .elder), [
            .sure("Porridge, stairs, early bed", Effect(body: 8, heart: -2, money: -2, add: [.athlete], text: "Dull, daily, devastatingly effective. You outlive the gym.")),
            .gamble("Quit the cigarettes", 60,
                win: Effect(body: 12, heart: 4, text: "Cold turkey and gum. Your lungs send a thank-you card."),
                lose: Effect(body: 2, heart: -5, text: "Three weeks, then one at a party, then all of them. Next year, maybe."))]),

        .make("amb_elder_choir", 36...56, "🎶", "The Choir",
              "A choir with a waiting list and an average age of seventy. They need an alto and someone to drive the minibus.",
              weight: 4, cond: Cond(ambition: .elder), [
            .sure("Join, and drive", Effect(heart: 10, bonds: 8, text: "Thursdays, harmonies, biscuits. You outlive everyone in the back row. Twice.")),
            .sure("Sing alone in the car", Effect(mind: 2, heart: 6, text: "Full volume, red lights, no witnesses. Good for the soul, if not the neighbours."))]),

        .make("amb_elder_doc", 44...64, "🩺", "The Specialist",
              "A doctor who charges by the syllable has found something early. Early is good. Expensive is also a word.",
              weight: 4, cond: Cond(ambition: .elder), [
            .sure("Pay the syllables", Effect(body: 12, money: -15, text: "Caught in time, fixed in full. The invoice is framed, out of spite.")),
            .gamble("Second opinion, cheaper", 55,
                win: Effect(body: 10, money: -4, text: "A kind doctor in a draughty clinic says the same thing for a tenth of the price."),
                lose: Effect(body: -4, mind: 3, money: -10, text: "The second opinion was wrong. The third was the first. You pay twice."))]),

        .make("amb_elder_final", 56...67, "🧘", "The Long View",
              "The plan is simple: outlive everyone. A clinic in the mountains promises twenty extra years. Your knees promise nothing.",
              weight: 5, priority: true, cond: Cond(ambition: .elder), [
            .sure("Sell the car. Walk.", Effect(body: 10, heart: 6, money: 8, text: "Four miles a day, rain or shine. The postman asks you for tips.")),
            .gamble("The mountain clinic", 60,
                win: Effect(body: 18, heart: 4, money: -30, text: "Thin air, cold plunges, a diet of nuts. You come back terrifyingly spry."),
                lose: Effect(body: -8, heart: -6, money: -30, text: "The clinic was a hotel with a juicer. You come back with a cold and a receipt."))])
    ]
}
