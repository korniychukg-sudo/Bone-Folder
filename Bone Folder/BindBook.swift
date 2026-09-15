import Foundation

struct Lesson: Identifiable, Equatable {
    var index: Int
    var title: String
    var summary: String
    var paragraphs: [String]
    var id: Int { index }
    var plate: String { "ls_\(index)" }
    var words: Int { paragraphs.reduce(0) { $0 + $1.split(separator: " ").count } }
}

struct GlossaryTerm: Identifiable, Equatable {
    var term: String
    var meaning: String
    var id: String { term }
}

struct ExamQuestion: Equatable {
    var prompt: String
    var choices: [String]
    var answer: Int
    var explain: String
    var plate: String?
    var diagram: Structure?
}

enum Lessons {
    private static let a: [Lesson] = [
        Lesson(index: 0, title: "Grain, and why it matters", summary: "Every sheet has a direction, and the book must agree with it.", paragraphs: [
            "Machine-made paper is born on a moving wire. The fibres are carried along in the flow of the pulp and settle pointing mostly one way, the way the paper travelled through the machine. That direction is the grain. Handmade paper, shaken on a mould, has fibres in every direction and no grain worth speaking of, which is one reason binders prize it. Mould-made paper, from a slowly turning cylinder, sits in between.",
            "Grain shows itself in three ways. A sheet folds cleanly along the grain and cracks or cockles across it, because across the grain the fold has to bend every fibre at right angles. A sheet bends easily with the grain and stiffly across it: hold a sheet by two edges and let it droop, then turn it ninety degrees. And a sheet takes water along the grain: paste it and it stretches across the fibres, then shrinks back as it dries, which is why a board pasted with the grain the wrong way warps into a curve.",
            "In a book the rule is simple and unforgiving: the grain runs parallel to the spine. Every leaf, every endpaper, every board and the cloth on it. A leaf with the grain across the spine will not lie down when the book is opened; it stands up in a curve, and the fold at the spine cracks along its length. A board with the grain across the spine warps toward the fore-edge as the paste dries and never comes back.",
            "You find the grain before you cut anything. Fold a corner both ways and feel which fold goes easily. Tear a scrap: it tears straight along the grain and wanders across it. Wet a scrap and watch which way it curls. Paper merchants mark the grain on the wrapper as long or short: grain long runs parallel to the long edge of the sheet, grain short parallel to the short edge. On a landscape sheet folded once into a folio, the spine is the short edge, so you want grain short. On a portrait sheet folded twice, quarto, the spine is the long edge, so you want grain long.",
            "The only fold that must run with the grain is the last one, the spine fold. In an octavo the first two folds cross it, and machine folders accept that: those folds become bolts that are slit open. But the spine fold across the grain is a fault that no amount of pressing cures. The book will not open flat, and it will tell everyone who opens it."
        ]),
        Lesson(index: 1, title: "Imposition and folding", summary: "The pages are printed out of order so the folds put them in order.", paragraphs: [
            "A signature is one sheet folded so that its pages come out in sequence. The printer arranges the pages on the sheet, some upside down, some out of order, in a pattern called the imposition. Fold the sheet the right way and the pattern resolves into pages one to sixteen. Fold it wrong and page nine is on the front and page three stands on its head.",
            "The count of folds gives the format its name. One fold is a folio: four pages. Two folds at right angles make a quarto: eight pages. Three folds make an octavo: sixteen pages, the format of nearly every novel. Four folds make a sextodecimo, sixteen leaves, thirty two small pages, and a thick little signature that needs every bolt slit before it opens. The names came from how many leaves a full sheet made, and they stuck long after sheet sizes changed.",
            "Right-angle folding is the rule: each fold is at ninety degrees to the last, and the last fold is the spine. On a landscape sheet an octavo goes right edge over to the left, bottom edge up to the top, right edge over to the left again. The first fold makes bolts at the fore-edge, the second at the head, and the third is the spine. Fold it in a different order and the spine lands at the head, with the pages lying sideways.",
            "The imposition and the folding are one thing seen from two ends. That is why the app derives the page pattern from the fold sequence rather than looking it up: whatever the folds do to the sheet, the pages must arrive in order. A mirror sequence, left over right instead of right over left, produces a booklet with page one on the back. Reading it, you see at once what went wrong.",
            "Fold accuracy is the other half. The edge you carry over must land exactly on the edge it meets. A folio out by two millimetres has a step at the fore-edge that no trimming hides. Line the edges up first, hold them with one hand, and only then run the bone folder down the crease from the middle out."
        ]),
        Lesson(index: 2, title: "The bone folder", summary: "One tool does the creasing, the smoothing and the turning in.", paragraphs: [
            "The bone folder is a flat blade of polished cattle bone, about the length of a hand, rounded at one end and pointed at the other. It does three jobs. It creases a fold hard enough that the fold stays. It smooths paper and cloth down onto paste without marking them. And its point turns cloth in over a board edge and works it into a corner.",
            "Bone was chosen because it is hard enough to burnish and soft enough not to cut. Steel would slice thin paper; wood would score it; a plastic folder squeaks and leaves a shine. Bone glides, warms in the hand, and takes on a polish from use. Every binder has a favourite that has worn to the shape of the grip.",
            "Creasing is the first skill. Fold the sheet, line up the edges, and hold them. Set the flat of the folder at the middle of the fold and draw it outward to one end in a single firm stroke, then from the middle to the other end. Speed and pressure both matter: a slow timid stroke leaves a soft fold that springs half open; a fast hard stroke sets it. On soft paper keep the folder flat, because the edge pressed into a fold burnishes a line that shows.",
            "The second skill is smoothing. When an endpaper is pasted down or cloth is laid on a board, air is trapped underneath in bubbles. The folder chases them out: work from the centre to the edges in overlapping strokes, through a sheet of waste paper so the folder does not polish the cloth. A bubble left under a pastedown dries as a blister.",
            "The point does the corners. Cloth turned in over a board leaves a little ear at each corner; the point tucks it, then the flat lays the turn-in down. In the app the folder is under your finger through every stage: a swipe along a fold creases it, and the speed of the swipe is the pressure."
        ])
    ]

    private static let b: [Lesson] = [
        Lesson(index: 3, title: "Stations and the awl", summary: "The holes are marked from a template and punched straight through the fold.", paragraphs: [
            "The sewing stations are the holes in the fold that the thread passes through. Their number and their spacing depend on the structure. A pamphlet has three or five; a Coptic block four to seven; a book on tapes has a kettle station near the head, another near the tail, and a pair either side of every tape. Whatever the count, every signature must have its stations in exactly the same places, or the stitches step across the spine.",
            "That is what the template is for: a strip of card the height of the signature with the stations marked, and the kettle stations set in from the ends by twelve millimetres or so. The template goes into the punching cradle, a V-shaped trough, and the signature goes on top opened at the fold. Each mark on the template is transferred by a prick of the awl through the fold.",
            "The awl must go through the fold itself, not beside it. The cradle helps by holding the signature open so the fold sits at the bottom of the V. Hold the awl upright, place the point on the mark, and push straight through. A tap off the mark by more than two millimetres makes a crooked station, and one crooked station makes one crooked stitch that every reader will see.",
            "The size of the hole matters as much as its place. The awl should be a shade thinner than the thread, so the stitch fills the hole. Too big and the thread rattles in it; too small and the needle tears its way through. Match awl to thread before you start, and wax the thread.",
            "The order of work is to fold every signature, press them, then punch them one at a time against the same template. Keep the signatures in order and the same way up as you go, head to head. It sounds like bookkeeping, and it is, but the alternative is a block that sews like a staircase."
        ]),
        Lesson(index: 4, title: "The kettle stitch", summary: "The link at the change-over station that ties one signature to the last.", paragraphs: [
            "Sewing on tapes is a running stitch inside each fold with the thread passing over the tapes on the outside. Enter at the kettle station near the head, come out at the station just before the first tape, go over the tape and in at the station just after it, and so on to the kettle station at the tail. Then the next signature goes on and you sew back the other way.",
            "The kettle stitch is what joins one signature to the next at each end. When the thread comes out at the tail station of a new signature, it is passed under the loop between the two signatures below, then drawn up, before it enters the next signature. It is a chain link made at the change-over station, and it locks the tension of the row just sewn. The name is probably from the German for a little chain, Kettelstich.",
            "Without the kettle the signatures are threaded but not linked: each row is free to slide along the tape. With it, every signature is tied to the one below at both ends and the block becomes one thing. It is the reason a book sewn on tapes can be rounded and backed, since the spine holds its shape only if the signatures are locked together.",
            "The kettle wants a particular tension: firm enough to close the gap between signatures, not so tight that it puckers the fold at the station. Pull toward the head or the tail, along the spine, never straight out from it, or the thread cuts the fold like a cheese wire.",
            "The French link is the kettle's cousin at the tapes. Instead of passing plainly over the tape, the thread dips under the stitch of the signature below on its way across. Each tape then carries a chain of small Vs down the spine, and the signatures cannot slide on the tapes at all."
        ]),
        Lesson(index: 5, title: "The Coptic stitch", summary: "A chain that links each signature to the one below and needs no support.", paragraphs: [
            "The Coptic stitch is the oldest sewing we have books in. The Egyptian codices of the fourth century were sewn this way, and the structure was found again by modern binders because it does something no other does: it lets a book open completely flat, page to page, with the spine exposed and the chain visible all the way down.",
            "There are no tapes or cords. Each signature is sewn to the one below at every station by a chain: the needle comes out of the station, passes under the stitch of the signature below, and goes back into the same station before travelling inside the fold to the next. Down the spine each station carries a chain of loops, like a row of knitting.",
            "With one needle you sew the first signature as a plain running row, climb into the second at the last station, and from then on chain at every station. With two needles, one on each end of a thread, you sew paired stations at once: both needles come out of the first signature, and at each new signature they enter, cross inside the fold, come out at each other's station and chain under the row below.",
            "The Ethiopian binding is the same chain with the boards inside it. The wooden boards are drilled at the edge, and the first and last passes go through the board holes so the chain holds the boards as it holds the signatures. No paste, no case; the book is sewn, and that is all it is.",
            "The chain has one weakness: it is the whole structure. A tight chain pulls the signatures against each other and the spine will not flex; a loose chain lets them gape. The tension window is wide for a heavy linen and narrow for silk, and every pull along the chain must land inside it."
        ])
    ]

    private static let c: [Lesson] = [
        Lesson(index: 6, title: "Tension", summary: "Every pull has a window, and the thread tells you where it is.", paragraphs: [
            "Sewing a book is mostly pulling thread, and how hard you pull decides what the book will be. Too loose and the signatures slide on each other; the spine goes baggy and the block sags in the case. Too tight and the thread cuts the paper at the station; the fold tears, the kettle puckers, and the book will not open beyond the tight row.",
            "The window between the two is real and you can feel it. Draw the thread up until the signature closes onto the one below and the loop takes the strain; then stop. On heavy linen, 18/3 or 25/3, the window is generous. Fine linen, 60/3, snaps before it tears the paper, so the ceiling is the thread's own. Silk is the hardest of all: slippery, so it slides back between pulls, and strong, so it cuts paper before it breaks.",
            "The direction of the pull matters as much as its force. Pull along the fold, toward the head or the tail, so the thread lies flat in the station. A pull straight up from the spine bends the thread over the edge of the hole and it saws through the fold. At the kettle, pull toward the end you are working from.",
            "Wax is part of tension. A waxed thread grips the paper and holds where you leave it; an unwaxed one creeps back a little between pulls and you end up tightening every stitch twice. Draw the thread across the beeswax before you thread the needle.",
            "The app judges every pull against the thread's window. Loose pulls make a baggy spine you can see in the finished book; tight pulls leave a torn station that shows on the inside of the fold for ever. The critique names both."
        ]),
        Lesson(index: 7, title: "Rounding and backing", summary: "The spine is knocked into a curve, then given shoulders for the boards.", paragraphs: [
            "A sewn block is thicker at the spine than at the fore-edge, because every signature carries a thread. Left flat, that swell makes the block wedge-shaped and the fore-edge concave. Rounding turns the swell into a curve: the spine is tapped with the backing hammer until it arcs, and the fore-edge takes the same curve inward. The target is about a third of a circle.",
            "Rounding is done in small taps, not blows. Hold the block on the bench spine up, thumbs on the fore-edge, and tap along the spine from the middle toward each edge, pushing the signatures over a little each time. Turn the block and tap the other side. Ten or twenty light taps do it; a heavy blow cracks the folds and drives the signatures into a hump in the middle. Tap too long and the curve flattens again as the signatures pass the centre.",
            "Backing makes the shoulders. The rounded block goes into the lying press between backing boards set a board's thickness below the spine, and the outer signatures are hammered over the edge of the boards until they form a ridge, the shoulder, on each side. The shoulder is the same height as the board that will sit against it, so the board hinges cleanly at the joint.",
            "The lip has to match the board: two millimetres for greyboard 2 mm, three for 3 mm. A shoulder too tall leaves the board proud; too small and the board sinks into the joint and the cloth wrinkles.",
            "Then the spine is lined. A layer of mull, the open cotton gauze, is pasted on and smoothed from the middle out; then a strip of kraft. Every bubble under a lining dries into a lump you can feel through the cloth. Headbands go on last, sewn or stuck at head and tail: two silks wound alternately in a rhythm, bead after bead."
        ]),
        Lesson(index: 8, title: "Boards, squares and the spine piece", summary: "The case is cut to the block, three millimetres over on every edge.", paragraphs: [
            "The boards are cut to the height of the block plus two squares, and to the width of the block from the shoulder to the fore-edge plus one square. The square is the margin of board that shows beyond the leaves: three millimetres is the usual, a little more on a big book, a little less on a small. It protects the edges of the leaves and it is the first thing a binder looks at on someone else's book.",
            "Cutting is done with a knife against a steel straightedge, several passes rather than one deep one. The board is marked with a pencil line and the blade runs along it. Two millimetres off the line shows: one square wider than the other three reads as a mistake from across the room.",
            "Grain again: the board's grain runs head to tail, parallel to the spine, or the board will warp as the cloth dries. Cheap greyboard is hard to read; bend it gently both ways and it flexes more easily along the grain.",
            "The spine piece is a strip of thin card, Bristol or manila, cut to the height of the boards and to the width of the rounded spine measured over the shoulders. It carries the cloth across the spine and gives the spine its shape. Too narrow and the boards pinch the block; too wide and the spine is hollow and sags.",
            "The three pieces are laid on the pasted cloth with the gaps between board and spine piece equal to the thickness of the board plus a little. Those gaps are the joints, where the boards hinge; a joint too narrow will not open, and a joint too wide lets the book flop."
        ])
    ]

    private static let d: [Lesson] = [
        Lesson(index: 9, title: "Covering and corners", summary: "Paste, turn-ins of fifteen millimetres, and a corner that stays neat.", paragraphs: [
            "The cloth is cut with fifteen millimetres to spare on every side, and pasted on the back. Paste is brushed from the centre outward so the edges get the least, then the boards and the spine piece are set down on it. The whole thing is turned over and the cloth rubbed down through waste paper with the bone folder.",
            "The turn-ins are the margins folded over the board edges. Head and tail first, then the fore-edges: each is drawn tight over the edge with the folder and laid down flat. Fifteen millimetres is enough to hold and not so much that it shows as a ridge under the pastedown. Twelve is the minimum; over twenty the turn-in reaches into the endpaper.",
            "Corners are where the four edges meet, and there are two ways. The library corner folds the corner of the cloth in diagonally over the board tip first, then turns the two sides in over it: three layers at the tip, strong, and the usual on cased books. The universal corner cuts the cloth off at forty five degrees, a board's thickness and a half from the tip, and turns the sides in so they just meet at the corner: flatter, tidier, and the one for thin cloth.",
            "On leather the corners are mitred, the two turn-ins pared to a feather edge and butted at forty five degrees, so there is no thickness at the tip at all. That is skilled work, and the reason a leather corner costs what it does.",
            "Casing in is the last of it. The endpaper of the block is pasted, the block is dropped into the case with the squares equal all round, and the book is nipped in the press for a moment to set the joints, then opened to check the pastedowns, then pressed properly."
        ]),
        Lesson(index: 10, title: "Pressing and drying", summary: "Hours in the press are part of the book; taking it out early warps the boards.", paragraphs: [
            "Paste is water, and water moves paper and board. When the case goes on and the endpapers are pasted down, the boards are wet on one side and dry on the other, and they want to curl toward the wet side. The press holds them flat while the water leaves; take the book out early and the boards set with a curve in them that never goes.",
            "The book goes into the nipping press between pressing boards, with a brass-edged board at each joint to press the groove in, and the screw is wound down hard. A cased book stays six hours at least, overnight better. A Coptic block or a long stitch, with no wet boards, needs an hour or two only to set its endpapers. A pamphlet can come out as soon as it has been nipped.",
            "Pressure alone is not enough; time is the point. The water has to leave through the edges of the board, slowly, with the board held flat the whole while. A book pulled after an hour looks fine on the bench and warps on the shelf by morning.",
            "Between the boards and the book go sheets of waste paper or blotting paper, changed once if the pastedowns were very wet. Nothing else: a rough board, a stray thread, a crease in the waste sheet, all print through into the cloth under pressure.",
            "After the press the book stands upright for a day to let the spine and the joints finish drying in the air, then it is ready. In the bindery of this app the press runs on the clock: the book stays in until the hours have passed, whatever else you do, and the Today page shows it there."
        ]),
        Lesson(index: 11, title: "The codex from the Copts to the publisher's case", summary: "Sixteen centuries of ways to hold a book together.", paragraphs: [
            "The codex, leaves folded and fastened at one edge, replaced the scroll between the second and fourth centuries, and the Copts of Egypt gave it its first sewing: a chain stitch linking one gathering to the next, with boards held in the same chain. The Ethiopian church kept that binding alive to the present day.",
            "Europe went another way. The Carolingian binders of the eighth century sewed onto cords laced into oak boards, and for a thousand years the Western book was a block of folded sheets sewn on supports, with heavy boards, leather over the lot, and clasps to keep vellum flat. The Romanesque binding was thick and square; the Gothic added bevelled boards, bosses and chains for the library shelf.",
            "The Renaissance lightened it. Limp vellum covers sewn through with a long stitch held the printed books of Aldus and the account books of Florence. Leather over pasteboard instead of wood made the book you could carry. In the seventeenth and eighteenth centuries the tight back, with the leather glued to the rounded spine over raised cords, was the standard; the hollow back of the 1770s let the spine flex without creasing.",
            "In the East the book had its own line: the Chinese butterfly and whirlwind bindings, glued rather than sewn, the concertina folded from the scroll, and the Japanese pouch binding stab-sewn through the margin with a pattern of thread, the four holes and the hemp leaf.",
            "The nineteenth century mechanised it. Book cloth, starch-filled cotton, appeared in the 1820s, and by the 1830s publishers were selling whole editions in cases made off the book and dropped on afterward. That is the cased book you hold now: signatures sewn on tapes, rounded and backed, a mull and a kraft lining, a case of two boards and a spine piece under cloth, stamped in a press. The perfect binding of the twentieth century cut the folds off and glued the leaves; it is faster, and it is why paperbacks break."
        ])
    ]

    static let all: [Lesson] = a + b + c + d
}

enum Glossary {
    private static func g(_ term: String, _ meaning: String) -> GlossaryTerm { GlossaryTerm(term: term, meaning: meaning) }

    private static let a: [GlossaryTerm] = [
        g("Awl", "A fine steel point in a handle, used to punch the sewing stations through a fold."),
        g("Backing", "Hammering the outer signatures of a rounded block over to form shoulders for the boards."),
        g("Bolt", "A folded edge of a signature that has not yet been cut; slit before the book will open."),
        g("Bone folder", "A flat blade of polished bone for creasing folds, smoothing paste and turning in cloth."),
        g("Boards", "The stiff covers of a book, cut from greyboard, millboard or wood."),
        g("Buckram", "A heavy starch-filled book cloth that wipes clean; the library binding cloth."),
        g("Case", "A cover of two boards and a spine piece under cloth, made off the book and attached afterward."),
        g("Casing in", "Attaching a sewn block to its case by pasting the endpapers down onto the boards."),
        g("Chain stitch", "Sewing in which each signature is linked to the one below by a loop, as in the Coptic binding."),
        g("Codex", "A book of folded leaves fastened at one edge, as opposed to a scroll."),
        g("Concertina", "A book made from a strip folded back and forth, also called an accordion or orihon."),
        g("Coptic binding", "An unsupported chain-stitched binding of Egyptian origin that opens completely flat."),
        g("Crease", "The set line of a fold, made hard with the bone folder."),
        g("Deckle", "The rough natural edge of a handmade sheet, left by the frame of the mould.")
    ]

    private static let b: [GlossaryTerm] = [
        g("Endpaper", "The folded sheet at each end of a block, half pasted to the board and half left free."),
        g("Folio", "A sheet folded once, giving two leaves and four pages; also a large book."),
        g("Fore-edge", "The edge of the book opposite the spine."),
        g("French groove", "A gap pressed between the board and the spine so a thick board can hinge."),
        g("French link", "A tape sewing in which the thread links under the stitch below at each tape."),
        g("Gathering", "A folded sheet or group of folded sheets sewn as one unit; another word for signature."),
        g("Grain", "The direction most fibres lie in a sheet; a book's grain runs parallel to the spine."),
        g("Greyboard", "Cheap grey pulp board used for case boards, sold by thickness."),
        g("Gutter", "The inner margin of a page, where it meets the spine."),
        g("Head", "The top edge of a book."),
        g("Headband", "A band of coloured silk sewn or stuck at head and tail of the spine."),
        g("Hollow back", "A spine with a paper tube between the block and the cover, so the cover flexes free."),
        g("Imposition", "The arrangement of pages on a sheet so they come out in order when folded."),
        g("Joint", "The hinge between a board and the spine, on the outside; the hinge inside is the inner joint.")
    ]

    private static let c: [GlossaryTerm] = [
        g("Kettle stitch", "The link made at the change-over station, tying a new signature to the one below."),
        g("Kozo", "Paper mulberry, the fibre of the strongest Japanese papers."),
        g("Laid paper", "Paper showing fine parallel lines from the wires of the mould."),
        g("Leaf", "One piece of paper in a book, with a page on each side."),
        g("Long stitch", "A sewing straight through a limp cover, with the stitches showing on the spine."),
        g("Lying press", "A wooden press with two cheeks and screws that lies on the bench for backing and ploughing."),
        g("Millboard", "A dense hard board of beaten rope and pulp for fine bindings."),
        g("Mull", "Open cotton gauze pasted to the spine as the first lining; it joins the block to the case."),
        g("Nipping press", "A screw press with a flat platen for pressing books while paste dries."),
        g("Octavo", "A sheet folded three times, sixteen pages; the common book format."),
        g("Pamphlet stitch", "A single signature sewn through the fold with three or five holes."),
        g("Paste", "Wheat starch cooked in water, the binder's reversible adhesive."),
        g("Pastedown", "The half of the endpaper pasted to the inside of the board."),
        g("Perfect binding", "Loose leaves glued at the spine with no sewing; the paperback method.")
    ]

    private static let d: [GlossaryTerm] = [
        g("Plough", "A blade on a screw carriage that trims the edges of a block in the lying press."),
        g("PVA", "Polyvinyl acetate glue, fast and flexible but not reversible."),
        g("Quarto", "A sheet folded twice, eight pages."),
        g("Rounding", "Tapping the spine of a sewn block into a curve of about a third of a circle."),
        g("Sewing frame", "A wooden frame that holds tapes or cords upright while the signatures are sewn to them."),
        g("Sextodecimo", "A sheet folded four times, thirty two pages."),
        g("Shoulder", "The ridge formed by backing, against which the board sits."),
        g("Signature", "A folded sheet forming a unit of the book; also the letter or number printed to identify it."),
        g("Spine", "The back of the book where the signatures are sewn."),
        g("Spine piece", "The strip of card in a case that spans the spine between the boards."),
        g("Square", "The margin of board showing beyond the leaves, usually about three millimetres."),
        g("Stab binding", "Sewing through the side of a stack of leaves near the spine edge, as in Japanese books."),
        g("Station", "A hole in the fold through which the sewing thread passes."),
        g("Tail", "The bottom edge of a book."),
        g("Tape", "A flat woven support the signatures are sewn over; its ends are pasted to the boards."),
        g("Tension", "How hard the thread is drawn at each pull; the window between baggy and torn."),
        g("Tipping", "Attaching a leaf or endpaper by a narrow line of paste along one edge."),
        g("Turn-in", "The margin of cloth or leather folded over the board edge onto the inside."),
        g("Vellum", "Calfskin limed, scraped and dried under tension; a writing surface and a covering."),
        g("Wove paper", "Paper made on a woven mesh, without laid lines.")
    ]

    static let all: [GlossaryTerm] = a + b + c + d
}
