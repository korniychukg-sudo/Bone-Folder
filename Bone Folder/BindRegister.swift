import Foundation

enum SpineLook: String, Codable {
    case exposedChain, exposedLong, stab, tapes, cords, tightBack, hollowBack, limp, concertina
    case perfect, springback, clasped, flap, chained, girdle, butterfly, whirlwind, pouch, dosados, pamphlet, groove
}

struct HistoricBinding: Identifiable, Equatable {
    var key: String
    var name: String
    var date: String
    var region: String
    var structure: Structure?
    var look: SpineLook
    var summary: String
    var history: String
    var fails: String
    var facts: [String]
    var cover: Tint
    var id: String { key }
    var plate: String { "hb_" + key }
}

struct Tool: Identifiable, Equatable {
    var key: String
    var name: String
    var use: String
    var note: String
    var wrong: String
    var id: String { key }
    var plate: String { "tl_" + key }
}

enum LabelStyle: String, Codable, CaseIterable {
    case paperLabel, giltCloth, blindStamp, handLettered

    var name: String {
        switch self {
        case .paperLabel: return "Printed paper label"
        case .giltCloth: return "Gilt on cloth"
        case .blindStamp: return "Blind stamped"
        case .handLettered: return "Hand lettered"
        }
    }
}

struct BookTitle: Identifiable, Equatable {
    var key: String
    var title: String
    var client: String
    var wants: String
    var label: LabelStyle
    var id: String { key }
    var plate: String { "lb_" + key }
}

enum Register {
    private static func b(_ key: String, _ name: String, _ date: String, _ region: String, _ s: Structure?, _ look: SpineLook,
                          _ summary: String, _ history: String, _ fails: String, _ facts: [String], _ cover: Tint) -> HistoricBinding {
        HistoricBinding(key: key, name: name, date: date, region: region, structure: s, look: look, summary: summary,
                        history: history, fails: fails, facts: facts, cover: cover)
    }

    private static let bindingsA: [HistoricBinding] = [
        b("copticCodex", "The Coptic codex", "4th century", "Egypt", .copticTwo, .exposedChain,
          "Signatures sewn to each other with a chain stitch, no supports, boards of papyrus or wood attached by the same thread.",
          "The Nag Hammadi codices of about 350 are the oldest surviving books in this form. The chain stitch let the book open completely flat, which is why the structure was revived by twentieth-century binders.",
          "The chain is the only thing holding the book: one broken thread and the signatures fall away like leaves.",
          ["Nag Hammadi library: 13 codices, about 350 AD", "Opens to 180 degrees"], Tint(r: 0.52, g: 0.36, b: 0.22)),
        b("ethiopian", "The Ethiopian binding", "6th century onward", "Ethiopia", .ethiopian, .exposedChain,
          "A Coptic chain sewn with two needles, wooden boards drilled at the edge and caught into the chain, covered in goatskin or left bare.",
          "The Garima Gospels, dated by radiocarbon to the fifth or sixth century, are the oldest illuminated Christian manuscripts and are still in this binding. The form has been made without interruption since.",
          "The drilled board edge is the weak point: the thread saws through the holes and the board hangs by a thread.",
          ["Garima Gospels: 390 to 660 AD", "Boards of olive or juniper wood"], Tint(r: 0.45, g: 0.30, b: 0.18)),
        b("islamicFlap", "The Islamic flap binding", "9th century onward", "The Islamic world", .copticOne, .flap,
          "A link-stitched block, leather boards flush with the text, and a pentagonal flap on the back board that folds over the fore-edge and under the front cover.",
          "The flap protected the fore-edge of a book kept flat on a shelf, not standing. The leather was pared thin and tooled with a central medallion and corner pieces.",
          "Flush boards give the leaves no square to hide behind; the corners of the paper round off with use.",
          ["Flap: five sides, envelope point", "Boards flush with the text block"], Tint(r: 0.50, g: 0.20, b: 0.16)),
        b("carolingian", "The Carolingian binding", "8th to 9th century", "The Frankish empire", .kettleTapes, .cords,
          "Signatures sewn in a herringbone pattern onto double cords laced through oak boards, covered in alum-tawed skin.",
          "The supported sewing that Europe used for the next thousand years appears here first: the cords carry the weight of the boards, and the sewing is herringbone, not chain.",
          "The heavy oak boards crush the tawed skin at the joint; the covering splits along the hinge first.",
          ["Boards: quarter-sawn oak, up to 15 mm", "Herringbone sewing on double cords"], Tint(r: 0.86, g: 0.82, b: 0.72)),
        b("romanesque", "The Romanesque binding", "11th to 12th century", "Western Europe", .kettleTapes, .cords,
          "Thick sewing on split alum-tawed thongs, the thongs laced into channels in wooden boards, a tab at head and tail of the spine.",
          "Monastic bindings of the great twelfth-century Bibles: heavy, square and plain, sometimes with a chemise of skin over the whole book.",
          "The thongs dry out and snap at the joint; the boards then hang from the spine leather alone.",
          ["Endband tabs sewn through the spine", "Thongs of alum-tawed skin, split"], Tint(r: 0.84, g: 0.80, b: 0.68)),
        b("gothicClasps", "Gothic wooden boards with clasps", "13th to 15th century", "Northern Europe", .kettleTapes, .clasped,
          "Sewing on raised cords, wooden boards bevelled at the edges, covered in leather, with brass clasps to keep the vellum leaves flat.",
          "Vellum wants to cockle, so the book was clamped shut. Bosses on the covers kept the leather off the desk; a chain staple at the edge kept the book on the shelf.",
          "The clasp catches are the first to go: once they tear from the board, the vellum text block curls open.",
          ["Bevelled boards, brass clasps and bosses", "Raised cords: 3 to 5 across the spine"], Tint(r: 0.36, g: 0.22, b: 0.14)),
        b("limpVellum", "The limp vellum binding", "16th to 17th century", "Italy and England", .longStitch, .limp,
          "A block sewn through a vellum cover with a long stitch or onto tawed thongs laced through it, no boards, ties at the fore-edge.",
          "The cheap durable binding of the Renaissance stationer: account books, notebooks, printed books sold unbound. Nearly every one is still opening after four centuries.",
          "The cover moves with the weather; in a dry room it curls like a leaf and the ties pull out.",
          ["Ties: alum-tawed or silk, at the fore-edge", "Still the most durable structure of its age"], Tint(r: 0.92, g: 0.87, b: 0.74)),
        b("girdleBook", "The girdle book", "15th century", "Germany and the Low Countries", .kettleTapes, .girdle,
          "A small book whose leather covering extends far beyond the tail into a knot, so it could hang from a belt and be swung up to read.",
          "Made for prayer books and travelling law books; only about two dozen survive, though hundreds appear in paintings and sculpture of the period.",
          "The extension takes all the wear and tears away at the tail; most survivors have lost their knot.",
          ["Survivors: about 26 worldwide", "Read upside down while hanging"], Tint(r: 0.44, g: 0.26, b: 0.16))
    ]

    private static let bindingsB: [HistoricBinding] = [
        b("chainedBook", "The chained library book", "14th to 17th century", "England and Europe", .kettleTapes, .chained,
          "A heavy cord-sewn book with a chain riveted to the fore-edge of the front board, running on a rod along the shelf.",
          "The book was shelved fore-edge out so the chain would not tangle; the title was written on the fore-edge. Hereford Cathedral keeps the largest surviving chained library.",
          "The chain staple loosens and tears the board; the fore-edge takes the wear that a spine normally takes.",
          ["Hereford: about 1,500 chained books", "Shelved fore-edge outward"], Tint(r: 0.34, g: 0.24, b: 0.16)),
        b("fukuroToji", "Fukuro-toji, the pouch binding", "12th century onward", "Japan", .yotsume, .pouch,
          "Leaves printed on one side only, folded with the fold at the fore-edge, and the loose edges sewn through with a stab stitch.",
          "The standard Japanese book from the Heian period through the Edo period. The fold at the fore-edge hides the blank side of the thin paper.",
          "Stab sewing will not let the book open flat, and the margin at the spine must be left generous or the text disappears.",
          ["Four-hole yotsume toji is the standard", "Paper: thin kozo, printed one side"], Tint(r: 0.24, g: 0.30, b: 0.46)),
        b("butterfly", "The Chinese butterfly binding", "10th to 13th century", "Song China", nil, .butterfly,
          "Leaves folded with the print inside, the folds pasted one to the next at the spine, so each opening spreads like a butterfly.",
          "Hudie zhuang replaced the scroll for printed books. The spine was paper and paste only; a stiff paper wrapper was pasted over it.",
          "Paste is the only structure: when it dries out, the leaves fall off the spine one at a time.",
          ["No thread at all: paste at the fold", "Blank versos face each other"], Tint(r: 0.60, g: 0.28, b: 0.22)),
        b("whirlwind", "The Chinese whirlwind binding", "7th to 10th century", "Tang China", nil, .whirlwind,
          "Leaves pasted in sequence to a scroll, each a little longer than the last, so the scroll rolls up with the pages inside like a whirlwind.",
          "A transitional form between the scroll and the codex, used for rhyme dictionaries that had to be consulted quickly.",
          "Rolling and unrolling breaks the pasted edges; almost none survive intact.",
          ["Xuanfeng zhuang: the whirlwind", "Leaves attached to a scroll backing"], Tint(r: 0.70, g: 0.56, b: 0.34)),
        b("orihon", "The concertina, or orihon", "9th century onward", "China and Japan", .accordion, .concertina,
          "A long strip folded back and forth into panels, boards pasted to the first and last, no sewing.",
          "Buddhist sutras were folded from scrolls so a monk could find a passage without unrolling a metre of paper.",
          "Each fold is a hinge that opens and closes ten thousand times; the paper wears through at the mountains.",
          ["Panels folded mountain, valley, mountain", "Boards at both ends"], Tint(r: 0.86, g: 0.72, b: 0.40)),
        b("longStitchBinding", "The long stitch binding", "14th to 16th century", "Germany and the Low Countries", .longStitch, .exposedLong,
          "Signatures sewn directly through a limp cover with long visible stitches, often in a woven or twisted pattern.",
          "The account book and notebook binding of the late medieval merchant; fast to sew and needing no press.",
          "The thread rubs at the cover slots and the stitches saw through the cover in daily use.",
          ["Sewn straight through the cover", "No adhesive, no boards"], Tint(r: 0.58, g: 0.44, b: 0.28)),
        b("frenchLinkBinding", "The French link", "18th century", "France", .frenchLink, .tapes,
          "Sewing on tapes with the thread linked under the stitch of the signature below at each tape, making a chain of Vs.",
          "A stronger tape sewing that stops the signatures sliding on the tape; still the choice for a book that must open flat.",
          "Linked too tight, the block will not round; the French link wants a looser hand than the kettle stitch.",
          ["Links: one per tape per signature", "Chain of Vs down each tape"], Tint(r: 0.40, g: 0.36, b: 0.50)),
        b("tightBack", "The tight-back leather binding", "17th to 18th century", "England and France", .kettleTapes, .tightBack,
          "The leather is pasted directly to the rounded spine over the raised cords, so the bands show as ridges.",
          "The classic library binding of the age of Pepys and Johnson. Handsome and stiff: the spine leather creases when the book is opened wide.",
          "Every opening flexes the leather glued to the spine; the leather cracks along the bands within a century.",
          ["Raised bands: five, the classic number", "Leather glued to the spine"], Tint(r: 0.36, g: 0.18, b: 0.10))
    ]

    private static let bindingsC: [HistoricBinding] = [
        b("hollowBack", "The hollow back", "Late 18th century", "France", .kettleTapes, .hollowBack,
          "A paper tube is glued to the spine, and the covering leather is glued to the tube, not the spine, so the book opens without creasing.",
          "Invented in the 1770s and adopted everywhere in the nineteenth century; false bands could be added to imitate the tight back.",
          "A hollow made of thin paper collapses when the book is dropped; the spine then goes concave.",
          ["Hollow: a paper tube, one on, two off", "Spine flexes without creasing the leather"], Tint(r: 0.28, g: 0.30, b: 0.42)),
        b("bradel", "The Bradel binding", "1770s", "Germany and France", .kettleTapes, .hollowBack,
          "A case made of boards and a spine strip joined by a paper cover before it is put on the book; the German case binding.",
          "Named after Alexis-Pierre Bradel, binder in Paris; the case is made off the book and the block dropped in, which is what a publisher's case is too.",
          "A wide joint gap lets the book sag in the case; the lining must be exact.",
          ["Case built off the book", "Wide, flexible joint"], Tint(r: 0.30, g: 0.42, b: 0.40)),
        b("publishersCloth", "The publisher's cloth case", "1830s", "England", .kettleTapes, .hollowBack,
          "Signatures sewn on tapes, a case of boards and cloth made separately, stamped with gold or blind in a press, then the block cased in.",
          "Archibald Leighton's starch-filled cloth of the 1820s made a cheap whole-edition binding possible; by 1840 nearly every book was sold in cloth.",
          "The mull is the only thing holding the block to the case; when it tears at the joint, the block drops out.",
          ["Leighton's book cloth: about 1823", "Cased: the block dropped into a made case"], Tint(r: 0.18, g: 0.23, b: 0.36)),
        b("libraryBuckram", "The library buckram binding", "1890s onward", "United States and Britain", .kettleTapes, .hollowBack,
          "A rebinding for library use: the block oversewn or sewn on tapes, heavy boards, buckram, and a title stamped on the spine.",
          "The Library Binding Institute's standard from 1935 specified buckram, cord and thread; it is the binding that survives a hundred readers.",
          "Oversewing consumes the inner margin and the book will never open flat again.",
          ["Buckram: starch and pyroxylin filled", "Built for 100 circulations"], Tint(r: 0.30, g: 0.36, b: 0.48)),
        b("springback", "The springback ledger", "1799", "England", .kettleTapes, .springback,
          "A stiff levered spine that springs the book open flat and lifts the pages toward the writer.",
          "Patented by John and Joseph Williams in 1799 for account books; every Victorian ledger has one.",
          "The spring takes all the strain; when the lever board breaks the book will not close.",
          ["Patent: Williams, 1799", "Opens flat on the desk by itself"], Tint(r: 0.36, g: 0.28, b: 0.20)),
        b("quarterLeather", "The quarter-leather binding", "19th century", "Europe", .kettleTapes, .hollowBack,
          "Leather on the spine only, paper or cloth on the sides.",
          "The economical half-way house: the spine, which takes the wear, gets the leather; the sides get marbled paper.",
          "The leather ends where the wear begins: the sides fray at the corners first.",
          ["Leather: spine only", "Sides: paper or cloth"], Tint(r: 0.46, g: 0.34, b: 0.46)),
        b("halfLeather", "The half-leather binding", "18th to 19th century", "Europe", .kettleTapes, .hollowBack,
          "Leather on the spine and the corners, paper or cloth between.",
          "The library standard for a century: the corners take the second most wear and get leather too.",
          "A badly pared corner shows as a step under the paper and wears through there.",
          ["Leather: spine and four corners", "Marbled paper sides"], Tint(r: 0.56, g: 0.46, b: 0.44)),
        b("fullLeather", "The full-leather binding", "Any period", "Europe", .kettleTapes, .hollowBack,
          "Leather over the whole book, tooled in gold or blind.",
          "The binding of presentation and of price; goatskin took gold tooling in the sixteenth century and has ever since.",
          "Leather rots from the inside if the tannage was poor; red rot turns a spine to powder.",
          ["Goatskin, calf or pigskin", "Tooled with heated brass tools"], Tint(r: 0.40, g: 0.18, b: 0.12))
    ]

    private static let bindingsD: [HistoricBinding] = [
        b("frenchGroove", "The French groove", "19th century", "France", .kettleTapes, .groove,
          "The boards are set a little away from the spine so a groove runs down each joint, letting a heavy board swing.",
          "Standard on cased books with thick boards; the groove is pressed in with brass-edged boards while the case dries.",
          "Cloth in the groove wears through first, since every opening flexes it.",
          ["Groove: about a board's thickness wide", "Pressed with brass-edged boards"], Tint(r: 0.24, g: 0.28, b: 0.30)),
        b("secretBelgianBinding", "The Secret Belgian binding", "1986", "Belgium", .secretBelgian, .exposedLong,
          "Boards and a spine piece sewn together first, then the signatures sewn to the spine piece through the inside, so the book opens flat with no visible sewing on the spine.",
          "Invented by Anne Goy in 1986 and named criss-cross binding; the English name came from a mistranslation.",
          "Everything hangs on the cover thread; wear it through and the boards are loose.",
          ["Anne Goy, 1986", "Criss-cross binding is its proper name"], Tint(r: 0.44, g: 0.50, b: 0.40)),
        b("dosADos", "The dos-a-dos binding", "16th to 17th century", "England", .kettleTapes, .dosados,
          "Two books bound back to back, sharing a middle board, so the fore-edge of one is the spine of the other.",
          "Made for a New Testament and a Psalter to be carried together; often embroidered.",
          "The shared board must carry two spines' worth of strain; it splits along the middle.",
          ["Two text blocks, three boards", "Often a Testament and a Psalter"], Tint(r: 0.50, g: 0.40, b: 0.22)),
        b("perfectBinding", "The perfect binding", "1895, in use from the 1930s", "United States and Britain", nil, .perfect,
          "The folds are cut off, the spine roughened, and the loose leaves glued to a paper cover with a hot-melt adhesive.",
          "Patented in the 1890s, used by Penguin from 1935 and everywhere since. No sewing, no fold, no thread.",
          "The glue is the whole structure. Open it flat once and the spine cracks; the leaves then fall out from the middle.",
          ["Folds cut off, leaves glued", "Hot-melt adhesive from the 1940s"], Tint(r: 0.86, g: 0.50, b: 0.22)),
        b("stabBinding", "The stab binding", "Any period", "Japan, China and the West", .yotsume, .stab,
          "Loose leaves or folded sections sewn through the side near the spine edge, the thread wrapping the spine and the ends.",
          "In the West it is the cheap way to bind loose sheets; in Japan it is an art, with named patterns like the hemp leaf and the tortoise shell.",
          "It will not open flat; the inner margin must be wide or the text is lost in the gutter.",
          ["Hemp leaf: asa-no-ha, tortoise: kikko", "Gutter margin: 20 mm or more"], Tint(r: 0.32, g: 0.36, b: 0.50)),
        b("pamphletBinding", "The pamphlet", "16th century onward", "Everywhere", .pamphlet3, .pamphlet,
          "A single signature sewn through the fold with three or five holes into a paper wrapper.",
          "The quickest binding there is: a sermon, a tract, a play, a poem. Most of what was printed before 1800 was sold like this.",
          "The thread is the spine; pulled too tight it tears the fold, too loose and the wrapper slides.",
          ["Three holes, one thread, five minutes", "Five holes for anything over A4"], Tint(r: 0.78, g: 0.70, b: 0.52))
    ]

    static let bindings: [HistoricBinding] = bindingsA + bindingsB + bindingsC + bindingsD

    static func binding(_ key: String) -> HistoricBinding { bindings.first { $0.key == key } ?? bindings[0] }

    private static let toolsA: [Tool] = [
        Tool(key: "boneFolder", name: "Bone folder", use: "Creasing a fold, smoothing paste, turning in cloth, rubbing down a pastedown.",
             note: "Cut from cattle bone and polished; it burnishes without marking because bone is softer than most paper's sizing. Every binder has one that fits the hand and one that is lost.",
             wrong: "A sharp edge dragged along a fold on soft paper leaves a shiny line; work with the flat, not the edge."),
        Tool(key: "teflonFolder", name: "Teflon folder", use: "Smoothing damp paper and thin tissue where bone would leave a shine.",
             note: "Milled from a block of PTFE; it does not stick to paste and does not burnish.",
             wrong: "It is too soft to make a sharp crease in heavy paper; use bone for the fold, Teflon for the paste."),
        Tool(key: "awl", name: "Awl", use: "Punching the sewing stations through the fold.",
             note: "A fine steel point in a wooden handle; a straight awl punches a round hole, a bodkin a slit. Hold it upright and go straight through the fold.",
             wrong: "An awl too thick for the thread leaves a hole the stitch cannot fill, and the paper tears from it."),
        Tool(key: "needle", name: "Needle", use: "Carrying the thread through the stations.",
             note: "A bookbinder's needle is blunt so it finds the hole instead of making a new one; sizes 18 for thick linen, 20 to 22 for fine.",
             wrong: "A sharp needle makes a second hole beside the station and the stitch runs crooked."),
        Tool(key: "beeswax", name: "Beeswax", use: "Drawing the thread through before sewing so it grips and does not kink.",
             note: "A cake of pure beeswax; the thread is pulled across it twice. Waxed thread holds tension between pulls.",
             wrong: "Too much wax clogs the station and leaves grey smears on the paper."),
        Tool(key: "thread", name: "Thread", use: "The sewing itself, in linen, cotton or silk.",
             note: "Linen is the binder's thread: strong, stable, and it does not stretch. Cut a length from fingertip to shoulder for each signature.",
             wrong: "A thread too long tangles and frays; too short and the join lands at a station.")
    ]

    private static let toolsB: [Tool] = [
        Tool(key: "cuttingMat", name: "Cutting mat", use: "Under every knife cut, so the blade does not blunt on the bench.",
             note: "Self-healing vinyl with a grid; the grid squares the board before the straightedge goes down.",
             wrong: "A mat cut through in one place will steer the next blade into the same groove."),
        Tool(key: "knife", name: "Knife", use: "Cutting paper, cloth and thin board; paring leather with a different blade.",
             note: "A scalpel for paper, a heavier trimming knife for board, a paring knife with a bevel for leather. Change the blade before you think you need to.",
             wrong: "A dull blade drags the cloth and leaves a fuzzy edge that shows under the turn-in."),
        Tool(key: "straightedge", name: "Straightedge", use: "Guiding the knife along a ruled line.",
             note: "Steel, heavy, with a non-slip back; the knife runs along it, never toward the hand holding it.",
             wrong: "A light plastic rule shifts under the blade and the board comes out two millimetres off."),
        Tool(key: "pasteBrush", name: "Paste brush", use: "Laying paste on a board, an endpaper or the back of cloth.",
             note: "Round, with hog bristle; paste is brushed from the centre outward so the edges get the thinnest layer.",
             wrong: "Brushing inward drags paste under the edge and onto the face of the cloth."),
        Tool(key: "wheatPaste", name: "Wheat paste", use: "Endpapers, tipping, cloth, leather: anything that must be moved once it is down.",
             note: "Wheat starch cooked in water to a translucent jelly; it stays workable for a few minutes and can be reversed with water a century later.",
             wrong: "Paste that is too thin soaks through the paper and cockles it; too thick and it dries in ridges."),
        Tool(key: "pva", name: "PVA", use: "Spine linings, cases, anywhere a fast strong grab is wanted.",
             note: "Polyvinyl acetate emulsion; dries flexible and clear in minutes. Many binders mix it half and half with paste.",
             wrong: "Once it has set there is no moving it; a crooked endpaper glued with PVA stays crooked.")
    ]

    private static let toolsC: [Tool] = [
        Tool(key: "nippingPress", name: "Nipping press", use: "Pressing a cased book while the paste dries, flattening signatures after folding.",
             note: "A cast-iron screw press with a wheel or a bar; the book goes in between pressing boards and stays for hours.",
             wrong: "Taking the book out early leaves the boards warped toward the wet side."),
        Tool(key: "lyingPress", name: "Lying press", use: "Holding the block spine up for backing, ploughing and lining.",
             note: "Two wooden cheeks drawn together by wooden screws; it lies on its side on the bench, hence the name.",
             wrong: "Cheeks not parallel pinch one end of the block and the shoulders come out uneven."),
        Tool(key: "backingHammer", name: "Backing hammer", use: "Rounding the spine and knocking over the shoulders.",
             note: "A short heavy hammer with a wide slightly domed face; it taps the signatures over in small steps, never in one blow.",
             wrong: "Hit the middle too much and the spine goes into a hump; hit the shoulders too much and the block cracks."),
        Tool(key: "plough", name: "Plough", use: "Trimming the edges of the block in the lying press.",
             note: "A blade on a screw-driven carriage that runs along the press cheek, shaving a sliver of paper each pass.",
             wrong: "A dull plough tears the edge instead of cutting it and the book looks chewed."),
        Tool(key: "sewingFrame", name: "Sewing frame", use: "Holding tapes or cords upright and taut while the signatures are sewn to them.",
             note: "A wooden base with two uprights and a crossbar; the tapes are keyed under the slot and tied to the bar.",
             wrong: "Slack tapes let the signatures wander and the spine comes out crooked."),
        Tool(key: "punchingCradle", name: "Punching cradle", use: "Holding a signature open at the fold so the awl goes through the centre.",
             note: "A V-shaped trough; the template lies in it and the signature on top; the awl finds the fold every time.",
             wrong: "Without the cradle the awl wanders off the fold and the stations step across the spine.")
    ]

    static let tools: [Tool] = toolsA + toolsB + toolsC

    static func tool(_ key: String) -> Tool { tools.first { $0.key == key } ?? tools[0] }

    private static func t(_ key: String, _ title: String, _ client: String, _ wants: String, _ label: LabelStyle) -> BookTitle {
        BookTitle(key: key, title: title, client: client, wants: wants, label: label)
    }

    private static let titlesA: [BookTitle] = [
        t("fieldNotebook", "A field notebook", "a naturalist", "something that opens flat on a knee and takes rain", .handLettered),
        t("herbarium", "A herbarium", "a botanist", "wide pages for pressed specimens and a spine that will not crack", .paperLabel),
        t("commonplace", "A commonplace book", "a reader", "a book for copied passages, to be filled over years", .giltCloth),
        t("shipsLog", "A ship's log", "a master mariner", "a log that lies flat on the chart table in a swell", .blindStamp),
        t("recipeBook", "A recipe book", "a cook", "a kitchen book that stays open at the page", .paperLabel),
        t("sketchbook", "A sketchbook", "a painter", "heavy leaves and an exposed spine", .handLettered),
        t("travelJournal", "A travel journal", "a traveller", "a small book for a coat pocket, tough at the corners", .blindStamp),
        t("birdingList", "A birding list", "a birdwatcher", "narrow pages ruled for dates and names", .paperLabel),
        t("gardenDiary", "A garden diary", "a gardener", "a book that can go out to the beds and back", .handLettered),
        t("familyRegister", "A family register", "a parish clerk", "a heavy register to outlast three generations", .giltCloth)
    ]

    private static let titlesB: [BookTitle] = [
        t("songbook", "A songbook", "a choir master", "a book that opens flat on a music stand", .giltCloth),
        t("chessScorebook", "A chess scorebook", "a chess player", "ruled pages for a hundred games", .blindStamp),
        t("album", "An album", "a collector", "guards at the spine so the pages lie flat when full", .giltCloth),
        t("ledger", "A ledger", "a merchant", "a ledger that springs open on the counter", .blindStamp),
        t("hymnal", "A hymnal", "a chapel", "a small stout book for a pew", .giltCloth),
        t("poetryBook", "A poetry book", "a poet", "a slim, quiet book in a soft cover", .handLettered),
        t("atlas", "An atlas", "a schoolmaster", "a wide book with a spine that lets the maps open", .paperLabel),
        t("bestiary", "A bestiary", "an illustrator", "a book of beasts with room for margins", .handLettered),
        t("grammar", "A grammar", "a tutor", "a book to be thumbed at the same page for years", .paperLabel),
        t("starCatalogue", "A star catalogue", "an astronomer", "columns of numbers and a cover that reads in lamplight", .blindStamp)
    ]

    private static let titlesC: [BookTitle] = [
        t("tideTable", "A tide table", "a harbourmaster", "a narrow book that lives in a wet pocket", .paperLabel),
        t("phraseBook", "A phrase book", "a traveller", "a pocket book that opens with one hand", .paperLabel),
        t("cookeryBook", "A cookery book", "a housekeeper", "a big working book with wipeable boards", .giltCloth),
        t("dictionary", "A dictionary", "a printer", "a thick block that opens at any page without strain", .giltCloth),
        t("psalter", "A psalter", "a cantor", "a small devotional book with a good square", .blindStamp),
        t("mapBook", "A map book", "a surveyor", "an oblong book with folded plates", .paperLabel),
        t("stampAlbum", "A stamp album", "a philatelist", "guarded leaves and an exposed spine", .giltCloth),
        t("guestBook", "A guest book", "an innkeeper", "a handsome book for the hall table", .giltCloth),
        t("weatherDiary", "A weather diary", "a meteorologist", "a ruled book for a year of mornings", .handLettered),
        t("visitorBook", "A visitor book", "a museum", "a heavy book with a spine that stays flat", .blindStamp)
    ]

    private static let titlesD: [BookTitle] = [
        t("portfolio", "A portfolio", "an architect", "boards and a wide spine for loose drawings", .paperLabel),
        t("menuBook", "A menu book", "a restaurant", "a limp cover that survives spills", .handLettered),
        t("sermonBook", "A sermon book", "a preacher", "a plain strong book for the pulpit", .blindStamp),
        t("prayerBook", "A prayer book", "a chaplain", "a small book in a soft skin", .blindStamp),
        t("copybook", "A school copybook", "a schoolmistress", "a cheap pamphlet by the dozen", .paperLabel),
        t("letterBook", "A letter book", "a clerk", "a book for fair copies, thin paper, opens flat", .paperLabel),
        t("musicManuscript", "A music manuscript book", "a composer", "staves on cream paper and a spine that opens flat", .giltCloth),
        t("patternBook", "A pattern book", "a weaver", "a book that lies open on the loom bench", .handLettered),
        t("sampleBook", "A sample book", "a cloth merchant", "a stout book with swatches pasted in", .blindStamp),
        t("scrapbook", "A scrapbook", "a child", "big pages, an exposed spine, a cover in colour", .handLettered)
    ]

    static let titles: [BookTitle] = titlesA + titlesB + titlesC + titlesD

    static func title(_ key: String) -> BookTitle { titles.first { $0.key == key } ?? titles[0] }
}
