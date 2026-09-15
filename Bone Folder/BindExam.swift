import Foundation

enum Exam {
    private static func q(_ prompt: String, _ choices: [String], _ answer: Int, _ explain: String, plate: String? = nil, diagram: Structure? = nil) -> ExamQuestion {
        ExamQuestion(prompt: prompt, choices: choices, answer: answer, explain: explain, plate: plate, diagram: diagram)
    }

    private static let a: [ExamQuestion] = [
        q("In a finished book, which way does the grain of every leaf run?",
          ["Parallel to the spine", "Parallel to the head", "Diagonally", "It does not matter"], 0,
          "Grain runs with the spine so the leaves lie down when the book opens and the fold does not crack."),
        q("A landscape sheet folded once into a folio: which grain does it want?",
          ["Grain short", "Grain long", "Either", "Cross grain"], 0,
          "The fold is parallel to the short edge, so the grain must be short to run with the spine."),
        q("How many pages does an octavo signature have?",
          ["4", "8", "16", "32"], 2,
          "Three folds make sixteen pages; the name comes from eight leaves."),
        q("Which fold of an octavo becomes the spine?",
          ["The first", "The second", "The third", "Any of them"], 2,
          "The last fold is the spine; the first makes fore-edge bolts and the second the head bolts."),
        q("The squares of a cased book are usually how wide?",
          ["1 mm", "3 mm", "8 mm", "15 mm"], 1,
          "About three millimetres of board shows beyond the leaves on the head, tail and fore-edge."),
        q("What is the kettle stitch?",
          ["A running stitch inside the fold", "The link at the change-over station joining a signature to the one below",
           "A stitch over the tape", "The knot at the start"], 1,
          "At each end of the spine the thread is passed under the loop below before entering the next signature."),
        q("Which structure needs no tapes, cords or paste and opens completely flat?",
          ["Kettle stitch on tapes", "Coptic chain", "Perfect binding", "Tight back"], 1,
          "The Coptic chain links each signature to the next at every station and the spine stays free."),
        q("What does the awl do?",
          ["Cuts the boards", "Punches the sewing stations", "Smooths the paste", "Trims the edges"], 1,
          "The awl goes straight through the fold at each mark on the template.")
    ]

    private static let b: [ExamQuestion] = [
        q("The thread is pulled too hard at a station. What happens?",
          ["The spine goes baggy", "The paper tears at the station", "The tape slips", "Nothing"], 1,
          "Over the window the thread cuts the fold; under it the spine sags."),
        q("Which thread has the narrowest tension window?",
          ["Linen 18/3", "Linen 25/3", "Silk", "Tape"], 2,
          "Silk is slippery and strong: it slides back between pulls and cuts paper before it breaks."),
        q("Rounding aims at a spine curve of about",
          ["A quarter circle", "A third of a circle", "A half circle", "A full circle"], 1,
          "A third of a circle lets the book open and gives the fore-edge its matching hollow."),
        q("The shoulder made by backing should be as tall as",
          ["The thread", "The board", "The square", "The headband"], 1,
          "The board sits against the shoulder; a two millimetre board wants a two millimetre shoulder."),
        q("What is mull?",
          ["A leather", "Open cotton gauze lining the spine", "A kind of paste", "A pressing board"], 1,
          "The mull is pasted to the spine and its edges are pasted under the endpapers to hold the case."),
        q("Turn-ins on a cased book are usually",
          ["5 mm", "15 mm", "30 mm", "50 mm"], 1,
          "Fifteen millimetres holds well and does not reach into the pastedown."),
        q("A library corner is made by",
          ["Cutting the corner at 45 degrees", "Folding the corner in diagonally, then the two sides over it",
           "Leaving the corner open", "Sewing the corner"], 1,
          "Three layers at the tip make the strong corner of the cased book."),
        q("How long does a cased book stay in the nipping press?",
          ["Ten minutes", "One hour", "Six hours or overnight", "A week"], 2,
          "The boards are wet on one side and must be held flat until the water leaves.")
    ]

    private static let c: [ExamQuestion] = [
        q("Which is the oldest surviving sewn book structure?",
          ["Publisher's cloth case", "Coptic codex", "Springback ledger", "Perfect binding"], 1,
          "The Nag Hammadi codices of about 350 AD are Coptic chain bindings."),
        q("Why do paperbacks break at the spine?",
          ["The cloth is thin", "The leaves are glued, not sewn, and the glue cracks", "The boards warp", "The thread rots"], 1,
          "Perfect binding cuts off the folds and relies on adhesive alone."),
        q("Publisher's cloth cases became common in",
          ["The 1530s", "The 1670s", "The 1830s", "The 1950s"], 2,
          "Starch-filled book cloth of the 1820s made whole-edition casing possible within a decade."),
        q("The Secret Belgian binding was invented by",
          ["Alexis-Pierre Bradel", "Anne Goy", "Archibald Leighton", "John Williams"], 1,
          "Anne Goy made it in 1986 and called it the criss-cross binding."),
        q("In a Japanese pouch binding, where is the fold of each leaf?",
          ["At the spine", "At the fore-edge", "At the head", "There is no fold"], 1,
          "Leaves printed on one side are folded with the fold outward and stab-sewn at the loose edges."),
        q("A hollow back does what?",
          ["Glues the leather to the spine", "Puts a paper tube between spine and cover so the cover flexes free",
           "Removes the spine", "Adds clasps"], 1,
          "The tube lets the book open without creasing the covering."),
        q("Which board is the wrong answer for a case?",
          ["Greyboard 2 mm", "Millboard", "Binder's board", "Corrugated"], 3,
          "Corrugated board dents, crushes and shows its flutes through the cloth."),
        q("Which paper is wrong for a text block?",
          ["Book wove 100 gsm", "Cotton rag laid", "Newsprint", "Hemp paper"], 2,
          "Newsprint is acidic and brittle; it yellows and breaks at the fold.")
    ]

    private static let d: [ExamQuestion] = [
        q("Wheat paste is preferred over PVA for endpapers because",
          ["It is stronger", "It can be moved while wet and reversed with water later", "It dries faster", "It is brown"], 1,
          "Paste gives time to position and can be undone; PVA sets in minutes for good."),
        q("What is a bolt?",
          ["A brass clasp", "An uncut folded edge of a signature", "A sewing station", "A board fastener"], 1,
          "Bolts at the head and fore-edge are slit so the pages open."),
        q("A crooked station is one punched",
          ["With the wrong awl", "More than two millimetres off the mark", "Through the cover", "Twice"], 1,
          "Off the mark by more than two millimetres the stitch steps across the spine."),
        q("The French link differs from the plain kettle-stitch-on-tapes by",
          ["Using no tapes", "Linking under the stitch below at each tape", "Sewing from the tail", "Using two needles"], 1,
          "Each tape carries a chain of Vs so the signatures cannot slide."),
        q("Which structure attaches wooden boards with the same chain that sews the signatures?",
          ["Ethiopian", "Bradel", "Springback", "Long stitch"], 0,
          "The Ethiopian binding drills the board edges and sews them into the chain."),
        q("How many folds in a sextodecimo?",
          ["Two", "Three", "Four", "Five"], 2,
          "Four folds, thirty two pages."),
        q("Where is a book's tail?",
          ["The top edge", "The bottom edge", "The spine", "The fore-edge"], 1,
          "Head is the top, tail the bottom."),
        q("A spine width for a 128-page block of 100 gsm paper is about",
          ["2 mm", "9 mm", "25 mm", "60 mm"], 1,
          "Sixty four leaves of about 0.11 mm plus the thread swell come to eight to eleven millimetres.")
    ]

    static let authored: [ExamQuestion] = a + b + c + d

    static func foldQuestion(seed: UInt64) -> ExamQuestion {
        var rng = Bobbin(seed)
        let imposition = [Imposition.quarto, .octavo][rng.int(0, 1)]
        let sequences = Imposer.allSequences(imposition)
        let moves = sequences[rng.int(0, sequences.count - 1)]
        let readout = Imposer.readout(imposition, moves)
        let words = moves.map { $0.name }.joined(separator: ", then ")
        let front = readout.pages.first ?? 1
        var choices = Set([front])
        while choices.count < 4 { choices.insert(rng.int(1, imposition.pages)) }
        let list = Array(choices).sorted()
        let answer = list.firstIndex(of: front) ?? 0
        let explain = readout.correct
            ? "Those folds are the right sequence: page 1 lands on the front and the pages run in order."
            : (readout.fault ?? "The folds put the pages out of order.")
        let article = imposition == .octavo ? "An" : "A"
        return ExamQuestion(prompt: "\(article) \(imposition.name.lowercased()) sheet is folded \(words). Which page is on the front of the folded signature, spine to the left?",
                            choices: list.map { "Page \($0)" }, answer: answer, explain: explain, plate: nil, diagram: nil)
    }

    static func structureQuestion(seed: UInt64) -> ExamQuestion {
        var rng = Bobbin(seed)
        let all = Structure.allCases.filter { $0 != .accordion }
        let target = all[rng.int(0, all.count - 1)]
        var others = Set<Structure>()
        while others.count < 3 {
            let s = all[rng.int(0, all.count - 1)]
            if s != target { others.insert(s) }
        }
        var list = Array(others) + [target]
        for i in stride(from: list.count - 1, to: 0, by: -1) { list.swapAt(i, rng.int(0, i)) }
        let answer = list.firstIndex(of: target) ?? 0
        let hint = Register.bindings.first { $0.structure == target }?.summary ?? ""
        return ExamQuestion(prompt: "Which structure is drawn on this spine?", choices: list.map { $0.name }, answer: answer,
                            explain: "\(target.name): \(hint)", plate: "st_" + target.rawValue, diagram: target)
    }

    static let faults: [(String, String, [String])] = [
        ("The book will not open flat and the leaves stand up in a curve.", "The grain runs across the spine",
         ["The thread was too fine", "The boards were too thick", "The paste was too thin"]),
        ("The finished signature has page 1 on the back.", "The fold sequence was mirrored",
         ["The awl was too thick", "The squares were uneven", "The press was too short"]),
        ("One stitch steps sideways down the whole spine.", "A station was punched off the mark",
         ["The thread was unwaxed", "The mull was too wide", "The corner was cut too short"]),
        ("The inside of the fold shows a tear at every station.", "The thread was pulled too tight",
         ["The paper was too heavy", "The needle was too blunt", "The tapes were slack"]),
        ("The block sags in its case and the signatures gape.", "The sewing was too loose",
         ["The boards were too thin", "The hollow was too wide", "The kettle was at the wrong end"]),
        ("The spine has a hump in the middle and flat ends.", "Rounding taps were all in the middle",
         ["The backing lip was too small", "The lining was too thick", "The headband was too tight"]),
        ("The boards have a curve toward the fore-edge that will not press out.", "The book left the press too early",
         ["The cloth was too heavy", "The squares were too wide", "The thread was silk"]),
        ("Lumps show through the cloth on the spine.", "Bubbles were left under the lining",
         ["The kettle stitch was skipped", "The boards were millboard", "The spine piece was Bristol"]),
        ("One square is five millimetres and the others three.", "A board was cut off the ruled line",
         ["The turn-ins were too wide", "The fold was across the grain", "The thread was too thick"]),
        ("The cloth at the corner of a board is a lump.", "The corner was folded on heavy canvas without trimming",
         ["The paste was wheat starch", "The awl was too fine", "The block was rounded too far"])
    ]

    static func faultQuestion(seed: UInt64) -> ExamQuestion {
        var rng = Bobbin(seed)
        let f = faults[rng.int(0, faults.count - 1)]
        var list = f.2 + [f.1]
        for i in stride(from: list.count - 1, to: 0, by: -1) { list.swapAt(i, rng.int(0, i)) }
        let answer = list.firstIndex(of: f.1) ?? 0
        return ExamQuestion(prompt: "What went wrong? \(f.0)", choices: list, answer: answer,
                            explain: "\(f.1). The critique names this fault whenever it appears.", plate: nil, diagram: nil)
    }

    static func paper(seed: UInt64, count: Int = 12) -> [ExamQuestion] {
        var rng = Bobbin(seed)
        var pool = authored
        for i in stride(from: pool.count - 1, to: 0, by: -1) { pool.swapAt(i, rng.int(0, i)) }
        var out = Array(pool.prefix(max(0, count - 4)))
        out.append(foldQuestion(seed: rng.next()))
        out.append(foldQuestion(seed: rng.next()))
        out.append(structureQuestion(seed: rng.next()))
        out.append(faultQuestion(seed: rng.next()))
        for i in stride(from: out.count - 1, to: 0, by: -1) { out.swapAt(i, rng.int(0, i)) }
        return out
    }
}
