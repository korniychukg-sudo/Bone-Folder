import Foundation
import CoreGraphics

func threadLine(_ p: Leaf, _ pts: [CGPoint], weight: Double, tone: Hue, rng: inout Chip, dashed: Bool = false) {
    guard pts.count > 1 else { return }
    if dashed {
        p.polyline(pts, weight * 0.7, tone.al(0.55), dash: [CGFloat(weight * 2.2), CGFloat(weight * 1.8)])
        return
    }
    pen(p, shifted(pts, 1.2, 1.8), weight: weight * 1.15, colour: Hue(r: 0, g: 0, b: 0, a: 0.28), wobble: 0.2, taper: false, seed: rng.next())
    pen(p, pts, weight: weight, colour: tone.dk(0.12), wobble: 0.25, taper: false, seed: rng.next())
    pen(p, shifted(pts, -weight * 0.18, -weight * 0.22), weight: weight * 0.34, colour: tone.lt(0.5).al(0.85), wobble: 0.2, taper: false, seed: rng.next())
}

func spineDiagram(_ p: Leaf, _ s: Structure, signatures: Int, stations: Int, frame: CGRect, rng: inout Chip) {
    let w = Double(frame.width), h = Double(frame.height)
    let ox = Double(frame.minX), oy = Double(frame.minY)
    let rows = StitchDiagram.rowsCount(s, signatures: signatures)
    let rowH = h / Double(rows)
    for r in 0..<rows {
        let y0 = oy + h - rowH * Double(r + 1)
        let isBoard = (s == .ethiopian && (r == 0 || r == rows - 1)) || (s == .secretBelgian && r == 0)
        let band = [pt(ox, y0 + 2), pt(ox + w, y0 + 2), pt(ox + w, y0 + rowH - 2), pt(ox, y0 + rowH - 2)]
        let path = pathOf(band)
        if isBoard {
            p.fillPath(path, s == .ethiopian ? Pot.walnutLight : Pot.greyboard)
            if s == .ethiopian { woodGrain(p, path, axis: 0.0, base: Pot.walnutLight, lines: 10, wave: 1.5, rng: &rng) }
        } else {
            p.fillPath(path, Pot.paper.dk(0.03 + Double(r % 2) * 0.05))
            paperFibres(p, path, base: Pot.paper, laid: false, count: 30, rng: &rng)
            linearInto(p, path, from: pt(ox, y0), to: pt(ox, y0 + rowH), colours: [Hue(r: 1, g: 1, b: 1, a: 0.20), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.22)], locations: [0, 0.5, 1])
        }
        pen(p, [pt(ox, y0 + 2), pt(ox + w, y0 + 2)], weight: 1.4, colour: Pot.ink.al(0.75), wobble: 0.5, taper: false, seed: rng.next())
    }
    if s.family == .supported {
        let tapes = s.tapes(stations)
        let positions = Stations.tapePositions(tapes: tapes, height: w, tapeWidth: w * 0.09)
        for t in 0..<tapes {
            let x0 = ox + positions[1 + t * 2], x1 = ox + positions[2 + t * 2]
            let tape = [pt(x0, oy - 40), pt(x1, oy - 40), pt(x1, oy + h + 40), pt(x0, oy + h + 40)]
            p.shape(shifted(tape, 2, 3), Hue(r: 0, g: 0, b: 0, a: 0.2))
            p.shape(tape, Pot.linenPale)
            clothWeave(p, pathOf(tape), base: Pot.linenPale, pitch: 3.0, rng: &rng)
            penEdge(p, tape, weight: 1.0, colour: Pot.ink.al(0.7), seed: rng.next())
        }
    }
    if s == .longStitch {
        let cover = [pt(ox - 30, oy - 30), pt(ox + w + 30, oy - 30), pt(ox + w + 30, oy + h + 30), pt(ox - 30, oy + h + 30)]
        p.shape(cover, Pot.walnutLight.al(0.35))
        penEdge(p, cover, weight: 1.2, colour: Pot.ink.al(0.6), seed: rng.next())
    }
    let nodes = StitchDiagram.nodes(s, signatures: signatures, stations: stations, width: w, height: h)
    let segs = StitchDiagram.segments(s, signatures: signatures, stations: stations, width: w, height: h)
    let tone = Pot.threadRed
    let weight = max(3.0, min(6.0, rowH * 0.12))
    for seg in segs where !seg.outside && seg.wrap == 0 {
        threadLine(p, [pt(ox + seg.ax, oy + seg.ay), pt(ox + seg.bx, oy + seg.by)], weight: weight, tone: Pot.inkPale, rng: &rng, dashed: true)
    }
    for seg in segs where seg.outside && seg.wrap == 0 {
        let a = pt(ox + seg.ax, oy + seg.ay), b = pt(ox + seg.bx, oy + seg.by)
        let needleTone = seg.needle % 2 == 1 && s.needles == 2 ? Pot.indigo : tone
        if s == .secretBelgian && seg.ay > oy + h - rowH - 1 && seg.by < seg.ay - 1 {
            threadLine(p, [a, b], weight: weight * 0.7, tone: Pot.inkPale, rng: &rng, dashed: true)
            continue
        }
        if seg.link == .overTape || seg.link == .frenchLink {
            let mid = pt((Double(a.x) + Double(b.x)) / 2, (Double(a.y) + Double(b.y)) / 2 - rowH * 0.12)
            threadLine(p, catmull([a, mid, b], steps: 8), weight: weight, tone: needleTone, rng: &rng)
            if seg.link == .frenchLink {
                let dip = pt(Double(mid.x), Double(mid.y) + rowH * 0.62)
                threadLine(p, catmull([a, dip, b], steps: 8), weight: weight * 0.85, tone: needleTone, rng: &rng)
            }
        } else {
            threadLine(p, [a, b], weight: weight, tone: needleTone, rng: &rng)
        }
    }
    for seg in segs where seg.link == .aroundBoard {
        let b = pt(ox + seg.bx, oy + seg.by)
        for dir in [-1.0, 1.0] {
            var loop: [CGPoint] = []
            var ang = 0.0
            while ang <= 3.3 { loop.append(pt(Double(b.x) + cos(ang) * rowH * 0.16, Double(b.y) + dir * (rowH * 0.5 - 2) - dir * sin(ang) * rowH * 0.18)); ang += 0.25 }
            threadLine(p, loop, weight: weight * 0.9, tone: tone, rng: &rng)
            threadLine(p, [pt(Double(b.x) - rowH * 0.16, Double(b.y)), pt(Double(b.x) - rowH * 0.16, Double(b.y) + dir * (rowH * 0.5 - 2))], weight: weight * 0.9, tone: tone, rng: &rng)
            threadLine(p, [pt(Double(b.x) + rowH * 0.16, Double(b.y)), pt(Double(b.x) + rowH * 0.16, Double(b.y) + dir * (rowH * 0.5 - 2))], weight: weight * 0.9, tone: tone, rng: &rng)
        }
    }
    for seg in segs where seg.link == .chainUnder || seg.link == .kettle || seg.link == .throughBoard || seg.link == .underCoverStitch {
        let b = pt(ox + seg.bx, oy + seg.by)
        let needleTone = seg.needle % 2 == 1 && s.needles == 2 ? Pot.indigo : tone
        var loop: [CGPoint] = []
        var ang = -0.5
        while ang <= 3.65 { loop.append(pt(Double(b.x) + cos(ang) * rowH * 0.22, Double(b.y) + sin(ang) * rowH * 0.50)); ang += 0.22 }
        threadLine(p, loop, weight: weight * 0.95, tone: needleTone, rng: &rng)
    }
    for n in nodes {
        let q = pt(ox + n.x, oy + n.y)
        p.dot(Double(q.x), Double(q.y), weight * 0.75, Pot.ink.al(0.9))
        p.dot(Double(q.x) - 1, Double(q.y) - 1, weight * 0.3, Hue(r: 1, g: 1, b: 1, a: 0.5))
    }
    for st in 0..<stations {
        if let n = nodes.first(where: { $0.row == 0 && $0.station == st }) {
            letter(p, "\(st + 1)", at: ox + n.x, oy + h + 34, size: 22, colour: Pot.inkSoft, face: "Cochin")
        }
    }
    for r in 0..<rows {
        let y = oy + h - rowH * (Double(r) + 0.5) + 8
        let name = StitchGrammar.rowName(s, r, signatures)
        letter(p, name, at: ox - 16, y, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic", align: .right)
    }
}

func stabDiagram(_ p: Leaf, _ s: Structure, frame: CGRect, rng: inout Chip) {
    let w = Double(frame.width), h = Double(frame.height)
    let ox = Double(frame.minX), oy = Double(frame.minY)
    let cover = [pt(ox, oy), pt(ox + w, oy), pt(ox + w, oy + h), pt(ox, oy + h)]
    castShadow(p, cover, dx: 8, dy: 10, steps: 6, alpha: 0.06)
    let stack = [pt(ox - 26, oy + 6), pt(ox, oy), pt(ox, oy + h), pt(ox - 26, oy + h + 6)]
    p.shape(stack, Pot.paper.dk(0.12))
    p.inside(pathOf(stack)) {
        var lines: [CGPoint] = []
        var x = ox - 25.0
        while x < ox { lines.append(pt(x, oy + (ox - x) * 0.23)); lines.append(pt(x, oy + h + (ox - x) * 0.23)); x += 1.6 }
        batchSegments(p, lines, colour: Pot.ink.al(0.25), width: 0.6)
    }
    let look = BookLook(cover: Pot.indigo, kind: .cloth, look: .stab, structure: s)
    coverMaterial(p, pathOf(cover), look, light: p.light, rng: &rng)
    penEdge(p, cover, weight: 1.4, colour: Pot.ink.al(0.85), seed: rng.next())
    let holes = StitchGrammar.holes(s)
    func at(_ hole: StabHole) -> CGPoint { pt(ox + hole.x / 40.0 * w * 0.9, oy + hole.y * h) }
    let steps = StitchGrammar.path(s, signatures: 1, stations: holes.count)
    var last: CGPoint? = nil
    var lastFront = true
    let weight = 5.0
    for step in steps {
        let q = at(holes[step.station])
        if step.link.isWrap {
            var arc: [CGPoint] = []
            switch step.link {
            case .aroundSpine:
                arc = catmull([q, pt(ox - 30, Double(q.y) - 6), pt(ox - 44, Double(q.y) + 2), pt(ox - 30, Double(q.y) + 8), q], steps: 6)
            case .aroundHead:
                arc = catmull([q, pt(Double(q.x) - 6, oy - 30), pt(Double(q.x) + 2, oy - 44), pt(Double(q.x) + 8, oy - 30), q], steps: 6)
            default:
                arc = catmull([q, pt(Double(q.x) - 6, oy + h + 30), pt(Double(q.x) + 2, oy + h + 44), pt(Double(q.x) + 8, oy + h + 30), q], steps: 6)
            }
            threadLine(p, arc, weight: weight, tone: Pot.threadRed, rng: &rng)
            continue
        }
        if let l = last {
            threadLine(p, [l, q], weight: weight, tone: Pot.threadRed, rng: &rng, dashed: !lastFront)
        }
        last = q
        lastFront = step.outward
    }
    for (i, hole) in holes.enumerated() {
        let q = at(hole)
        p.dot(Double(q.x), Double(q.y), hole.main ? 5.5 : 4, Pot.ink.al(0.9))
        letter(p, "\(i + 1)", at: Double(q.x) + 22, Double(q.y) + 7, size: 18, colour: Pot.paper.lt(0.3), face: "Cochin")
    }
    letter(p, "head", at: ox + w * 0.5, oy - 54, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic")
    letter(p, "tail", at: ox + w * 0.5, oy + h + 68, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic")
    letter(p, "spine", at: ox - 80, oy + h * 0.5, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic", rotate: -.pi / 2)
}

func accordionDiagram(_ p: Leaf, frame: CGRect, rng: inout Chip) {
    let w = Double(frame.width), h = Double(frame.height)
    let ox = Double(frame.minX), oy = Double(frame.minY)
    let panels = 8
    let pw = w / Double(panels)
    var x = ox
    let ground = [pt(ox - 20, oy + h + 30), pt(ox + w + 40, oy + h + 30), pt(ox + w + 70, oy + h + 60), pt(ox + 10, oy + h + 60)]
    castShadow(p, ground, dx: 6, dy: 8, steps: 5, alpha: 0.05)
    for k in 0..<panels {
        let mountain = k % 2 == 0
        let top = oy + (mountain ? 0 : 26)
        let quad = [pt(x, top + 6), pt(x + pw, top - 6 + (mountain ? 16 : -16)), pt(x + pw + 12, top + h - 6 + (mountain ? 16 : -16)), pt(x + 12, top + h + 6)]
        let path = pathOf(quad)
        p.fillPath(path, mountain ? Pot.paper.lt(0.12) : Pot.paper.dk(0.16))
        paperFibres(p, path, base: Pot.paper, laid: true, count: 50, rng: &rng)
        linearInto(p, path, from: quad[0], to: quad[1], colours: mountain ? [Hue(r: 1, g: 1, b: 1, a: 0.12), Hue(r: 0, g: 0, b: 0, a: 0.22)] : [Hue(r: 0, g: 0, b: 0, a: 0.24), Hue(r: 1, g: 1, b: 1, a: 0.06)], locations: [0, 1])
        penEdge(p, quad, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
        if k < panels - 1 {
            let fx = x + pw + 6, fy = top - 20 + (mountain ? 16 : -16)
            letter(p, mountain ? "M" : "V", at: fx, fy - 8, size: 24, colour: mountain ? Pot.threadRed : Pot.indigo, face: "Cochin-Bold")
        }
        x += pw
    }
    letter(p, "mountain fold: the crease rises toward you", at: ox + w * 0.5, oy + h + 110, size: 22, colour: Pot.threadRed, face: "Cochin-Italic")
    letter(p, "valley fold: the crease sinks away", at: ox + w * 0.5, oy + h + 140, size: 22, colour: Pot.indigo, face: "Cochin-Italic")
}

func structureSubtitle(_ s: Structure) -> String {
    switch s {
    case .pamphlet3: return "One signature, three stations, one thread; out at the middle, in at the head, out at the tail, in at the middle, tie."
    case .pamphlet5: return "Five stations; the middle stations are passed twice so the stitch runs the whole fold."
    case .copticTwo: return "Two needles on one thread per pair of stations; they cross inside the fold and chain under the row below."
    case .copticOne: return "One needle: out, chain under the loop below, back in, along the fold, and up at the last station."
    case .kettleTapes: return "A running stitch over the tapes with a kettle stitch at each change-over station."
    case .frenchLink: return "The same sewing on tapes, but at each tape the thread dips under the stitch below: a chain of Vs."
    case .longStitch: return "Every signature sewn straight through the cover; the long stitches show on the spine."
    case .yotsume: return "Four holes stab-sewn through the side; every hole wrapped over the spine, the ends wrapped at head and tail."
    case .asanoha: return "The four-hole base with a small hole between and beyond each pair, the thread fanning into leaves."
    case .kikko: return "The four holes each flanked by a pair of small holes: hexagons of thread like a tortoise shell."
    case .secretBelgian: return "The cover is sewn first, boards to spine piece; then each signature is sewn to the spine piece from inside."
    case .ethiopian: return "The two-needle chain with the drilled boards sewn in as the first and last rows."
    case .accordion: return "No thread: a strip folded mountain, valley, mountain, with boards pasted to the end panels."
    }
}

func drawStructurePlate(_ s: Structure, dir: String) -> CGImage? {
    let p = Leaf(1200, 900)
    var rng = Chip(hashOf("structure." + s.rawValue))
    plateGround(p, seed: rng.next(), tone: Pot.paperWarm, border: true)
    p.light = 2.34
    let signatures = s.family == .stab || s.family == .pamphlet || s == .accordion ? 1 : (s.family == .chain ? 4 : 4)
    let stations = s.defaultStations
    switch s.family {
    case .stab: stabDiagram(p, s, frame: CGRect(x: 420, y: 130, width: 360, height: 520), rng: &rng)
    case .fold: accordionDiagram(p, frame: CGRect(x: 120, y: 200, width: 960, height: 300), rng: &rng)
    default: spineDiagram(p, s, signatures: signatures, stations: stations, frame: CGRect(x: 250, y: 110, width: 820, height: signatures == 1 ? 260 : 520), rng: &rng)
    }
    captionLabel(p, title: s.name, sub: structureSubtitle(s), y: 706, size: 36)
    p.writeJPG(dir, "st_" + s.rawValue, quality: 0.86)
    return p.image()
}
