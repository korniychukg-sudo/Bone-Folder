import Foundation

enum StructureFamily: String, Codable {
    case pamphlet, chain, supported, longStitch, stab, belgian, fold
}

enum Stage: String, CaseIterable, Codable {
    case sheet, fold, punch, sew, spine, boards, cover, press

    var name: String {
        switch self {
        case .sheet: return "Sheet"
        case .fold: return "Fold"
        case .punch: return "Punch"
        case .sew: return "Sew"
        case .spine: return "Spine"
        case .boards: return "Boards"
        case .cover: return "Cover"
        case .press: return "Press"
        }
    }
}

enum StitchLink: String, Codable {
    case none, kettle, chainUnder, overTape, frenchLink, aroundSpine, aroundHead, aroundTail
    case throughBoard, aroundBoard, underCoverStitch, acrossCover, tieOff

    var word: String {
        switch self {
        case .none: return ""
        case .kettle: return "kettle stitch under the signature below"
        case .chainUnder: return "chain under the loop of the signature below"
        case .overTape: return "over the tape"
        case .frenchLink: return "French link under the stitch below, over the tape"
        case .aroundSpine: return "around the spine edge and back through the same hole"
        case .aroundHead: return "around the head and back through the same hole"
        case .aroundTail: return "around the tail and back through the same hole"
        case .throughBoard: return "through the board"
        case .aroundBoard: return "around the board edge"
        case .underCoverStitch: return "under the cover stitch"
        case .acrossCover: return "across the cover to the next signature"
        case .tieOff: return "tie off"
        }
    }

    var needsPass: Bool {
        switch self {
        case .kettle, .chainUnder, .frenchLink, .underCoverStitch: return true
        default: return false
        }
    }

    var isWrap: Bool { self == .aroundSpine || self == .aroundHead || self == .aroundTail }
}

struct StitchStep: Equatable, Codable {
    var row: Int
    var station: Int
    var outward: Bool
    var link: StitchLink
    var needle: Int = 0
}

struct StabHole: Equatable {
    var x: Double
    var y: Double
    var main: Bool
}

enum Structure: String, CaseIterable, Codable {
    case pamphlet3, pamphlet5, copticTwo, copticOne, kettleTapes, frenchLink, longStitch
    case yotsume, asanoha, kikko, secretBelgian, ethiopian, accordion

    var name: String {
        switch self {
        case .pamphlet3: return "Pamphlet, three holes"
        case .pamphlet5: return "Pamphlet, five holes"
        case .copticTwo: return "Coptic, two needles"
        case .copticOne: return "Coptic, one needle"
        case .kettleTapes: return "Kettle stitch on tapes"
        case .frenchLink: return "French link on tapes"
        case .longStitch: return "Long stitch"
        case .yotsume: return "Yotsume toji"
        case .asanoha: return "Asa-no-ha toji"
        case .kikko: return "Kikko toji"
        case .secretBelgian: return "Secret Belgian"
        case .ethiopian: return "Ethiopian chain"
        case .accordion: return "Accordion"
        }
    }

    var shortName: String {
        switch self {
        case .pamphlet3: return "Pamphlet 3"
        case .pamphlet5: return "Pamphlet 5"
        case .copticTwo: return "Coptic II"
        case .copticOne: return "Coptic I"
        case .kettleTapes: return "Kettle"
        case .frenchLink: return "French link"
        case .longStitch: return "Long stitch"
        case .yotsume: return "Yotsume"
        case .asanoha: return "Hemp leaf"
        case .kikko: return "Tortoise"
        case .secretBelgian: return "Belgian"
        case .ethiopian: return "Ethiopian"
        case .accordion: return "Accordion"
        }
    }

    var family: StructureFamily {
        switch self {
        case .pamphlet3, .pamphlet5: return .pamphlet
        case .copticTwo, .copticOne, .ethiopian: return .chain
        case .kettleTapes, .frenchLink: return .supported
        case .longStitch: return .longStitch
        case .yotsume, .asanoha, .kikko: return .stab
        case .secretBelgian: return .belgian
        case .accordion: return .fold
        }
    }

    var signatureRange: ClosedRange<Int> {
        switch self {
        case .pamphlet3, .pamphlet5: return 1...1
        case .copticTwo, .copticOne: return 3...12
        case .kettleTapes, .frenchLink: return 4...12
        case .longStitch: return 3...10
        case .yotsume, .asanoha, .kikko: return 1...1
        case .secretBelgian: return 3...10
        case .ethiopian: return 3...10
        case .accordion: return 1...1
        }
    }

    var leavesRange: ClosedRange<Int> { family == .stab ? 12...48 : signatureRange }

    var stationOptions: [Int] {
        switch self {
        case .pamphlet3: return [3]
        case .pamphlet5: return [5]
        case .copticTwo: return [4, 6]
        case .copticOne: return [3, 4, 5, 7]
        case .kettleTapes, .frenchLink: return [4, 6, 8]
        case .longStitch: return [4, 6]
        case .yotsume: return [4]
        case .asanoha: return [9]
        case .kikko: return [12]
        case .secretBelgian: return [4, 6]
        case .ethiopian: return [4, 6]
        case .accordion: return [6, 8, 10, 12]
        }
    }

    var defaultStations: Int {
        switch self {
        case .copticTwo, .ethiopian, .secretBelgian, .longStitch: return 4
        case .copticOne: return 5
        case .kettleTapes, .frenchLink: return 6
        case .accordion: return 8
        default: return stationOptions[0]
        }
    }

    var needles: Int { self == .copticTwo || self == .ethiopian ? 2 : 1 }
    var exposedSpine: Bool { family == .chain || family == .longStitch || family == .stab || self == .secretBelgian }

    var stages: [Stage] {
        switch family {
        case .pamphlet: return [.sheet, .fold, .punch, .sew, .cover, .press]
        case .chain: return [.sheet, .fold, .punch, .sew, .boards, .cover, .press]
        case .supported: return Stage.allCases
        case .longStitch: return [.sheet, .fold, .punch, .sew, .cover, .press]
        case .stab: return [.sheet, .fold, .punch, .sew, .cover, .press]
        case .belgian: return [.sheet, .fold, .punch, .sew, .boards, .cover, .press]
        case .fold: return [.sheet, .fold, .boards, .cover, .press]
        }
    }

    func hasStage(_ stage: Stage) -> Bool { stages.contains(stage) }

    func tapes(_ stations: Int) -> Int { family == .supported ? max(0, (stations - 2) / 2) : 0 }

    var coverWord: String {
        switch family {
        case .pamphlet: return "a folded wrapper"
        case .chain: return "covered boards, sewn on"
        case .supported: return "a full case"
        case .longStitch: return "a limp cover"
        case .stab: return "paper covers with a corner"
        case .belgian: return "boards and a spine piece"
        case .fold: return "two boards"
        }
    }

    var defaultImposition: Imposition {
        switch family {
        case .pamphlet: return .quarto
        case .stab, .fold: return .folio
        default: return .octavo
        }
    }

    var allowedImpositions: [Imposition] {
        switch family {
        case .pamphlet: return [.folio, .quarto, .octavo]
        case .stab, .fold: return [.folio]
        default: return [.quarto, .octavo, .sextodecimo]
        }
    }
}

enum StitchGrammar {
    static func path(_ s: Structure, signatures: Int, stations: Int) -> [StitchStep] {
        switch s {
        case .pamphlet3: return pamphlet3()
        case .pamphlet5: return pamphlet5()
        case .copticOne: return copticOne(rows: signatures, n: stations)
        case .copticTwo: return copticTwo(rows: signatures, n: stations, boards: false)
        case .ethiopian: return copticTwo(rows: signatures, n: stations, boards: true)
        case .kettleTapes: return supported(rows: signatures, n: stations, french: false)
        case .frenchLink: return supported(rows: signatures, n: stations, french: true)
        case .longStitch: return longStitch(rows: signatures, n: stations)
        case .secretBelgian: return belgian(rows: signatures, n: stations)
        case .yotsume: return yotsume()
        case .asanoha: return asanoha()
        case .kikko: return kikko()
        case .accordion: return accordion(panels: stations)
        }
    }

    static func pamphlet3() -> [StitchStep] {
        [StitchStep(row: 0, station: 1, outward: true, link: .none),
         StitchStep(row: 0, station: 0, outward: false, link: .none),
         StitchStep(row: 0, station: 2, outward: true, link: .none),
         StitchStep(row: 0, station: 1, outward: false, link: .tieOff)]
    }

    static func pamphlet5() -> [StitchStep] {
        let order: [(Int, Bool)] = [(2, true), (1, false), (0, true), (1, false), (3, true), (4, false), (3, true), (2, false)]
        return order.enumerated().map { i, o in
            StitchStep(row: 0, station: o.0, outward: o.1, link: i == order.count - 1 ? .tieOff : .none)
        }
    }

    static func rowOrder(_ r: Int, _ n: Int) -> [Int] { r % 2 == 0 ? Array(0..<n) : Array((0..<n).reversed()) }

    static func copticOne(rows: Int, n: Int) -> [StitchStep] {
        var out: [StitchStep] = []
        for r in 0..<rows {
            let order = rowOrder(r, n)
            for (i, s) in order.enumerated() {
                let entry = i == 0 && r > 0
                if !entry {
                    out.append(StitchStep(row: r, station: s, outward: true, link: r > 0 ? .chainUnder : .none))
                }
                let last = i == order.count - 1
                if last {
                    if r == rows - 1 {
                        out.append(StitchStep(row: r, station: s, outward: false, link: .tieOff))
                    } else {
                        out.append(StitchStep(row: r + 1, station: s, outward: false, link: r >= 1 ? .chainUnder : .kettle))
                    }
                } else if !entry {
                    out.append(StitchStep(row: r, station: s, outward: false, link: .none))
                }
            }
        }
        return out
    }

    static func copticTwo(rows: Int, n: Int, boards: Bool) -> [StitchStep] {
        var out: [StitchStep] = []
        let pairs = n / 2
        let total = boards ? rows + 2 : rows
        for r in 0..<total {
            let isBoard = boards && (r == 0 || r == total - 1)
            for p in 0..<pairs {
                let a = 2 * p, b = 2 * p + 1
                let left = 2 * p, right = 2 * p + 1
                if r == 0 {
                    out.append(StitchStep(row: r, station: a, outward: true, link: isBoard ? .throughBoard : .none, needle: left))
                    out.append(StitchStep(row: r, station: b, outward: true, link: isBoard ? .throughBoard : .none, needle: right))
                } else {
                    let link: StitchLink = isBoard ? .throughBoard : .chainUnder
                    let flip = r % 2 == 0
                    let aIn = flip ? b : a, aOut = flip ? a : b
                    out.append(StitchStep(row: r, station: aIn, outward: false, link: link, needle: left))
                    out.append(StitchStep(row: r, station: aOut, outward: true, link: .none, needle: left))
                    out.append(StitchStep(row: r, station: aOut, outward: false, link: link, needle: right))
                    out.append(StitchStep(row: r, station: aIn, outward: true, link: .none, needle: right))
                }
            }
        }
        if !out.isEmpty { out[out.count - 1].link = .tieOff }
        return out
    }

    static func supported(rows: Int, n: Int, french: Bool) -> [StitchStep] {
        var out: [StitchStep] = []
        for r in 0..<rows {
            let order = rowOrder(r, n)
            for (i, s) in order.enumerated() {
                let outward = i % 2 == 1
                var link: StitchLink = .none
                if i == 0 && r > 0 {
                    link = .kettle
                } else if !outward && i >= 2 {
                    let prev = order[i - 1]
                    let lo = min(prev, s), hi = max(prev, s)
                    if lo % 2 == 1 && hi == lo + 1 && hi <= n - 2 {
                        link = (french && r > 0) ? .frenchLink : .overTape
                    }
                }
                out.append(StitchStep(row: r, station: s, outward: outward, link: link))
            }
        }
        if !out.isEmpty { out[out.count - 1].link = .tieOff }
        return out
    }

    static func longStitch(rows: Int, n: Int) -> [StitchStep] {
        var out: [StitchStep] = []
        for r in 0..<rows {
            let order = rowOrder(r, n)
            for (i, s) in order.enumerated() {
                out.append(StitchStep(row: r, station: s, outward: i % 2 == 1, link: i == 0 && r > 0 ? .acrossCover : .none))
            }
        }
        if !out.isEmpty { out[out.count - 1].link = .tieOff }
        return out
    }

    static func belgian(rows: Int, n: Int) -> [StitchStep] {
        var out: [StitchStep] = []
        for s in 0..<n { out.append(StitchStep(row: 0, station: s, outward: true, link: .aroundBoard)) }
        for r in 1...max(1, rows) {
            let order = rowOrder(r - 1, n)
            for (i, s) in order.enumerated() {
                let outward = i % 2 == 1
                out.append(StitchStep(row: r, station: s, outward: outward, link: outward ? .none : .underCoverStitch))
            }
        }
        if !out.isEmpty { out[out.count - 1].link = .tieOff }
        return out
    }

    static func yotsume() -> [StitchStep] {
        let m: [(Int, Bool, StitchLink)] = [
            (1, true, .none), (1, true, .aroundSpine), (0, false, .none), (0, false, .aroundSpine), (0, false, .aroundHead),
            (1, true, .none), (2, false, .none), (2, false, .aroundSpine), (3, true, .none), (3, true, .aroundSpine),
            (3, true, .aroundTail), (2, false, .none), (1, true, .tieOff)]
        return m.map { StitchStep(row: 0, station: $0.0, outward: $0.1, link: $0.2) }
    }

    static func asanoha() -> [StitchStep] {
        var m: [(Int, Bool, StitchLink)] = []
        func add(_ h: Int, _ front: Bool, _ l: StitchLink = .none) { m.append((h, front, l)) }
        add(0, true)
        add(4, false); add(4, false, .aroundSpine); add(4, false, .aroundHead); add(0, true)
        for i in 0..<3 {
            let e = 5 + i
            add(e, false); add(e, false, .aroundSpine); add(i, true)
            add(i + 1, false)
            add(e, true); add(i + 1, false)
            add(i + 1, true)
        }
        add(8, false); add(8, false, .aroundSpine); add(8, false, .aroundTail); add(3, true)
        add(2, false); add(1, true); add(0, false); add(0, false, .aroundSpine)
        add(1, true); add(1, true, .aroundSpine); add(2, false); add(2, false, .aroundSpine)
        add(3, true); add(3, true, .aroundSpine); add(2, false); add(1, true); add(0, false); add(0, false, .tieOff)
        return m.map { StitchStep(row: 0, station: $0.0, outward: $0.1, link: $0.2) }
    }

    static func kikko() -> [StitchStep] {
        var m: [(Int, Bool, StitchLink)] = []
        func add(_ h: Int, _ front: Bool, _ l: StitchLink = .none) { m.append((h, front, l)) }
        add(0, true)
        for i in 0..<4 {
            let up = 4 + 2 * i, low = 5 + 2 * i
            add(up, false); add(up, false, .aroundSpine); add(i, true)
            add(low, false); add(low, false, .aroundSpine); add(i, true)
            if i == 0 { add(0, true, .aroundHead) }
            if i == 3 { add(3, true, .aroundTail) }
            if i < 3 { add(i + 1, false); add(i + 1, true, .aroundSpine) }
        }
        add(2, false); add(1, true); add(0, false); add(0, false, .aroundSpine)
        add(1, true); add(2, false); add(3, true); add(3, true, .tieOff)
        return m.map { StitchStep(row: 0, station: $0.0, outward: $0.1, link: $0.2) }
    }

    static func accordion(panels: Int) -> [StitchStep] {
        (0..<max(1, panels - 1)).map { StitchStep(row: 0, station: $0, outward: $0 % 2 == 0, link: .none) }
    }

    static func holes(_ s: Structure) -> [StabHole] {
        let ys = [0.12, 0.37, 0.63, 0.88]
        var out = ys.map { StabHole(x: 15, y: $0, main: true) }
        switch s {
        case .asanoha:
            for y in [0.03, 0.245, 0.50, 0.755, 0.97] { out.append(StabHole(x: 7, y: y, main: false)) }
        case .kikko:
            for y in ys {
                out.append(StabHole(x: 7, y: y - 0.06, main: false))
                out.append(StabHole(x: 7, y: y + 0.06, main: false))
            }
        default: break
        }
        return out
    }

    static func stationName(_ s: Structure, _ station: Int, _ n: Int) -> String {
        if s.family == .stab {
            let holes = holes(s)
            guard station < holes.count else { return "hole \(station + 1)" }
            if holes[station].main { return "hole \(station + 1)" }
            return "small hole \(station + 1 - 4)"
        }
        if s == .accordion { return "fold \(station + 1)" }
        if station == 0 { return "the head station" }
        if station == n - 1 { return "the tail station" }
        let words = ["first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth"]
        return "the \(words[min(station, words.count - 1)]) station"
    }

    static func rowName(_ s: Structure, _ row: Int, _ rows: Int) -> String {
        switch s {
        case .ethiopian:
            if row == 0 { return "the front board" }
            if row == rows + 1 { return "the back board" }
            return "signature \(row)"
        case .secretBelgian:
            return row == 0 ? "the cover" : "signature \(row)"
        default:
            return "signature \(row + 1)"
        }
    }

    static func instruction(_ s: Structure, step: StitchStep, previous: StitchStep?, stations n: Int, rows: Int) -> String {
        if s == .accordion {
            return "Fold \(step.station + 1): \(step.outward ? "a mountain fold, lift the panel up" : "a valley fold, press the panel down")."
        }
        let place = stationName(s, step.station, n)
        var text = ""
        if step.link.isWrap {
            text = "Take the thread \(step.link.word) at \(place)."
        } else if s.family == .stab {
            text = (step.outward ? "Up through \(place) to the front" : "Down through \(place) to the back") + "."
        } else {
            let motion = step.outward ? "Out through \(place)" : "In at \(place)"
            let rowChange = previous.map { $0.row != step.row } ?? true
            if rowChange && previous != nil { text = "\(motion) of \(rowName(s, step.row, rows))" }
            else { text = motion }
            if step.link != .none && step.link != .tieOff { text += ", \(step.link.word)" }
            text += "."
        }
        if step.link == .tieOff { text += " Then tie off." }
        if s.needles == 2 {
            let pair = n > 2 ? " of pair \(step.needle / 2 + 1)" : ""
            text = (step.needle % 2 == 0 ? "Left needle\(pair): " : "Right needle\(pair): ") + text
        }
        return text
    }

    static func chainLinks(_ steps: [StitchStep]) -> Int {
        steps.filter { $0.link == .chainUnder || $0.link == .kettle || $0.link == .frenchLink || $0.link == .throughBoard }.count
    }

    static func visited(_ steps: [StitchStep]) -> Set<Int> {
        Set(steps.map { $0.row * 1000 + $0.station })
    }
}

struct DiagramNode: Equatable {
    var row: Int
    var station: Int
    var x: Double
    var y: Double
}

struct DiagramSegment: Equatable {
    var ax: Double
    var ay: Double
    var bx: Double
    var by: Double
    var outside: Bool
    var link: StitchLink
    var needle: Int
    var wrap: Int
}

enum StitchDiagram {
    static func rowsCount(_ s: Structure, signatures: Int) -> Int {
        switch s {
        case .ethiopian: return signatures + 2
        case .secretBelgian: return signatures + 1
        default: return s.family == .stab || s == .accordion ? 1 : signatures
        }
    }

    static func nodes(_ s: Structure, signatures: Int, stations: Int, width: Double, height: Double) -> [DiagramNode] {
        var out: [DiagramNode] = []
        if s.family == .stab {
            for (i, h) in StitchGrammar.holes(s).enumerated() {
                out.append(DiagramNode(row: 0, station: i, x: h.x / 40.0 * width, y: h.y * height))
            }
            return out
        }
        if s == .accordion {
            for i in 0..<max(1, stations - 1) {
                out.append(DiagramNode(row: 0, station: i, x: width * (Double(i) + 1) / Double(stations), y: height / 2))
            }
            return out
        }
        let rows = rowsCount(s, signatures: signatures)
        let rowH = height / Double(rows)
        let inset = width * 0.08
        for r in 0..<rows {
            let y = height - rowH * (Double(r) + 0.5)
            for st in 0..<stations {
                let x = stations > 1 ? inset + (width - inset * 2) * Double(st) / Double(stations - 1) : width / 2
                out.append(DiagramNode(row: r, station: st, x: x, y: y))
            }
        }
        return out
    }

    static func segments(_ s: Structure, signatures: Int, stations: Int, width: Double, height: Double,
                         upTo count: Int? = nil) -> [DiagramSegment] {
        let steps = StitchGrammar.path(s, signatures: signatures, stations: stations)
        let nodes = nodes(s, signatures: signatures, stations: stations, width: width, height: height)
        func node(_ r: Int, _ st: Int) -> DiagramNode? { nodes.first { $0.row == r && $0.station == st } }
        var out: [DiagramSegment] = []
        let limit = min(steps.count, count ?? steps.count)
        guard limit > 0 else { return out }
        var lastByNeedle: [Int: StitchStep] = [:]
        for i in 0..<limit {
            let step = steps[i]
            if step.link.isWrap, let n = node(step.row, step.station) {
                let wrap = step.link == .aroundSpine ? 1 : (step.link == .aroundHead ? 2 : 3)
                out.append(DiagramSegment(ax: n.x, ay: n.y, bx: n.x, by: n.y, outside: step.outward, link: step.link, needle: step.needle, wrap: wrap))
                lastByNeedle[step.needle] = step
                continue
            }
            if let prev = lastByNeedle[step.needle], let a = node(prev.row, prev.station), let b = node(step.row, step.station) {
                let outside = s.family == .stab ? prev.outward : (prev.row == step.row ? prev.outward : true)
                out.append(DiagramSegment(ax: a.x, ay: a.y, bx: b.x, by: b.y, outside: outside, link: step.link, needle: step.needle, wrap: 0))
            }
            lastByNeedle[step.needle] = step
        }
        return out
    }
}
