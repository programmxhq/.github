import Foundation

// MARK: - Build (ages 24-47)
// Careers, love, mortgages, and the first mistakes that stick.
// Hands are dealt at 24, 28, 32, 36, 40, 44.

extension Content {
    static let build: [Card] = [

        // MARK: Careers

        .make("build_offer", 24...40, "🏢", "The Offer",
              "A glass tower wants you. It pays well and smells like printer toner.",
              weight: 5, cond: Cond(needFlags: ["degree"]), [
            .sure("Take the desk", Effect(heart: -3, money: 5, income: 18, text: "You have a lanyard now. The lanyard has you.")),
            .sure("Take it and grind", Effect(body: -4, heart: -8, income: 24, add: [.workaholic], text: "Promoted twice. Nobody remembers your birthday, including you.")),
            .sure("Start your own thing", Effect(heart: 6, money: -15, income: 8, add: [.hustler], text: "A laptop, a logo, and the firm belief that this will work."))]),

        .make("build_trade", 24...36, "🔧", "Hands On",
              "Your cousin's crew needs a pair of hands. The hands don't need a degree. They do need gloves.",
              weight: 4, [
            .sure("Sign on", Effect(body: 3, money: 4, income: 14, text: "Blistered, sunburnt, paid on Fridays. You sleep like a stone.")),
            .gamble("Work up to foreman", 60,
                win: Effect(body: -2, bonds: 5, income: 20, text: "You run the crew now. They mock you, affectionately, from a ladder."),
                lose: Effect(body: -8, heart: -3, income: 12, text: "A dropped beam, a slipped disc, a desk on the site. Not the one you wanted.")),
            .sure("Pass. Keep looking.", Effect(mind: 3, money: -3, text: "Another year of interviews. You get very good at describing yourself."))]),

        .make("build_city", 24...32, "🌆", "The Big City Job",
              "A job in the city, where rent is a mood and everyone walks fast. They want you Monday.",
              weight: 4, [
            .sure("Pack a bag", Effect(heart: 4, bonds: -6, money: -5, income: 20, set: ["saw_city"], text: "You learn to eat standing up. You stop calling home. The skyline is yours.")),
            .sure("Commute instead", Effect(body: -4, mind: 2, income: 16, set: ["saw_city"], text: "Four hours a day on a train. You finish every podcast ever made.")),
            .sure("Stay where your people are", Effect(heart: 3, bonds: 6, text: "Smaller job, bigger dinners. No regrets, mostly."))]),

        .make("build_hustle", 24...36, "🃏", "The Side Hustle",
              "You have a van, a cousin, and a theory about reselling office chairs. The theory has a margin.",
              cond: Cond(needTraits: [.hustler]), [
            .gamble("Scale it up", 60,
                win: Effect(mind: 3, money: 30, text: "Four vans. The cousin has a title. You have a warehouse that smells of foam."),
                lose: Effect(heart: -5, money: -12, text: "The chairs were not ergonomic. The refunds were.")),
            .sure("Go legit", Effect(heart: 2, money: 5, income: 22, text: "A proper company, a proper salary, a proper accountant who sighs at you.")),
            .sure("Keep it small", Effect(heart: 4, money: 6, text: "Beer money and a van that smells of success."))]),

        .make("build_promotion", 32...44, "📈", "The Corner Office",
              "A door with your name on it is on offer. So is a chair, a budget, and everyone's problems.",
              weight: 4, cond: Cond(min: [.mind: 55]), [
            .sure("Take it", Effect(heart: -4, income: 30, add: [.workaholic], text: "You answer emails at weddings. One of them was yours.")),
            .gamble("Negotiate hard", 55,
                win: Effect(bonds: 4, income: 34, text: "A bigger number, a nicer chair. They respect you, grudgingly."),
                lose: Effect(heart: -6, bonds: -3, text: "They give it to Dave. Dave is lovely. That makes it worse.")),
            .sure("Decline", Effect(heart: 5, bonds: 5, text: "You leave at five. Dave does not."))]),

        .make("build_headhunted", 36...44, "🏛️", "Headhunted",
              "A woman in a very good coat buys you lunch and names a number. The number has a comma in it.",
              weight: 4, cond: Cond(min: [.mind: 65], needFlags: ["degree"]), [
            .sure("Take the number", Effect(heart: -6, bonds: -3, income: 45, add: [.workaholic], text: "A car, a driver, a calendar that owns you. The comma was real.")),
            .gamble("Name a bigger one", 45,
                win: Effect(heart: -4, income: 50, text: "She blinks once and says yes. You should have asked for more."),
                lose: Effect(heart: 2, bonds: 2, text: "She finishes her coffee and leaves. The lunch was still free.")),
            .sure("Stay loyal", Effect(heart: 4, bonds: 6, text: "Your team buys you a cake. It says STAY on it. Spelled correctly, even."))]),

        .make("build_burnout", 32...44, "🔥", "Running on Fumes",
              "You fell asleep in a meeting you were leading. Nobody noticed. That is the worst part.",
              weight: 4, cond: Cond(needTraits: [.workaholic]), [
            .sure("Quit, loudly", Effect(body: 6, heart: 10, income: 10, remove: [.workaholic], text: "A speech, a box of things, a bus home at 2pm. Terrifying. Wonderful.")),
            .sure("Take a sabbatical", Effect(body: 8, heart: 8, money: -12, remove: [.workaholic], text: "Three months, one beach, zero emails. You come back human.")),
            .sure("Push through", Effect(body: -10, heart: -4, money: 20, text: "Another bonus. Another grey hair. The meeting, you learn, went fine."))]),

        .make("build_pitch", 28...44, "🚀", "The Pitch",
              "A friend has a deck. Forty slides. Slide thirty-nine says 'profit' in a very large font.",
              weight: 4, [
            .gamble("Go all in", 20,
                win: Effect(heart: 8, bonds: 4, money: 150, set: ["famous_once"], text: "Acquired in three years. You are briefly on a magazine cover, holding a laptop."),
                lose: Effect(heart: -8, bonds: -3, money: -30, text: "Slide thirty-nine was aspirational. So was your savings account.")),
            .gamble("Put in a little", 50,
                win: Effect(money: 25, text: "A tidy exit. The friend sends a fruit basket."),
                lose: Effect(heart: -3, money: -10, text: "The app did one thing, badly. The money did the same.")),
            .sure("Pass", Effect(mind: 3, bonds: -2, text: "The friend forgives you, slowly. Slide forty was 'thank you'."))]),

        .make("build_partner", 28...44, "🗡️", "The Partner",
              "Your business partner has emptied the account, the office, and the kettle. There is a note. It is not an apology.", [
            .gamble("Lawyer up", 55,
                win: Effect(mind: 3, money: 15, text: "You win. The lawyer wins more. Still, principle."),
                lose: Effect(heart: -8, money: -20, add: [.haunted], text: "The judge likes their smile. You stare at ceilings for years.")),
            .gamble("Hustle it back yourself", 45,
                win: Effect(heart: 6, money: 30, add: [.hustler], text: "You rebuild alone, faster and meaner. The kettle was never recovered."),
                lose: Effect(heart: -10, money: -10, add: [.haunted], text: "Every lead goes cold. So do you.")),
            .sure("Let it go", Effect(mind: 5, heart: -5, money: -15, text: "You buy a new kettle. You never answer unknown numbers again."))]),

        // MARK: Love & family

        .make("build_dating", 24...44, "🥂", "Second Date",
              "They laughed at your joke. Not the good one. The one about the pelican.",
              weight: 4, cond: Cond(noTraits: [.cynic], noFlags: ["married"]), [
            .gamble("Propose. Wildly early.", 35,
                win: Effect(heart: 15, bonds: 12, add: [.romantic], set: ["married"], text: "They said yes. The pelican is in the vows."),
                lose: Effect(heart: -10, bonds: -6, set: ["lost_love"], text: "They said 'oh no'. The pelican is retired.")),
            .gamble("Take it slow", 70,
                win: Effect(heart: 8, bonds: 8, set: ["married"], text: "Four years, one shared toothbrush holder, one small wedding. Progress."),
                lose: Effect(heart: -4, bonds: 2, text: "Four years, then a very kind conversation. You keep the toothbrush holder.")),
            .sure("Ghost them", Effect(mind: 2, heart: -3, bonds: -2, text: "You stop replying. The pelican joke follows you anyway."))]),

        .make("build_setup", 24...40, "💌", "The Set-Up",
              "Your aunt knows someone. Your aunt always knows someone. This one, she says, has a boat.",
              cond: Cond(noFlags: ["married"]), [
            .gamble("Go to dinner", 55,
                win: Effect(heart: 10, bonds: 8, set: ["married"], text: "No boat. A kayak. Reader, you married them anyway."),
                lose: Effect(heart: -4, bonds: 2, text: "Three hours on their lizard. Your aunt is undeterred.")),
            .sure("Decline, politely", Effect(mind: 3, bonds: -3, text: "Your aunt takes it personally. Christmas is quieter."))]),

        .make("build_question", 28...44, "💍", "The Question",
              "A ring in your coat pocket, a restaurant with a view. You have rehearsed. The rehearsal did not include the waiter.",
              weight: 4, cond: Cond(needTraits: [.romantic], noFlags: ["married"]), [
            .sure("Ask, right now", Effect(heart: 12, bonds: 10, money: -6, set: ["married"], text: "Yes. The waiter cries. Dessert is free.")),
            .sure("Wait for a better moment", Effect(mind: 2, heart: -4, text: "The better moment never quite arrives. The ring moves coats."))]),

        .make("build_nursery", 28...44, "🍼", "The Nursery Question",
              "The spare room has been 'the spare room' for years. Lately it has started to look like a nursery.",
              weight: 4, cond: Cond(needFlags: ["married"], noFlags: ["kids"]), [
            .sure("Paint it yellow", Effect(body: -4, heart: 10, bonds: 8, money: -10, set: ["kids"], text: "Sleep is a rumour. The small person has your scowl.")),
            .gamble("Go big", 50,
                win: Effect(body: -6, heart: 12, bonds: 12, money: -18, set: ["kids"], text: "Three of them. The house is loud and the car is a bus."),
                lose: Effect(body: -8, heart: 6, bonds: 6, money: -14, set: ["kids"], text: "One, in the end, and a long year. You'd do it again.")),
            .sure("Keep it a spare room", Effect(heart: -4, bonds: -3, text: "A quiet drive home. Nobody says the word 'later'."))]),

        .make("build_divorce", 32...47, "💔", "The Quiet Kitchen",
              "Breakfasts have gone silent. Not angry. Just two people reading the same cereal box for different reasons.",
              cond: Cond(needFlags: ["married"]), [
            .sure("End it, kindly", Effect(heart: -10, bonds: -6, money: -25, set: ["divorced"], clear: ["married"], text: "Half the plates, all the records. The kitchen is loud again, eventually.")),
            .gamble("Try counselling", 60,
                win: Effect(heart: 8, bonds: 6, money: -4, text: "A stranger with a notepad fixes it. You both hate how well it worked."),
                lose: Effect(heart: -6, money: -4, text: "Six sessions. You learn new words for the same silence.")),
            .sure("Stay. Say nothing.", Effect(mind: 2, heart: -8, text: "The cereal box gets read for years. You know it by heart."))]),

        .make("build_conference", 32...44, "💋", "The Conference",
              "Hotel bar, a colleague's laugh, a hand on your arm that stays. Your phone buzzes. It's a photo of the dog.",
              cond: Cond(needFlags: ["married"]), [
            .sure("Go to bed. Alone.", Effect(heart: 4, bonds: 4, text: "You call home and describe the keynote at length. Nobody minds.")),
            .gamble("Stay for one more", 50,
                win: Effect(heart: 4, bonds: -2, text: "Nothing happened, you say. Nothing happened, you tell yourself. Mostly true."),
                lose: Effect(heart: -12, bonds: -10, money: -20, add: [.haunted], set: ["divorced"], clear: ["married"], text: "Something happened. Then everything did. The dog stayed with them."))]),

        .make("build_dog", 24...44, "🐕", "The Dog",
              "A shelter dog with one ear and the eyes of a poet looks at you. The shelter closes in ten minutes.",
              cond: Cond(noFlags: ["pet"]), [
            .sure("Take him home", Effect(body: 3, heart: 8, bonds: 3, money: -3, set: ["pet"], text: "His name is Admiral. He has eaten a shoe and your loneliness.")),
            .sure("Walk away", Effect(mind: 2, heart: -3, text: "You think about the ear for a decade."))]),

        .make("build_neighbour", 28...44, "🧸", "The Neighbour",
              "The old man next door has fallen again. His daughter lives far away and says so, often.", [
            .sure("Check on him every day", Effect(heart: 5, bonds: 8, money: -3, add: [.kind], text: "Tea, crosswords, war stories. He leaves you his chess set.")),
            .sure("Call the daughter", Effect(mind: 2, bonds: 2, text: "She sighs, arrives, sorts it. You wave from the window.")),
            .sure("Close the blinds", Effect(mind: 3, heart: -4, bonds: -4, add: [.cynic], text: "Not your problem. The ambulance comes twice more. You hear it both times."))]),

        // MARK: Money & home

        .make("build_mortgage", 28...44, "🏠", "The Mortgage",
              "A house with a door you'd own and a roof you'd worry about. The bank smiles the way banks do.",
              weight: 4, cond: Cond(noFlags: ["own_home"], minMoney: 20), [
            .sure("Sign the papers", Effect(heart: 6, bonds: 4, money: -40, set: ["own_home"], text: "Yours, mostly. The bank keeps a photo of it on their desk.")),
            .gamble("Buy the fixer-upper", 55,
                win: Effect(body: -3, heart: 9, money: -25, set: ["own_home"], text: "Cheap, cheerful, two surprise fireplaces. You learn plumbing."),
                lose: Effect(body: -7, heart: -2, money: -45, set: ["own_home"], text: "Damp, rot, a wasp situation. It is still, legally, a home.")),
            .sure("Keep renting", Effect(mind: 2, heart: -2, money: 2, text: "Freedom, you call it. The landlord calls it rent."))]),

        .make("build_frugal", 24...36, "🪙", "The Spreadsheet",
              "You open a budget. It has colours. Column F says you can afford one coffee a week. Column F is a tyrant.", [
            .sure("Obey Column F", Effect(heart: -2, money: 8, add: [.frugal], text: "You now know the price of everything. People stop inviting you to brunch.")),
            .sure("Delete the spreadsheet", Effect(heart: 6, bonds: 3, money: -8, text: "Brunch. Taxis. A jacket you did not need. Glorious.")),
            .sure("Keep it, ignore it", Effect(mind: 2, text: "It sits in a folder named 'Serious'. You open it once a year to feel bad."))]),

        // MARK: Body, art, fame

        .make("build_bike", 24...40, "🏍️", "The Bike",
              "A motorbike with a reputation is for sale. The seller says 'she's fine' in a tone that suggests otherwise.",
              cond: Cond(needTraits: [.daredevil]), [
            .gamble("Buy it, ride it hard", 85,
                win: Effect(heart: 12, bonds: 4, text: "Coast roads at dawn. You have never felt more alive, or more insured."),
                lose: Effect(text: "The bend was sharper than the brochure. The bike survived.", dies: true)),
            .sure("Buy it, ride it gently", Effect(heart: 6, money: -5, text: "You wave at other riders. They do not wave back. Still lovely.")),
            .sure("Sell it on", Effect(mind: 2, heart: -3, money: 6, text: "Profit. The seller's tone haunts you anyway."))]),

        .make("build_marathon", 28...44, "🏃", "The Marathon",
              "A colleague is running a marathon 'for fun'. The phrase sits wrong. You look at your trainers anyway.",
              cond: Cond(min: [.body: 45]), [
            .sure("Train. Properly.", Effect(body: 8, heart: 4, bonds: -3, money: -2, add: [.athlete], text: "Twenty-six miles and a toenail short. Smug at 6am for the rest of your life.")),
            .sure("Cheer, loudly, with a sign", Effect(heart: 3, bonds: 5, text: "The sign says RUN LIKE THE WIFI IS DOWN. It's a hit."))]),

        .make("build_gallery", 24...40, "🎨", "The Gallery",
              "A gallery with white walls and no heating will show your work. Opening night is Thursday. Your mother is coming.",
              weight: 4, cond: Cond(needTraits: [.artist]), [
            .gamble("Hang everything", 45,
                win: Effect(heart: 10, bonds: 5, money: 15, add: [.famous], set: ["famous_once"], text: "Sold out. A critic uses the word 'urgent'. Your mother buys two."),
                lose: Effect(heart: -8, money: -3, text: "Three sales, two to your mother. The critic went to the bar next door.")),
            .sure("Hang the safe ones", Effect(heart: 4, bonds: 2, money: 6, text: "Pleasant. Sold a few. Nobody said 'urgent'.")),
            .sure("Keep painting quietly", Effect(mind: 3, heart: 6, text: "The work gets better in the dark. Nobody sees it yet."))]),

        .make("build_viral", 28...44, "📱", "Fifteen Minutes",
              "You filmed something stupid. It has four million views by lunch. People want to know who you are.",
              cond: Cond(noTraits: [.famous]), [
            .gamble("Lean in", 35,
                win: Effect(heart: 4, bonds: 8, money: 10, add: [.famous], set: ["famous_once"], text: "A second video, then a third. Strangers say your catchphrase at you. You have one."),
                lose: Effect(heart: -5, bonds: -3, money: -2, text: "The second video got nine views. Two were your mother refreshing.")),
            .sure("Delete it", Effect(mind: 3, heart: 2, text: "Gone by dinner. The internet forgets. Your aunt does not."))]),

        .make("build_manuscript", 28...44, "📚", "The Manuscript",
              "Eleven years, three hundred pages, one idea. It is finished. Now someone else has to read it.",
              cond: Cond(min: [.mind: 60]), [
            .gamble("Send it to the big press", 55,
                win: Effect(mind: 6, heart: 8, money: 10, set: ["published"], text: "Accepted. A small print run, a large sense of relief."),
                lose: Effect(mind: 2, heart: -6, text: "A form rejection. Someone has spelt your name wrong on it.")),
            .sure("Self-publish", Effect(heart: 4, money: -8, set: ["published"], text: "Forty copies, one review, two stars. It exists. That was the point.")),
            .sure("Put it in a drawer", Effect(mind: 4, heart: -3, text: "The drawer also contains a theory about the drawer."))]),

        // MARK: Travel

        .make("build_mountains", 24...44, "🏔️", "Out of Office",
              "Two weeks of leave and a map with a crease down the middle. One side is mountains. The other is sea.", [
            .sure("Mountains", Effect(body: 4, heart: 8, money: -6, set: ["saw_mountains"], text: "Thin air, thick socks, a view that rearranges your priorities.")),
            .sure("Sea", Effect(heart: 7, bonds: 3, money: -5, set: ["saw_sea"], text: "Salt in your hair, sand in everything else. You send one postcard.")),
            .sure("Work through it", Effect(heart: -4, money: 4, add: [.workaholic], text: "The out-of-office never goes on. Your boss notices. Nobody else does."))]),

        .make("build_desert", 28...47, "🏜️", "Road Trip",
              "A friend with a van and no plan is driving across the desert. There is one seat left, and it does not recline.", [
            .gamble("Take the seat", 65,
                win: Effect(heart: 10, bonds: 6, money: -4, set: ["saw_desert"], text: "Stars like spilt salt. The van breaks down twice. You remember it forever."),
                lose: Effect(body: -6, heart: 3, money: -8, set: ["saw_desert"], text: "Heatstroke, a lost wallet, a scorpion in a boot. Technically a holiday.")),
            .sure("Fly over it", Effect(mind: 2, money: -4, text: "It's very beige from above. You take a photo of the wing."))]),

        // MARK: Debt (forced when money < -200, any age)

        .make("build_debt", 18...104, "💸", "The Red Letter",
              "The letters have gone from polite to bold to red. A man with a clipboard knows your dog's name.",
              weight: 5, once: false, priority: true, cond: Cond(maxMoney: -201), [
            .sure("Declare bankruptcy", Effect(mind: 2, heart: -8, bonds: -5, money: 200, income: 8, set: ["debt"], text: "Wiped clean, mostly. Your income takes a hit and your name goes on a list.")),
            .sure("Work it off", Effect(body: -10, heart: -8, money: 60, text: "Three jobs, four hours of sleep, one very tired dog. It's a dent.")),
            .gamble("Ask the family", 50,
                win: Effect(bonds: -6, money: 90, text: "A cheque and a look. The look costs more."),
                lose: Effect(heart: -6, bonds: -12, money: 25, text: "A smaller cheque and a much longer look. Christmas is cancelled."))])
    ]
}
