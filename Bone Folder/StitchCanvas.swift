import SwiftUI

struct StitchFrame {
    var rect: CGRect
    var structure: Structure
    var signatures: Int
    var stations: Int

    var rows: Int { StitchDiagram.rowsCount(structure, signatures: signatures) }
    var rowH: CGFloat { rect.height / CGFloat(max(1, rows)) }

    var nodes: [DiagramNode] {
        StitchDiagram.nodes(structure, signatures: signatures, stations: stations, width: Double(rect.width), height: Double(rect.height))
    }

    func point(_ n: DiagramNode) -> CGPoint { CGPoint(x: rect.minX + CGFloat(n.x), y: rect.minY + CGFloat(n.y)) }

    func point(row: Int, station: Int) -> CGPoint? {
        nodes.first { $0.row == row && $0.station == station }.map { point($0) }
    }

    func nearest(_ p: CGPoint, within radius: CGFloat) -> DiagramNode? {
        var best: DiagramNode? = nil
        var bestD = radius
        for n in nodes {
            let q = point(n)
            let d = hypot(q.x - p.x, q.y - p.y)
            if d < bestD { bestD = d; best = n }
        }
        return best
    }

    static func make(in size: CGSize, structure: Structure, signatures: Int, stations: Int) -> StitchFrame {
        let rows = StitchDiagram.rowsCount(structure, signatures: signatures)
        let inset: CGFloat = structure.family == .stab ? 60 : 44
        let width = size.width - inset * 2
        let maxH = size.height - 40
        let rowH = min(maxH / CGFloat(max(1, rows)), structure.family == .stab ? maxH : 74)
        let height = structure.family == .stab ? maxH : rowH * CGFloat(rows)
        let rect = CGRect(x: inset, y: (size.height - height) / 2, width: width, height: height)
        return StitchFrame(rect: rect, structure: structure, signatures: signatures, stations: stations)
    }
}

enum StitchPainter {
    static func threadColor(_ thread: ThreadKind, needle: Int) -> Color {
        if needle % 2 == 1 { return Quire.indigo }
        return Color.tint(Materials.thread(thread).tone)
    }

    static func drawSpine(_ ctx: inout GraphicsContext, frame: StitchFrame, thread: ThreadKind, done: Int, expected: StitchStep?,
                          tears: [Int], torn: Bool, tapes: Bool, highlight: Bool, dim: Double = 1.0) {
        let s = frame.structure
        let rows = frame.rows
        let rowH = frame.rowH
        let r = frame.rect
        for row in 0..<rows {
            let y0 = r.maxY - rowH * CGFloat(row + 1)
            let isBoard = (s == .ethiopian && (row == 0 || row == rows - 1)) || (s == .secretBelgian && row == 0)
            let band = CGRect(x: r.minX, y: y0 + 1.5, width: r.width, height: rowH - 3)
            let fill: Color = isBoard ? (s == .ethiopian ? Quire.walnutLight : Quire.greyboard) : (row % 2 == 0 ? Quire.card : Quire.paste)
            ctx.fill(Path(roundedRect: band, cornerRadius: 2), with: .color(fill.opacity(dim)))
            ctx.fill(Path(CGRect(x: band.minX, y: band.minY, width: band.width, height: 2)), with: .color(Color.white.opacity(0.45 * dim)))
            ctx.fill(Path(CGRect(x: band.minX, y: band.maxY - 3, width: band.width, height: 3)), with: .color(Quire.ink.opacity(0.18 * dim)))
            ctx.stroke(Path(roundedRect: band, cornerRadius: 2), with: .color(Quire.ink.opacity(0.35 * dim)), lineWidth: 0.8)
        }
        if tapes && s.family == .supported {
            let count = s.tapes(frame.stations)
            let positions = Stations.tapePositions(tapes: count, height: Double(r.width), tapeWidth: Double(r.width) * 0.09)
            for t in 0..<count {
                let x0 = r.minX + CGFloat(positions[1 + t * 2]), x1 = r.minX + CGFloat(positions[2 + t * 2])
                let tape = CGRect(x: x0, y: r.minY - 18, width: x1 - x0, height: r.height + 36)
                ctx.fill(Path(tape), with: .color(Quire.linenPale.opacity(0.92 * dim)))
                ctx.stroke(Path(tape), with: .color(Quire.ink.opacity(0.35 * dim)), lineWidth: 0.8)
            }
        }
        let segs = StitchDiagram.segments(s, signatures: frame.signatures, stations: frame.stations, width: Double(r.width), height: Double(r.height), upTo: done)
        let weight = max(2.2, min(5.0, rowH * 0.11))
        for seg in segs where !seg.outside && seg.wrap == 0 {
            var p = Path()
            p.move(to: CGPoint(x: r.minX + CGFloat(seg.ax), y: r.minY + CGFloat(seg.ay)))
            p.addLine(to: CGPoint(x: r.minX + CGFloat(seg.bx), y: r.minY + CGFloat(seg.by)))
            ctx.stroke(p, with: .color(Quire.inkFaint.opacity(0.55 * dim)), style: StrokeStyle(lineWidth: weight * 0.6, lineCap: .round, dash: [weight * 1.8, weight * 1.6]))
        }
        for seg in segs where seg.outside && seg.wrap == 0 {
            let a = CGPoint(x: r.minX + CGFloat(seg.ax), y: r.minY + CGFloat(seg.ay))
            let b = CGPoint(x: r.minX + CGFloat(seg.bx), y: r.minY + CGFloat(seg.by))
            let tone = threadColor(thread, needle: seg.needle)
            var p = Path()
            if seg.link == .overTape || seg.link == .frenchLink {
                let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2 - rowH * 0.12)
                p.move(to: a); p.addQuadCurve(to: b, control: mid)
                if seg.link == .frenchLink {
                    var v = Path()
                    v.move(to: a); v.addQuadCurve(to: b, control: CGPoint(x: mid.x, y: mid.y + rowH * 0.7))
                    strokeThread(&ctx, v, weight * 0.85, tone, dim)
                }
            } else {
                p.move(to: a); p.addLine(to: b)
            }
            strokeThread(&ctx, p, weight, tone, dim)
        }
        for seg in segs where seg.link == .chainUnder || seg.link == .kettle || seg.link == .throughBoard || seg.link == .underCoverStitch {
            let b = CGPoint(x: r.minX + CGFloat(seg.bx), y: r.minY + CGFloat(seg.by))
            var loop = Path()
            loop.addArc(center: CGPoint(x: b.x, y: b.y + rowH * 0.02), radius: rowH * 0.24, startAngle: .degrees(-20), endAngle: .degrees(200), clockwise: false)
            let tone = threadColor(thread, needle: seg.needle)
            strokeThread(&ctx, loop, weight * 0.95, tone, dim)
        }
        for seg in segs where seg.link == .aroundBoard {
            let b = CGPoint(x: r.minX + CGFloat(seg.bx), y: r.minY + CGFloat(seg.by))
            var p = Path()
            p.move(to: CGPoint(x: b.x - rowH * 0.16, y: b.y - rowH * 0.45)); p.addLine(to: CGPoint(x: b.x - rowH * 0.16, y: b.y + rowH * 0.45))
            p.move(to: CGPoint(x: b.x + rowH * 0.16, y: b.y - rowH * 0.45)); p.addLine(to: CGPoint(x: b.x + rowH * 0.16, y: b.y + rowH * 0.45))
            strokeThread(&ctx, p, weight * 0.9, threadColor(thread, needle: 0), dim)
        }
        for n in frame.nodes {
            let q = frame.point(n)
            let isExpected = highlight && expected != nil && expected!.row == n.row && expected!.station == n.station
            let isTorn = torn && tears.contains(n.station) && n.row == (expected?.row ?? -1) - 1
            ctx.fill(Path(ellipseIn: CGRect(x: q.x - weight * 0.8, y: q.y - weight * 0.8, width: weight * 1.6, height: weight * 1.6)), with: .color(Quire.ink.opacity(0.85 * dim)))
            if isExpected {
                ctx.stroke(Path(ellipseIn: CGRect(x: q.x - weight * 2.4, y: q.y - weight * 2.4, width: weight * 4.8, height: weight * 4.8)), with: .color(Quire.thread.opacity(0.9)), lineWidth: 1.6)
            }
            if isTorn {
                var tear = Path()
                tear.move(to: CGPoint(x: q.x - 3, y: q.y + 3)); tear.addLine(to: CGPoint(x: q.x + 6, y: q.y - 9))
                tear.move(to: CGPoint(x: q.x - 1, y: q.y + 4)); tear.addLine(to: CGPoint(x: q.x + 9, y: q.y - 5))
                ctx.stroke(tear, with: .color(Quire.ink.opacity(0.7)), lineWidth: 1.2)
            }
        }
    }

    static func strokeThread(_ ctx: inout GraphicsContext, _ p: Path, _ weight: CGFloat, _ tone: Color, _ dim: Double) {
        ctx.stroke(p, with: .color(Color.black.opacity(0.22 * dim)), style: StrokeStyle(lineWidth: weight * 1.3, lineCap: .round, lineJoin: .round))
        ctx.stroke(p, with: .color(tone.opacity(dim)), style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
        var lit = ctx
        lit.translateBy(x: -weight * 0.18, y: -weight * 0.22)
        lit.stroke(p, with: .color(Color.white.opacity(0.35 * dim)), style: StrokeStyle(lineWidth: weight * 0.35, lineCap: .round, lineJoin: .round))
    }

    static func drawStab(_ ctx: inout GraphicsContext, frame: StitchFrame, thread: ThreadKind, done: Int, expected: StitchStep?, highlight: Bool, coverTone: Color, dim: Double = 1.0) {
        let r = frame.rect
        let s = frame.structure
        let stack = Path(CGRect(x: r.minX - 18, y: r.minY + 4, width: 18, height: r.height))
        ctx.fill(stack, with: .color(Quire.paste.opacity(dim)))
        var leaves = Path()
        var x = r.minX - 17
        while x < r.minX { leaves.move(to: CGPoint(x: x, y: r.minY + 4)); leaves.addLine(to: CGPoint(x: x, y: r.maxY + 4)); x += 1.6 }
        ctx.stroke(leaves, with: .color(Quire.ink.opacity(0.2 * dim)), lineWidth: 0.5)
        ctx.fill(Path(r), with: .color(coverTone.opacity(dim)))
        ctx.stroke(Path(r), with: .color(Quire.ink.opacity(0.6 * dim)), lineWidth: 1)
        let holes = StitchGrammar.holes(s)
        func at(_ h: StabHole) -> CGPoint { CGPoint(x: r.minX + CGFloat(h.x / 40.0) * r.width * 0.9, y: r.minY + CGFloat(h.y) * r.height) }
        let steps = StitchGrammar.path(s, signatures: 1, stations: holes.count)
        let tone = Color.tint(Materials.thread(thread).tone)
        var last: CGPoint? = nil
        var lastFront = true
        let weight: CGFloat = 4
        for (i, step) in steps.enumerated() where i < done {
            let q = at(holes[step.station])
            if step.link.isWrap {
                var arc = Path()
                switch step.link {
                case .aroundSpine:
                    arc.move(to: q); arc.addCurve(to: q, control1: CGPoint(x: r.minX - 34, y: q.y - 10), control2: CGPoint(x: r.minX - 34, y: q.y + 12))
                case .aroundHead:
                    arc.move(to: q); arc.addCurve(to: q, control1: CGPoint(x: q.x - 12, y: r.minY - 34), control2: CGPoint(x: q.x + 12, y: r.minY - 34))
                default:
                    arc.move(to: q); arc.addCurve(to: q, control1: CGPoint(x: q.x - 12, y: r.maxY + 34), control2: CGPoint(x: q.x + 12, y: r.maxY + 34))
                }
                strokeThread(&ctx, arc, weight, tone, dim)
                continue
            }
            if let l = last {
                var p = Path()
                p.move(to: l); p.addLine(to: q)
                if lastFront { strokeThread(&ctx, p, weight, tone, dim) }
                else { ctx.stroke(p, with: .color(tone.opacity(0.5 * dim)), style: StrokeStyle(lineWidth: weight * 0.6, lineCap: .round, dash: [6, 5])) }
            }
            last = q
            lastFront = step.outward
        }
        for (i, hole) in holes.enumerated() {
            let q = at(hole)
            let rad: CGFloat = hole.main ? 4.5 : 3.5
            ctx.fill(Path(ellipseIn: CGRect(x: q.x - rad, y: q.y - rad, width: rad * 2, height: rad * 2)), with: .color(Quire.ink.opacity(0.9 * dim)))
            if highlight, let e = expected, e.station == i {
                ctx.stroke(Path(ellipseIn: CGRect(x: q.x - 12, y: q.y - 12, width: 24, height: 24)), with: .color(Quire.thread.opacity(0.9)), lineWidth: 1.6)
                if e.link.isWrap {
                    var hint = Path()
                    switch e.link {
                    case .aroundSpine: hint.move(to: q); hint.addLine(to: CGPoint(x: r.minX - 30, y: q.y))
                    case .aroundHead: hint.move(to: q); hint.addLine(to: CGPoint(x: q.x, y: r.minY - 30))
                    default: hint.move(to: q); hint.addLine(to: CGPoint(x: q.x, y: r.maxY + 30))
                    }
                    ctx.stroke(hint, with: .color(Quire.thread.opacity(0.5)), style: StrokeStyle(lineWidth: 1.2, dash: [4, 4]))
                }
            }
        }
    }

    static func stabPoint(_ frame: StitchFrame, _ index: Int) -> CGPoint {
        let holes = StitchGrammar.holes(frame.structure)
        guard index < holes.count else { return CGPoint(x: frame.rect.midX, y: frame.rect.midY) }
        let h = holes[index]
        return CGPoint(x: frame.rect.minX + CGFloat(h.x / 40.0) * frame.rect.width * 0.9, y: frame.rect.minY + CGFloat(h.y) * frame.rect.height)
    }

    static func nearestStab(_ frame: StitchFrame, _ p: CGPoint, within radius: CGFloat) -> Int? {
        var best: Int? = nil
        var bestD = radius
        for i in 0..<StitchGrammar.holes(frame.structure).count {
            let q = stabPoint(frame, i)
            let d = hypot(q.x - p.x, q.y - p.y)
            if d < bestD { bestD = d; best = i }
        }
        return best
    }

    static func drawNeedle(_ ctx: inout GraphicsContext, at p: CGPoint, angle: CGFloat, length: CGFloat) {
        let dx = cos(angle), dy = sin(angle)
        let eye = CGPoint(x: p.x - dx * length, y: p.y - dy * length)
        var shadow = Path()
        shadow.move(to: CGPoint(x: eye.x + 2, y: eye.y + 3)); shadow.addLine(to: CGPoint(x: p.x + 2, y: p.y + 3))
        ctx.stroke(shadow, with: .color(Color.black.opacity(0.25)), style: StrokeStyle(lineWidth: 5, lineCap: .round))
        var body = Path()
        body.move(to: eye); body.addLine(to: p)
        ctx.stroke(body, with: .color(Quire.steel), style: StrokeStyle(lineWidth: 4.2, lineCap: .round))
        var lit = Path()
        lit.move(to: CGPoint(x: eye.x - dy * 1.2, y: eye.y + dx * 1.2)); lit.addLine(to: CGPoint(x: p.x - dy * 1.2, y: p.y + dx * 1.2))
        ctx.stroke(lit, with: .color(Color.white.opacity(0.85)), style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        let eyeC = CGPoint(x: eye.x + dx * 8, y: eye.y + dy * 8)
        ctx.fill(Path(ellipseIn: CGRect(x: eyeC.x - 1.6, y: eyeC.y - 1.6, width: 3.2, height: 3.2)), with: .color(Quire.ink))
    }

    static func drawLiveThread(_ ctx: inout GraphicsContext, from a: CGPoint, to b: CGPoint, tone: Color) {
        var p = Path()
        p.move(to: a)
        let mid = CGPoint(x: (a.x + b.x) / 2 + (b.y - a.y) * 0.15, y: (a.y + b.y) / 2 - abs(b.x - a.x) * 0.12 - 10)
        p.addQuadCurve(to: b, control: mid)
        strokeThread(&ctx, p, 3.6, tone, 1.0)
    }
}

struct StitchDiagramView: View {
    var structure: Structure
    var signatures: Int
    var stations: Int
    var thread: ThreadKind = .linen25
    var done: Int? = nil
    var coverTone: Color = Quire.indigo

    var body: some View {
        Canvas { ctx, size in
            let frame = StitchFrame.make(in: size, structure: structure, signatures: signatures, stations: stations)
            let steps = StitchGrammar.path(structure, signatures: signatures, stations: stations).count
            if structure.family == .stab {
                StitchPainter.drawStab(&ctx, frame: frame, thread: thread, done: done ?? steps, expected: nil, highlight: false, coverTone: coverTone)
            } else if structure == .accordion {
                AccordionPainter.draw(&ctx, size: size, panels: stations, results: nil, progress: nil)
            } else {
                StitchPainter.drawSpine(&ctx, frame: frame, thread: thread, done: done ?? steps, expected: nil, tears: [], torn: false, tapes: true, highlight: false)
            }
        }
    }
}

enum AccordionPainter {
    static func draw(_ ctx: inout GraphicsContext, size: CGSize, panels: Int, results: [Bool]?, progress: Int?) {
        let inset: CGFloat = 24
        let w = size.width - inset * 2
        let pw = w / CGFloat(panels)
        let h = min(size.height * 0.5, pw * 2.2)
        let top = (size.height - h) / 2
        for k in 0..<panels {
            let mountain = k % 2 == 0
            let x = inset + pw * CGFloat(k)
            let lift: CGFloat = mountain ? 0 : 12
            var quad = Path()
            quad.move(to: CGPoint(x: x, y: top + lift + 4))
            quad.addLine(to: CGPoint(x: x + pw, y: top + (mountain ? 12 : 0) + 4))
            quad.addLine(to: CGPoint(x: x + pw + 6, y: top + h + (mountain ? 12 : 0)))
            quad.addLine(to: CGPoint(x: x + 6, y: top + h + lift))
            quad.closeSubpath()
            let folded = (progress ?? panels) > k - 1
            ctx.fill(quad, with: .color(folded ? (mountain ? Quire.card : Quire.paste) : Quire.card.opacity(0.6)))
            ctx.stroke(quad, with: .color(Quire.ink.opacity(0.7)), lineWidth: 1)
            if k < panels - 1 {
                let fx = x + pw + 3, fy = top + (mountain ? 12 : 0) - 10
                let done = (results?.count ?? panels) > k
                let ok = results == nil ? true : results![k]
                let label = mountain ? "M" : "V"
                if done {
                    ctx.draw(Text(label).font(Quire.title(13)).foregroundColor(ok ? (mountain ? Quire.thread : Quire.indigo) : Quire.warn), at: CGPoint(x: fx, y: fy))
                } else if progress == k {
                    ctx.stroke(Path(ellipseIn: CGRect(x: fx - 9, y: fy - 9, width: 18, height: 18)), with: .color(Quire.thread), lineWidth: 1.5)
                }
            }
        }
    }
}
