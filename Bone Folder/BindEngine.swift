import Foundation

struct Bobbin {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
    mutating func unit() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func range(_ a: Double, _ b: Double) -> Double { a + unit() * (b - a) }
    mutating func int(_ a: Int, _ b: Int) -> Int { a + Int(next() % UInt64(max(1, b - a + 1))) }
    mutating func chance(_ p: Double) -> Bool { unit() < p }
    mutating func pick<T>(_ items: [T]) -> T { items[int(0, items.count - 1)] }
}

func seedOf(_ text: String) -> UInt64 {
    var h: UInt64 = 14695981039346656037
    for b in text.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
    return h
}

enum Almanac {
    static let epoch: Double = 1_767_225_600

    static func dayIndex(_ date: Date = Date()) -> Int {
        max(0, Int((date.timeIntervalSince1970 - epoch) / 86_400))
    }

    static func seed(_ day: Int) -> UInt64 { seedOf("bonefolder.day.\(day)") }
}

enum SheetSize: String, CaseIterable, Codable {
    case a3, a4, b4, sra3, crown, demy, royal, imperial, letter, legal, tabloid

    var name: String {
        switch self {
        case .a3: return "A3"
        case .a4: return "A4"
        case .b4: return "B4"
        case .sra3: return "SRA3"
        case .crown: return "Crown"
        case .demy: return "Demy"
        case .royal: return "Royal"
        case .imperial: return "Imperial"
        case .letter: return "Letter"
        case .legal: return "Legal"
        case .tabloid: return "Tabloid"
        }
    }

    var family: String {
        switch self {
        case .a3, .a4, .sra3: return "ISO A series"
        case .b4: return "ISO B series"
        case .crown, .demy, .royal, .imperial: return "British imperial"
        case .letter, .legal, .tabloid: return "North American"
        }
    }

    var shortMM: Double {
        switch self {
        case .a3: return 297
        case .a4: return 210
        case .b4: return 250
        case .sra3: return 320
        case .crown: return 381
        case .demy: return 445
        case .royal: return 508
        case .imperial: return 559
        case .letter: return 216
        case .legal: return 216
        case .tabloid: return 279
        }
    }

    var longMM: Double {
        switch self {
        case .a3: return 420
        case .a4: return 297
        case .b4: return 353
        case .sra3: return 450
        case .crown: return 508
        case .demy: return 572
        case .royal: return 635
        case .imperial: return 762
        case .letter: return 279
        case .legal: return 356
        case .tabloid: return 432
        }
    }

    var note: String {
        switch self {
        case .a3: return "Twice A4. Folded once it gives an A4 folio, the everyday pamphlet sheet."
        case .a4: return "The office sheet. Folded once it makes an A5 folio; small but honest."
        case .b4: return "Between A3 and A4, the size Japanese stab bindings are often made from."
        case .sra3: return "A3 with a bleed allowance, what a print shop hands you."
        case .crown: return "The old English octavo sheet, fifteen by twenty inches."
        case .demy: return "Seventeen and a half by twenty two and a half inches, the novel's sheet for two centuries."
        case .royal: return "Twenty by twenty five inches, for the handsome edition."
        case .imperial: return "Twenty two by thirty inches, the drawing paper sheet."
        case .letter: return "Eight and a half by eleven inches."
        case .legal: return "Eight and a half by fourteen, a long folio."
        case .tabloid: return "Eleven by seventeen, twice letter."
        }
    }
}

enum Grain: String, Codable, CaseIterable {
    case long, short

    var name: String { self == .long ? "Grain long" : "Grain short" }
}

enum PaperTexture: String, Codable, CaseIterable {
    case laid, wove, kozo, rag

    var name: String {
        switch self {
        case .laid: return "laid"
        case .wove: return "wove"
        case .kozo: return "kozo"
        case .rag: return "rag"
        }
    }
}

enum FoldAxis { case vertical, horizontal }

enum FoldMove: String, Codable, CaseIterable {
    case rightOverLeft, leftOverRight, bottomOverTop, topOverBottom

    var axis: FoldAxis {
        switch self {
        case .rightOverLeft, .leftOverRight: return .vertical
        case .bottomOverTop, .topOverBottom: return .horizontal
        }
    }

    var name: String {
        switch self {
        case .rightOverLeft: return "right edge over to the left"
        case .leftOverRight: return "left edge over to the right"
        case .bottomOverTop: return "bottom edge up to the top"
        case .topOverBottom: return "top edge down to the bottom"
        }
    }
}

enum Imposition: String, CaseIterable, Codable {
    case folio, quarto, octavo, sextodecimo

    var name: String {
        switch self {
        case .folio: return "Folio"
        case .quarto: return "Quarto"
        case .octavo: return "Octavo"
        case .sextodecimo: return "Sextodecimo"
        }
    }

    var folds: Int {
        switch self {
        case .folio: return 1
        case .quarto: return 2
        case .octavo: return 3
        case .sextodecimo: return 4
        }
    }

    var pages: Int { 4 << (folds - 1) }
    var leaves: Int { pages / 2 }

    var rows: Int {
        switch self {
        case .folio: return 1
        case .quarto: return 2
        case .octavo: return 2
        case .sextodecimo: return 4
        }
    }

    var cols: Int {
        switch self {
        case .folio: return 2
        case .quarto: return 2
        case .octavo: return 4
        case .sextodecimo: return 4
        }
    }

    var sheetPortrait: Bool { self == .quarto || self == .sextodecimo }

    var canonical: [FoldMove] {
        switch self {
        case .folio: return [.rightOverLeft]
        case .quarto: return [.bottomOverTop, .rightOverLeft]
        case .octavo: return [.rightOverLeft, .bottomOverTop, .rightOverLeft]
        case .sextodecimo: return [.bottomOverTop, .rightOverLeft, .bottomOverTop, .rightOverLeft]
        }
    }

    var correctGrain: Grain { sheetPortrait ? .long : .short }

    var note: String {
        switch self {
        case .folio: return "One fold, four pages. The sheet lies landscape and the fold is the spine."
        case .quarto: return "Two folds at right angles, eight pages. The first fold makes the head bolt, the second is the spine."
        case .octavo: return "Three folds, sixteen pages. Fore-edge bolts from the first fold, head bolts from the second, the spine from the third."
        case .sextodecimo: return "Four folds, thirty two small pages. Every bolt must be slit before the book will open."
        }
    }
}

struct FoldLayer: Equatable {
    var cell: Int
    var frontUp: Bool
    var turn: Int
}

struct PrintedPage: Equatable {
    var number: Int
    var turn: Int
}

struct SheetMap: Equatable {
    var rows: Int
    var cols: Int
    var front: [PrintedPage]
    var back: [PrintedPage]

    func frontAt(_ r: Int, _ c: Int) -> PrintedPage { front[r * cols + c] }
    func backAt(_ r: Int, _ c: Int) -> PrintedPage { back[r * cols + c] }
}

struct FoldState: Equatable {
    var rows: Int
    var cols: Int
    var stacks: [[FoldLayer]]
    var moves: [FoldMove] = []

    init(imposition: Imposition) {
        rows = imposition.rows
        cols = imposition.cols
        stacks = (0..<(rows * cols)).map { [FoldLayer(cell: $0, frontUp: true, turn: 0)] }
    }

    var folded: Bool { rows == 1 && cols == 1 }

    func canFold(_ move: FoldMove) -> Bool {
        switch move.axis {
        case .vertical: return cols >= 2 && cols % 2 == 0
        case .horizontal: return rows >= 2 && rows % 2 == 0
        }
    }

    @discardableResult
    mutating func fold(_ move: FoldMove) -> Bool {
        guard canFold(move) else { return false }
        var out: [[FoldLayer]] = []
        switch move {
        case .rightOverLeft, .leftOverRight:
            let half = cols / 2
            out = Array(repeating: [], count: rows * half)
            for r in 0..<rows {
                for c in 0..<half {
                    let keep = move == .rightOverLeft ? c : c + half
                    let flip = move == .rightOverLeft ? cols - 1 - c : half - 1 - c
                    var stack = stacks[r * cols + keep]
                    let moved = stacks[r * cols + flip].reversed().map {
                        FoldLayer(cell: $0.cell, frontUp: !$0.frontUp, turn: $0.turn)
                    }
                    stack.append(contentsOf: moved)
                    out[r * half + c] = stack
                }
            }
            cols = half
        case .bottomOverTop, .topOverBottom:
            let half = rows / 2
            out = Array(repeating: [], count: half * cols)
            for r in 0..<half {
                for c in 0..<cols {
                    let keep = move == .bottomOverTop ? r : r + half
                    let flip = move == .bottomOverTop ? rows - 1 - r : half - 1 - r
                    var stack = stacks[keep * cols + c]
                    let moved = stacks[flip * cols + c].reversed().map {
                        FoldLayer(cell: $0.cell, frontUp: !$0.frontUp, turn: ($0.turn + 2) % 4)
                    }
                    stack.append(contentsOf: moved)
                    out[r * cols + c] = stack
                }
            }
            rows = half
        }
        stacks = out
        moves.append(move)
        return true
    }

    var spineOnSide: Bool { moves.last?.axis == .vertical }

    var readingStack: [FoldLayer] {
        guard folded, let last = moves.last else { return [] }
        var stack = stacks[0]
        switch last {
        case .rightOverLeft:
            stack = stack.reversed().map { FoldLayer(cell: $0.cell, frontUp: !$0.frontUp, turn: $0.turn) }
        case .leftOverRight:
            break
        case .bottomOverTop:
            stack = stack.map { FoldLayer(cell: $0.cell, frontUp: $0.frontUp, turn: ($0.turn + 1) % 4) }
        case .topOverBottom:
            stack = stack.map { FoldLayer(cell: $0.cell, frontUp: $0.frontUp, turn: ($0.turn + 3) % 4) }
        }
        return stack.reversed()
    }
}

struct FoldReadout: Equatable {
    var pages: [Int]
    var upright: [Bool]
    var spineOnSide: Bool
    var complete: Bool

    var correct: Bool {
        complete && spineOnSide && pages == Array(1...max(1, pages.count)) && !upright.contains(false)
    }

    var fault: String? {
        if !complete { return "The sheet is not folded down yet." }
        if !spineOnSide { return "The last fold ran across the sheet: the spine is at the head and the pages lie sideways." }
        if pages.first != 1 {
            if pages.first == pages.count { return "Page \(pages.count) is on the front: the block is back to front." }
            return "Page \(pages.first ?? 0) is on the front where page 1 should be: a fold went the wrong way."
        }
        if let i = upright.firstIndex(of: false) { return "Page \(pages[i]) stands on its head: the fold before the spine went the wrong way." }
        if let i = (0..<pages.count).first(where: { pages[$0] != $0 + 1 }) {
            return "Page \(pages[i]) follows page \(i > 0 ? pages[i - 1] : 0): the leaves are out of order."
        }
        return nil
    }
}

enum Imposer {
    static func map(_ imposition: Imposition) -> SheetMap {
        var state = FoldState(imposition: imposition)
        for move in imposition.canonical { state.fold(move) }
        let cells = imposition.rows * imposition.cols
        var front = [PrintedPage](repeating: PrintedPage(number: 0, turn: 0), count: cells)
        var back = [PrintedPage](repeating: PrintedPage(number: 0, turn: 0), count: cells)
        for (i, layer) in state.readingStack.enumerated() {
            let turn = (4 - layer.turn) % 4
            if layer.frontUp {
                front[layer.cell] = PrintedPage(number: 2 * i + 1, turn: turn)
                back[layer.cell] = PrintedPage(number: 2 * i + 2, turn: turn)
            } else {
                back[layer.cell] = PrintedPage(number: 2 * i + 1, turn: turn)
                front[layer.cell] = PrintedPage(number: 2 * i + 2, turn: turn)
            }
        }
        return SheetMap(rows: imposition.rows, cols: imposition.cols, front: front, back: back)
    }

    static func readout(_ imposition: Imposition, _ moves: [FoldMove]) -> FoldReadout {
        let sheet = map(imposition)
        var state = FoldState(imposition: imposition)
        for move in moves { state.fold(move) }
        guard state.folded else { return FoldReadout(pages: [], upright: [], spineOnSide: false, complete: false) }
        var pages: [Int] = []
        var upright: [Bool] = []
        for layer in state.readingStack {
            let seen = layer.frontUp ? sheet.front[layer.cell] : sheet.back[layer.cell]
            let hidden = layer.frontUp ? sheet.back[layer.cell] : sheet.front[layer.cell]
            pages.append(seen.number)
            upright.append((seen.turn + layer.turn) % 4 == 0)
            pages.append(hidden.number)
            upright.append((hidden.turn + layer.turn) % 4 == 0)
        }
        return FoldReadout(pages: pages, upright: upright, spineOnSide: state.spineOnSide, complete: true)
    }

    static func allSequences(_ imposition: Imposition) -> [[FoldMove]] {
        var out: [[FoldMove]] = []
        func grow(_ state: FoldState, _ moves: [FoldMove]) {
            if state.folded { out.append(moves); return }
            for move in FoldMove.allCases where state.canFold(move) {
                var next = state
                next.fold(move)
                grow(next, moves + [move])
            }
        }
        grow(FoldState(imposition: imposition), [])
        return out
    }
}

struct FoldRecord: Codable, Equatable {
    var move: FoldMove
    var offsetMM: Double
    var crease: Double
    var acrossGrain: Bool
}

enum FoldJudge {
    static func accuracy(_ records: [FoldRecord]) -> Double {
        guard !records.isEmpty else { return 0 }
        var total = 0.0
        for r in records {
            let square = max(0, 1 - max(0, r.offsetMM - 0.5) / 4.0)
            let crease = min(1, max(0, r.crease))
            total += square * 0.55 + crease * 0.45
        }
        return total / Double(records.count)
    }
}

enum Stations {
    static let kettleInset = 12.0

    static func evenPositions(count: Int, height: Double) -> [Double] {
        guard count > 1 else { return [height / 2] }
        let span = height - kettleInset * 2
        return (0..<count).map { kettleInset + span * Double($0) / Double(count - 1) }
    }

    static func tapePositions(tapes: Int, height: Double, tapeWidth: Double = 12) -> [Double] {
        var out: [Double] = [kettleInset]
        let span = height - kettleInset * 2
        for t in 0..<tapes {
            let centre = kettleInset + span * (Double(t) + 1) / Double(tapes + 1)
            out.append(centre - tapeWidth / 2)
            out.append(centre + tapeWidth / 2)
        }
        out.append(height - kettleInset)
        return out
    }

    static func punchError(tap: Double, mark: Double) -> Double { abs(tap - mark) }

    static func accuracy(_ errorsMM: [Double]) -> Double {
        guard !errorsMM.isEmpty else { return 0 }
        var total = 0.0
        for e in errorsMM { total += e <= 2 ? 1 - e / 6 : max(0, 0.45 - (e - 2) / 8) }
        return total / Double(errorsMM.count)
    }
}

enum ThreadKind: String, CaseIterable, Codable {
    case linen18, linen25, linen35, linen60, silk, waxedCotton, unwaxedLinen, tape12

    var name: String {
        switch self {
        case .linen18: return "Linen 18/3"
        case .linen25: return "Linen 25/3"
        case .linen35: return "Linen 35/3"
        case .linen60: return "Linen 60/3"
        case .silk: return "Silk"
        case .waxedCotton: return "Waxed cotton"
        case .unwaxedLinen: return "Unwaxed linen"
        case .tape12: return "Tape 12 mm"
        }
    }

    var diameterMM: Double {
        switch self {
        case .linen18: return 0.72
        case .linen25: return 0.60
        case .linen35: return 0.48
        case .linen60: return 0.36
        case .silk: return 0.30
        case .waxedCotton: return 0.50
        case .unwaxedLinen: return 0.55
        case .tape12: return 0.40
        }
    }

    var swellMM: Double { diameterMM * 0.42 }

    var tensionWindow: ClosedRange<Double> {
        switch self {
        case .linen18: return 0.40...0.78
        case .linen25: return 0.42...0.76
        case .linen35: return 0.44...0.72
        case .linen60: return 0.46...0.68
        case .silk: return 0.50...0.64
        case .waxedCotton: return 0.42...0.74
        case .unwaxedLinen: return 0.40...0.70
        case .tape12: return 0.36...0.80
        }
    }
}

enum TensionResult: String, Codable {
    case loose, good, tight

    var word: String {
        switch self {
        case .loose: return "too loose, the spine will be baggy"
        case .good: return "in the window"
        case .tight: return "too tight, the paper tore at the station"
        }
    }
}

enum Tension {
    static func judge(_ pull: Double, thread: ThreadKind) -> TensionResult {
        let w = thread.tensionWindow
        if pull < w.lowerBound { return .loose }
        if pull > w.upperBound { return .tight }
        return .good
    }

    static func score(_ results: [TensionResult]) -> Double {
        guard !results.isEmpty else { return 0 }
        var total = 0.0
        for r in results {
            switch r {
            case .good: total += 1
            case .loose: total += 0.35
            case .tight: total += 0.15
            }
        }
        return total / Double(results.count)
    }
}

enum Rounding {
    static let targetArc = 2.0 * Double.pi / 3.0

    static func tapsNeeded(signatures: Int) -> Int { max(6, 4 + signatures * 2) }

    static func rounding(taps: Int, needed: Int) -> Double {
        guard needed > 0 else { return 0 }
        if taps <= needed { return Double(taps) / Double(needed) }
        return max(0, 1 - Double(taps - needed) * 0.05)
    }

    static func profileError(zoneTaps: [Int], needed: Int) -> Double {
        guard !zoneTaps.isEmpty else { return 1 }
        let perZone = max(1.0, Double(needed) / Double(zoneTaps.count))
        var total = 0.0
        for taps in zoneTaps {
            let r = rounding(taps: taps, needed: Int(perZone.rounded()))
            total += abs(1 - r)
        }
        return total / Double(zoneTaps.count)
    }

    static func shoulder(taps: Int, boardMM: Double) -> Double {
        let perMM = 5.0
        let lip = Double(taps) / perMM
        return lip
    }

    static func shoulderError(taps: Int, boardMM: Double) -> Double {
        abs(shoulder(taps: taps, boardMM: boardMM) - boardMM) / max(0.5, boardMM)
    }
}

enum Lining {
    static let bubblesToStart = 4

    static func bubbles(swipes: Int) -> Int { max(0, bubblesToStart - swipes) }
}

enum Rhythm {
    static func regularity(_ intervals: [Double]) -> Double {
        guard intervals.count >= 2 else { return 0 }
        let mean = intervals.reduce(0, +) / Double(intervals.count)
        guard mean > 0 else { return 0 }
        var v = 0.0
        for i in intervals { v += (i - mean) * (i - mean) }
        let cv = (v / Double(intervals.count)).squareRoot() / mean
        return max(0, min(1, 1 - cv * 1.6))
    }
}

enum Squares {
    static let target = 3.0

    static func error(cutMM: Double) -> Double { abs(cutMM - target) }

    static func score(_ errors: [Double]) -> Double {
        guard !errors.isEmpty else { return 0 }
        var total = 0.0
        for e in errors { total += e <= 0.5 ? 1 : (e <= 2 ? 1 - (e - 0.5) / 3 : max(0, 0.4 - (e - 2) / 5)) }
        return total / Double(errors.count)
    }
}

enum TurnIns {
    static let target = 15.0

    static func score(_ widths: [Double]) -> Double {
        guard !widths.isEmpty else { return 0 }
        var total = 0.0
        for w in widths { total += max(0, 1 - abs(w - target) / 8) }
        return total / Double(widths.count)
    }
}

enum Press {
    static func hours(for structure: Structure) -> Double {
        switch structure.family {
        case .supported, .belgian: return 6
        case .chain, .longStitch, .stab: return 2
        case .pamphlet, .fold: return 1
        }
    }

    static func patience(pressedHours: Double, needed: Double) -> Double {
        guard needed > 0 else { return 1 }
        let f = min(1, max(0, pressedHours / needed))
        return f < 1 ? f * f : 1
    }
}

enum SpineMath {
    static func caliperMM(gsm: Double, texture: PaperTexture) -> Double {
        let bulk: Double
        switch texture {
        case .laid: return gsm * 0.00118
        case .wove: bulk = 0.00112
        case .kozo: bulk = 0.00150
        case .rag: bulk = 0.00125
        }
        return gsm * bulk
    }

    static func widthMM(pages: Int, gsm: Double, texture: PaperTexture, signatures: Int, thread: ThreadKind) -> Double {
        let leaves = Double(pages) / 2
        return leaves * caliperMM(gsm: gsm, texture: texture) + Double(signatures) * thread.swellMM * 1.1
    }
}

struct ScorePart: Codable, Hashable {
    var name: String
    var weight: Double
    var value: Double
    var note: String
}

struct Verdict: Codable, Equatable {
    var score: Int
    var word: String
    var parts: [ScorePart]
    var critique: [String]
}

enum Grading {
    static func word(_ score: Int) -> String {
        if score >= 90 { return "A master binding" }
        if score >= 75 { return "A fine binding" }
        if score >= 55 { return "A sound book" }
        return "A working copy"
    }

    static func verdict(_ parts: [ScorePart], critique: [String]) -> Verdict {
        let live = parts.filter { $0.weight > 0 }
        let totalWeight = live.reduce(0.0) { $0 + $1.weight }
        var sum = 0.0
        for p in live { sum += p.weight * min(1, max(0, p.value)) }
        let score = totalWeight > 0 ? Int((sum / totalWeight * 100).rounded()) : 0
        return Verdict(score: min(100, max(0, score)), word: word(score), parts: live, critique: critique)
    }
}
