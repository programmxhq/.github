import Foundation

// MARK: - Dawn (ages 0-11, hands dealt at 0, 4, 8)

extension Content {
    static let dawn: [Card] = [
        .make("dawn_first_word", 0...3, "👶", "First Word",
              "Everyone is leaning in with phones out. Whatever you say next will be repeated at your wedding.",
              weight: 4, [
            .sure("Say 'Mama'", Effect(heart: 4, bonds: 8, text: "Tears. Applause. You have no idea what you did, but you will do it again.")),
            .sure("Say 'No.'", Effect(mind: 6, bonds: -2, add: [.stubborn], text: "A full stop at nine months. The family braces itself.")),
            .gamble("Attempt a whole sentence", 40,
                win: Effect(mind: 10, bonds: 6, text: "'Where is the cat.' Grammatically flawless. The cat is unimpressed."),
                lose: Effect(heart: 3, bonds: 2, text: "A noise like a kettle. It is not a word. It is on four phones forever."))]),

        .make("dawn_crib", 0...3, "🧗", "The Great Escape",
              "The crib has bars. You have a plan. The plan is mostly gravity.", [
            .gamble("Climb out", 55,
                win: Effect(body: 6, heart: 6, add: [.daredevil], text: "You land on the dog. The dog forgives you. Nobody else does."),
                lose: Effect(body: -4, heart: 2, text: "You dangle by one sock until rescued. The sock is never found.")),
            .sure("Rattle the bars and wait", Effect(mind: 2, bonds: 5, text: "Someone comes. Someone always comes. Useful to know.")),
            .sure("Chew the bars", Effect(body: 3, mind: 1, text: "The paint is lead-free, probably. Your teeth come in strong."))]),

        .make("dawn_blanket", 0...7, "🧸", "The Blanket",
              "One blanket. Grey, torn, and more important to you than most relatives.", [
            .sure("Take it everywhere", Effect(heart: 6, bonds: -3, add: [.loner], text: "You and the blanket against the world. The world mostly shrugs.")),
            .sure("Share it with the baby", Effect(heart: 2, bonds: 8, add: [.kind], text: "The baby drools on it. You let it. Growth.")),
            .gamble("Hide it from the wash", 45,
                win: Effect(mind: 3, heart: 5, text: "Under the mattress for a month. It smells like victory and feet."),
                lose: Effect(mind: 2, heart: -4, text: "Found, washed, and shrunk. You learn about loss early."))]),

        .make("dawn_lullaby", 0...3, "🎶", "The Lullaby",
              "Somebody sings to you every night, badly, in a language you will half remember later.", [
            .sure("Hum it back", Effect(mind: 3, heart: 6, add: [.artist], text: "Off-key, on purpose. The first of many creative decisions.")),
            .sure("Fall asleep immediately", Effect(body: 5, heart: 2, text: "A superpower you will lose at twenty and miss at forty.")),
            .gamble("Scream until it stops", 50,
                win: Effect(mind: 3, heart: 3, bonds: -2, text: "They stop singing. You win. Years later, you wish you hadn't."),
                lose: Effect(body: -2, heart: -2, bonds: 2, text: "They sing louder. You lose your voice. They win, and they are right to."))]),

        .make("dawn_sibling", 0...7, "🍼", "The Arrival",
              "A sibling appears. Nobody asked you. It cries, it is adored, and it has your old room.",
              weight: 4, [
            .sure("Appoint yourself bodyguard", Effect(heart: 4, bonds: 8, add: [.kind], text: "You guard the crib from cats, drafts, and a very confused uncle.")),
            .sure("Sulk magnificently", Effect(mind: 4, heart: -3, bonds: -4, text: "You sulk for a year. You get very good at it. It becomes a skill.")),
            .gamble("Teach it to say your name", 50,
                win: Effect(heart: 8, bonds: 6, text: "Its first word is your name, mangled. You are a hero to one person."),
                lose: Effect(heart: -2, bonds: 2, text: "Its first word is 'dog'. The dog is also pleased."))]),

        .make("dawn_frog", 4...11, "🐸", "The Frog Situation",
              "You found a frog. It is now your frog. Your mother disagrees.",
              weight: 4, [
            .sure("Hide it in a shoebox", Effect(heart: 8, bonds: -3, set: ["pet"], text: "Three weeks of secret amphibian joy. Then: the smell.")),
            .sure("Release it, tearfully", Effect(mind: 4, heart: -2, add: [.kind], text: "It hopped away without looking back. Typical.")),
            .gamble("Sneak it into school", 50,
                win: Effect(heart: 6, bonds: 10, text: "Instant legend. Children chant your name."),
                lose: Effect(heart: -4, bonds: -5, set: ["detention"], text: "The frog landed in Mrs. Patel's tea. You are a cautionary tale now."))]),

        .make("dawn_bike", 4...11, "🚲", "Two Wheels, No Stabilizers",
              "The stabilizers come off today. Your father is holding the seat. He will let go without telling you.",
              weight: 4, [
            .gamble("Pedal like mad", 60,
                win: Effect(body: 8, heart: 6, add: [.athlete], text: "You are flying. You look back. He is tiny and waving. You keep going."),
                lose: Effect(body: -5, mind: 2, heart: 3, text: "Hedge. Face first. The hedge has a name now, and it is yours.")),
            .sure("Wobble carefully", Effect(body: 4, mind: 3, text: "Slow, upright, and furious at everyone going faster.")),
            .sure("Demand the stabilizers back", Effect(body: 1, heart: 2, bonds: -2, text: "Dignity intact. Pride, less so. The street notices."))]),

        .make("dawn_library", 4...11, "📚", "The Library Card",
              "A small plastic card with your name on it. It opens a building full of other people's heads.", [
            .sure("Read everything, in order", Effect(mind: 10, bonds: -3, add: [.bookworm], text: "Aardvarks to Zoroaster. You are insufferable and well informed.")),
            .sure("Only the ones with dragons", Effect(mind: 5, heart: 5, text: "A balanced diet of fire and princes. No regrets.")),
            .sure("Use it as a bookmark", Effect(heart: 3, bonds: 3, text: "You go for the beanbags and the friends. The books watch, patiently."))]),

        .make("dawn_piggy", 4...11, "🐷", "The Piggy Bank",
              "A ceramic pig holds your entire fortune: eleven dollars and a button. The ice cream van is playing your song.", [
            .sure("Smash the pig", Effect(heart: 6, text: "Three ice creams, a brain freeze, and a pig-shaped guilt.")),
            .sure("Feed the pig", Effect(mind: 4, heart: -2, add: [.frugal], text: "You watch the van go. You feel the coins. Both feelings last a lifetime.")),
            .gamble("Sell the button", 50,
                win: Effect(mind: 4, heart: 4, money: 1, text: "Turns out it was Victorian. A collector pays. Your first thousand."),
                lose: Effect(heart: 2, bonds: 2, text: "Nobody buys the button. You trade it for a friend's marble. Fair."))]),

        .make("dawn_seaside", 4...11, "🌊", "The Seaside",
              "A long drive ends at something grey, enormous, and loud. It is the sea. It does not care about you.", [
            .sure("Run straight in", Effect(body: 5, heart: 8, set: ["saw_sea"], text: "Freezing. Salt in your nose. The best day of your life so far.")),
            .sure("Build a fortress", Effect(mind: 5, heart: 4, set: ["saw_sea"], text: "A sandcastle with a moat and a tax policy. The tide is unimpressed.")),
            .gamble("Wade out to the rock", 55,
                win: Effect(body: 4, mind: 2, heart: 6, add: [.daredevil], set: ["saw_sea"], text: "You reach it. From the rock, the world looks like it wants exploring."),
                lose: Effect(body: -6, heart: 2, set: ["saw_sea"], text: "A wave takes your shorts. The lifeguard takes your dignity."))]),

        .make("dawn_nightlight", 4...11, "🕯️", "The Night Light",
              "Something heavy came with you into this life. It sits in the dark corner and hums. Tonight, someone sits with you.",
              weight: 5, cond: Cond(needTraits: [.haunted]), [
            .sure("Tell them about it", Effect(heart: 12, bonds: 8, remove: [.haunted], text: "They listen. They don't laugh. The corner is just a corner by morning.")),
            .sure("Face it alone", Effect(mind: 8, heart: 6, add: [.stubborn], remove: [.haunted], text: "You stare it down until it blinks. Turns out it was a coat on a chair.")),
            .sure("Leave the light on", Effect(mind: 2, heart: 3, text: "It stays. So does the light. The bill goes up and the corner hums."))]),

        .make("dawn_stage", 8...11, "🎭", "The School Play",
              "You are Tree Number Two. Tree Number One has the flu. There is a speaking part open.", [
            .gamble("Take the lead", 50,
                win: Effect(heart: 8, bonds: 8, add: [.charmer], text: "You forget one line and improvise six. The parents weep. A star is born."),
                lose: Effect(heart: -5, bonds: -2, text: "You freeze. A tree does not freeze. The silence is reviewed poorly.")),
            .sure("Paint the scenery instead", Effect(mind: 3, heart: 6, add: [.artist], text: "Nobody applauds the forest. You know it was the best thing on stage.")),
            .sure("Be the best Tree Two ever", Effect(body: 2, bonds: 4, text: "You rustle with conviction. Your grandmother records all of it."))]),

        .make("dawn_bully", 8...11, "👊", "The Bully",
              "A larger child wants your lunch money, your dignity, and possibly your shoes. The teacher is not looking.",
              weight: 4, [
            .gamble("Stand up to him", 50,
                win: Effect(body: 4, heart: 8, bonds: 6, text: "He blinks first. Legend by lunchtime. You keep the shoes."),
                lose: Effect(body: -6, heart: -3, bonds: 2, text: "You lose the money and a tooth. But the small kids saw you try.")),
            .sure("Hand it over, eyes narrow", Effect(mind: 6, heart: -3, add: [.cynic], text: "You pay. You note his face. People, you decide, are mostly like this.")),
            .sure("Befriend him, somehow", Effect(heart: 4, bonds: 8, add: [.kind], text: "He just wanted someone to sit with. You split the sandwich. Odd, this."))]),

        .make("dawn_city", 8...11, "🏙️", "The Big City",
              "A train to the city for the day. The buildings are too tall and the pigeons are not afraid of anything.", [
            .sure("Look up the whole time", Effect(mind: 6, heart: 6, set: ["saw_city"], text: "You walk into three lampposts and one future. You want to live here.")),
            .sure("Hold a hand tightly", Effect(heart: 3, bonds: 6, set: ["saw_city"], text: "Too loud, too fast. But the hand is warm. You go home relieved.")),
            .gamble("Wander off", 45,
                win: Effect(mind: 8, heart: 5, add: [.daredevil], set: ["saw_city"], text: "Twenty minutes of glorious freedom and a very good pretzel."),
                lose: Effect(heart: -5, bonds: -3, set: ["saw_city"], text: "Found by a police officer and a furious parent. The pretzel is confiscated."))])
    ]
}

// MARK: - Bloom (ages 12-23, hands dealt at 12, 15, 18, 21)

extension Content {
    static let bloom: [Card] = [
        .make("bloom_band", 12...21, "🎸", "Garage Band",
              "Your friend owns a drum kit and no talent. He wants a bassist. You own neither bass nor talent.",
              weight: 4, [
            .sure("Join. Obviously.", Effect(mind: -3, heart: 10, bonds: 6, add: [.artist], text: "You are terrible together, and it is the best year of your life.")),
            .sure("Study instead", Effect(mind: 8, bonds: -4, text: "You ace the exam. Somewhere, a bassline goes unplayed.")),
            .gamble("Book a real gig", 40,
                win: Effect(heart: 8, bonds: 10, money: 1, set: ["famous_once"], text: "Forty people, one encore, a photo in the local paper. Peak."),
                lose: Effect(heart: -4, bonds: 3, text: "The amp dies in song two. You finish a cappella. The crowd is kind, mostly."))]),

        .make("bloom_paper_route", 12...17, "🗞️", "The Paper Round",
              "Dawn. Rain. A bag of newspapers heavier than you. A dog at number 42 with a personal grudge.", [
            .sure("Do it, every single day", Effect(body: 5, heart: -2, money: 2, income: 2, add: [.frugal], text: "You learn the value of a dollar, and the exact bite radius of a terrier.")),
            .gamble("Subcontract the hills", 55,
                win: Effect(mind: 6, bonds: 3, money: 2, income: 3, add: [.hustler], text: "Your cousin does the hills. You take a cut. It is the family business now."),
                lose: Effect(mind: 3, bonds: -3, money: 1, income: 2, text: "Your cousin quits in a week and tells everyone. You do the hills. In the rain.")),
            .sure("Quit after one week", Effect(body: -1, heart: 4, text: "Sleep is also a kind of wealth, you tell your mother. She is not convinced."))]),

        .make("bloom_diary", 12...17, "📓", "The Diary",
              "A notebook with a lock a toddler could pick. In it: feelings, in capital letters, about everyone.", [
            .sure("Write in it every night", Effect(mind: 6, heart: 5, bonds: -3, add: [.loner], text: "Pages and pages. Nobody understands you, which is written down, twice.")),
            .sure("Turn it into poems", Effect(mind: 4, heart: 8, add: [.artist], text: "The poems are terrible. One of them is not. You keep that one forever.")),
            .gamble("Leave it lying around", 45,
                win: Effect(heart: 6, bonds: 8, text: "Your brother reads it and, incredibly, is nice to you. For a month."),
                lose: Effect(heart: -8, bonds: -5, text: "Read aloud at dinner. Page 12 is quoted at you for the next decade."))]),

        .make("bloom_dare", 12...17, "🌉", "The Dare",
              "The railway bridge. The river below. Everyone has done it, apparently. Nobody can name who.", [
            .gamble("Jump", 60,
                win: Effect(body: 6, heart: 10, bonds: 6, add: [.daredevil], text: "Cold, loud, glorious. You surface to cheering and one very angry swan."),
                lose: Effect(body: -10, heart: 4, bonds: 4, text: "Belly flop. Purple for a fortnight. Still, you jumped, and they know it.")),
            .sure("Decline, eloquently", Effect(mind: 6, bonds: -3, text: "You cite physics. They cite cowardice. History will show you were right.")),
            .sure("Race them there instead", Effect(body: 6, heart: 3, bonds: 3, add: [.athlete], text: "You win the run and skip the jump. Legs over nerve, every time."))]),

        .make("bloom_sub", 12...17, "🧑‍🏫", "The Substitute",
              "A substitute teacher who is clearly not okay. The class smells blood. You have a choice of weapons.", [
            .gamble("Lead the mutiny", 50,
                win: Effect(mind: -2, heart: 6, bonds: 10, set: ["detention"], text: "Chairs on desks, a chant, a legend. And a month of Thursday detentions. Worth it."),
                lose: Effect(mind: -2, heart: -4, bonds: 2, set: ["detention"], text: "The head walks in mid-chant. Just you, on a desk, alone. A month of Thursdays.")),
            .sure("Sit it out, unimpressed", Effect(mind: 6, bonds: -3, add: [.cynic], text: "You read while it burns. You conclude most people are just loud.")),
            .sure("Help the poor man", Effect(mind: 3, heart: 3, bonds: 2, add: [.kind], text: "You hand out worksheets. He remembers your name. Odd, how much that matters."))]),

        .make("bloom_science_fair", 12...17, "🧪", "The Science Fair",
              "Your volcano has a theory. Your theory has a volcano. The judges have seen nineteen volcanoes today.",
              weight: 4, cond: Cond(needTraits: [.bookworm]), [
            .sure("Present the maths instead", Effect(mind: 10, bonds: -2, text: "No lava, lots of graphs. Second place and a judge's card in your pocket.")),
            .gamble("Add more baking soda", 55,
                win: Effect(mind: 6, heart: 8, bonds: 6, set: ["famous_once"], text: "The ceiling. The judges. The local paper. First prize, by acclamation."),
                lose: Effect(mind: 4, heart: -3, bonds: -3, text: "The eruption takes out the pie stand. You are banned from baking soda.")),
            .sure("Help the sad-potato kid", Effect(mind: 3, heart: 4, bonds: 6, add: [.kind], text: "The potato powers a clock. The kid powers a friendship that outlasts both."))]),

        .make("bloom_first_love", 15...21, "💌", "First Love",
              "They sit two rows ahead and have never once turned around. Today, impossibly, they turn around.",
              weight: 5, cond: Cond(noTraits: [.cynic]), [
            .gamble("Say the thing", 55,
                win: Effect(heart: 14, bonds: 6, add: [.romantic], text: "Six months of rain-soaked, hand-held, song-lyric happiness. You keep the ticket stubs."),
                lose: Effect(mind: 2, heart: -10, set: ["lost_love"], text: "They are kind about it, which is worse. You write a song. It is also worse.")),
            .sure("Write a note. Lose nerve.", Effect(mind: 3, heart: 4, add: [.romantic], text: "The note survives three washes in your pocket. The feeling outlasts the paper.")),
            .sure("Become their best friend", Effect(heart: 2, bonds: 10, text: "You are the shoulder. The shoulder hears about everyone else. Still, a good shoulder."))]),

        .make("bloom_curfew", 15...21, "🌙", "After Curfew",
              "Midnight. The window opens. The drainpipe looks sturdy and the night looks like it was made for you.", [
            .gamble("Out the window", 60,
                win: Effect(body: 2, heart: 10, bonds: 8, text: "Fields, a bonfire, a kiss or near enough. Home by four, drainpipe intact."),
                lose: Effect(body: -5, heart: 2, bonds: -6, text: "The drainpipe surrenders. So do you, to a parent in a dressing gown.")),
            .sure("Stay in, text everyone", Effect(mind: 3, heart: 2, bonds: 3, text: "You live it secondhand, in blurry photos. Not nothing.")),
            .sure("Ask permission, incredibly", Effect(mind: 2, heart: 4, bonds: 6, add: [.charmer], text: "You make the case. It is a good case. You go out the front door like a king."))]),

        .make("bloom_summer_job", 15...21, "🍟", "The Summer Job",
              "Six weeks at the fryer. The hat is orange. The manager is nineteen and drunk with power.",
              weight: 4, [
            .sure("Keep your head down", Effect(body: -2, heart: -2, money: 3, income: 3, text: "Grease in your hair, cash in your hand. The hat stays on.")),
            .sure("Quietly run the place", Effect(mind: 5, bonds: 4, money: 3, income: 5, add: [.hustler], text: "You fix the rota, charm the regulars, and own the kitchen by August.")),
            .gamble("Date the manager", 45,
                win: Effect(heart: 8, bonds: 4, money: 2, income: 3, text: "Workplace romance survives the summer, just. You get all the good shifts."),
                lose: Effect(heart: -6, bonds: -4, money: 1, text: "It ends by July. So do your shifts. The bus home is very awkward."))]),

        .make("bloom_party", 15...21, "🎈", "The Party",
              "Somebody's parents are away. Somebody's cousin has a car. Somebody has invited the whole year.",
              cond: Cond(noTraits: [.loner]), [
            .sure("Work the room", Effect(heart: 6, bonds: 10, add: [.charmer], text: "You remember every name. By midnight, every name remembers you.")),
            .gamble("Jump in the pool, clothed", 50,
                win: Effect(body: 3, heart: 8, bonds: 8, text: "Everyone follows. The pool is 80 percent teenager by one a.m. Iconic."),
                lose: Effect(body: -3, heart: -4, bonds: -4, text: "Nobody follows. You drip through the kitchen. The cousin drives you home.")),
            .sure("Mind the drinks and the door", Effect(mind: 4, bonds: 5, add: [.kind], text: "You hold hair back and call taxis. People remember that longer than the pool."))]),

        .make("bloom_open_mic", 15...21, "🎤", "Open Mic Night",
              "A pub back room, a microphone that squeals, and your name on a list in your own handwriting.",
              cond: Cond(needTraits: [.artist]), [
            .gamble("Play the sad one", 55,
                win: Effect(heart: 10, bonds: 8, set: ["famous_once"], text: "Silence, then the good kind of noise. Someone buys you a lemonade. A fan."),
                lose: Effect(heart: -5, bonds: 2, text: "A string breaks on the bridge. You finish anyway. Someone claps. Your mother.")),
            .sure("Play the funny one", Effect(heart: 6, bonds: 8, add: [.charmer], text: "They laugh in the right places. You decide laughter counts as art.")),
            .sure("Watch from the back", Effect(mind: 5, heart: 2, text: "You take notes on everyone. Next time, you tell yourself. There is a next time."))]),

        .make("bloom_exam", 18...21, "🎓", "The Big Exam",
              "University wants a number. Your brain has a number. They may not be the same number.",
              weight: 5, priority: true, cond: Cond(noFlags: ["degree", "dropout"]), [
            .gamble("Cram all night", 55,
                win: Effect(mind: 10, set: ["degree"], text: "You pass, powered by instant noodles and fear."),
                lose: Effect(body: -4, heart: -8, set: ["dropout"], text: "You fall asleep on the paper. The drool is graded.")),
            .sure("Skip it. Get a trade.", Effect(body: 3, money: 10, income: 14, set: ["dropout"], text: "Electrician's apprentice. Hands blistered, pockets lined.")),
            .sure("Bribe the bookworm", Effect(mind: 6, bonds: 4, money: -2, set: ["degree"], text: "Group study, you call it. Tutoring, she calls it."))]),

        .make("bloom_scholarship", 18...21, "🏛️", "The Scholarship Letter",
              "A thick envelope. A crest. Someone has noticed your brain and would like to rent it for three years.",
              weight: 4, cond: Cond(min: [.mind: 60], noFlags: ["degree", "dropout"]), [
            .sure("Accept, pack, go", Effect(mind: 8, heart: 4, bonds: -4, set: ["degree"], text: "A tiny room, a huge library, and a kettle you share with a philosopher.")),
            .sure("Defer a year, see the world", Effect(mind: 4, heart: 8, money: -4, set: ["degree", "saw_sea"], text: "Hostels, ferries, one lost passport. You arrive a year late, sunburnt and sure.")),
            .sure("Turn it down for the job", Effect(heart: -2, money: 6, income: 10, add: [.stubborn], set: ["dropout"], text: "The crest goes in a drawer. The payslip goes on the fridge. Both are real."))]),

        .make("bloom_trade", 18...21, "🔧", "The Apprenticeship",
              "A woman with a van and a reputation needs a pair of hands. Yours will do, she says, once they stop shaking.",
              weight: 4, cond: Cond(noFlags: ["degree", "dropout"]), [
            .sure("Sign up", Effect(body: 5, mind: 2, money: 4, income: 12, set: ["dropout"], text: "Plumbing, mostly. You are soaked daily and solvent monthly.")),
            .sure("Sign up, save every cent", Effect(body: 4, heart: -3, money: 8, income: 10, add: [.frugal], set: ["dropout"], text: "Van by twenty-one. Flat deposit by twenty-four. Fun, allegedly, by fifty.")),
            .gamble("Go it alone instead", 45,
                win: Effect(mind: 4, heart: 6, money: 6, income: 14, add: [.hustler], set: ["dropout"], text: "Your own van, your own name on the side, your own terrible hours."),
                lose: Effect(heart: -4, money: -5, income: 4, set: ["dropout"], text: "The van dies on week two. You take cash jobs and lessons in humility."))]),

        .make("bloom_road_trip", 18...21, "🚐", "The Road Trip",
              "Four friends, one borrowed van, a map with coffee rings and no plan past the first service station.", [
            .sure("Head for the coast", Effect(body: 2, heart: 8, bonds: 6, set: ["saw_sea"], text: "Chips on a wall, sunset, a tent that leaks. You would do it all again.")),
            .sure("Head for the city", Effect(mind: 6, heart: 5, bonds: 4, money: -2, set: ["saw_city"], text: "Five of you in one hostel bed. Museums by day, mistakes by night.")),
            .gamble("Just drive north", 55,
                win: Effect(mind: 4, heart: 10, bonds: 4, set: ["saw_mountains"], text: "You wake at a lake under mountains nobody packed for. Sublime."),
                lose: Effect(body: -3, heart: 2, bonds: -3, money: -3, text: "Breakdown, drizzle, a lay-by for two days. Still, a story."))]),

        .make("bloom_car", 18...21, "🏎️", "The Night Drive",
              "Your mate's car has a new exhaust and a stretch of empty road. He wants to see what it does. So do you.",
              weight: 2, cond: Cond(needTraits: [.daredevil]), [
            .gamble("Floor it", 85,
                win: Effect(body: 3, heart: 12, bonds: 6, text: "The needle, the noise, the laughter. You are briefly immortal, which is enough."),
                lose: Effect(text: "The bend was sharper than the road let on. The exhaust is found in a tree.", dies: true)),
            .sure("Ride along, buckled", Effect(mind: 2, heart: 6, bonds: 4, text: "Fast enough. You hold the dashboard and the moment. Home by one.")),
            .sure("Take the keys off him", Effect(mind: 4, heart: -2, bonds: 6, add: [.kind], text: "He sulks. He also lives. Years later he says thank you, sort of."))]),

        .make("bloom_freshers", 18...21, "🏫", "Freshers' Week",
              "A corridor of strangers, a kettle, and a society for everything. You could be anyone here. Pick carefully.",
              weight: 4, cond: Cond(needFlags: ["degree"]), [
            .sure("Join every society", Effect(mind: 2, heart: 6, bonds: 10, add: [.charmer], text: "Fencing, debating, cheese. You know four hundred people by name by October.")),
            .sure("Find the library early", Effect(mind: 10, bonds: -3, add: [.bookworm], text: "A corner desk, a view of a wall. Three years of furious, happy quiet.")),
            .gamble("Run for student president", 40,
                win: Effect(mind: 4, heart: 6, bonds: 12, set: ["famous_once"], text: "You win on a platform of cheaper toast. Governance has never been so buttery."),
                lose: Effect(mind: 3, heart: -4, bonds: 4, text: "You lose to a man in a banana costume. The toast remains expensive."))]),

        .make("bloom_first_paycheck", 18...21, "💵", "First Real Paycheck",
              "A number with a comma in it. Yours. The world suddenly contains price tags you can actually read.",
              weight: 4, cond: Cond(needFlags: ["dropout"]), [
            .sure("Take all the overtime", Effect(body: -4, heart: -2, money: 6, income: 12, text: "Twelve-hour days and a wallet that finally has a shape. Sleep is for the degree crowd.")),
            .sure("Bank it, live small", Effect(mind: 3, heart: 2, money: 6, add: [.frugal], text: "An account with your name and a balance. You check it like a pulse.")),
            .gamble("Buy a motorbike", 55,
                win: Effect(body: 3, heart: 10, money: -3, add: [.daredevil], text: "Freedom at sixty miles an hour. Your mother stops speaking to you for a week."),
                lose: Effect(body: -6, heart: 3, money: -5, text: "The bike and a hedge become close. You keep the jacket, scuffs and all."))])
    ]
}
