import Foundation
import SwiftUI
import Combine

struct BenchSnapshot: Codable, Equatable {
    var structure: String
    var titleKey: String
    var label: String
    var signatures: Int
    var stations: Int
    var imposition: String
    var sheet: String
    var paperKey: String
    var thread: String
    var coverKey: String
    var boardKey: String
    var stageIndex: Int = 0
    var forCommission: Bool = false
    var commissionDay: Int? = nil
    var foldMoves: [String] = []
    var foldRecords: [FoldRecord] = []
    var accordionResults: [Bool] = []
    var punchErrors: [Double] = []
    var stitchIndex: Int = 0
    var stitchFaults: Int = 0
    var linkMisses: Int = 0
    var tensions: [String] = []
    var tears: [Int] = []
    var pendingPull: Bool = false
    var roundingTaps: [Int] = [0, 0, 0]
    var backingTaps: Int = 0
    var liningMull: Bool = false
    var liningKraft: Bool = false
    var liningSwipes: Int = 0
    var headbandA: Int = 0
    var headbandB: Int = 1
    var headbandIntervals: [Double] = []
    var headbandTaps: Int = 0
    var endpaperStroke: Double = -1
    var boardCuts: [Double] = []
    var pasteCoverage: Double = 0
    var turnIns: [Double] = []
    var cornerKind: String = "library"
    var cornerSteps: Int = 0
    var cornerFaults: Int = 0
    var caseOffsetMM: Double = -1
    var nipped: Bool = false
    var pressStart: Double? = nil
    var pressScrewed: Bool = false
    var pressedHours: Double? = nil
    var started: Double = Date().timeIntervalSince1970
}

enum StitchAttempt: Equatable {
    case accepted, acceptedNoLink, wrongStation, needsPull, finished, wrongNeedle
}

final class BenchSession: ObservableObject {
    @Published var s: BenchSnapshot? = nil

    func snapshot() -> BenchSnapshot? { s }
    func restore(_ snap: BenchSnapshot) { s = snap }
    func reset() { s = nil }

    var structure: Structure { Structure(rawValue: s?.structure ?? "") ?? .pamphlet3 }
    var imposition: Imposition { Imposition(rawValue: s?.imposition ?? "") ?? .octavo }
    var sheetSize: SheetSize { SheetSize(rawValue: s?.sheet ?? "") ?? .a3 }
    var thread: ThreadKind { ThreadKind(rawValue: s?.thread ?? "") ?? .linen25 }
    var paper: Material { Materials.find(s?.paperKey ?? "bookWove") }
    var cover: Material { Materials.find(s?.coverKey ?? "starchCotton") }
    var board: Material { Materials.find(s?.boardKey ?? "grey2") }
    var title: BookTitle { Register.title(s?.titleKey ?? "fieldNotebook") }
    var stages: [Stage] { structure.stages }
    var stage: Stage { stages[min(max(0, s?.stageIndex ?? 0), stages.count - 1)] }
    var stageIndex: Int { s?.stageIndex ?? 0 }
    var active: Bool { s != nil }

    var rows: Int { structure.family == .stab || structure == .accordion ? 1 : (s?.signatures ?? 1) }
    var path: [StitchStep] { StitchGrammar.path(structure, signatures: rows, stations: s?.stations ?? structure.defaultStations) }
    var pages: Int {
        guard let snap = s else { return 0 }
        if structure.family == .stab { return snap.signatures * 2 }
        return snap.signatures * imposition.pages
    }
    var spineMM: Double {
        guard let snap = s else { return 0 }
        return SpineMath.widthMM(pages: pages, gsm: paper.gsm, texture: paper.texture, signatures: max(1, snap.signatures), thread: thread)
    }
    var pressNeeded: Double { Press.hours(for: structure) }

    func start(structure: Structure, title: BookTitle, label: LabelStyle, signatures: Int, stations: Int, imposition: Imposition, sheet: SheetSize,
               paper: Material, thread: ThreadKind, cover: Material, board: Material, commission: Commission?) {
        var snap = BenchSnapshot(structure: structure.rawValue, titleKey: title.key, label: label.rawValue, signatures: signatures, stations: stations,
                                 imposition: imposition.rawValue, sheet: sheet.rawValue, paperKey: paper.key, thread: thread.rawValue,
                                 coverKey: cover.key, boardKey: board.key)
        if let c = commission {
            snap.forCommission = c.structure == structure && c.titleKey == title.key
            snap.commissionDay = c.day
        }
        s = snap
    }

    func startFromCommission(_ c: Commission) {
        start(structure: c.structure, title: c.title, label: c.title.label, signatures: c.signatures, stations: c.stations, imposition: c.imposition,
              sheet: c.sheet, paper: c.paper, thread: c.thread, cover: c.cover, board: c.board, commission: c)
    }

    var foldState: FoldState {
        var state = FoldState(imposition: imposition)
        for m in s?.foldMoves ?? [] { if let move = FoldMove(rawValue: m) { state.fold(move) } }
        return state
    }

    var readout: FoldReadout { Imposer.readout(imposition, (s?.foldMoves ?? []).compactMap { FoldMove(rawValue: $0) }) }

    var grainAcross: Bool { paper.grain != imposition.correctGrain }

    func fold(_ move: FoldMove, offsetMM: Double) -> Bool {
        guard var snap = s else { return false }
        var state = foldState
        guard state.canFold(move) else { return false }
        state.fold(move)
        snap.foldMoves.append(move.rawValue)
        snap.foldRecords.append(FoldRecord(move: move, offsetMM: offsetMM, crease: 0, acrossGrain: move.axis == .vertical ? (imposition.correctGrain == .short ? paper.grain != .short : paper.grain != .long) : false))
        s = snap
        return true
    }

    func crease(_ quality: Double) {
        guard var snap = s, let last = snap.foldRecords.indices.last else { return }
        snap.foldRecords[last].crease = max(snap.foldRecords[last].crease, min(1, max(0, quality)))
        s = snap
    }

    var lastCrease: Double { s?.foldRecords.last?.crease ?? 0 }

    func unfoldAll() {
        guard var snap = s else { return }
        snap.foldMoves = []
        snap.foldRecords = []
        s = snap
    }

    func accordionFold(_ index: Int, mountain: Bool) -> Bool {
        guard var snap = s else { return false }
        let expected = StitchGrammar.accordion(panels: snap.stations)
        guard index == snap.accordionResults.count, index < expected.count else { return false }
        let ok = expected[index].outward == mountain
        snap.accordionResults.append(ok)
        s = snap
        return ok
    }

    var stationMarks: [Double] {
        guard let snap = s else { return [] }
        let height = imposition.sheetPortrait ? sheetSize.longMM / 2 : sheetSize.shortMM
        if structure.family == .stab { return StitchGrammar.holes(structure).map { $0.y * height } }
        if structure.family == .supported { return Stations.tapePositions(tapes: structure.tapes(snap.stations), height: height) }
        return Stations.evenPositions(count: snap.stations, height: height)
    }

    var signatureHeightMM: Double { imposition.sheetPortrait ? sheetSize.longMM / 2 : sheetSize.shortMM }

    func punch(errorMM: Double) {
        guard var snap = s, snap.punchErrors.count < stationMarks.count else { return }
        snap.punchErrors.append(max(0, errorMM))
        s = snap
    }

    var expectedStep: StitchStep? {
        guard let snap = s, snap.stitchIndex < path.count else { return nil }
        return path[snap.stitchIndex]
    }

    var previousStep: StitchStep? {
        guard let snap = s, snap.stitchIndex > 0 else { return nil }
        return path[snap.stitchIndex - 1]
    }

    func rowOfStep(_ index: Int) -> Int {
        let steps = path
        guard index < steps.count else { return rows }
        if structure.family == .stab { return index / 5 }
        return steps[index].row
    }

    func attempt(row: Int, station: Int, passedLink: Bool, needle: Int = 0) -> StitchAttempt {
        guard var snap = s, snap.stitchIndex < path.count else { return .finished }
        if snap.pendingPull { return .needsPull }
        let step = path[snap.stitchIndex]
        if structure.needles == 2 && needle != step.needle { return .wrongNeedle }
        if step.row != row || step.station != station {
            snap.stitchFaults += 1
            s = snap
            return .wrongStation
        }
        var result: StitchAttempt = .accepted
        if step.link.needsPass && !passedLink {
            snap.linkMisses += 1
            result = .acceptedNoLink
        }
        snap.stitchIndex += 1
        let done = snap.stitchIndex >= path.count
        let rowEnds = done || rowOfStep(snap.stitchIndex) != rowOfStep(snap.stitchIndex - 1)
        if rowEnds { snap.pendingPull = true }
        s = snap
        return done && !snap.pendingPull ? .finished : result
    }

    func wrapDone(station: Int) -> StitchAttempt {
        guard var snap = s, snap.stitchIndex < path.count else { return .finished }
        if snap.pendingPull { return .needsPull }
        let step = path[snap.stitchIndex]
        guard step.link.isWrap, step.station == station else {
            snap.stitchFaults += 1
            s = snap
            return .wrongStation
        }
        snap.stitchIndex += 1
        let done = snap.stitchIndex >= path.count
        if done || rowOfStep(snap.stitchIndex) != rowOfStep(snap.stitchIndex - 1) { snap.pendingPull = true }
        s = snap
        return .accepted
    }

    func pull(_ tension: Double) -> TensionResult {
        guard var snap = s else { return .good }
        let result = Tension.judge(tension, thread: thread)
        snap.tensions.append(result.rawValue)
        if result == .tight {
            let station = previousStep?.station ?? 0
            snap.tears.append(station)
        }
        snap.pendingPull = false
        s = snap
        return result
    }

    var sewingDone: Bool {
        guard let snap = s else { return false }
        return snap.stitchIndex >= path.count && !snap.pendingPull
    }

    var tensionResults: [TensionResult] { (s?.tensions ?? []).compactMap { TensionResult(rawValue: $0) } }

    func roundingTap(zone: Int) {
        guard var snap = s, zone >= 0, zone < 3 else { return }
        snap.roundingTaps[zone] += 1
        s = snap
    }

    var roundingNeeded: Int { Rounding.tapsNeeded(signatures: s?.signatures ?? 4) }
    var roundingProfile: [Double] {
        let need = max(1.0, Double(roundingNeeded) / 3)
        return (s?.roundingTaps ?? [0, 0, 0]).map { Rounding.rounding(taps: $0, needed: Int(need.rounded())) }
    }

    func backingTap() {
        guard var snap = s else { return }
        snap.backingTaps += 1
        s = snap
    }

    var shoulderMM: Double { Rounding.shoulder(taps: s?.backingTaps ?? 0, boardMM: board.boardMM) }

    func layLining(mull: Bool) {
        guard var snap = s else { return }
        if mull { snap.liningMull = true } else if snap.liningMull { snap.liningKraft = true }
        s = snap
    }

    func liningSwipe() {
        guard var snap = s, snap.liningMull else { return }
        snap.liningSwipes += 1
        s = snap
    }

    var bubbles: Int { Lining.bubbles(swipes: s?.liningSwipes ?? 0) }

    func chooseHeadband(_ a: Int, _ b: Int) {
        guard var snap = s else { return }
        snap.headbandA = a
        snap.headbandB = b
        s = snap
    }

    func headbandTap(interval: Double?) {
        guard var snap = s else { return }
        snap.headbandTaps += 1
        if let i = interval { snap.headbandIntervals.append(i) }
        s = snap
    }

    func endpaper(_ accuracy: Double) {
        guard var snap = s else { return }
        snap.endpaperStroke = max(snap.endpaperStroke, min(1, max(0, accuracy)))
        s = snap
    }

    func cutBoard(errorMM: Double) {
        guard var snap = s, snap.boardCuts.count < 2 else { return }
        snap.boardCuts.append(abs(errorMM))
        s = snap
    }

    func paste(coverage: Double) {
        guard var snap = s else { return }
        snap.pasteCoverage = max(snap.pasteCoverage, min(1, coverage))
        s = snap
    }

    func turnIn(widthMM: Double) {
        guard var snap = s, snap.turnIns.count < 4 else { return }
        snap.turnIns.append(widthMM)
        s = snap
    }

    func chooseCorner(_ kind: String) {
        guard var snap = s else { return }
        snap.cornerKind = kind
        snap.cornerSteps = 0
        s = snap
    }

    func cornerStep(_ step: Int) -> Bool {
        guard var snap = s else { return false }
        if step == snap.cornerSteps {
            snap.cornerSteps += 1
            s = snap
            return true
        }
        snap.cornerFaults += 1
        s = snap
        return false
    }

    func caseIn(offsetMM: Double) {
        guard var snap = s else { return }
        snap.caseOffsetMM = abs(offsetMM)
        s = snap
    }

    func nip() {
        guard var snap = s else { return }
        snap.nipped = true
        s = snap
    }

    func pressIn() {
        guard var snap = s, snap.pressStart == nil else { return }
        snap.pressStart = Date().timeIntervalSince1970
        s = snap
    }

    func screwDown() {
        guard var snap = s else { return }
        snap.pressScrewed = true
        s = snap
    }

    var pressElapsedHours: Double {
        guard let start = s?.pressStart else { return 0 }
        return (Date().timeIntervalSince1970 - start) / 3600
    }

    var pressRemaining: Double { max(0, pressNeeded * 3600 - pressElapsedHours * 3600) }

    func takeOut() {
        guard var snap = s, snap.pressStart != nil else { return }
        snap.pressedHours = min(pressNeeded, pressElapsedHours)
        s = snap
    }

    var stageComplete: Bool {
        guard let snap = s else { return false }
        switch stage {
        case .sheet: return true
        case .fold:
            if structure == .accordion { return snap.accordionResults.count >= snap.stations - 1 }
            return foldState.folded && (snap.foldRecords.last?.crease ?? 0) > 0.2
        case .punch: return snap.punchErrors.count >= stationMarks.count
        case .sew: return sewingDone
        case .spine: return snap.liningMull && snap.liningKraft && snap.headbandTaps >= 4 && snap.endpaperStroke >= 0
        case .boards: return snap.boardCuts.count >= 2
        case .cover:
            let corners = snap.cornerSteps >= 3
            let base = snap.pasteCoverage >= 0.5 && snap.turnIns.count >= 4 && corners
            if structure.family == .supported { return base && snap.caseOffsetMM >= 0 && snap.nipped }
            return base
        case .press: return snap.pressedHours != nil
        }
    }

    func advance() {
        guard var snap = s, snap.stageIndex < stages.count - 1 else { return }
        snap.stageIndex += 1
        s = snap
    }

    func goTo(_ index: Int) {
        guard var snap = s, index >= 0, index <= snap.stageIndex else { return }
        snap.stageIndex = index
        s = snap
    }

    var verdict: Verdict {
        guard let snap = s else { return Verdict(score: 0, word: "", parts: [], critique: []) }
        var parts: [ScorePart] = []
        var critique: [String] = []
        let has = stages
        if has.contains(.fold) {
            var v = 0.0
            var note = ""
            if structure == .accordion {
                let ok = snap.accordionResults.filter { $0 }.count
                v = snap.accordionResults.isEmpty ? 0 : Double(ok) / Double(snap.accordionResults.count)
                note = ok == snap.accordionResults.count ? "Mountain and valley in rhythm." : "\(snap.accordionResults.count - ok) folds went the wrong way."
            } else {
                let r = readout
                let order = r.correct ? 1.0 : (r.complete ? 0.35 : 0.0)
                let accuracy = FoldJudge.accuracy(snap.foldRecords)
                let grain = grainAcross ? 0.4 : 1.0
                v = order * 0.5 + accuracy * 0.3 + grain * 0.2
                if !r.correct { note = r.fault ?? "The pages came out of order." } else { note = "Pages 1 to \(imposition.pages) in order." }
                if grainAcross { critique.append("The grain runs across the spine: the fold cracked and the book will not open flat.") }
                if accuracy < 0.6 { critique.append("The folds are out of square and the creases were soft.") }
            }
            parts.append(ScorePart(name: "Folding", weight: 15, value: v, note: note))
        }
        if has.contains(.punch) {
            let v = Stations.accuracy(snap.punchErrors)
            let crooked = snap.punchErrors.filter { $0 > 2 }.count
            parts.append(ScorePart(name: "Stations", weight: 10, value: v, note: crooked == 0 ? "Every station on its mark." : "\(crooked) crooked station\(crooked == 1 ? "" : "s")."))
            if crooked > 0 { critique.append("\(crooked) station\(crooked == 1 ? " was" : "s were") punched off the mark; the stitch steps across the spine there.") }
        }
        if has.contains(.sew) {
            let steps = max(1, path.count)
            let faults = Double(snap.stitchFaults) + Double(snap.linkMisses) * 0.6
            let v = max(0, 1 - faults / Double(steps) * 3)
            parts.append(ScorePart(name: "Stitch grammar", weight: 20, value: v, note: snap.stitchFaults == 0 && snap.linkMisses == 0 ? "The needle went where the grammar says." : "\(snap.stitchFaults) skipped station\(snap.stitchFaults == 1 ? "" : "s"), \(snap.linkMisses) missed link\(snap.linkMisses == 1 ? "" : "s")."))
            if snap.stitchFaults > 0 { critique.append("The needle went to the wrong station \(snap.stitchFaults) time\(snap.stitchFaults == 1 ? "" : "s") and the thread had to be drawn back.") }
            if snap.linkMisses > 0 { critique.append("\(snap.linkMisses) link\(snap.linkMisses == 1 ? " was" : "s were") skipped; the chain is open there.") }
            let t = Tension.score(tensionResults)
            let loose = tensionResults.filter { $0 == .loose }.count, tight = tensionResults.filter { $0 == .tight }.count
            parts.append(ScorePart(name: "Tension", weight: 15, value: t, note: loose == 0 && tight == 0 ? "Every pull in the window." : "\(loose) loose, \(tight) tight."))
            if loose > 0 { critique.append("\(loose) pull\(loose == 1 ? " was" : "s were") loose; the spine is baggy there.") }
            if tight > 0 { critique.append("\(tight) pull\(tight == 1 ? " was" : "s were") too hard and tore the paper at the station.") }
        }
        if has.contains(.spine) {
            let profile = 1 - Rounding.profileError(zoneTaps: snap.roundingTaps, needed: roundingNeeded)
            let shoulder = 1 - min(1, Rounding.shoulderError(taps: snap.backingTaps, boardMM: board.boardMM))
            let lining = snap.liningMull && snap.liningKraft ? 1 - Double(bubbles) * 0.2 : 0.2
            let rhythm = Rhythm.regularity(snap.headbandIntervals)
            let end = max(0, snap.endpaperStroke)
            let v = profile * 0.35 + shoulder * 0.2 + lining * 0.2 + rhythm * 0.15 + end * 0.1
            parts.append(ScorePart(name: "Spine", weight: 10, value: v, note: profile > 0.85 ? "A third of a circle, near enough." : "The round is \(profile < 0.5 ? "far" : "a little") off."))
            if profile < 0.6 { critique.append(snap.roundingTaps.reduce(0, +) > roundingNeeded ? "Over-tapped: the round flattened back into a hump." : "Under-rounded: the spine is still nearly flat.") }
            if bubbles > 0 && snap.liningMull { critique.append("\(bubbles) bubble\(bubbles == 1 ? "" : "s") left under the lining will show through the cloth.") }
            if shoulder < 0.5 { critique.append(snap.backingTaps == 0 ? "No shoulders were made; the boards sink into the joint." : "The shoulders do not match the board.") }
        }
        if has.contains(.boards) {
            let v = Squares.score(snap.boardCuts.map { Squares.error(cutMM: 3 + $0) })
            let off = snap.boardCuts.filter { $0 > 2 }.count
            parts.append(ScorePart(name: "Boards", weight: 10, value: v, note: off == 0 ? "Squares of three millimetres." : "A board cut off the line."))
            if off > 0 { critique.append("One square is wider than the others; the board was cut off the ruled line.") }
        }
        if has.contains(.cover) {
            let paste = snap.pasteCoverage
            let turn = TurnIns.score(snap.turnIns)
            let corner = max(0, 1 - Double(snap.cornerFaults) * 0.3)
            var v = paste * 0.3 + turn * 0.4 + corner * 0.3
            var note = paste > 0.85 && turn > 0.8 ? "Turn-ins of fifteen and clean corners." : "The covering is uneven."
            if structure.family == .supported {
                let offset = snap.caseOffsetMM < 0 ? 0 : max(0, 1 - snap.caseOffsetMM / 4)
                v = v * 0.7 + offset * 0.3
                if snap.caseOffsetMM > 2 { critique.append("The block sits crooked in the case; the squares are unequal."); note = "Cased in crooked." }
            }
            parts.append(ScorePart(name: "Covering", weight: 10, value: v, note: note))
            if paste < 0.6 { critique.append("The paste did not reach the edges; the cloth will lift.") }
            if turn < 0.6 { critique.append("The turn-ins are not fifteen millimetres; they show under the pastedown or will not hold.") }
            if snap.cornerFaults > 0 { critique.append("The corner was folded out of order.") }
        }
        if has.contains(.press) {
            let pressed = snap.pressedHours ?? 0
            let v = Press.patience(pressedHours: pressed, needed: pressNeeded)
            parts.append(ScorePart(name: "Pressing", weight: 10, value: v, note: v >= 0.99 ? "The full time in the press." : "Taken out after \(Clock.durationWords(pressed * 3600))."))
            if v < 0.9 { critique.append("Taken out of the press early: the boards warped toward the wet side.") }
        }
        if critique.isEmpty { critique.append("Nothing to fault. Shelve it with the good ones.") }
        return Grading.verdict(parts, critique: critique)
    }

    func finish() -> BoundBook? {
        guard let snap = s else { return nil }
        let v = verdict
        let book = BoundBook(id: "book-\(Int(Date().timeIntervalSince1970))-\(Int.random(in: 100...999))", titleKey: snap.titleKey, label: snap.label,
                             structure: snap.structure, signatures: snap.signatures, imposition: snap.imposition, stations: snap.stations, sheet: snap.sheet,
                             paperKey: snap.paperKey, thread: snap.thread, coverKey: snap.coverKey, boardKey: snap.boardKey, score: v.score, word: v.word,
                             day: Almanac.dayIndex(), hour: Calendar.current.component(.hour, from: Date()), pages: pages, spineMM: spineMM,
                             critique: v.critique, tensions: snap.tensions, pressHours: snap.pressedHours ?? 0,
                             forCommission: snap.forCommission && snap.commissionDay == Almanac.dayIndex(), headbandA: snap.headbandA, headbandB: snap.headbandB, parts: v.parts)
        s = nil
        return book
    }
}
