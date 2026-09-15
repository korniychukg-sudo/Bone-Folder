import Foundation

struct Commission: Equatable {
    var day: Int
    var titleKey: String
    var structure: Structure
    var signatures: Int
    var imposition: Imposition
    var stations: Int
    var sheet: SheetSize
    var paperKey: String
    var thread: ThreadKind
    var coverKey: String
    var boardKey: String
    var line: String
    var target: Int
    var reward: Int

    var title: BookTitle { Register.title(titleKey) }
    var paper: Material { Materials.find(paperKey) }
    var cover: Material { Materials.find(coverKey) }
    var board: Material { Materials.find(boardKey) }
}

enum WeatherKind: String, Codable {
    case clear, hazy, overcast, rain, storm, snow

    var word: String {
        switch self {
        case .clear: return "clear"
        case .hazy: return "hazy"
        case .overcast: return "overcast"
        case .rain: return "rain on the window"
        case .storm: return "a storm outside"
        case .snow: return "snow"
        }
    }
}

struct Weather: Equatable {
    var kind: WeatherKind
    var wind: Double
    var cloud: Double
}

enum Daily {
    static let ladder: [(Int, String, String)] = [
        (0, "Apprentice", "You sweep the bench and fold what you are given. Pamphlets, a folded book and the four-hole stab are yours to learn."),
        (150, "Journeyman Binder", "You sew on your own account now: the long stitch and the Coptic chain come to the bench."),
        (450, "Forwarder", "Rounding, backing and the sewing frame. Kettle stitch and French link on tapes are yours, and the case."),
        (950, "Finisher", "The hemp leaf, the tortoise shell, the Ethiopian boards and the Belgian cover are asked of you."),
        (1800, "Master Binder", "The commissions come with a name on them. Nothing is asked of you that you cannot do, and a master binding is expected.")
    ]

    static func rankIndex(points: Int) -> Int {
        var index = 0
        for (i, step) in ladder.enumerated() where points >= step.0 { index = i }
        return index
    }

    static func structures(forRank rank: Int) -> [Structure] {
        var out: [Structure] = [.pamphlet3, .pamphlet5, .accordion, .yotsume]
        if rank >= 1 { out += [.longStitch, .copticOne, .copticTwo] }
        if rank >= 2 { out += [.kettleTapes, .frenchLink] }
        if rank >= 3 { out += [.asanoha, .kikko, .ethiopian, .secretBelgian] }
        return out
    }

    static func sheet(for imposition: Imposition, rng: inout Bobbin) -> SheetSize {
        switch imposition {
        case .folio: return rng.pick([.a3, .a4, .b4, .letter, .legal, .tabloid])
        case .quarto: return rng.pick([.a3, .sra3, .crown, .tabloid])
        case .octavo: return rng.pick([.a3, .sra3, .demy, .royal, .crown])
        case .sextodecimo: return rng.pick([.imperial, .royal, .demy])
        }
    }

    static func commission(day: Int, rank: Int) -> Commission {
        var rng = Bobbin(Almanac.seed(day))
        let title = Register.titles[rng.int(0, Register.titles.count - 1)]
        let pool = structures(forRank: rank)
        let structure = pool[rng.int(0, pool.count - 1)]
        let signatures = structure.family == .stab
            ? rng.int(structure.leavesRange.lowerBound, structure.leavesRange.upperBound) / 4 * 4
            : rng.int(structure.signatureRange.lowerBound, min(structure.signatureRange.upperBound, 8))
        let imposition = rng.pick(structure.allowedImpositions)
        let stations = rng.pick(structure.stationOptions)
        let sheet = sheet(for: imposition, rng: &rng)
        let papers = Materials.benchPapers
        var paper = papers[rng.int(0, papers.count - 1)]
        if paper.grain != imposition.correctGrain, let better = papers.first(where: { $0.grain == imposition.correctGrain && $0.gsm <= 120 }), rng.chance(0.7) {
            paper = better
        }
        let threads: [ThreadKind] = structure.family == .stab ? [.silk, .linen35, .waxedCotton] : [.linen18, .linen25, .linen35, .waxedCotton, .linen60, .unwaxedLinen]
        let thread = rng.pick(threads)
        let covers = Materials.benchCovers
        let cover = covers[rng.int(0, covers.count - 1)]
        let boards = Materials.benchBoards.filter { $0.key != "wood" || structure == .ethiopian }
        let board = boards[rng.int(0, boards.count - 1)]
        let target = [55, 60, 70, 75, 85][min(rank, 4)]
        let reward = 30 + rank * 10
        let count = structure.family == .stab ? "\(signatures) leaves" : (structure.family == .fold ? "\(stations) panels" : "\(signatures) signature\(signatures == 1 ? "" : "s")")
        let line = "\(title.client) wants \(title.title.lowercased()): \(title.wants). \(structure.name), \(count), \(paper.name.lowercased()) \(paper.grain.name.lowercased()), \(Materials.thread(thread).name.lowercased()), \(cover.name.lowercased()) over \(board.name.lowercased())."
        return Commission(day: day, titleKey: title.key, structure: structure, signatures: max(1, signatures), imposition: imposition,
                          stations: stations, sheet: sheet, paperKey: paper.key, thread: thread, coverKey: cover.key,
                          boardKey: board.key, line: line, target: target, reward: reward)
    }

    static func weather(day: Int) -> Weather {
        var rng = Bobbin(seedOf("bonefolder.weather.\(day)"))
        let roll = rng.unit()
        let kind: WeatherKind
        if roll < 0.34 { kind = .clear }
        else if roll < 0.50 { kind = .hazy }
        else if roll < 0.72 { kind = .overcast }
        else if roll < 0.90 { kind = .rain }
        else if roll < 0.96 { kind = .storm }
        else { kind = .snow }
        let cloud: Double
        switch kind {
        case .clear: cloud = rng.range(0.0, 0.2)
        case .hazy: cloud = rng.range(0.3, 0.5)
        case .overcast: cloud = rng.range(0.6, 0.85)
        case .rain: cloud = rng.range(0.7, 0.95)
        case .storm: cloud = rng.range(0.85, 1.0)
        case .snow: cloud = rng.range(0.6, 0.9)
        }
        return Weather(kind: kind, wind: rng.range(0.1, kind == .storm ? 1.0 : 0.6), cloud: cloud)
    }

    static func sunrise(month: Int) -> Double {
        let table: [Double] = [8.1, 7.5, 6.6, 5.7, 5.0, 4.7, 4.9, 5.5, 6.2, 6.9, 7.6, 8.1]
        return table[max(0, min(11, month - 1))]
    }

    static func sunset(month: Int) -> Double {
        let table: [Double] = [16.3, 17.2, 18.0, 18.9, 19.7, 20.3, 20.2, 19.4, 18.3, 17.2, 16.3, 15.9]
        return table[max(0, min(11, month - 1))]
    }

    static let badges: [(String, String, String)] = [
        ("first", "First Book", "One book shelved, whatever the score."),
        ("pamphlet", "Three Holes", "A pamphlet sewn and wrapped."),
        ("chain", "The Chain", "A Coptic or Ethiopian block chained without a skipped station."),
        ("tapes", "On the Frame", "A book sewn on tapes, rounded, backed and cased."),
        ("stab", "Four Holes", "A Japanese stab binding, every wrap in place."),
        ("belgian", "Criss-cross", "A Secret Belgian binding shelved."),
        ("fold", "Mountain and Valley", "An accordion folded in rhythm."),
        ("master", "A Master Binding", "A book scored ninety or better."),
        ("fine", "Five Fine Bindings", "Five books on the shelf at seventy five or better."),
        ("shelf", "A Full Shelf", "Twenty four books on the first shelf."),
        ("patience", "The Full Six Hours", "A cased book left in the press until it was done."),
        ("streak", "Seven Days at the Bench", "A seven day streak."),
        ("reader", "Read the Book", "All twelve lessons read."),
        ("glossary", "Every Term", "The whole glossary read."),
        ("examiner", "Examined", "Eighty percent or better in the examination."),
        ("allStructures", "Every Structure", "One book in every structure the bench knows.")
    ]
}
