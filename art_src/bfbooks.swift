import Foundation
import CoreGraphics

struct BookPose {
    var ox: Double
    var oy: Double
    var eH: (Double, Double)
    var eW: (Double, Double)
    var eT: (Double, Double)
    var width: Double
    var height: Double
    var thick: Double

    func at(_ h: Double, _ w: Double, _ t: Double) -> CGPoint {
        pt(ox + eH.0 * h + eW.0 * w + eT.0 * t, oy + eH.1 * h + eW.1 * w + eT.1 * t)
    }

    var topFace: [CGPoint] { [at(0, 0, 0), at(height, 0, 0), at(height, width, 0), at(0, width, 0)] }
    var spineFace: [CGPoint] { [at(0, 0, 0), at(height, 0, 0), at(height, 0, thick), at(0, 0, thick)] }
    var tailFace: [CGPoint] { [at(0, 0, 0), at(0, width, 0), at(0, width, thick), at(0, 0, thick)] }

    static func lying(cx: Double, cy: Double, scale: Double, width: Double, height: Double, thick: Double, tilt: Double = -0.06) -> BookPose {
        let eH = (cos(tilt) * scale, sin(tilt) * scale)
        let eW = (0.52 * scale, -0.66 * scale)
        let eT = (0.0, 1.0 * scale)
        let ox = cx - (eH.0 * height + eW.0 * width) / 2
        let oy = cy - (eH.1 * height + eW.1 * width + eT.1 * thick) / 2
        return BookPose(ox: ox, oy: oy, eH: eH, eW: eW, eT: eT, width: width, height: height, thick: thick)
    }
}

enum CoverKind { case cloth, leather, paper, vellum, wood, bare }

struct BookLook {
    var cover: Hue
    var kind: CoverKind
    var look: SpineLook
    var structure: Structure?
    var signatures: Int = 8
    var stations: Int = 4
    var boardMM: Double = 0.06
    var title: String = ""
    var gilt: Bool = false
}

func coverMaterial(_ p: Leaf, _ clip: CGPath, _ look: BookLook, light: Double, rng: inout Chip) {
    let box = clip.boundingBox
    p.fillPath(clip, look.cover)
    let lx = Double(box.midX) + cos(light) * Double(box.width) * 0.6
    let ly = Double(box.midY) + sin(light) * Double(box.height) * 0.6
    switch look.kind {
    case .cloth:
        radialInto(p, clip, from: pt(lx, ly), inner: look.cover.lt(0.22), outer: look.cover.dk(0.30), radius: Double(max(box.width, box.height)) * 1.3)
        clothWeave(p, clip, base: look.cover, pitch: 3.4, rng: &rng, sheen: 0.2)
    case .leather:
        radialInto(p, clip, from: pt(lx, ly), inner: look.cover.lt(0.30), outer: look.cover.dk(0.42), radius: Double(max(box.width, box.height)) * 1.2)
        leatherGrain(p, clip, base: look.cover, pebble: 2.6, count: Int(Double(box.width * box.height) / 55), rng: &rng)
    case .paper:
        radialInto(p, clip, from: pt(lx, ly), inner: look.cover.lt(0.10), outer: look.cover.dk(0.18), radius: Double(max(box.width, box.height)) * 1.4)
        paperFibres(p, clip, base: look.cover, laid: true, count: Int(Double(box.width * box.height) / 900), rng: &rng)
    case .vellum:
        radialInto(p, clip, from: pt(lx, ly), inner: look.cover.lt(0.18), outer: look.cover.dk(0.22), radius: Double(max(box.width, box.height)) * 1.3)
        p.inside(clip) {
            for _ in 0..<40 {
                let x = Double(box.minX) + rng.d() * Double(box.width)
                let y = Double(box.minY) + rng.d() * Double(box.height)
                p.egg(x, y, rng.r(8, 40), rng.r(4, 18), (rng.chance(0.5) ? look.cover.dk(0.2) : look.cover.lt(0.3)).al(0.10))
            }
            var veins: [CGPoint] = []
            for _ in 0..<60 {
                let x = Double(box.minX) + rng.d() * Double(box.width)
                let y = Double(box.minY) + rng.d() * Double(box.height)
                let a = rng.r(0, 6.283)
                veins.append(pt(x, y)); veins.append(pt(x + cos(a) * rng.r(10, 40), y + sin(a) * rng.r(4, 14)))
            }
            batchSegments(p, veins, colour: look.cover.dk(0.35).al(0.12), width: 1.0)
        }
    case .wood:
        woodGrain(p, clip, axis: 0.1, base: look.cover, lines: 60, wave: 6, rng: &rng)
    case .bare:
        paperFibres(p, clip, base: look.cover, laid: false, count: Int(Double(box.width * box.height) / 1200), rng: &rng)
    }
}

func pageEdges(_ p: Leaf, _ pose: BookPose, board: Double, rng: inout Chip, along: Bool = true) {
    let face = pose.tailFace
    let path = pathOf(face)
    p.fillPath(path, Pot.paper.dk(0.06))
    p.inside(path) {
        var lines: [CGPoint] = []
        var t = board
        while t < pose.thick - board {
            let a = pose.at(0, 0, t), b = pose.at(0, pose.width, t)
            lines.append(a); lines.append(b)
            t += rng.r(0.9, 1.4)
        }
        batchSegments(p, lines, colour: Pot.ink.al(0.16), width: 0.6)
        linearInto(p, path, from: pose.at(0, 0, 0), to: pose.at(0, pose.width, 0),
                   colours: [Hue(r: 0, g: 0, b: 0, a: 0.30), Hue(r: 0, g: 0, b: 0, a: 0.06)], locations: [0, 1])
    }
}

func boardEdges(_ p: Leaf, _ pose: BookPose, board: Double, cover: Hue) {
    for t in [0.0, pose.thick - board] {
        let quad = [pose.at(0, 0, t), pose.at(0, pose.width, t), pose.at(0, pose.width, t + board), pose.at(0, 0, t + board)]
        p.shape(quad, cover.dk(0.35))
    }
}

func spineSurface(_ p: Leaf, _ pose: BookPose, _ look: BookLook, light: Double, rng: inout Chip) {
    let face = pose.spineFace
    let path = pathOf(face)
    switch look.look {
    case .exposedChain, .exposedLong:
        p.fillPath(path, Pot.paper.dk(0.10))
        p.inside(path) {
            var lines: [CGPoint] = []
            let rows = max(3, look.signatures)
            for r in 0...rows {
                let t = pose.thick * Double(r) / Double(rows)
                lines.append(pose.at(0, 0, t)); lines.append(pose.at(pose.height, 0, t))
            }
            batchSegments(p, lines, colour: Pot.ink.al(0.30), width: 1.0)
            linearInto(p, path, from: pose.at(0, 0, 0), to: pose.at(0, 0, pose.thick),
                       colours: [Hue(r: 0, g: 0, b: 0, a: 0.05), Hue(r: 0, g: 0, b: 0, a: 0.30)], locations: [0, 1])
        }
        let underSpine = [pose.at(0, 0, pose.thick * 0.55), pose.at(pose.height, 0, pose.thick * 0.55), pose.at(pose.height, 0, pose.thick), pose.at(0, 0, pose.thick)]
        rules(p, pathOf(underSpine), angle: light + .pi / 2, spacing: 6, weight: 0.9, colour: Pot.inkSoft.al(0.35), coverage: 0.6, seed: rng.next())
        if let s = look.structure {
            drawSpineStitches(p, pose, s, signatures: look.signatures, stations: look.stations, rng: &rng)
        }
    case .stab, .pouch, .concertina, .butterfly, .whirlwind, .perfect:
        p.fillPath(path, look.look == .perfect ? look.cover : Pot.paper.dk(0.08))
        p.inside(path) {
            if look.look == .perfect {
                let cx = pose.height * rng.r(0.4, 0.6)
                var crack: [CGPoint] = []
                var t = 0.0
                while t <= pose.thick { crack.append(pose.at(cx + rng.r(-3, 3), 0, t)); t += pose.thick / 8 }
                pen(p, crack, weight: 2.2, colour: Pot.ink.al(0.8), wobble: 0.6, taper: false, seed: rng.next())
                pen(p, shifted(crack, 1.5, 0), weight: 1.0, colour: Pot.paper.al(0.7), wobble: 0.5, taper: false, seed: rng.next())
            } else {
                var lines: [CGPoint] = []
                var t = 1.0
                while t < pose.thick {
                    lines.append(pose.at(0, 0, t)); lines.append(pose.at(pose.height, 0, t))
                    t += rng.r(1.0, 1.6)
                }
                batchSegments(p, lines, colour: Pot.ink.al(0.16), width: 0.6)
            }
            linearInto(p, path, from: pose.at(0, 0, 0), to: pose.at(0, 0, pose.thick),
                       colours: [Hue(r: 0, g: 0, b: 0, a: 0.04), Hue(r: 0, g: 0, b: 0, a: 0.28)], locations: [0, 1])
        }
    default:
        coverMaterial(p, path, look, light: light, rng: &rng)
        linearInto(p, path, from: pose.at(0, 0, 0), to: pose.at(0, 0, pose.thick),
                   colours: [Hue(r: 1, g: 1, b: 1, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.34)], locations: [0, 0.4, 1])
        if look.look == .cords || look.look == .tightBack || look.look == .clasped || look.look == .chained || look.look == .girdle {
            let bands = look.look == .cords ? 4 : 5
            for k in 0..<bands {
                let h = pose.height * (0.14 + 0.72 * Double(k) / Double(bands - 1))
                let a = pose.at(h, 0, 0), b = pose.at(h, 0, pose.thick)
                pen(p, [pt(Double(a.x) + 2.5, Double(a.y)), pt(Double(b.x) + 2.5, Double(b.y))], weight: 5.0, colour: look.cover.dk(0.5).al(0.7), wobble: 0.2, taper: false, seed: rng.next())
                pen(p, [a, b], weight: 4.4, colour: look.cover.lt(0.28), wobble: 0.2, taper: false, seed: rng.next())
                if look.gilt {
                    for d in [-5.0, 5.0] {
                        pen(p, [pose.at(h + d, 0, 1.5), pose.at(h + d, 0, pose.thick - 1.5)], weight: 1.1, colour: Pot.brassPale.al(0.85), wobble: 0.1, taper: true, seed: rng.next())
                    }
                }
            }
        }
        if look.look == .hollowBack || look.look == .groove || look.look == .tapes || look.look == .springback {
            if look.gilt {
                for f in [0.10, 0.90] {
                    pen(p, [pose.at(pose.height * f, 0, 1.5), pose.at(pose.height * f, 0, pose.thick - 1.5)], weight: 1.2, colour: Pot.brassPale.al(0.8), wobble: 0.1, taper: true, seed: rng.next())
                }
            } else if look.look == .tapes {
                let lx = pose.height * 0.60, w = pose.height * 0.22
                let label = [pose.at(lx, 0, pose.thick * 0.18), pose.at(lx + w, 0, pose.thick * 0.18), pose.at(lx + w, 0, pose.thick * 0.82), pose.at(lx, 0, pose.thick * 0.82)]
                p.shape(label, Pot.paper)
                penEdge(p, label, weight: 0.8, colour: Pot.ink.al(0.6), seed: rng.next())
            }
        }
        if look.look == .springback {
            let a = pose.at(0, 0, pose.thick * 0.5), b = pose.at(pose.height, 0, pose.thick * 0.5)
            pen(p, [a, b], weight: 3, colour: look.cover.lt(0.3).al(0.5), wobble: 0.2, taper: false, seed: rng.next())
        }
    }
}

func drawSpineStitches(_ p: Leaf, _ pose: BookPose, _ s: Structure, signatures: Int, stations: Int, rng: inout Chip) {
    let rows = StitchDiagram.rowsCount(s, signatures: signatures)
    let segs = StitchDiagram.segments(s, signatures: signatures, stations: stations, width: pose.height, height: pose.thick)
    let nodes = StitchDiagram.nodes(s, signatures: signatures, stations: stations, width: pose.height, height: pose.thick)
    let threadTone = s.family == .stab ? Pot.threadRed : Pot.linen
    let rowH = pose.thick / Double(max(1, rows))
    let thick = max(2.2, min(4.5, rowH * 0.34))
    for n in nodes {
        let q = pose.at(n.x, 0, n.y)
        p.dot(Double(q.x), Double(q.y), thick * 0.7, Pot.ink.al(0.55))
    }
    if s.family == .supported {
        let positions = Stations.tapePositions(tapes: s.tapes(stations), height: pose.height, tapeWidth: pose.height * 0.09)
        for t in 0..<s.tapes(stations) {
            let tape = [pose.at(positions[1 + t * 2], 0, -6), pose.at(positions[2 + t * 2], 0, -6), pose.at(positions[2 + t * 2], 0, pose.thick + 6), pose.at(positions[1 + t * 2], 0, pose.thick + 6)]
            p.shape(shifted(tape, 2, 2), Hue(r: 0, g: 0, b: 0, a: 0.2))
            p.shape(tape, Pot.linenPale)
            penEdge(p, tape, weight: 0.8, colour: Pot.ink.al(0.6), seed: rng.next())
        }
    }
    for seg in segs where seg.wrap == 0 && seg.outside {
        let a = pose.at(seg.ax, 0, seg.ay), b = pose.at(seg.bx, 0, seg.by)
        if seg.link == .frenchLink {
            let mid = pt((Double(a.x) + Double(b.x)) / 2, (Double(a.y) + Double(b.y)) / 2 + rowH * 0.7)
            pen(p, [a, mid, b], weight: thick * 0.9, colour: threadTone.dk(0.1), wobble: 0.2, taper: false, seed: rng.next())
        }
        pen(p, [pt(Double(a.x) + 1, Double(a.y) + 1.4), pt(Double(b.x) + 1, Double(b.y) + 1.4)], weight: thick * 1.2, colour: Hue(r: 0, g: 0, b: 0, a: 0.35), wobble: 0.2, taper: false, seed: rng.next())
        pen(p, [a, b], weight: thick, colour: threadTone.dk(0.12), wobble: 0.25, taper: false, seed: rng.next())
        pen(p, [pt(Double(a.x) - 0.5, Double(a.y) - 0.7), pt(Double(b.x) - 0.5, Double(b.y) - 0.7)], weight: thick * 0.35, colour: threadTone.lt(0.5).al(0.85), wobble: 0.2, taper: false, seed: rng.next())
    }
    for seg in segs where seg.link == .chainUnder || seg.link == .kettle || seg.link == .throughBoard {
        let b = pose.at(seg.bx, 0, seg.by)
        let cx = Double(b.x), cy = Double(b.y)
        var loop: [CGPoint] = []
        var ang = -0.4
        while ang <= 3.6 { loop.append(pt(cx + cos(ang) * rowH * 0.30, cy + sin(ang) * rowH * 0.48)); ang += 0.25 }
        pen(p, shifted(loop, 1, 1.4), weight: thick * 1.1, colour: Hue(r: 0, g: 0, b: 0, a: 0.30), wobble: 0.2, taper: false, seed: rng.next())
        pen(p, loop, weight: thick, colour: threadTone.dk(0.05), wobble: 0.2, taper: false, seed: rng.next())
        pen(p, shifted(loop, -0.5, -0.7), weight: thick * 0.3, colour: threadTone.lt(0.5).al(0.8), wobble: 0.2, taper: false, seed: rng.next())
    }
}

func coverFrame(_ p: Leaf, _ pose: BookPose, _ look: BookLook, inset: Double, rng: inout Chip) {
    let frame = [pose.at(inset, inset, 0), pose.at(pose.height - inset, inset, 0), pose.at(pose.height - inset, pose.width - inset, 0), pose.at(inset, pose.width - inset, 0)]
    let tone = look.gilt ? Pot.brassPale.al(0.9) : look.cover.dk(0.45).al(0.75)
    for k in 0..<4 { pen(p, [frame[k], frame[(k + 1) % 4]], weight: 1.4, colour: tone, wobble: 0.2, taper: false, seed: rng.next()) }
}

func coverDecoration(_ p: Leaf, _ pose: BookPose, _ look: BookLook, rng: inout Chip) {
    let inset = pose.width * 0.08
    switch look.look {
    case .clasped, .cords, .tightBack:
        coverFrame(p, pose, look, inset: inset, rng: &rng)
        if look.look == .clasped {
            for (h, w) in [(pose.height * 0.22, pose.width * 0.22), (pose.height * 0.78, pose.width * 0.22), (pose.height * 0.22, pose.width * 0.78), (pose.height * 0.78, pose.width * 0.78), (pose.height * 0.5, pose.width * 0.5)] {
                let c = pose.at(h, w, 0)
                p.dot(Double(c.x) + 1.5, Double(c.y) + 2, 5.5, Hue(r: 0, g: 0, b: 0, a: 0.4))
                p.dot(Double(c.x), Double(c.y), 5.5, Pot.brass)
                p.dot(Double(c.x) - 1.6, Double(c.y) - 1.8, 2.2, Pot.brassPale)
            }
            for h in [pose.height * 0.30, pose.height * 0.70] {
                let a = pose.at(h, pose.width * 0.78, 0), b = pose.at(h, pose.width, 0)
                pen(p, [a, b], weight: 6, colour: look.cover.dk(0.5), wobble: 0.1, taper: false, seed: rng.next())
                pen(p, [a, b], weight: 3.4, colour: Pot.brass, wobble: 0.1, taper: false, seed: rng.next())
            }
        }
    case .flap:
        let flap = [pose.at(0, pose.width, 0), pose.at(pose.height, pose.width, 0), pose.at(pose.height, pose.width * 0.62, 0), pose.at(pose.height * 0.5, pose.width * 0.42, 0), pose.at(0, pose.width * 0.62, 0)]
        castShadow(p, flap, dx: 2, dy: 5, steps: 4, alpha: 0.10)
        var flapLook = look
        flapLook.cover = look.cover.dk(0.06)
        coverMaterial(p, pathOf(flap), flapLook, light: p.light, rng: &rng)
        penEdge(p, flap, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
        let medal = ringOf(cx: Double(pose.at(pose.height * 0.5, pose.width * 0.30, 0).x), cy: Double(pose.at(pose.height * 0.5, pose.width * 0.30, 0).y), rx: pose.width * 0.11, ry: pose.width * 0.075, steps: 40)
        for k in 0..<medal.count { pen(p, [medal[k], medal[(k + 1) % medal.count]], weight: 1.2, colour: Pot.brassPale.al(0.9), wobble: 0.1, taper: false, seed: rng.next()) }
    case .chained:
        coverFrame(p, pose, look, inset: inset, rng: &rng)
        let start = pose.at(pose.height * 0.5, pose.width, 0)
        var chain: [CGPoint] = []
        for k in 0...14 {
            let f = Double(k) / 14
            chain.append(pt(Double(start.x) + f * 150 + sin(f * 6) * 6, Double(start.y) - f * 40 + f * f * 60))
        }
        for k in 0..<chain.count - 1 {
            let a = chain[k], b = chain[k + 1]
            let cx = (Double(a.x) + Double(b.x)) / 2, cy = (Double(a.y) + Double(b.y)) / 2
            p.egg(cx, cy, 6, 3.6, Hue(r: 0, g: 0, b: 0, a: 0.3))
            p.hoop(cx, cy, 5, 2.0, k % 2 == 0 ? Pot.steel : Pot.steel.dk(0.3))
        }
    case .girdle:
        coverFrame(p, pose, look, inset: inset, rng: &rng)
        let tail = pose.at(0, pose.width * 0.5, pose.thick * 0.5)
        var skin: [CGPoint] = [pose.at(0, 0, 0), pose.at(0, pose.width, 0)]
        skin.append(pt(Double(tail.x) - 90, Double(tail.y) + 40))
        skin.append(pt(Double(tail.x) - 150, Double(tail.y) + 20))
        skin.append(pt(Double(tail.x) - 160, Double(tail.y) + 46))
        skin.append(pt(Double(tail.x) - 95, Double(tail.y) + 70))
        skin.append(pose.at(0, pose.width, pose.thick))
        skin.append(pose.at(0, 0, pose.thick))
        var skinLook = look
        skinLook.cover = look.cover.dk(0.08)
        coverMaterial(p, pathOf(skin), skinLook, light: p.light, rng: &rng)
        penEdge(p, skin, weight: 1.4, colour: Pot.ink.al(0.8), seed: rng.next())
        let knot = ringOf(cx: Double(tail.x) - 165, cy: Double(tail.y) + 36, rx: 18, ry: 14, steps: 24)
        coverMaterial(p, pathOf(knot), skinLook, light: p.light, rng: &rng)
        penEdge(p, knot, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
    case .stab, .pouch:
        let holes = StitchGrammar.holes(look.structure ?? .yotsume)
        let stationsAlong = holes.map { pose.at(pose.height * $0.y, pose.width * $0.x / 60.0, 0) }
        var last: CGPoint? = nil
        for (i, q) in stationsAlong.enumerated() {
            p.dot(Double(q.x), Double(q.y), 2.2, Pot.ink.al(0.8))
            if let l = last, holes[i].main {
                pen(p, [l, q], weight: 2.4, colour: Pot.threadRed, wobble: 0.2, taper: false, seed: rng.next())
            }
            let edge = pose.at(pose.height * holes[i].y, 0, 0)
            let under = pose.at(pose.height * holes[i].y, 0, pose.thick)
            pen(p, [q, edge, under], weight: 2.2, colour: Pot.threadRed.dk(0.1), wobble: 0.2, taper: false, seed: rng.next())
            if holes[i].main { last = q }
        }
        if let first = stationsAlong.first, let lastMain = stationsAlong.prefix(4).last {
            pen(p, [first, pose.at(0, pose.width * holes[0].x / 60.0, 0)], weight: 2.2, colour: Pot.threadRed, wobble: 0.2, taper: false, seed: rng.next())
            pen(p, [lastMain, pose.at(pose.height, pose.width * holes[3].x / 60.0, 0)], weight: 2.2, colour: Pot.threadRed, wobble: 0.2, taper: false, seed: rng.next())
        }
    case .hollowBack, .tapes, .groove, .springback:
        if look.gilt && look.kind == .cloth {
            coverFrame(p, pose, look, inset: inset, rng: &rng)
            let c = pose.at(pose.height * 0.5, pose.width * 0.5, 0)
            let orn = ringOf(cx: Double(c.x), cy: Double(c.y), rx: pose.width * 0.16, ry: pose.width * 0.10, steps: 4)
            for k in 0..<4 { pen(p, [orn[k], orn[(k + 1) % 4]], weight: 1.6, colour: Pot.brassPale.al(0.9), wobble: 0.2, taper: false, seed: rng.next()) }
            for k in 0..<4 { pen(p, [pose.at(pose.height * 0.5, pose.width * 0.5, 0), orn[k]], weight: 1.0, colour: Pot.brassPale.al(0.7), wobble: 0.2, taper: true, seed: rng.next()) }
        }
        if look.look == .groove {
            let g = [pose.at(0, pose.width * 0.055, 0), pose.at(pose.height, pose.width * 0.055, 0), pose.at(pose.height, pose.width * 0.085, 0), pose.at(0, pose.width * 0.085, 0)]
            p.shape(g, look.cover.dk(0.55))
            pen(p, [g[0], g[1]], weight: 1.2, colour: Pot.ink.al(0.6), wobble: 0.2, taper: false, seed: rng.next())
            pen(p, [g[3], g[2]], weight: 1.0, colour: look.cover.lt(0.3).al(0.6), wobble: 0.2, taper: false, seed: rng.next())
        }
    case .limp:
        for h in [pose.height * 0.3, pose.height * 0.7] {
            let a = pose.at(h, pose.width, 0)
            var tie: [CGPoint] = [a]
            for k in 1...6 { tie.append(pt(Double(a.x) + Double(k) * 9 + sin(Double(k)) * 4, Double(a.y) - Double(k) * 3 + Double(k * k))) }
            pen(p, tie, weight: 2.6, colour: Pot.linen.dk(0.2), wobble: 0.3, taper: true, seed: rng.next())
        }
    default:
        break
    }
    if !look.title.isEmpty {
        let c = pose.at(pose.height * 0.5, pose.width * 0.5, 0)
        let ang = atan2(pose.eH.1, pose.eH.0)
        letter(p, look.title, at: Double(c.x), Double(c.y), size: pose.width * 0.11, colour: look.gilt ? Pot.brassPale : look.cover.dk(0.5), face: "Cochin-Bold", align: .centre, rotate: ang)
    }
}

func paintBook(_ p: Leaf, _ pose: BookPose, _ look: BookLook, rng: inout Chip, shadow: Bool = true) {
    let light = p.light
    let board = pose.thick * look.boardMM
    if shadow {
        let ground = [pose.at(0, 0, pose.thick), pose.at(pose.height, 0, pose.thick), pose.at(pose.height, pose.width, pose.thick), pose.at(0, pose.width, pose.thick)]
        castShadow(p, ground, dx: 14, dy: 10, steps: 9, alpha: 0.05)
        p.shape(shifted(ground, 3, 3), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.30))
    }
    pageEdges(p, pose, board: board, rng: &rng)
    if look.look != .exposedChain && look.look != .exposedLong && look.look != .stab && look.look != .pouch && look.kind != .bare {
        boardEdges(p, pose, board: board, cover: look.cover)
    }
    spineSurface(p, pose, look, light: light, rng: &rng)
    let top = pathOf(pose.topFace)
    if look.kind == .bare {
        p.fillPath(top, Pot.paper.dk(0.04))
        paperFibres(p, top, base: Pot.paper, laid: true, count: 300, rng: &rng)
    } else {
        coverMaterial(p, top, look, light: light, rng: &rng)
        linearInto(p, top, from: pose.at(0, 0, 0), to: pose.at(0, pose.width, 0),
                   colours: [Hue(r: 1, g: 1, b: 1, a: 0.06), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.14)], locations: [0, 0.5, 1])
    }
    coverDecoration(p, pose, look, rng: &rng)
    rimLight(p, pose.topFace, light: light, weight: 3.2, colour: Hue(r: 1, g: 0.97, b: 0.88, a: 0.55), dark: nil, seed: rng.next())
    penEdge(p, pose.topFace, weight: 1.5, colour: Pot.ink.al(0.85), seed: rng.next())
    penEdge(p, pose.spineFace, weight: 1.3, colour: Pot.ink.al(0.75), seed: rng.next())
    penEdge(p, pose.tailFace, weight: 1.2, colour: Pot.ink.al(0.7), seed: rng.next())
    let tailShade = [pose.at(0, 0, pose.thick * 0.5), pose.at(0, pose.width, pose.thick * 0.5), pose.at(0, pose.width, pose.thick), pose.at(0, 0, pose.thick)]
    rules(p, pathOf(tailShade), angle: p.light + .pi / 2, spacing: 6.5, weight: 0.9, colour: Pot.inkSoft.al(0.4), coverage: 0.7, seed: rng.next())
    if look.look != .exposedChain && look.look != .exposedLong {
        let underSpine = [pose.at(0, 0, pose.thick * 0.55), pose.at(pose.height, 0, pose.thick * 0.55), pose.at(pose.height, 0, pose.thick), pose.at(0, 0, pose.thick)]
        rules(p, pathOf(underSpine), angle: light + .pi / 2, spacing: 6, weight: 0.9, colour: Pot.inkSoft.al(0.45), coverage: 0.7, seed: rng.next())
    }
}

func benchGround(_ p: Leaf, seed: UInt64, wallTone: Hue = Pot.paperWarm, benchTone: Hue = Pot.walnut, horizon: Double = 0.42) {
    plateGround(p, seed: seed, tone: wallTone, border: false)
    var rng = Chip(seed &+ 77)
    let hy = p.h * horizon
    linearFree(p, pt(0, 0), pt(0, hy), [Pot.linenPale.al(0.28), Pot.linenPale.al(0.0)], [0, 1])
    let shelfEdge = [pt(-10, hy - 14), pt(p.w + 10, hy - 10), pt(p.w + 10, hy + 4), pt(-10, hy + 8)]
    let benchPath = pathOf([pt(-10, hy + 4), pt(p.w + 10, hy), pt(p.w + 10, p.h + 10), pt(-10, p.h + 10)])
    p.fillPath(benchPath, benchTone)
    linearInto(p, benchPath, from: pt(0, hy), to: pt(0, p.h), colours: [benchTone.lt(0.22), benchTone.lt(0.05), benchTone.dk(0.30)], locations: [0, 0.35, 1])
    woodGrain(p, benchPath, axis: 0.015, base: benchTone, lines: 70, wave: 6, rng: &rng)
    p.shape(shelfEdge, benchTone.lt(0.30))
    woodGrain(p, pathOf(shelfEdge), axis: 0.01, base: benchTone.lt(0.3), lines: 8, wave: 1.5, rng: &rng)
    pen(p, [pt(0, hy - 13), pt(p.w, hy - 9)], weight: 1.6, colour: Pot.ink.al(0.7), wobble: 0.6, taper: false, seed: rng.next())
    pen(p, [pt(0, hy + 7), pt(p.w, hy + 3)], weight: 2.0, colour: Pot.ink.al(0.75), wobble: 0.6, taper: false, seed: rng.next())
    linearFree(p, pt(0, hy + 4), pt(0, hy + 60), [Hue(r: 0, g: 0, b: 0, a: 0.18), Hue(r: 0, g: 0, b: 0, a: 0)], [0, 1])
    rules(p, pathOf([pt(0, hy + 6), pt(p.w, hy + 2), pt(p.w, hy + 40), pt(0, hy + 44)]), angle: 0.02, spacing: 5, weight: 0.8, colour: Pot.inkSoft.al(0.35), coverage: 0.6, seed: rng.next())
    borderRule(p, inset: 30, seed: seed &+ 3)
}

func plateFrameInset(_ p: Leaf) -> Double { 30 }

struct StandPose {
    var x: Double
    var y: Double
    var height: Double
    var thick: Double
    var depth: Double
    var lean: Double

    func spine(_ h: Double, _ t: Double) -> CGPoint { pt(x + t + h * lean, y - h) }
    func head(_ t: Double, _ w: Double) -> CGPoint { pt(x + t + height * lean + w * 0.55, y - height - w * 0.36) }
    func board(_ h: Double, _ w: Double) -> CGPoint { pt(x + thick + h * lean + w * 0.55, y - h - w * 0.36) }

    var spineFace: [CGPoint] { [spine(0, 0), spine(height, 0), spine(height, thick), spine(0, thick)] }
    var headFace: [CGPoint] { [head(0, 0), head(thick, 0), head(thick, depth), head(0, depth)] }
    var boardFace: [CGPoint] { [board(0, 0), board(height, 0), board(height, depth), board(0, depth)] }
}

func paintStandingBook(_ p: Leaf, _ pose: StandPose, _ look: BookLook, rng: inout Chip, bands: Int = 5, label: String = "") {
    let light = p.light
    let ground = [pose.spine(0, 0), pose.spine(0, pose.thick), pose.board(0, pose.depth), pt(Double(pose.spine(0, 0).x) + pose.depth * 0.55, Double(pose.spine(0, 0).y) - pose.depth * 0.36)]
    castShadow(p, ground, dx: 18, dy: 8, steps: 9, alpha: 0.05)
    p.shape(shifted(ground, 3, 2), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.3))
    let boardPath = pathOf(pose.boardFace)
    coverMaterial(p, boardPath, look, light: light, rng: &rng)
    linearInto(p, boardPath, from: pose.board(0, 0), to: pose.board(0, pose.depth), colours: [Hue(r: 0, g: 0, b: 0, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.34)], locations: [0, 1])
    let headPath = pathOf(pose.headFace)
    p.fillPath(headPath, Pot.paper.dk(0.05))
    p.inside(headPath) {
        var lines: [CGPoint] = []
        var t = 2.0
        while t < pose.thick - 2 { lines.append(pose.head(t, 0)); lines.append(pose.head(t, pose.depth)); t += 1.3 }
        batchSegments(p, lines, colour: Pot.ink.al(0.18), width: 0.6)
        linearInto(p, headPath, from: pose.head(0, 0), to: pose.head(0, pose.depth), colours: [Hue(r: 1, g: 1, b: 1, a: 0.2), Hue(r: 0, g: 0, b: 0, a: 0.14)], locations: [0, 1])
    }
    let boardT = pose.thick * 0.07
    for t in [0.0, pose.thick - boardT] {
        p.shape([pose.head(t, 0), pose.head(t + boardT, 0), pose.head(t + boardT, pose.depth), pose.head(t, pose.depth)], look.cover.dk(0.25))
    }
    let spinePath = pathOf(pose.spineFace)
    coverMaterial(p, spinePath, look, light: light, rng: &rng)
    linearInto(p, spinePath, from: pose.spine(0, 0), to: pose.spine(0, pose.thick), colours: [Hue(r: 1, g: 1, b: 1, a: 0.18), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.30)], locations: [0, 0.45, 1])
    if bands > 0 {
        for k in 0..<bands {
            let h = pose.height * (0.12 + 0.76 * Double(k) / Double(max(1, bands - 1)))
            let a = pose.spine(h, 0), b = pose.spine(h, pose.thick)
            pen(p, [pt(Double(a.x), Double(a.y) + 3), pt(Double(b.x), Double(b.y) + 3)], weight: 6, colour: look.cover.dk(0.5).al(0.7), wobble: 0.2, taper: false, seed: rng.next())
            pen(p, [a, b], weight: 5, colour: look.cover.lt(0.3), wobble: 0.2, taper: false, seed: rng.next())
            if look.gilt {
                pen(p, [pose.spine(h - 7, 2), pose.spine(h - 7, pose.thick - 2)], weight: 1.2, colour: Pot.brassPale.al(0.9), wobble: 0.1, taper: true, seed: rng.next())
                pen(p, [pose.spine(h + 7, 2), pose.spine(h + 7, pose.thick - 2)], weight: 1.2, colour: Pot.brassPale.al(0.9), wobble: 0.1, taper: true, seed: rng.next())
            }
        }
    }
    if !label.isEmpty {
        let ly0 = pose.height * 0.62, ly1 = pose.height * 0.80
        let lab = [pose.spine(ly0, 3), pose.spine(ly0, pose.thick - 3), pose.spine(ly1, pose.thick - 3), pose.spine(ly1, 3)]
        p.shape(lab, look.gilt ? look.cover.dk(0.45) : Pot.paper)
        penEdge(p, lab, weight: 0.8, colour: Pot.ink.al(0.6), seed: rng.next())
        let c = pose.spine((ly0 + ly1) / 2, pose.thick / 2)
        letter(p, label, at: Double(c.x), Double(c.y) + 5, size: min(pose.thick * 0.5, 18), colour: look.gilt ? Pot.brassPale : Pot.ink, face: "Cochin-Bold", rotate: -.pi / 2)
    }
    rimLight(p, pose.spineFace, light: light, weight: 3.0, colour: Hue(r: 1, g: 0.96, b: 0.86, a: 0.6), dark: nil, seed: rng.next())
    penEdge(p, pose.spineFace, weight: 1.4, colour: Pot.ink.al(0.85), seed: rng.next())
    penEdge(p, pose.headFace, weight: 1.2, colour: Pot.ink.al(0.75), seed: rng.next())
    penEdge(p, pose.boardFace, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
    rules(p, pathOf([pose.board(0, pose.depth * 0.5), pose.board(pose.height, pose.depth * 0.5), pose.board(pose.height, pose.depth), pose.board(0, pose.depth)]), angle: light + .pi / 2, spacing: 6, weight: 0.9, colour: Pot.inkSoft.al(0.4), coverage: 0.6, seed: rng.next())
}
