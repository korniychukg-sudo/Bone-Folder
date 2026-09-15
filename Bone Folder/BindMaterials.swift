import Foundation

enum MaterialKind: String, Codable, CaseIterable {
    case paper, cloth, leather, thread, board

    var name: String {
        switch self {
        case .paper: return "Papers"
        case .cloth: return "Book cloths"
        case .leather: return "Leathers and skins"
        case .thread: return "Threads"
        case .board: return "Boards"
        }
    }

    var drawer: String {
        switch self {
        case .paper: return "Paper drawer"
        case .cloth: return "Cloth drawer"
        case .leather: return "Leather drawer"
        case .thread: return "Thread and board drawer"
        case .board: return "Thread and board drawer"
        }
    }
}

struct Tint: Equatable {
    var r: Double
    var g: Double
    var b: Double
}

struct Material: Identifiable, Equatable {
    var key: String
    var kind: MaterialKind
    var name: String
    var spec: String
    var gsm: Double
    var grain: Grain
    var texture: PaperTexture
    var tone: Tint
    var use: String
    var note: String
    var wrong: String
    var benchOK: Bool
    var id: String { key }
    var plate: String { "mt_" + key }
    var thread: ThreadKind? { ThreadKind(rawValue: key) }
    var boardMM: Double { kind == .board ? gsm : 0 }
}

enum Materials {
    static func paper(_ key: String, _ name: String, _ gsm: Double, _ grain: Grain, _ texture: PaperTexture,
                      _ tone: Tint, _ use: String, _ note: String, _ wrong: String, ok: Bool = true) -> Material {
        Material(key: key, kind: .paper, name: name, spec: "\(Int(gsm)) gsm, \(grain.name.lowercased()), \(texture.name)",
                 gsm: gsm, grain: grain, texture: texture, tone: tone, use: use, note: note, wrong: wrong, benchOK: ok)
    }

    static func other(_ key: String, _ kind: MaterialKind, _ name: String, _ spec: String, _ value: Double,
                      _ tone: Tint, _ use: String, _ note: String, _ wrong: String, ok: Bool = true) -> Material {
        Material(key: key, kind: kind, name: name, spec: spec, gsm: value, grain: .long, texture: .wove,
                 tone: tone, use: use, note: note, wrong: wrong, benchOK: ok)
    }

    private static let papersA: [Material] = [
        paper("ragLaid", "Cotton rag laid", 120, .long, .laid, Tint(r: 0.93, g: 0.89, b: 0.80),
              "Text blocks, endpapers, fine pamphlets.",
              "Made on a mould with wires that leave the laid lines and chain lines you see against the light. Cotton rag has long fibres and folds a hundred times without cracking.",
              "Folded across the grain it cockles along the crease and the book will not lie open."),
        paper("ragWove", "Cotton rag wove", 110, .long, .rag, Tint(r: 0.95, g: 0.92, b: 0.85),
              "Text blocks where a smooth page is wanted.",
              "Wove paper is made on a woven mesh, so it has no lines; Baskerville had the first made in 1757 for his Virgil.",
              "Too much size makes it stiff, and a stiff page fights the spine every time the book opens."),
        paper("mouldMade", "Mould-made 300 gsm", 300, .long, .rag, Tint(r: 0.96, g: 0.94, b: 0.88),
              "Covers of pamphlets and limp bindings, folders, the accordion's boards.",
              "Made on a slowly turning cylinder mould, so the fibres lie in every direction and the deckle edge is real.",
              "As a text page it is far too heavy: the fold cracks and the signature will not close.", ok: false),
        paper("hotPressed", "Hot-pressed watercolour", 300, .long, .rag, Tint(r: 0.97, g: 0.96, b: 0.92),
              "Cover papers, drawing leaves in a sketchbook.",
              "Pressed between hot plates until the surface is glassy. Takes a pen line without feathering.",
              "The surface is so hard that paste sits on it rather than in it; the turn-ins lift after a week.", ok: false),
        paper("coldPressed", "Cold-pressed watercolour", 300, .long, .rag, Tint(r: 0.95, g: 0.94, b: 0.90),
              "Sketchbook leaves in a single folio, cover papers.",
              "Pressed cold, so the felt texture stays. Called NOT in Britain, as in not hot-pressed.",
              "Heavy leaves in a sewn signature pull the stations open; use two leaves a section at most.", ok: false),
        paper("kozo", "Kozo tissue", 12, .long, .kozo, Tint(r: 0.97, g: 0.96, b: 0.93),
              "Hinges, repairs, guarding a torn fold, lining a fragile spine.",
              "Paper mulberry fibre, long and strong; a repair that is almost invisible and can be lifted again with water.",
              "As a text page it is too thin to hold a stitch: the thread cuts straight through.", ok: false),
        paper("gampi", "Gampi", 30, .long, .kozo, Tint(r: 0.96, g: 0.93, b: 0.86),
              "Interleaving, translucent leaves, a delicate cover over a coloured paper.",
              "The most lustrous of the Japanese fibres, naturally sized, with a faint sheen and a rustle like silk.",
              "Insects love it; store it dry, and never paste it wet, or it stretches and dries in ridges.", ok: false),
        paper("mitsumata", "Mitsumata", 40, .long, .kozo, Tint(r: 0.95, g: 0.93, b: 0.88),
              "Thin text leaves in a stab binding, pouch-bound pages.",
              "Softer than kozo, with a fine even surface that was used for Japanese banknotes.",
              "It creases where it is looked at; keep the bone folder flat and do not burnish the page.")
    ]

    private static let papersB: [Material] = [
        paper("khadi", "Khadi cotton", 210, .long, .rag, Tint(r: 0.94, g: 0.90, b: 0.80),
              "Sketchbook leaves, wrappers, a heavy folio.",
              "Indian handmade paper from cotton rag offcuts, with four deckle edges and a mottled surface.",
              "Thick and short-fibred: a fold across the grain snaps the surface into white lines."),
        paper("lokta", "Lokta", 60, .short, .kozo, Tint(r: 0.91, g: 0.86, b: 0.72),
              "Text leaves for a long stitch, endpapers, covers of small books.",
              "From the bark of the Himalayan daphne shrub, made in Nepal for centuries; strong, cloudy, slightly waxy.",
              "The cloudiness is uneven thickness; a thin patch under a station tears at the first pull."),
        paper("bamboo", "Bamboo paper", 70, .long, .wove, Tint(r: 0.93, g: 0.90, b: 0.78),
              "Text leaves, Chinese-style bindings, calligraphy books.",
              "Bamboo pulp was the everyday paper of southern China from the Song dynasty; soft, absorbent, yellowish.",
              "Absorbent means paste bleeds through; tip endpapers with the thinnest line you can draw."),
        paper("hemp", "Hemp paper", 90, .long, .wove, Tint(r: 0.90, g: 0.88, b: 0.80),
              "Text blocks for a working book, journals, ledgers.",
              "Hemp was the fibre of the earliest Chinese paper, second century, and of European rag paper's rope scraps.",
              "It is strong along the fibre and weaker across; punch the stations with a fine awl or they spread."),
        paper("vellum", "Vellum, true", 200, .long, .rag, Tint(r: 0.94, g: 0.90, b: 0.80),
              "Limp vellum covers, a single leaf for a certificate, spine linings on the best work.",
              "Calfskin, limed, scraped and dried under tension; a writing surface for fifteen hundred years.",
              "It moves with the weather: a vellum cover pasted down wet will pull the boards into a curve.", ok: false),
        paper("parchment", "Parchment, true", 180, .long, .rag, Tint(r: 0.92, g: 0.87, b: 0.74),
              "Wrappers, spine strips, the girdle book's flap.",
              "Sheepskin or goatskin prepared like vellum, a little greasier and more yellow.",
              "Too greasy for paste in places; degrease with a damp cloth or the paste beads and lets go.", ok: false),
        paper("textWove", "Text wove 90 gsm", 90, .long, .wove, Tint(r: 0.96, g: 0.95, b: 0.91),
              "The standard text block; octavo and sextodecimo signatures.",
              "Machine-made book paper, the sort a novel is printed on; grain runs the length of the reel.",
              "Bought the wrong way of the grain it is useless; check by folding a corner both ways before you cut."),
        paper("bookWove", "Book wove 100 gsm", 100, .long, .wove, Tint(r: 0.95, g: 0.94, b: 0.89),
              "The standard text block for cased books and Coptic blocks.",
              "A little heavier and creamier than text wove; a 128-page block of it makes a spine near nine millimetres.",
              "Heavier paper swells the spine more with each signature; allow for it when you cut the spine piece.")
    ]

    private static let papersC: [Material] = [
        paper("laidWriting", "Laid writing 120 gsm", 120, .long, .laid, Tint(r: 0.94, g: 0.92, b: 0.86),
              "Journals, commonplace books, letter books.",
              "A sized laid paper for pen and ink; the laid lines run with the grain on a proper sheet.",
              "Hard-sized paper is brittle at the fold in a dry room; crease it in one confident pass, not four."),
        paper("kraft", "Kraft", 90, .long, .wove, Tint(r: 0.72, g: 0.56, b: 0.38),
              "The second spine lining over the mull; wrappers for pamphlets.",
              "Sulphate pulp, strong and brown, named from the German for strength.",
              "Lined onto a wet spine it wrinkles; lay it on dry paste and smooth from the middle out.", ok: false),
        paper("glassine", "Glassine", 40, .long, .wove, Tint(r: 0.90, g: 0.90, b: 0.88),
              "Interleaving plates, protecting a pasted-down endpaper while it dries.",
              "Supercalendered until it is glassy and grease-resistant; the stamp collector's paper.",
              "It holds no stitch and takes no paste; it is a barrier, not a page.", ok: false),
        paper("marbled", "Marbled endpaper", 100, .long, .wove, Tint(r: 0.55, g: 0.42, b: 0.50),
              "Endpapers, the sides of a half-leather binding.",
              "Colour floated on size, combed into a pattern and lifted onto the sheet; the Turkish and Italian trades made it famous.",
              "Paste it on the plain side only; water on the face lifts the colour off in a cloud.", ok: false),
        paper("pastePaper", "Paste paper", 100, .long, .wove, Tint(r: 0.50, g: 0.58, b: 0.62),
              "Endpapers and covers, the plain binder's own decorated paper.",
              "Coloured paste brushed on and combed, stamped or drawn through with a finger; the German trade's answer to marbling.",
              "The paste layer cracks along a fold; use it flat on boards, never as a folded wrapper.", ok: false),
        paper("teaChest", "Tea-chest paper", 80, .short, .wove, Tint(r: 0.68, g: 0.66, b: 0.62),
              "Nothing in a book; it is the wrong answer in the drawer.",
              "Foil-backed lining paper from tea chests, sometimes sold as a curiosity.",
              "The foil side will not take paste, the paper side tears, and the grain runs the wrong way for a book.", ok: false),
        paper("blotting", "Blotting paper", 250, .short, .wove, Tint(r: 0.96, g: 0.95, b: 0.90),
              "Between the boards in the press, never in the book.",
              "Unsized and soft, made to drink ink; the binder uses it to draw moisture out of a pasted-down endpaper.",
              "As a text page it will not hold a fold, a stitch or a line of ink.", ok: false),
        paper("newsprint", "Newsprint", 45, .long, .wove, Tint(r: 0.90, g: 0.88, b: 0.80),
              "Waste sheets to protect the bench and the book when pasting.",
              "Groundwood pulp, cheap and acidic; it browns in a few years and turns brittle in twenty.",
              "Bound as pages it yellows and breaks at the fold; the paste from it stains the endpapers.", ok: false)
    ]

    private static let cloths: [Material] = [
        other("buckram", .cloth, "Buckram", "Heavy, starch and pyroxylin filled", 0, Tint(r: 0.30, g: 0.36, b: 0.48),
              "Library bindings, ledgers, anything that must survive a thousand openings.",
              "Coarse cotton filled with starch and coated so it wipes clean; the library standard since the 1890s.",
              "Too stiff for a small book: the joint fights the boards and the case gapes."),
        other("starchCotton", .cloth, "Starch-filled cotton", "Medium weight, plain weave", 0, Tint(r: 0.18, g: 0.23, b: 0.36),
              "The everyday case; the publisher's cloth of the nineteenth century.",
              "Filled with starch so paste does not strike through and the weave shows as a fine grain.",
              "Water strikes through starch: a wet paste leaves a dark tide-line on the face that never goes."),
        other("linen", .cloth, "Linen", "Unfilled, natural", 0, Tint(r: 0.76, g: 0.70, b: 0.56),
              "Covers where the weave is meant to be seen; the slip of a portfolio.",
              "Flax woven plain; unfilled, so it must be backed with tissue before it is pasted.",
              "Unbacked linen lets paste through and shows every stroke of the brush as a stain."),
        other("silkCloth", .cloth, "Silk", "Fine, backed with paper", 0, Tint(r: 0.62, g: 0.25, b: 0.30),
              "Presentation bindings, albums, the doublures of a fine book.",
              "Woven silk on a paper backing; it catches the light along the weave.",
              "It waterspots; work with a dry brush and a thin paste, and never wipe it."),
        other("rayon", .cloth, "Rayon", "Light, lustrous", 0, Tint(r: 0.36, g: 0.30, b: 0.46),
              "Small books, the covers of a cheap edition.",
              "Regenerated cellulose, silk's cheaper cousin; slick and easy to turn in.",
              "It frays at the cut edge, and paste that reaches the face dulls it for good."),
        other("japaneseSilk", .cloth, "Japanese silk cloth", "Paper-backed, fine weave", 0, Tint(r: 0.28, g: 0.38, b: 0.36),
              "Boxes, folders, the covers of stab bindings.",
              "Kinran and its plain cousins, silk on a thin paper backing that turns a sharp corner.",
              "Handle it by the edges: a fingerprint of paste on the face stays there."),
        other("italianCotton", .cloth, "Italian cotton", "Paper-backed, ribbed", 0, Tint(r: 0.58, g: 0.22, b: 0.20),
              "Cased books of every kind.",
              "Fine cotton on a paper backing with a faint rib; it turns in cleanly and keeps a colour.",
              "The rib shows a wrinkle if the turn-in is not pulled tight before the corner is laid."),
        other("canvas", .cloth, "Canvas", "Heavy plain weave", 0, Tint(r: 0.70, g: 0.66, b: 0.54),
              "Sketchbooks, field notebooks, anything that goes in a bag.",
              "Cotton duck, thick and tough, the sail-maker's cloth.",
              "It will not take a sharp corner; a library corner on canvas is a lump."),
        other("velvet", .cloth, "Velvet", "Pile cloth", 0, Tint(r: 0.30, g: 0.12, b: 0.22),
              "Albums, prayer books, the covers of a wedding register.",
              "A woven pile that shows every touch of the hand as a change in the light.",
              "Paste crushes the pile; it must be glued only at the turn-ins and never pressed hard."),
        other("moire", .cloth, "Moiré", "Watered silk or rayon", 0, Tint(r: 0.66, g: 0.62, b: 0.70),
              "Endpapers of a fine binding, the linings of a box.",
              "Passed between rollers so the weave is crushed into a watered pattern.",
              "Pressing it flat again destroys the pattern; it goes in the press only between soft boards."),
        other("oilcloth", .cloth, "Oilcloth", "Oil-coated cotton", 0, Tint(r: 0.20, g: 0.26, b: 0.24),
              "Ship's logs, garden diaries, books that will get wet.",
              "Cotton soaked in linseed oil and dried, the wipe-clean cover of a working book.",
              "Nothing water-based sticks to it; the turn-ins need a glue, not a paste, and time to grab."),
        other("leatherette", .cloth, "Bookbinder's leatherette", "Coated paper or cloth", 0, Tint(r: 0.38, g: 0.24, b: 0.16),
              "Cheap ledgers, diaries, the wrong answer for a fine book.",
              "Embossed and coated to look like grained leather from across the room.",
              "The coating cracks at the joint within a year of daily opening.")
    ]

    private static let leathers: [Material] = [
        other("goatskin", .leather, "Goatskin", "Vegetable-tanned, pared", 0, Tint(r: 0.48, g: 0.22, b: 0.14),
              "Full and quarter leather bindings, the standard for fine work.",
              "Morocco: a goatskin with a pronounced grain, strong, and it takes gold tooling like nothing else.",
              "Pared too thin at the joint it splits; too thick it will not turn the corner."),
        other("calfskin", .leather, "Calfskin", "Smooth, vegetable-tanned", 0, Tint(r: 0.60, g: 0.42, b: 0.26),
              "Eighteenth-century style bindings, tight backs, sprinkled and tree calf.",
              "Fine and smooth with almost no grain; it can be marbled, sprinkled and polished.",
              "It is the leather most prone to red rot; keep it out of the sun and away from gas lamps."),
        other("vellumSkin", .leather, "Vellum", "Calfskin, limed and scraped", 0, Tint(r: 0.93, g: 0.89, b: 0.78),
              "Limp vellum bindings, spine strips over boards.",
              "Not tanned at all: a skin dried under tension, translucent at the edges.",
              "It wants to curl in dry air and flatten in damp; a vellum cover needs ties or a clasp."),
        other("sheepskin", .leather, "Sheepskin", "Soft, loose-grained", 0, Tint(r: 0.66, g: 0.50, b: 0.34),
              "Cheap account books, law books, sprinkled bindings.",
              "Loose in the fibre and easy to pare; the cheap leather of the trade for three centuries.",
              "The grain layer peels away from the flesh side; a sheepskin spine powders where it is handled."),
        other("pigskin", .leather, "Pigskin", "Tough, follicle-marked", 0, Tint(r: 0.84, g: 0.76, b: 0.60),
              "German and Swiss bindings of the sixteenth century, blind-tooled over wooden boards.",
              "Alum-tawed or tanned, with the hair follicles in threes; nearly white and extremely hard.",
              "It does not want to turn a corner; the boards must be cut with a wide square and the corners mitred."),
        other("alumTawed", .leather, "Alum-tawed skin", "White, tawed not tanned", 0, Tint(r: 0.92, g: 0.90, b: 0.84),
              "Sewing supports, the covering of Romanesque and Carolingian bindings.",
              "Treated with alum and salt rather than tannin; it stays white and lasts a thousand years.",
              "Tawing washes out: wet it and it goes back to rawhide."),
        other("suede", .leather, "Suede", "Split, napped", 0, Tint(r: 0.58, g: 0.46, b: 0.40),
              "Limp covers for a poetry book, the lining of a box.",
              "The flesh side of a split skin, brushed to a nap.",
              "It shows every mark, drinks paste, and cannot be cleaned; a working book should never wear it."),
        other("fishSkin", .leather, "Fish skin", "Salmon or cod, tanned", 0, Tint(r: 0.52, g: 0.50, b: 0.44),
              "Onlays, small book spines, a talking point.",
              "Salmon skin tanned to a scaly leather; stronger for its thickness than goatskin.",
              "It comes in narrow pieces; nothing larger than a spine can be covered in one skin.")
    ]

    private static let threads: [Material] = [
        other("linen18", .thread, "Linen 18/3", "Heavy, three-ply, unbleached", 0, Tint(r: 0.80, g: 0.72, b: 0.56),
              "Coptic and Ethiopian chains, big blocks, exposed spines.",
              "The number is the yarn count and the plies: 18/3 is thick. Wax it and it grips.",
              "Too thick for a thin block: eight signatures of it swell the spine into a wedge."),
        other("linen25", .thread, "Linen 25/3", "The all-round thread", 0, Tint(r: 0.84, g: 0.77, b: 0.60),
              "Kettle stitch on tapes, French link, most cased work.",
              "Strong enough for a full case, fine enough not to swell a spine of eight signatures.",
              "Unwaxed it kinks and knots itself at every third pass."),
        other("linen35", .thread, "Linen 35/3", "Fine, three-ply", 0, Tint(r: 0.86, g: 0.80, b: 0.64),
              "Thin signatures, sextodecimo blocks, pamphlets on soft paper.",
              "Fine enough to pass a small station twice without tearing the paper.",
              "It will cut through thin Japanese paper at the kettle if pulled hard."),
        other("linen60", .thread, "Linen 60/3", "Very fine", 0, Tint(r: 0.88, g: 0.84, b: 0.70),
              "Miniature books, repairs, resewing a fragile block.",
              "Nearly a sewing-thread weight; for stations no bigger than a pin.",
              "The tension window is narrow: a fraction too hard and it snaps."),
        other("silk", .thread, "Silk", "Twisted, coloured", 0, Tint(r: 0.66, g: 0.18, b: 0.16),
              "Japanese stab bindings, headbands, decorative Coptic in colour.",
              "Smooth, strong and slippery; it shows off a hemp-leaf pattern like nothing else.",
              "Slippery means the tension does not hold between pulls; the window is the narrowest of all."),
        other("waxedCotton", .thread, "Waxed cotton", "Coarse, waxed", 0, Tint(r: 0.34, g: 0.30, b: 0.26),
              "Long stitch through leather, field notebooks, Coptic in black.",
              "The wax holds each stitch where you put it and keeps the thread from fraying on a tape.",
              "Cotton stretches: a spine sewn tight in a damp room goes slack in a dry one."),
        other("unwaxedLinen", .thread, "Unwaxed linen", "Plain, natural", 0, Tint(r: 0.82, g: 0.78, b: 0.66),
              "Sewing that will be pasted over, where wax would repel the paste.",
              "The same linen without beeswax; draw it through the block of wax yourself if you need it.",
              "It knots. Every binder has lost a pass to a knot at the station."),
        other("tape12", .thread, "Tape 12 mm", "Unbleached linen tape", 0, Tint(r: 0.90, g: 0.86, b: 0.74),
              "The sewing support for kettle stitch and French link; it is pasted to the boards.",
              "A flat woven tape twelve millimetres wide; the thread passes over it between the paired stations.",
              "Cut too short it will not reach the boards; leave sixty millimetres each side of the spine.")
    ]

    private static let boards: [Material] = [
        other("grey15", .board, "Greyboard 1.5 mm", "Light board", 1.5, Tint(r: 0.62, g: 0.60, b: 0.56),
              "Small books, sextodecimos, pamphlet covers stiffened.",
              "Recycled grey pulp board, the cheapest and most common.",
              "Under a larger book it bows; the squares look thin and the corners dent."),
        other("grey2", .board, "Greyboard 2 mm", "The standard case board", 2.0, Tint(r: 0.60, g: 0.58, b: 0.54),
              "Octavo cases, most cased work.",
              "Two millimetres suits a book up to A4; the backing lip is cut to match it.",
              "Cut against the grain it warps toward the paste side and stays warped."),
        other("grey3", .board, "Greyboard 3 mm", "Heavy board", 3.0, Tint(r: 0.58, g: 0.56, b: 0.52),
              "Large books, ledgers, albums, portfolios.",
              "Three millimetres will not bow across a wide album cover.",
              "On a small book it looks like a doorstop, and the joint needs a French groove to open."),
        other("millboard", .board, "Millboard", "Dense, dark, hard", 2.5, Tint(r: 0.42, g: 0.36, b: 0.30),
              "Fine leather bindings, the tight-back and the hollow back.",
              "Rope and pulp beaten and rolled dense; the traditional board of the English trade.",
              "It blunts a knife in a few cuts and cannot be scored; cut it in a plough or a board shear."),
        other("binders", .board, "Binder's board", "Archival, buffered", 2.4, Tint(r: 0.70, g: 0.66, b: 0.58),
              "Conservation work, any book meant to last.",
              "Acid-free and lignin-free with a calcium carbonate buffer; the museum board.",
              "It costs four times greyboard and looks the same from the outside."),
        other("wood", .board, "Wood boards", "Quarter-sawn oak or beech", 6.0, Tint(r: 0.55, g: 0.40, b: 0.26),
              "Gothic and Romanesque bindings, Ethiopian bindings, books with clasps.",
              "Quarter-sawn so they do not cup; the sewing supports pass through channels cut in the wood.",
              "A board sawn the wrong way cups in a season and splits the leather at the joint."),
        other("bristol", .board, "Bristol board", "Thin, smooth", 0.5, Tint(r: 0.96, g: 0.95, b: 0.91),
              "Stiffeners for limp covers, the spine strip of a Secret Belgian binding.",
              "Pasted paper layers, smooth on both sides; it folds without cracking.",
              "It is not a case board: a full case on Bristol flops like a pamphlet."),
        other("corrugated", .board, "Corrugated", "Packing board", 3.0, Tint(r: 0.74, g: 0.60, b: 0.42),
              "Nothing. It is the wrong answer in the drawer.",
              "Two liners around a fluted core; it is light, it is free, and it is not a book board.",
              "The flutes dent under a thumb, the edges crush, and the case shows every rib through the cloth.", ok: false)
    ]

    static let all: [Material] = papersA + papersB + papersC + cloths + leathers + threads + boards

    static func find(_ key: String) -> Material { all.first { $0.key == key } ?? all[0] }

    static func of(_ kind: MaterialKind) -> [Material] { all.filter { $0.kind == kind } }

    static var benchPapers: [Material] { of(.paper).filter { $0.benchOK } }
    static var benchCovers: [Material] { of(.cloth).filter { $0.benchOK } + of(.leather) + [find("marbled"), find("pastePaper"), find("mouldMade")] }
    static var benchBoards: [Material] { of(.board).filter { $0.benchOK } }

    static func thread(_ kind: ThreadKind) -> Material { find(kind.rawValue) }
}
