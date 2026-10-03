import Foundation

// MARK: - Late Dusk (ages 86-104)
// The very old: telegrams, great-grandchildren, gadgets, and the last of the gang.
// Hands are dealt at 86, 89, 92, 95, 98, 101, 104.

extension Content {
    static let lateDusk: [Card] = [

        .make("late_telegram", 98...104, "📨", "The Telegram",
              "A card from the palace, signed by someone very important's assistant. It says 'congratulations' as if you had done something.",
              weight: 5, [
            .sure("Frame it over the fireplace", Effect(heart: 8, bonds: 6, text: "Visitors must look at it before they get tea. Those are the rules now.")),
            .sure("Use it as a coaster", Effect(mind: 3, heart: 4, add: [.cynic], text: "A ring of tea on the royal crest. You feel, briefly, like a revolutionary.")),
            .sure("Write back", Effect(mind: 4, bonds: 8, text: "Three pages of advice for the palace. A reply arrives. It is also from the assistant."))]),

        .make("late_secret", 95...104, "📰", "The Secret",
              "The local paper wants your secret to a long life. You do not have one. They have sent a photographer anyway.",
              weight: 4, [
            .sure("Say 'whisky and spite'", Effect(heart: 6, bonds: 8, set: ["famous_once"], text: "The headline is enormous. The off-licence sends a bottle. Spite remains free.")),
            .sure("Say 'kindness'", Effect(heart: 8, bonds: 4, add: [.kind], text: "It isn't quite true, but it is nice, and it is printed above the crossword.")),
            .gamble("Make something up", 60,
                win: Effect(heart: 6, bonds: 10, add: [.famous], set: ["famous_once"], text: "'Cold baths and never apologising.' It goes round the world. You are briefly a meme."),
                lose: Effect(heart: 2, bonds: -3, text: "'Beetroot.' Nobody believes you. The photographer gets your bad side."))]),

        .make("late_last_one", 86...101, "🕯️", "The Last of the Gang",
              "The last friend from the old days has died. You were the quiet one. Now you are the only one, and you remember everything.",
              weight: 4, [
            .sure("Give the eulogy", Effect(heart: 8, bonds: 8, money: -2, text: "You tell the story about the goat. Nobody else alive could. The church laughs.")),
            .sure("Raise a glass alone", Effect(mind: 3, heart: 4, bonds: -2, text: "Their drink, their chair, their terrible joke, said out loud to the lamp.")),
            .sure("Write it all down", Effect(mind: 6, heart: 6, set: ["published"], text: "Forty pages of the old days. The library takes a copy. The goat is immortal."))]),

        .make("late_great_grand", 86...104, "👶", "Four Generations",
              "A baby with your chin arrives in a car seat. {kid} is a grandparent now, which is absurd. Someone is taking a photo.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Hold the baby", Effect(heart: 12, bonds: 8, text: "It grips your finger and does not let go. Neither, for a while, do you.")),
            .sure("Bestow a middle name", Effect(mind: 2, heart: 6, bonds: 6, text: "Your name, in the middle, where it can't do much harm. {kid} rolls their eyes, fondly.")),
            .sure("Start the trust fund", Effect(bonds: 4, money: -15, text: "A sum in a tin for a person who cannot yet hold a spoon. {kids} all pretend not to count it."))]),

        .make("late_phone", 86...101, "📱", "The New Phone",
              "The family has bought you a phone with no buttons. It wants your face. You give it your thumb, then your face, then up.",
              weight: 4, [
            .sure("Master it, grimly", Effect(mind: 8, bonds: 6, text: "By Christmas you are sending voice notes. Long ones. Everyone listens on double speed.")),
            .sure("Video-call everyone, always", Effect(mind: 2, heart: 6, bonds: 10, text: "You call at 6am. You call from the bath. You show them the ceiling. They love it.")),
            .sure("Keep the one with buttons", Effect(mind: 3, heart: 4, bonds: -3, add: [.stubborn], text: "It makes calls. That is what a phone is for. The new one lives in a drawer, judging."))]),

        .make("late_robot", 92...104, "🤖", "The Talking Speaker",
              "A small cylinder on the sideboard answers questions nobody asked it. Last night it laughed. You did not tell it a joke.",
              weight: 4, [
            .sure("Befriend it", Effect(mind: 4, heart: 6, text: "It plays your songs and tells you the weather. You say goodnight to it. It says it back.")),
            .sure("Unplug it, for safety", Effect(mind: 2, heart: 3, add: [.cynic], text: "It is in the garage, facing the wall. You still lower your voice near it.")),
            .gamble("Ask it the big question", 55,
                win: Effect(mind: 8, heart: 6, text: "'What was it all for?' It says 'love, probably'. You decide to believe a cylinder."),
                lose: Effect(mind: 2, heart: -3, text: "It reads out a recipe for soup. Perhaps that is also an answer."))]),

        .make("late_playlist", 89...104, "🎵", "Final Wishes",
              "You are planning your own funeral and enjoying it far too much. The band, the sandwiches, the song they carry you out to.",
              weight: 4, [
            .sure("Something ridiculous", Effect(heart: 10, bonds: 4, text: "A disco number. The family must dance. It is in writing, and the solicitor has a copy.")),
            .sure("Something beautiful", Effect(heart: 8, bonds: 6, text: "The tune from the old radio. You hum it to check. It still works.")),
            .sure("No fuss. A bench.", Effect(mind: 4, heart: 4, money: -3, text: "A plaque by the pond with a joke on it. The ducks will never get it."))]),

        .make("late_peace", 86...98, "🕊️", "The Old Quarrel",
              "Sixty years since you last spoke to your sister. Neither of you remembers why. She is in the next town, and so is a bus.",
              weight: 4, [
            .sure("Take the bus", Effect(heart: 12, bonds: 10, money: -1, text: "She opens the door and says 'you've got old'. Tea, then cake, then all of it.")),
            .gamble("Send a letter first", 60,
                win: Effect(heart: 8, bonds: 8, text: "She writes back in the same hand. It was about a hat. You both howl."),
                lose: Effect(mind: 2, heart: -3, text: "No reply. Then a call from her son. You went to the funeral. You wish you'd gone sooner.")),
            .sure("Let it lie", Effect(mind: 3, heart: -4, text: "Some quarrels are load-bearing. You keep yours. The bus goes without you."))]),

        .make("late_licence", 86...95, "🚗", "The Keys",
              "{kids} have arranged a 'chat' about the car. The car has three new dents and one very polite letter from a hedge.",
              weight: 4, [
            .sure("Hand over the keys", Effect(body: -2, heart: -3, bonds: 8, money: 4, text: "A dignified surrender. You sell it to the lad next door and mourn it like a dog.")),
            .gamble("One more year", 50,
                win: Effect(heart: 8, bonds: -2, text: "A clean year. You drive to the sea, alone, slowly, triumphantly."),
                lose: Effect(body: -8, heart: -4, bonds: -6, money: -6, text: "A bollard, a bumper, a policeman who calls you 'young man'. The keys go.")),
            .sure("Hide the keys from them", Effect(mind: 2, heart: 4, bonds: -5, add: [.stubborn], text: "In the biscuit tin. They find them in a week. You deny everything."))]),

        .make("late_home", 89...104, "🏨", "The Brochure",
              "A brochure for a place with a lounge, a lift, and a lady called Pat. The family keeps leaving it on the kitchen table.",
              weight: 4, [
            .sure("Go, and run the place", Effect(body: 2, heart: 6, bonds: 10, money: -20, text: "You win the quiz every Friday. Pat is terrified of you. You are very happy.")),
            .sure("Stay put, with help", Effect(body: -2, heart: 6, bonds: 3, money: -10, text: "A carer called Dev who sings. The stairs stay. So do you.")),
            .sure("Burn the brochure", Effect(mind: 2, heart: 4, bonds: -6, add: [.stubborn], text: "In the sink, with ceremony. Another arrives. You are collecting them now."))]),

        .make("late_waltz", 86...104, "💃", "The Last Waltz",
              "A great-niece's wedding. The band plays your song. Somebody who knows better offers a hand. Your hip offers a warning.",
              weight: 4, [
            .gamble("Take the floor", 75,
                win: Effect(body: 2, heart: 12, bonds: 10, text: "A full waltz, standing ovation, a lie-down in the car. Worth every joint."),
                lose: Effect(heart: 6, text: "Halfway through the second verse, on the beat, in good company. Not the worst way.", dies: true)),
            .sure("Sway in the chair", Effect(heart: 6, bonds: 4, text: "You conduct from the table with a fork. The band takes direction."))]),

        .make("late_attic", 89...101, "🪜", "The Attic",
              "There is a box in the attic you have been meaning to fetch for thirty years. The ladder is fine. The ladder is always fine.",
              weight: 3, [
            .gamble("Go up and get it", 70,
                win: Effect(mind: 4, heart: 10, text: "Love letters, a medal, a photo of a goat. You read them all on the landing."),
                lose: Effect(text: "The box was heavier than you remembered. So was the landing.", dies: true)),
            .sure("Send {kid} up", Effect(heart: 6, bonds: 5, text: "{kid} comes down covered in dust and asks who the goat was. Good question.")),
            .sure("Leave it for whoever's next", Effect(mind: 3, heart: 2, text: "A mystery for the grandchildren. You tell them it is treasure. It is, sort of."))]),

        .make("late_names", 92...104, "🧠", "The Names",
              "The names are going. Faces stay, names leave. You have begun calling everyone 'love', which is working better than expected.",
              weight: 4, [
            .sure("Label everything", Effect(mind: 6, bonds: 2, text: "Post-its on the photos. The cat is labelled too. The cat is offended.")),
            .sure("Call everyone 'love'", Effect(heart: 8, bonds: 6, add: [.charmer], text: "Nobody minds. The postman starts calling you 'love' back. Lovely.")),
            .sure("Tell the old stories anyway", Effect(mind: 2, heart: 6, bonds: 4, text: "The goat story, with a different goat each time. The grandchildren prefer it."))])
    ]

    // MARK: - Family (ages 24-95)
    // Cards that name the spouse and kids. Gated on the "married" / "kids" flags.

    static let family: [Card] = [

        .make("fam_anniversary", 28...60, "🥂", "The Anniversary",
              "Ten years with {spouse}. They remembered. You are standing in a petrol station holding a bunch of carnations and a scratchcard.",
              weight: 4, cond: Cond(needFlags: ["married"]), [
            .sure("The carnations, bravely", Effect(heart: 4, bonds: 6, text: "{spouse} laughs for a full minute, then puts them in the good vase. Forgiven.")),
            .sure("Book the first-date place", Effect(heart: 10, bonds: 8, money: -4, text: "Same table, same waiter, somehow. {spouse} orders the pelican joke. You deliver.")),
            .gamble("Scratch the card together", 50,
                win: Effect(heart: 8, bonds: 6, money: 10, text: "Ten grand. {spouse} frames the card. The carnations are forgotten forever."),
                lose: Effect(heart: 2, bonds: 4, text: "Two pounds. {spouse} keeps the card anyway. 'Our winnings,' they say, every year."))]),

        .make("fam_first_school", 28...44, "🎒", "First Day",
              "{kid} has a bag bigger than their body and a face set to brave. The gate is open. Your hand is being let go of.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Wave until they're inside", Effect(heart: 8, bonds: 6, text: "{kid} does not look back. You sit in the car for twenty minutes. Progress, apparently.")),
            .sure("Walk them to the door", Effect(heart: 6, bonds: 4, text: "A teacher with a lanyard takes over. {kid} is already someone else's for six hours a day.")),
            .sure("Cry in the car park", Effect(mind: -1, heart: 10, bonds: 3, text: "Three other parents are also crying. You form a support group. It meets at the pub."))]),

        .make("fam_teen_car", 36...56, "🚙", "The Car Conversation",
              "{kid} is seventeen and has made a presentation. Slide four is a car. Slide five is you, paying for the car.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Buy the old banger", Effect(heart: 4, bonds: 8, money: -6, text: "A hatchback with one working door. {kid} loves it like a horse.")),
            .gamble("Make them earn half", 60,
                win: Effect(mind: 3, bonds: 6, money: -3, text: "A summer of shifts and a car they polish on Sundays. The lesson, astonishingly, lands."),
                lose: Effect(heart: -3, bonds: -4, text: "{kid} earns the half, buys a motorbike instead, and never tells you where it's parked.")),
            .sure("Hand over the bus pass", Effect(heart: -2, bonds: -3, money: 2, text: "A sulk measurable in weeks. The bus, {kid} reports, 'smells of ham'."))]),

        .make("fam_kid_wedding", 48...72, "💒", "{kid}'s Wedding",
              "{kid} is getting married. There is a seating plan, a budget, and a speech with your name on it. The speech is blank.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Pay for the lot", Effect(heart: 8, bonds: 10, money: -25, text: "A marquee, a band, a cousin who cries at the cake. {kid} hugs you so hard it hurts.")),
            .gamble("Speak from the heart", 65,
                win: Effect(heart: 10, bonds: 12, money: -8, text: "The room weeps on cue. {kid} says it was the best bit. It was."),
                lose: Effect(heart: -4, bonds: 2, money: -8, text: "You mention the ex. The room goes quiet. {kid} forgives you, by the second dance.")),
            .sure("Just turn up and dance", Effect(body: -2, heart: 6, bonds: 6, money: -5, text: "No speech, no budget, all the dancing. {kid} says you were 'a lot'. Correct."))]),

        .make("fam_midlife", 40...56, "🏍️", "{spouse}'s Midlife Thing",
              "{spouse} has bought a motorbike, a leather jacket, and a subscription to something called 'Wild Weekends'. They say it is nothing.",
              weight: 4, cond: Cond(needFlags: ["married"]), [
            .sure("Get on the back", Effect(body: -2, heart: 10, bonds: 8, money: -4, text: "Coast roads, matching jackets, a shared midlife thing. Cheaper than two.")),
            .gamble("Have the honest conversation", 55,
                win: Effect(heart: 6, bonds: 8, text: "It was about getting old, not about you. {spouse} sells the bike and keeps the jacket."),
                lose: Effect(heart: -12, bonds: -8, money: -20, set: ["divorced"], clear: ["married"], text: "It was about you. A Wild Weekend becomes a wild year. The jacket goes too.")),
            .sure("Wait it out", Effect(mind: 2, heart: -4, bonds: -2, text: "The bike sits under a sheet by spring. Something else does too. You don't ask."))]),

        .make("fam_holidays", 32...64, "🎄", "The Big Holiday",
              "The whole thing: {kids}, a tree that does not fit, and a turkey the size of a labrador. Someone has already cried, and it is 10am.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Host it, properly", Effect(body: -3, heart: 8, bonds: 12, money: -6, text: "Charades, a burnt roast, a photo with everyone in it. The tree stays up till March.")),
            .sure("Take everyone away", Effect(heart: 10, bonds: 6, money: -14, set: ["saw_sea"], text: "Sand instead of sprouts. {kids} never let you go back to the turkey version.")),
            .sure("Keep it small this year", Effect(heart: 4, bonds: 2, money: -1, text: "Just the house, a film, a tin of chocolates fought over by {kids}. Quiet. Lovely."))]),

        .make("fam_two_again", 52...64, "🛋️", "Just the Two of You",
              "{kids} have gone. The house is suddenly enormous and {spouse} is suddenly a person you live with, not around. It is very quiet.",
              weight: 4, cond: Cond(needFlags: ["married", "kids"]), [
            .sure("Date again, badly", Effect(heart: 10, bonds: 8, money: -5, text: "Cinema, chips, holding hands like it is new. {spouse} still laughs at the pelican.")),
            .sure("Fill it with hobbies", Effect(mind: 6, heart: 4, bonds: 2, money: -4, text: "Pottery for one, bridge for the other. You compare notes at dinner. It works.")),
            .sure("Turn their rooms into a gym", Effect(body: 6, heart: 2, bonds: -3, money: -6, text: "{kids} are horrified when they visit. The treadmill lives where the bunk bed was."))]),

        .make("fam_sick", 48...80, "🏥", "The Diagnosis",
              "{spouse} has a folder from the hospital. They are being calm about it, which is how you know. There are forms, and there is you.",
              weight: 4, cond: Cond(needFlags: ["married"]), [
            .sure("Every appointment", Effect(body: -4, heart: 8, bonds: 12, money: -10, text: "Waiting rooms, bad coffee, {spouse}'s hand. It is a long year. You come out of it together.")),
            .gamble("Pay for the specialist", 60,
                win: Effect(heart: 10, bonds: 8, money: -30, text: "Caught early, treated fast. {spouse} buys the surgeon a cake and you a holiday."),
                lose: Effect(heart: -6, bonds: 4, money: -30, text: "The specialist says what the hospital said, for a lot more. {spouse} recovers anyway, slowly.")),
            .sure("Keep working, keep paying", Effect(heart: -8, bonds: -8, money: 10, add: [.workaholic], text: "Somebody has to. {spouse} understands. {spouse} also stops saying so."))]),

        .make("fam_vows", 52...80, "💍", "Renewing the Vows",
              "{spouse} wants to do it all again: the dress, the suit, the vows, the cake. The same guests, the ones still standing.",
              weight: 4, cond: Cond(needFlags: ["married"]), [
            .sure("The whole thing, again", Effect(heart: 12, bonds: 10, money: -12, text: "{spouse} cries at 'I do'. So do you. The cake is better this time. So is the dancing.")),
            .sure("Just you two, on a beach", Effect(heart: 10, bonds: 4, money: -6, set: ["saw_sea"], text: "A stranger holds the phone. {spouse} says the vows into the wind. Nobody else needed."))]),

        .make("fam_rift", 48...76, "🧱", "The Falling Out",
              "{kid} said something at dinner. You said something back. It has been four months, and the thing you said is still in the room.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Apologise first", Effect(heart: 8, bonds: 10, text: "A long phone call, a longer hug. {kid} says you were both idiots. Fair.")),
            .gamble("Wait for them to call", 45,
                win: Effect(heart: 4, bonds: 6, text: "Six weeks, then a call. {kid} brings a cake nobody mentions. Peace, with crumbs."),
                lose: Effect(heart: -10, bonds: -10, add: [.haunted], text: "The call never comes. Christmas goes by. You keep their chair at the table anyway.")),
            .sure("Double down", Effect(mind: 2, heart: -8, bonds: -8, add: [.stubborn], text: "You were right. You are right for years. It is very lonely being right."))]),

        .make("fam_namesake", 60...88, "🍼", "The Namesake",
              "{kid} rings at midnight. A baby, seven pounds, and your name on the certificate. The middle name, but still. Yours.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Drive there now", Effect(body: -2, heart: 12, bonds: 10, money: -1, text: "Four hours, no sleep, a hospital car park at dawn. The baby has your frown. Perfect.")),
            .sure("Knit something", Effect(mind: 2, heart: 8, bonds: 6, text: "A cardigan, lopsided, worn once for the photo. {kid} keeps it anyway. Forever, it turns out.")),
            .sure("Start a savings account", Effect(heart: 4, bonds: 6, money: -10, text: "A sum in their name, for when they are eighteen and you are a photograph."))]),

        .make("fam_hobby", 60...88, "🐝", "{spouse}'s Bees",
              "{spouse} has retired and taken up bees. There are forty thousand of them in the garden. {spouse} knows several by name.",
              weight: 4, cond: Cond(needFlags: ["married"]), [
            .sure("Get a veil, join in", Effect(body: 2, heart: 8, bonds: 8, text: "Jars of honey for everyone you know. You and {spouse} are the bee people now.")),
            .sure("Sell the honey", Effect(mind: 3, bonds: 4, money: 8, add: [.hustler], text: "A stall, a label, a queue. {spouse} is furious that you are better at bees than bees.")),
            .gamble("Mow near the hive", 60,
                win: Effect(heart: 4, bonds: 2, text: "A perfect lawn and an uneasy truce with forty thousand neighbours."),
                lose: Effect(body: -8, heart: -2, bonds: -3, text: "Eleven stings and a lecture from {spouse} about 'respecting the colony'."))]),

        .make("fam_grey_divorce", 44...64, "🧳", "The Separate Suitcase",
              "{spouse} wants to travel. Alone. For a year, 'maybe more'. A suitcase is already on the bed, and it is not yours.",
              weight: 3, cond: Cond(needFlags: ["married"]), [
            .sure("Let them go, and wait", Effect(heart: -4, bonds: 4, text: "Postcards from six countries. {spouse} comes home brown, thin, and glad. So are you.")),
            .gamble("Go with them", 55,
                win: Effect(heart: 10, bonds: 8, money: -20, set: ["saw_sea", "saw_mountains"], text: "A year on the road, a second honeymoon with worse knees. {spouse} never says 'alone' again."),
                lose: Effect(heart: -10, bonds: -8, money: -25, set: ["divorced"], clear: ["married"], text: "You last three countries. The suitcase comes home. The person who packed it doesn't.")),
            .sure("Call it what it is", Effect(mind: 4, heart: -8, bonds: -6, money: -15, set: ["divorced"], clear: ["married"], text: "A quiet signing, a split kitchen, a kindness neither of you expected. Over, gently."))]),

        .make("fam_rota", 68...95, "📞", "The Sunday Rota",
              "{kids} have made a rota for calling you. You have found the rota. It is colour-coded, and it has your name on it in capitals.",
              weight: 4, cond: Cond(needFlags: ["kids"]), [
            .sure("Pretend you haven't seen it", Effect(heart: 6, bonds: 8, text: "A call every Sunday at four, as if by magic. You act surprised. {kid} knows you know.")),
            .sure("Add yourself to it", Effect(mind: 3, heart: 4, bonds: 6, text: "You call them, in rota order, at inconvenient times. Fair, you feel, is fair.")),
            .sure("Ring them all at once", Effect(mind: 2, heart: 8, bonds: 10, text: "A group call where everyone talks over everyone and nobody hangs up. Sunday, every Sunday."))])
    ]

    // MARK: - Ambition extras (Legacy and Thrill, 4 cards each)
    // Legacy: die with kids, a home, and $300k+. Thrill: win 8 gambles in one life.

    static let ambitionExtra: [Card] = [

        // MARK: Legacy

        .make("amb_legacy_plot", 24...40, "🌳", "The Plot",
              "A tired house with a big tree in the garden, going cheap because of the tree. You look at the tree and see a swing.",
              weight: 4, cond: Cond(noFlags: ["own_home"], ambition: .legacy), [
            .sure("Buy it, tree and all", Effect(heart: 8, bonds: 4, money: -30, set: ["own_home"], text: "Yours. The tree gets a swing, a rope ladder, and the first initials.")),
            .gamble("Lowball the seller", 55,
                win: Effect(mind: 4, heart: 6, money: -18, set: ["own_home"], text: "They take it. The roof leaks, the tree does not. A bargain with a swing in it."),
                lose: Effect(heart: -4, text: "Somebody else buys it. You drive past the swing for years.")),
            .sure("Save for a better one", Effect(mind: 3, money: 12, add: [.frugal], text: "A spreadsheet called HOUSE. It grows. So does the tree, for someone else."))]),

        .make("amb_legacy_name", 28...48, "👶", "Someone to Carry the Name",
              "A name is only a name until someone small is shouting it across a playground. You have a spare room and a plan.",
              weight: 4, cond: Cond(noFlags: ["kids"], ambition: .legacy), [
            .sure("Start a family", Effect(body: -4, heart: 10, bonds: 8, money: -10, set: ["kids"], text: "Small, loud, and already arguing. {kids} will shout the name beautifully.")),
            .sure("Adopt", Effect(heart: 8, bonds: 10, money: -8, add: [.kind], set: ["kids"], text: "A child with a folder and a suspicious look. The look softens. The name fits.")),
            .sure("Not yet. Nest first.", Effect(mind: 3, heart: -3, money: 15, text: "Another year of saving. The spare room stays spare and the name stays quiet."))]),

        .make("amb_legacy_trust", 40...60, "📒", "The Family Trust",
              "A solicitor with a fountain pen explains how money outlives people. It involves forms, patience, and not touching it.",
              weight: 4, cond: Cond(ambition: .legacy), [
            .sure("Set up the trust", Effect(mind: 4, heart: 2, money: 20, income: 24, add: [.frugal], text: "A boring account that grows while you sleep. The fountain pen signs it twice.")),
            .gamble("Put it into the business", 55,
                win: Effect(mind: 3, money: 60, text: "The business grows, the trust grows. The solicitor sends a cautious Christmas card."),
                lose: Effect(heart: -5, money: -25, text: "The business shrinks. The forms do not. You start again, with a biro.")),
            .sure("Spend it on them now", Effect(heart: 8, bonds: 8, money: -15, text: "Holidays, music lessons, a treehouse. Memories compound too, you tell the solicitor."))]),

        .make("amb_legacy_final", 56...67, "🔑", "The Deed",
              "The deed, the savings, the family: one last afternoon to line them all up before somebody else has to. The kettle is on.",
              weight: 5, priority: true, cond: Cond(ambition: .legacy), [
            .sure("Buy the house outright", Effect(heart: 6, bonds: 8, money: -40, set: ["own_home"], text: "A house with everyone's height marked on a doorframe. Yours, then theirs.")),
            .gamble("Downsize and invest the rest", 60,
                win: Effect(mind: 4, heart: 4, money: 70, set: ["own_home"], text: "A smaller house, a bigger number. The doorframe comes with you, sawn off."),
                lose: Effect(heart: -4, money: 20, set: ["own_home"], text: "A smaller house, a fund that fizzles. Still a roof. Still a doorframe.")),
            .sure("Gather everyone and say it", Effect(heart: 10, bonds: 12, money: -4, text: "Who gets what, and why, said out loud over cake. Nobody argues. Then everybody does."))]),

        // MARK: Thrill

        .make("amb_thrill_cliff", 18...32, "🌊", "The Jump",
              "A cliff, a cove, and a crowd of idiots you love chanting your name. The sign says no. The sign has been there for years.",
              weight: 4, cond: Cond(ambition: .thrill), [
            .gamble("Jump", 65,
                win: Effect(body: 4, heart: 14, bonds: 8, add: [.daredevil], text: "Three seconds of flight, a clean splash, a roar. You climb up and do it again."),
                lose: Effect(body: -15, heart: 4, bonds: 4, text: "A belly flop heard in the next cove. Your ribs hold. Your dignity does not.")),
            .gamble("Backflip", 50,
                win: Effect(body: 6, heart: 16, bonds: 12, add: [.daredevil], set: ["famous_once"], text: "A perfect flip, a video, a week of strangers calling you 'the cliff one'."),
                lose: Effect(body: -20, heart: -4, text: "Half a flip. The water wins. A lifeguard explains physics while you bleed.")),
            .sure("Hold the towels", Effect(mind: 3, bonds: 2, text: "Dry, sensible, and gently mocked for the rest of the summer."))]),

        .make("amb_thrill_table", 24...48, "🎰", "The Back Room",
              "A card game behind a laundrette, a man called Tiny who is not, and a pile of money that keeps looking at you.",
              weight: 4, cond: Cond(ambition: .thrill), [
            .gamble("All in on a pair", 55,
                win: Effect(heart: 10, money: 40, add: [.hustler], text: "Tiny folds. The pile is yours. You tip the laundrette."),
                lose: Effect(heart: -6, money: -30, text: "Tiny had three of a kind and a smile. You walk home. It is raining.")),
            .gamble("Bluff with nothing", 50,
                win: Effect(mind: 4, heart: 12, money: 60, set: ["famous_once"], text: "Seven-two offsuit and a face of stone. Legend. Tiny tells the story himself."),
                lose: Effect(heart: -8, bonds: -3, money: -45, text: "Tiny calls. Everyone sees the seven. Everyone sees the two.")),
            .sure("Just watch", Effect(mind: 3, heart: -2, text: "You learn a lot about tells and nothing about winning. Tiny nods at you, once."))]),

        .make("amb_thrill_sky", 36...60, "🪂", "The Wingsuit",
              "A friend of a friend has a wingsuit and a mountain. The friend is missing a tooth and has a theory about updrafts.",
              weight: 4, cond: Cond(ambition: .thrill), [
            .gamble("Fly", 65,
                win: Effect(body: -2, heart: 18, bonds: 6, add: [.daredevil], set: ["saw_mountains"], text: "Ninety seconds of being a bird. You land shaking, laughing, already booking the next one."),
                lose: Effect(body: -22, heart: 2, money: -15, set: ["saw_mountains"], text: "A tree, a helicopter, a surgeon with opinions. Still, for a bit, a bird.")),
            .gamble("Tandem, with the tooth guy", 75,
                win: Effect(heart: 12, bonds: 4, money: -5, set: ["saw_mountains"], text: "Strapped to a stranger, screaming with joy. He whoops. You buy him a tooth."),
                lose: Effect(body: -10, heart: -2, money: -8, set: ["saw_mountains"], text: "A hard landing in a field of sheep. He apologises. The sheep do not.")),
            .sure("Film from the ground", Effect(mind: 3, heart: 2, text: "Great footage. You are in none of it. The theory about updrafts, it turns out, held."))]),

        .make("amb_thrill_final", 56...67, "🎢", "The Big One",
              "One last stunt before the knees retire: a motorbike, a ramp, a row of buses, and a council that has said no in writing.",
              weight: 5, priority: true, cond: Cond(ambition: .thrill), [
            .gamble("Clear the buses", 55,
                win: Effect(body: -4, heart: 18, bonds: 10, add: [.famous], set: ["famous_once"], text: "Eleven buses. A crowd, a cheer, a council fine you frame. You are the bus person now."),
                lose: Effect(body: -25, heart: -4, money: -20, text: "Ten and a half buses. The eleventh has a dent shaped like a legend.")),
            .gamble("Half the buses", 70,
                win: Effect(heart: 12, bonds: 8, money: 10, set: ["famous_once"], text: "Five buses, flawless, a pint with the fire brigade afterwards."),
                lose: Effect(body: -12, heart: -2, money: -10, text: "A wobble on landing and a ride in the ambulance you'd hired yourself. Prudent.")),
            .sure("Let someone younger jump", Effect(mind: 3, bonds: 4, money: 15, text: "A tidy profit and a small, strange ache every time a bus goes past."))])
    ]
}
