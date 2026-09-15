import Foundation

var failures: [String: Int] = [:]
var checks = 0

func fail(_ message: String) { failures[message, default: 0] += 1 }
func expect(_ condition: Bool, _ message: @autoclosure () -> String) {
    checks += 1
    if !condition { fail(message()) }
}

let artDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : ""
func plateExists(_ name: String) -> Bool {
    artDir.isEmpty || FileManager.default.fileExists(atPath: artDir + "/" + name + ".jpg")
}

print("Bone Folder validator")

print("== imposition ==")
for imposition in Imposition.allCases {
    let map = Imposer.map(imposition)
    let numbers = (map.front + map.back).map { $0.number }.sorted()
    expect(numbers == Array(1...imposition.pages), "\(imposition.name): the sheet does not carry pages 1...\(imposition.pages)")
    expect(Imposer.readout(imposition, imposition.canonical).correct, "\(imposition.name): canonical folds do not give pages in order")
    let sequences = Imposer.allSequences(imposition)
    let good = sequences.filter { Imposer.readout(imposition, $0).correct }
    expect(good.count >= 1 && good.count <= 2, "\(imposition.name): \(good.count) correct sequences (expected 1 or 2)")
    for seq in sequences where !Imposer.readout(imposition, seq).correct {
        expect(Imposer.readout(imposition, seq).fault != nil, "\(imposition.name): wrong sequence without a fault text")
    }
    for seq in sequences {
        let a = Imposer.readout(imposition, seq), b = Imposer.readout(imposition, seq)
        expect(a == b, "\(imposition.name): readout not reproducible")
    }
    expect(imposition.correctGrain == (imposition.sheetPortrait ? .long : .short), "\(imposition.name): grain rule")
    let across = FoldRecord(move: imposition.canonical.last!, offsetMM: 0, crease: 1, acrossGrain: true)
    expect(across.acrossGrain, "grain flag missing")
}
print("   \(Imposition.allCases.count) impositions checked")

print("== stitch grammar ==")
for s in Structure.allCases {
    for k in [s.signatureRange.lowerBound, min(s.signatureRange.upperBound, 6), s.signatureRange.upperBound] {
        for n in s.stationOptions {
            let path = StitchGrammar.path(s, signatures: k, stations: n)
            expect(!path.isEmpty, "\(s.rawValue): empty path")
            let rows = StitchDiagram.rowsCount(s, signatures: k)
            let visited = StitchGrammar.visited(path).count
            let expected = s == .accordion ? n - 1 : rows * n
            expect(visited == expected, "\(s.rawValue) k=\(k) n=\(n): visited \(visited) of \(expected) stations")
            expect(path.last?.link == .tieOff || s == .accordion, "\(s.rawValue): path does not tie off")
            for step in path {
                expect(step.row >= 0 && step.row < rows, "\(s.rawValue): row out of range")
                expect(step.station >= 0 && step.station < n, "\(s.rawValue): station out of range")
                expect(step.needle < s.needles * max(1, n / 2), "\(s.rawValue): needle index out of range")
            }
            let links = StitchGrammar.chainLinks(path)
            switch s {
            case .kettleTapes: expect(links == k - 1, "kettle: \(links) kettle links for \(k) signatures (expected \(k - 1))")
            case .frenchLink: expect(links == (k - 1) + (k - 1) * s.tapes(n), "french link: \(links) links (expected \((k - 1) + (k - 1) * s.tapes(n)))")
            case .copticOne, .copticTwo: expect(links == (k - 1) * n, "\(s.rawValue): \(links) chain links (expected \((k - 1) * n))")
            case .ethiopian: expect(links == (k + 2) * n, "ethiopian: \(links) links (expected \((k + 2) * n))")
            default: break
            }
            for i in 1..<path.count where s.family != .stab && s != .accordion && s.needles == 1 {
                let a = path[i - 1], b = path[i]
                if a.row == b.row && !b.link.isWrap && !(s == .secretBelgian && b.row == 0) {
                    expect(a.outward != b.outward || a.station == b.station, "\(s.rawValue): two passes in the same direction between \(a.station) and \(b.station)")
                }
            }
            for i in 1..<path.count {
                expect(path[i] != path[i - 1], "\(s.rawValue): two identical consecutive steps")
            }
            if s.family == .stab {
                let holes = StitchGrammar.holes(s)
                expect(holes.count == n, "\(s.rawValue): \(holes.count) holes for \(n) stations")
                expect(path.contains { $0.link == .aroundHead } && path.contains { $0.link == .aroundTail }, "\(s.rawValue): head or tail wrap missing")
                let wrapped = Set(path.filter { $0.link == .aroundSpine }.map { $0.station })
                let mains = Set(holes.enumerated().filter { $0.element.main }.map { $0.offset })
                let extras = Set(holes.enumerated().filter { !$0.element.main }.map { $0.offset })
                expect(mains.isSubset(of: wrapped) || extras.isSubset(of: wrapped), "\(s.rawValue): spine wraps missing")
            }
            for i in 0..<path.count {
                let text = StitchGrammar.instruction(s, step: path[i], previous: i > 0 ? path[i - 1] : nil, stations: n, rows: k)
                expect(!text.isEmpty, "\(s.rawValue): empty instruction")
            }
            let segs = StitchDiagram.segments(s, signatures: k, stations: n, width: 800, height: 400)
            expect(!segs.isEmpty, "\(s.rawValue): no diagram segments")
        }
    }
    expect(plateExists("st_" + s.rawValue), "structure plate missing: st_\(s.rawValue)")
}
print("   \(Structure.allCases.count) structures checked")

print("== tension, rounding, squares, press ==")
for t in ThreadKind.allCases {
    let w = t.tensionWindow
    expect(w.upperBound > w.lowerBound, "\(t.name): empty tension window")
    expect(Tension.judge((w.lowerBound + w.upperBound) / 2, thread: t) == .good, "\(t.name): centre of window not good")
    expect(Tension.judge(w.lowerBound - 0.05, thread: t) == .loose, "\(t.name): below window not loose")
    expect(Tension.judge(w.upperBound + 0.05, thread: t) == .tight, "\(t.name): above window not tight")
}
let silkWidth = ThreadKind.silk.tensionWindow.upperBound - ThreadKind.silk.tensionWindow.lowerBound
let linenWidth = ThreadKind.linen18.tensionWindow.upperBound - ThreadKind.linen18.tensionWindow.lowerBound
expect(silkWidth < linenWidth, "silk window not narrower than linen 18/3")
for sigs in 3...12 {
    let needed = Rounding.tapsNeeded(signatures: sigs)
    var lastError = 2.0
    for taps in 0...needed {
        let e = abs(1 - Rounding.rounding(taps: taps, needed: needed))
        expect(e <= lastError + 1e-9, "rounding not monotonic at \(taps)/\(needed)")
        lastError = e
    }
    expect(abs(1 - Rounding.rounding(taps: needed + 6, needed: needed)) > abs(1 - Rounding.rounding(taps: needed, needed: needed)), "over-tapping does not regress at \(sigs) signatures")
}
expect(Squares.target == 3, "square target is not 3 mm")
expect(Squares.score([0, 0, 0]) == 1, "perfect squares not scored 1")
expect(Squares.score([2, 0, 0]) < Squares.score([0, 0, 0]), "a 2 mm error not penalised")
expect(Squares.error(cutMM: 3) == 0 && Squares.error(cutMM: 5) == 2, "square error scale")
for s in Structure.allCases {
    let needed = Press.hours(for: s)
    expect(needed >= 1 && needed <= 6, "\(s.rawValue): press hours out of range")
    expect(Press.patience(pressedHours: needed, needed: needed) > Press.patience(pressedHours: 1, needed: needed) || needed == 1, "\(s.rawValue): full press not better than 1 h")
}
expect(Press.hours(for: .kettleTapes) == 6, "cased book press is not 6 h")

print("== spine width ==")
for sigs in 4...8 {
    let w = SpineMath.widthMM(pages: 128, gsm: 100, texture: .wove, signatures: sigs, thread: .linen25)
    expect(w >= 8 && w <= 11, "128 pages 100 gsm \(sigs) signatures: \(w) mm not in 8...11")
}
expect(SpineMath.widthMM(pages: 128, gsm: 150, texture: .wove, signatures: 8, thread: .linen25) > SpineMath.widthMM(pages: 128, gsm: 100, texture: .wove, signatures: 8, thread: .linen25), "spine does not grow with gsm")
expect(SpineMath.widthMM(pages: 256, gsm: 100, texture: .wove, signatures: 8, thread: .linen25) > SpineMath.widthMM(pages: 128, gsm: 100, texture: .wove, signatures: 8, thread: .linen25), "spine does not grow with pages")

print("== grading ==")
for s in Structure.allCases {
    var parts: [ScorePart] = []
    for stage in s.stages {
        parts.append(ScorePart(name: stage.name, weight: 10, value: 1.0, note: ""))
    }
    let v = Grading.verdict(parts, critique: [])
    expect(v.score >= 95, "\(s.rawValue): perfect run scores \(v.score)")
    expect(v.score <= 100, "score above 100")
    let poor = Grading.verdict(parts.map { ScorePart(name: $0.name, weight: $0.weight, value: 0.2, note: "") }, critique: [])
    expect(poor.score >= 0 && poor.score < 55, "poor run not a working copy: \(poor.score)")
}
expect(Grading.word(95) == "A master binding" && Grading.word(80) == "A fine binding" && Grading.word(60) == "A sound book" && Grading.word(20) == "A working copy", "grade words")

print("== registers and plates ==")
expect(Register.bindings.count == 30, "bindings: \(Register.bindings.count)")
expect(Set(Register.bindings.map { $0.key }).count == 30, "binding keys not unique")
expect(Set(Register.bindings.map { $0.name }).count == 30, "binding names not unique")
for b in Register.bindings {
    expect(!b.summary.isEmpty && !b.history.isEmpty && !b.fails.isEmpty && b.facts.count == 2, "\(b.key): text incomplete")
    expect(plateExists(b.plate), "binding plate missing: \(b.plate)")
}
expect(Materials.all.count == 60, "materials: \(Materials.all.count)")
expect(Materials.of(.paper).count == 24 && Materials.of(.cloth).count == 12 && Materials.of(.leather).count == 8 && Materials.of(.thread).count == 8 && Materials.of(.board).count == 8, "material kind counts")
expect(Set(Materials.all.map { $0.key }).count == 60, "material keys not unique")
for m in Materials.all {
    expect(!m.use.isEmpty && !m.note.isEmpty && !m.wrong.isEmpty, "\(m.key): text incomplete")
    expect(plateExists(m.plate), "material plate missing: \(m.plate)")
    if m.kind == .paper { expect(m.gsm >= 12 && m.gsm <= 300, "\(m.key): gsm out of range") }
}
for t in ThreadKind.allCases { expect(Materials.all.contains { $0.key == t.rawValue }, "thread \(t.rawValue) has no material entry") }
expect(Register.tools.count == 18, "tools: \(Register.tools.count)")
for t in Register.tools {
    expect(!t.use.isEmpty && !t.note.isEmpty && !t.wrong.isEmpty, "\(t.key): tool text incomplete")
    expect(plateExists(t.plate), "tool plate missing: \(t.plate)")
}
expect(Register.titles.count == 40, "titles: \(Register.titles.count)")
expect(Set(Register.titles.map { $0.title }).count == 40, "titles not unique")
for t in Register.titles { expect(plateExists(t.plate), "label plate missing: \(t.plate)") }
expect(Lessons.all.count == 12, "lessons: \(Lessons.all.count)")
for l in Lessons.all {
    expect(l.words >= 250 && l.words <= 450, "\(l.title): \(l.words) words")
    expect(plateExists(l.plate), "lesson plate missing: \(l.plate)")
}
expect(Set(Lessons.all.map { $0.title }).count == 12, "lesson titles not unique")
expect(Glossary.all.count >= 45 && Glossary.all.count <= 62, "glossary: \(Glossary.all.count)")
expect(Set(Glossary.all.map { $0.term }).count == Glossary.all.count, "glossary terms not unique")
for g in Glossary.all { expect(!g.meaning.isEmpty, "\(g.term): empty meaning") }
for i in 0..<7 { expect(plateExists("hr_\(i)"), "hour plate missing: hr_\(i)") }
for i in 0..<4 { expect(plateExists("ob_\(i)"), "onboarding plate missing: ob_\(i)") }
for key in ["shelfWood", "shelfBack", "endMarbled", "endPaste", "headband", "clothBolt", "spools", "pastePot", "pressEmpty", "benchTop"] {
    expect(plateExists("dc_" + key), "decor plate missing: dc_\(key)")
}

print("== exam ==")
expect(Exam.authored.count >= 30, "authored questions: \(Exam.authored.count)")
expect(Set(Exam.authored.map { $0.prompt }).count == Exam.authored.count, "exam prompts not unique")
for q in Exam.authored {
    expect(q.choices.count == 4 && q.answer >= 0 && q.answer < 4 && !q.explain.isEmpty, "exam question malformed: \(q.prompt)")
    expect(Set(q.choices).count == 4, "duplicate choices: \(q.prompt)")
}
for seed in 0..<600 {
    let f = Exam.foldQuestion(seed: UInt64(seed))
    expect(f.choices.count == 4 && f.answer >= 0 && f.answer < 4, "fold question malformed")
    let g = Exam.foldQuestion(seed: UInt64(seed))
    expect(f == g, "fold question not reproducible")
    let s = Exam.structureQuestion(seed: UInt64(seed))
    expect(s.choices.count == 4 && s.answer < 4 && s.plate != nil, "structure question malformed")
    let w = Exam.faultQuestion(seed: UInt64(seed))
    expect(w.choices.count == 4 && Set(w.choices).count == 4, "fault question malformed")
    let paper = Exam.paper(seed: UInt64(seed))
    expect(paper.count == 12, "exam paper size \(paper.count)")
}

print("== daily commissions ==")
for day in 0..<3000 {
    for rank in 0...4 {
        let c = Daily.commission(day: day, rank: rank)
        let again = Daily.commission(day: day, rank: rank)
        expect(c == again, "commission not reproducible")
        expect(Daily.structures(forRank: rank).contains(c.structure), "commission structure not open at rank \(rank)")
        expect(c.structure.signatureRange.contains(c.signatures) || (c.structure.family == .stab && c.structure.leavesRange.contains(c.signatures)), "commission signatures out of range: \(c.structure.rawValue) \(c.signatures)")
        expect(c.structure.stationOptions.contains(c.stations), "commission stations not offered")
        expect(c.structure.allowedImpositions.contains(c.imposition), "commission imposition not allowed")
        expect(Materials.find(c.paperKey).benchOK, "commission paper not usable")
        expect(!c.line.isEmpty && c.target >= 55 && c.target <= 85, "commission line or target")
        let path = StitchGrammar.path(c.structure, signatures: c.structure.family == .stab ? 1 : c.signatures, stations: c.stations)
        expect(!path.isEmpty, "commission has no sewing path")
    }
    let w = Daily.weather(day: day)
    expect(w.cloud >= 0 && w.cloud <= 1 && w.wind >= 0 && w.wind <= 1, "weather out of range")
}
for m in 1...12 { expect(Daily.sunrise(month: m) < Daily.sunset(month: m), "sunrise after sunset in month \(m)") }
expect(Daily.ladder.count == 5 && Daily.badges.count == 16, "ladder or badge count")

print("== stations ==")
for n in [3, 4, 5, 7] {
    let pos = Stations.evenPositions(count: n, height: 210)
    expect(pos.count == n && pos.first! >= 10 && pos.last! <= 200, "even positions for \(n)")
    for i in 1..<pos.count { expect(pos[i] > pos[i - 1], "stations not increasing") }
}
for tapes in 1...3 {
    let pos = Stations.tapePositions(tapes: tapes, height: 210)
    expect(pos.count == 2 + tapes * 2, "tape positions count for \(tapes) tapes")
    for i in 1..<pos.count { expect(pos[i] > pos[i - 1], "tape stations not increasing") }
}
expect(Stations.accuracy([0, 0, 0]) == 1 && Stations.accuracy([3, 3, 3]) < 0.5, "station accuracy scale")
expect(Lining.bubbles(swipes: 0) == 4 && Lining.bubbles(swipes: 4) == 0, "lining bubbles")
expect(Rhythm.regularity([1, 1, 1, 1]) > 0.95 && Rhythm.regularity([1, 3, 0.5, 2]) < 0.5, "rhythm regularity")

print("== result ==")
print("checks: \(checks)")
if failures.isEmpty {
    print("all passed")
} else {
    for (message, count) in failures.sorted(by: { $0.value > $1.value }) {
        print("FAIL x\(count): \(message)")
    }
    exit(1)
}
