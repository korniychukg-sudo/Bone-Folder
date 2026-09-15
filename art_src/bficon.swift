import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

private let keyLight = -2.30

private struct Oblique {
    var ox: Double
    var oy: Double
    var dx: Double = 0.55
    var dy: Double = -0.32

    func at(_ x: Double, _ d: Double, _ y: Double) -> CGPoint { pt(ox + x + d * dx, oy - y + d * dy) }

    func front(x0: Double, x1: Double, d: Double, y0: Double, y1: Double) -> [CGPoint] {
        [at(x0, d, y0), at(x1, d, y0), at(x1, d, y1), at(x0, d, y1)]
    }

    func top(x0: Double, x1: Double, d0: Double, d1: Double, y: Double) -> [CGPoint] {
        [at(x0, d0, y), at(x1, d0, y), at(x1, d1, y), at(x0, d1, y)]
    }

    func side(x: Double, d0: Double, d1: Double, y0: Double, y1: Double) -> [CGPoint] {
        [at(x, d0, y0), at(x, d1, y0), at(x, d1, y1), at(x, d0, y1)]
    }
}

private func iconBackground(_ p: Leaf, rng: inout Chip) {
    p.fillAll(Hue(r: 0.050, g: 0.036, b: 0.028))
    p.flipDown()
    radialFree(p, 240, 140, 0, 1200, [Hue(r: 0.27, g: 0.19, b: 0.13), Hue(r: 0.11, g: 0.075, b: 0.055), Hue(r: 0.032, g: 0.022, b: 0.018)], [0, 0.5, 1], extend: true)
    for _ in 0..<7000 {
        let x = rng.d() * 1024, y = rng.d() * 640
        let far = max(0.0, 1.0 - y / 640.0)
        let len = rng.r(4, 12) * (1 + far)
        let tone = rng.chance(0.5) ? Hue(r: 0.60, g: 0.46, b: 0.32) : Hue(r: 0.02, g: 0.015, b: 0.01)
        p.ctx.setStrokeColor(cg(tone.al(rng.r(0.025, 0.08))))
        p.ctx.setLineWidth(CGFloat(rng.r(0.8, 1.8)))
        p.ctx.beginPath()
        p.ctx.move(to: pt(x, y))
        p.ctx.addLine(to: pt(x + len, y + rng.r(-1, 1)))
        p.ctx.strokePath()
    }
    radialFree(p, 190, 250, 0, 360, [Hue(r: 0.70, g: 0.56, b: 0.38, a: 0.20), Hue(r: 0.70, g: 0.56, b: 0.38, a: 0)], [0, 1])
    linearFree(p, pt(0, 0), pt(0, 560), [Hue(r: 0, g: 0, b: 0, a: 0.48), Hue(r: 0, g: 0, b: 0, a: 0.0)], [0, 1])
    let benchY = 660.0
    let benchPath = pathOf([pt(-10, benchY), pt(1034, benchY - 30), pt(1034, 1034), pt(-10, 1034)])
    p.fillPath(benchPath, Pot.walnut.dk(0.30))
    linearInto(p, benchPath, from: pt(0, benchY), to: pt(0, 1024), colours: [Pot.walnut.lt(0.06), Pot.walnut.dk(0.18), Pot.walnut.dk(0.50)], locations: [0, 0.4, 1])
    woodGrain(p, benchPath, axis: -0.028, base: Pot.walnut.dk(0.2), lines: 110, wave: 7, rng: &rng)
    pen(p, [pt(0, benchY), pt(1024, benchY - 30)], weight: 2.2, colour: Hue(r: 0, g: 0, b: 0, a: 0.6), wobble: 0.6, taper: false, seed: rng.next())
    pen(p, [pt(0, benchY - 3), pt(1024, benchY - 33)], weight: 1.6, colour: Hue(r: 1, g: 0.9, b: 0.75, a: 0.26), wobble: 0.5, taper: false, seed: rng.next())
    radialFree(p, 1070, 1050, 0, 820, [Hue(r: 1.0, g: 0.72, b: 0.44, a: 0.15), Hue(r: 1.0, g: 0.72, b: 0.44, a: 0)], [0, 1])
}

private func walnutFace(_ p: Leaf, _ poly: [CGPoint], base: Hue, axis: Double, level: Double, rng: inout Chip, lines: Int = 40, wave: Double = 4) {
    let path = pathOf(poly)
    p.fillPath(path, lit(base, level))
    woodGrain(p, path, axis: axis, base: lit(base, level), lines: lines, wave: wave, rng: &rng)
    let box = path.boundingBox
    p.inside(path) {
        var flecks: [CGPoint] = []
        for _ in 0..<Int(Double(box.width * box.height) / 700) {
            let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
            let l = rng.r(2, 8)
            flecks.append(pt(x, y)); flecks.append(pt(x + cos(axis) * l, y + sin(axis) * l))
        }
        batchSegments(p, flecks, colour: Hue(r: 0.9, g: 0.75, b: 0.55, a: 0.07), width: 0.8)
    }
}

private func walnutBlock(_ p: Leaf, _ o: Oblique, x0: Double, x1: Double, d0: Double, d1: Double, y0: Double, y1: Double, rng: inout Chip, chamfer: Double = 0, rim: Bool = true) {
    let front = o.front(x0: x0, x1: x1, d: d0, y0: y0, y1: y1)
    let top = o.top(x0: x0, x1: x1, d0: d0, d1: d1, y: y1)
    let side = o.side(x: x1, d0: d0, d1: d1, y0: y0, y1: y1)
    walnutFace(p, side, base: Pot.walnutLight, axis: atan2(o.dy, o.dx), level: 0.30, rng: &rng, lines: 22, wave: 3)
    linearInto(p, pathOf(side), from: o.at(x1, d0, y0), to: o.at(x1, d1, y0), colours: [Hue(r: 0, g: 0, b: 0, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.42)], locations: [0, 1])
    walnutFace(p, front, base: Pot.walnutLight, axis: 0.0, level: 0.50, rng: &rng, lines: 34, wave: 4)
    linearInto(p, pathOf(front), from: o.at(x0, d0, y1), to: o.at(x0, d0, y0), colours: [Hue(r: 1, g: 0.95, b: 0.85, a: 0.12), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.30)], locations: [0, 0.35, 1])
    linearInto(p, pathOf(front), from: o.at(x0, d0, y0), to: o.at(x1, d0, y0), colours: [Hue(r: 1, g: 0.95, b: 0.85, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.26)], locations: [0, 0.45, 1])
    walnutFace(p, top, base: Pot.walnutLight, axis: 0.0, level: 0.78, rng: &rng, lines: 30, wave: 4)
    linearInto(p, pathOf(top), from: o.at(x0, d0, y1), to: o.at(x1, d1, y1), colours: [Hue(r: 1, g: 0.96, b: 0.86, a: 0.22), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.22)], locations: [0, 0.5, 1])
    if chamfer > 0 {
        let bevel = [o.at(x0, d0, y1), o.at(x1, d0, y1), o.at(x1, d0 + chamfer * 1.4, y1 + 0.0), o.at(x0, d0 + chamfer * 1.4, y1)]
        p.shape(bevel, Hue(r: 1, g: 0.94, b: 0.80, a: 0.22))
        let bevelFront = [o.at(x0, d0, y1 - chamfer), o.at(x1, d0, y1 - chamfer), o.at(x1, d0, y1), o.at(x0, d0, y1)]
        p.shape(bevelFront, Hue(r: 1, g: 0.94, b: 0.80, a: 0.16))
        pen(p, [o.at(x0, d0, y1 - chamfer), o.at(x1, d0, y1 - chamfer)], weight: 1.2, colour: Hue(r: 0, g: 0, b: 0, a: 0.35), wobble: 0.2, taper: false, seed: rng.next())
    }
    if rim {
        rimLight(p, top, light: keyLight, weight: 5.0, colour: Hue(r: 1, g: 0.95, b: 0.82, a: 0.85), dark: nil, step: 3, seed: rng.next())
        rimLight(p, front, light: keyLight, weight: 3.0, colour: Hue(r: 1, g: 0.95, b: 0.82, a: 0.55), dark: Hue(r: 0, g: 0, b: 0, a: 0.5), step: 3, seed: rng.next())
    }
    penEdge(p, top, weight: 1.4, colour: Hue(r: 0.06, g: 0.04, b: 0.02, a: 0.85), seed: rng.next())
    penEdge(p, front, weight: 1.4, colour: Hue(r: 0.06, g: 0.04, b: 0.02, a: 0.85), seed: rng.next())
    penEdge(p, side, weight: 1.2, colour: Hue(r: 0.06, g: 0.04, b: 0.02, a: 0.8), seed: rng.next())
}

private func brassCylinder(_ p: Leaf, _ o: Oblique, cx: Double, cd: Double, y0: Double, y1: Double, radius: Double, threads: Bool, rng: inout Chip) {
    let a = o.at(cx, cd, y0), b = o.at(cx, cd, y1)
    let base = Pot.brass
    let bands = 18
    for k in 0..<bands {
        let f0 = -1.0 + 2.0 * Double(k) / Double(bands), f1 = -1.0 + 2.0 * Double(k + 1) / Double(bands)
        let u = (f0 + f1) / 2
        let shade = 0.12 + 0.88 * pow(max(0, 1 - abs(u + 0.35) / 1.1), 1.3)
        let quad = [pt(Double(a.x) + f0 * radius, Double(a.y)), pt(Double(a.x) + f1 * radius + 0.6, Double(a.y)), pt(Double(b.x) + f1 * radius + 0.6, Double(b.y)), pt(Double(b.x) + f0 * radius, Double(b.y))]
        p.shape(quad, lit(base, max(0.06, min(0.98, shade))))
    }
    let poly = [pt(Double(a.x) - radius, Double(a.y)), pt(Double(a.x) + radius, Double(a.y)), pt(Double(b.x) + radius, Double(b.y)), pt(Double(b.x) - radius, Double(b.y))]
    let path = pathOf(poly)
    streaks(p, path, count: Int((y1 - y0) * 9), angle: .pi / 2, lenMin: 6, lenMax: 26, light: Hue(r: 1, g: 0.97, b: 0.85), dark: Hue(r: 0.25, g: 0.14, b: 0.02), alphaMin: 0.04, alphaMax: 0.14, weightMax: 1.2, rng: &rng)
    if threads {
        p.inside(path) {
            var t: [CGPoint] = []
            var y = Double(b.y) + 6
            while y < Double(a.y) - 4 {
                t.append(pt(Double(a.x) - radius, y)); t.append(pt(Double(a.x) + radius, y + radius * 0.34))
                y += 9
            }
            batchSegments(p, t, colour: Hue(r: 0.18, g: 0.10, b: 0.02, a: 0.6), width: 1.6)
            var lightT: [CGPoint] = []
            y = Double(b.y) + 4
            while y < Double(a.y) - 4 {
                lightT.append(pt(Double(a.x) - radius, y)); lightT.append(pt(Double(a.x) + radius, y + radius * 0.34))
                y += 9
            }
            batchSegments(p, lightT, colour: Hue(r: 1, g: 0.96, b: 0.80, a: 0.35), width: 0.8)
        }
    }
    pen(p, [pt(Double(a.x) - radius * 0.42, Double(a.y)), pt(Double(b.x) - radius * 0.42, Double(b.y))], weight: radius * 0.22, colour: Hue(r: 1, g: 0.98, b: 0.88, a: 0.9), wobble: 0.2, taper: true, seed: rng.next())
    pen(p, [pt(Double(a.x) - radius * 0.94, Double(a.y)), pt(Double(b.x) - radius * 0.94, Double(b.y))], weight: 1.4, colour: Hue(r: 0.15, g: 0.08, b: 0.01, a: 0.8), wobble: 0.1, taper: false, seed: rng.next())
    pen(p, [pt(Double(a.x) + radius * 0.96, Double(a.y)), pt(Double(b.x) + radius * 0.96, Double(b.y))], weight: 1.6, colour: Hue(r: 0.10, g: 0.05, b: 0.0, a: 0.85), wobble: 0.1, taper: false, seed: rng.next())
}

private func brassBar(_ p: Leaf, from a: CGPoint, to b: CGPoint, radius: Double, rng: inout Chip) {
    let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
    let len = max(1e-6, (dx * dx + dy * dy).squareRoot())
    let ux = dx / len, uy = dy / len
    let nx = -uy, ny = ux
    pen(p, [pt(Double(a.x) + 8, Double(a.y) + 12), pt(Double(b.x) + 8, Double(b.y) + 12)], weight: radius * 2.2, colour: Hue(r: 0, g: 0, b: 0, a: 0.30), wobble: 0.1, taper: false, seed: rng.next())
    let bands = 14
    for k in 0..<bands {
        let f0 = -1.0 + 2.0 * Double(k) / Double(bands), f1 = -1.0 + 2.0 * Double(k + 1) / Double(bands)
        let u = (f0 + f1) / 2
        let facing = nx * cos(keyLight) + ny * sin(keyLight)
        let shade = 0.15 + 0.85 * pow(max(0, 1 - abs(u - facing * 0.55) / 1.15), 1.4)
        let quad = [pt(Double(a.x) + nx * f0 * radius, Double(a.y) + ny * f0 * radius), pt(Double(b.x) + nx * f0 * radius, Double(b.y) + ny * f0 * radius),
                    pt(Double(b.x) + nx * f1 * radius + ux * 0.4, Double(b.y) + ny * f1 * radius + uy * 0.4), pt(Double(a.x) + nx * f1 * radius, Double(a.y) + ny * f1 * radius)]
        p.shape(quad, lit(Pot.brass, max(0.06, min(0.98, shade))))
    }
    let poly = [pt(Double(a.x) + nx * -radius, Double(a.y) + ny * -radius), pt(Double(b.x) + nx * -radius, Double(b.y) + ny * -radius), pt(Double(b.x) + nx * radius, Double(b.y) + ny * radius), pt(Double(a.x) + nx * radius, Double(a.y) + ny * radius)]
    streaks(p, pathOf(poly), count: Int(len * 6), angle: atan2(uy, ux), lenMin: 6, lenMax: 24, light: Hue(r: 1, g: 0.97, b: 0.85), dark: Hue(r: 0.25, g: 0.14, b: 0.02), alphaMin: 0.04, alphaMax: 0.14, weightMax: 1.2, rng: &rng)
    let hl = radius * 0.45
    pen(p, [pt(Double(a.x) + nx * -hl, Double(a.y) + ny * -hl), pt(Double(b.x) + nx * -hl, Double(b.y) + ny * -hl)], weight: radius * 0.28, colour: Hue(r: 1, g: 0.98, b: 0.90, a: 0.9), wobble: 0.15, taper: true, seed: rng.next())
    penEdge(p, poly, weight: 1.3, colour: Hue(r: 0.10, g: 0.05, b: 0.0, a: 0.8), seed: rng.next())
    for c in [a, b] {
        let cap = ringOf(cx: Double(c.x), cy: Double(c.y), rx: radius * 1.35, ry: radius * 1.35, steps: 30)
        p.shape(cap, Pot.brass)
        radialInto(p, pathOf(cap), from: pt(Double(c.x) - radius * 0.5, Double(c.y) - radius * 0.6), inner: Pot.brassPale.lt(0.4), outer: Pot.brass.dk(0.55), radius: radius * 2)
        penEdge(p, cap, weight: 1.2, colour: Hue(r: 0.10, g: 0.05, b: 0.0, a: 0.8), seed: rng.next())
    }
}

private func casedBook(_ p: Leaf, _ o: Oblique, x0: Double, x1: Double, d0: Double, d1: Double, y0: Double, y1: Double, coverDepth: Double, rng: inout Chip) {
    let cloth = Pot.indigo
    let board = 9.0
    let spine = o.front(x0: x0, x1: x1, d: d0, y0: y0, y1: y1)
    let spinePath = pathOf(spine)
    p.fillPath(spinePath, cloth)
    clothWeave(p, spinePath, base: cloth, pitch: 3.2, rng: &rng, sheen: 0.35)
    linearInto(p, spinePath, from: o.at(x0, d0, y1), to: o.at(x0, d0, y0), colours: [Hue(r: 1, g: 1, b: 1, a: 0.16), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.34)], locations: [0, 0.4, 1])
    linearInto(p, spinePath, from: o.at(x0, d0, y0), to: o.at(x1, d0, y0), colours: [Hue(r: 1, g: 1, b: 1, a: 0.12), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.30)], locations: [0, 0.45, 1])
    for f in [0.10, 0.90] {
        pen(p, [o.at(x0 + (x1 - x0) * f, d0, y0 + 6), o.at(x0 + (x1 - x0) * f, d0, y1 - 6)], weight: 1.2, colour: Pot.brassPale.al(0.7), wobble: 0.1, taper: true, seed: rng.next())
    }
    let lx0 = x0 + (x1 - x0) * 0.34, lx1 = x0 + (x1 - x0) * 0.70
    let label = o.front(x0: lx0, x1: lx1, d: d0, y0: y0 + (y1 - y0) * 0.22, y1: y1 - (y1 - y0) * 0.22)
    p.shape(shifted(label, 2, 3), Hue(r: 0, g: 0, b: 0, a: 0.35))
    let labelPath = pathOf(label)
    p.fillPath(labelPath, Pot.paper.lt(0.15))
    paperFibres(p, labelPath, base: Pot.paper, laid: true, count: 60, rng: &rng)
    let inner = o.front(x0: lx0 + 10, x1: lx1 - 10, d: d0, y0: y0 + (y1 - y0) * 0.22 + 8, y1: y1 - (y1 - y0) * 0.22 - 8)
    penEdge(p, inner, weight: 1.1, colour: Pot.ink.al(0.7), seed: rng.next())
    let inner2 = o.front(x0: lx0 + 15, x1: lx1 - 15, d: d0, y0: y0 + (y1 - y0) * 0.22 + 13, y1: y1 - (y1 - y0) * 0.22 - 13)
    penEdge(p, inner2, weight: 0.7, colour: Pot.ink.al(0.5), seed: rng.next())
    penEdge(p, label, weight: 0.9, colour: Pot.ink.al(0.6), seed: rng.next())
    let fore = o.side(x: x1, d0: d0, d1: d1, y0: y0 + board, y1: y1 - board)
    let forePath = pathOf(fore)
    p.fillPath(forePath, Pot.paper.dk(0.03))
    p.inside(forePath) {
        var lines: [CGPoint] = []
        var y = y0 + board + 1.2
        while y < y1 - board { lines.append(o.at(x1, d0, y)); lines.append(o.at(x1, d1, y)); y += 1.5 }
        batchSegments(p, lines, colour: Hue(r: 0.25, g: 0.2, b: 0.14, a: 0.30), width: 0.7)
        linearInto(p, forePath, from: o.at(x1, d0, y0), to: o.at(x1, d1, y0), colours: [Hue(r: 0, g: 0, b: 0, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.45)], locations: [0, 1])
    }
    for (ya, yb) in [(y0, y0 + board), (y1 - board, y1)] {
        let edge = o.side(x: x1, d0: d0, d1: d1, y0: ya, y1: yb)
        p.shape(edge, cloth.dk(0.35))
        clothWeave(p, pathOf(edge), base: cloth.dk(0.35), pitch: 3.0, rng: &rng)
    }
    let cover = o.top(x0: x0, x1: x1, d0: d0, d1: d0 + coverDepth, y: y1)
    let coverPath = pathOf(cover)
    p.fillPath(coverPath, cloth.lt(0.06))
    clothWeave(p, coverPath, base: cloth.lt(0.06), pitch: 3.2, rng: &rng, sheen: 0.5)
    linearInto(p, coverPath, from: o.at(x0, d0, y1), to: o.at(x1, d0 + coverDepth, y1), colours: [Hue(r: 1, g: 1, b: 1, a: 0.26), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.28)], locations: [0, 0.5, 1])
    let groove = o.top(x0: x0, x1: x1, d0: d0 + coverDepth * 0.14, d1: d0 + coverDepth * 0.22, y: y1)
    p.shape(groove, Hue(r: 0, g: 0, b: 0, a: 0.30))
    rimLight(p, cover, light: keyLight, weight: 4.0, colour: Hue(r: 0.85, g: 0.90, b: 1.0, a: 0.75), dark: nil, step: 3, seed: rng.next())
    rimLight(p, spine, light: keyLight, weight: 3.0, colour: Hue(r: 0.85, g: 0.90, b: 1.0, a: 0.55), dark: Hue(r: 0, g: 0, b: 0, a: 0.4), step: 3, seed: rng.next())
    penEdge(p, spine, weight: 1.3, colour: Hue(r: 0.03, g: 0.03, b: 0.06, a: 0.85), seed: rng.next())
    penEdge(p, cover, weight: 1.2, colour: Hue(r: 0.03, g: 0.03, b: 0.06, a: 0.8), seed: rng.next())
    penEdge(p, fore, weight: 1.1, colour: Hue(r: 0.03, g: 0.03, b: 0.06, a: 0.7), seed: rng.next())
}

private func iconBoneFolder(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let nx = -dy, ny = dx
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for k in 0...30 {
        let t = Double(k) / 30
        let x = Double(c.x) + dx * (t - 0.5) * length
        let y = Double(c.y) + dy * (t - 0.5) * length
        let w = length * 0.070 * (t < 0.12 ? (0.30 + t / 0.12 * 0.70) : (t > 0.70 ? max(0.05, 1 - pow((t - 0.70) / 0.30, 1.2)) : 1.0))
        left.append(pt(x + nx * w, y + ny * w)); right.append(pt(x - nx * w, y - ny * w))
    }
    let poly = left + right.reversed()
    castShadow(p, poly, dx: 16, dy: 14, steps: 9, alpha: 0.07)
    p.shape(shifted(poly, 4, 5), Hue(r: 0, g: 0, b: 0, a: 0.42))
    let path = pathOf(poly)
    let ivory = Hue(r: 0.93, g: 0.89, b: 0.79)
    p.fillPath(path, ivory)
    linearInto(p, path, from: pt(Double(c.x) + nx * length * 0.07, Double(c.y) + ny * length * 0.07), to: pt(Double(c.x) - nx * length * 0.07, Double(c.y) - ny * length * 0.07),
               colours: [ivory.dk(0.40), ivory.dk(0.05), ivory.lt(0.55), ivory.lt(0.15), ivory.dk(0.12)], locations: [0, 0.28, 0.5, 0.72, 1])
    let box = path.boundingBox
    p.inside(path) {
        var veins: [CGPoint] = []
        for _ in 0..<Int(Double(box.width * box.height) / 170) {
            let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
            let l = rng.r(4, 18)
            veins.append(pt(x, y)); veins.append(pt(x + dx * l, y + dy * l))
        }
        batchSegments(p, veins, colour: Pot.boneDeep.al(0.26), width: 0.9)
        for _ in 0..<50 {
            let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
            p.egg(x, y, rng.r(6, 22), rng.r(2, 5), (rng.chance(0.5) ? Pot.boneDeep : Hue(r: 1, g: 0.98, b: 0.92)).al(0.12))
        }
        linearInto(p, path, from: pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5), to: pt(Double(c.x) + dx * length * 0.5, Double(c.y) + dy * length * 0.5),
                   colours: [Hue(r: 1, g: 0.96, b: 0.85, a: 0.0), Hue(r: 1, g: 0.96, b: 0.85, a: 0.22), Hue(r: 0.9, g: 0.7, b: 0.45, a: 0.10)], locations: [0, 0.5, 1])
    }
    rimLight(p, poly, light: keyLight, weight: 4.2, colour: Hue(r: 1, g: 1, b: 0.96, a: 0.92), dark: Pot.boneDeep.dk(0.45).al(0.6), step: 3, seed: rng.next())
    penEdge(p, poly, weight: 1.4, colour: Hue(r: 0.08, g: 0.05, b: 0.03, a: 0.85), seed: rng.next())
}

func drawIcon(_ dir: String, _ scratch: String) {
    let previous = sheetScale
    sheetScale = 1.0
    let p = Leaf(1024, 1024)
    var rng = Chip(hashOf("bone-folder-icon-nipping-press"))
    iconBackground(p, rng: &rng)
    p.light = keyLight
    let o = Oblique(ox: 40, oy: 1050)
    let baseGround = [o.at(-20, -40, 0), o.at(1060, -40, 0), o.at(1060, 420, 0), o.at(-20, 420, 0)]
    castShadow(p, baseGround, dx: 30, dy: 26, steps: 12, alpha: 0.06)
    walnutBlock(p, o, x0: 0, x1: 1060, d0: 0, d1: 400, y0: 0, y1: 96, rng: &rng, chamfer: 14)
    walnutBlock(p, o, x0: 60, x1: 160, d0: 150, d1: 250, y0: 96, y1: 560, rng: &rng, chamfer: 0)
    let bookShadow = [o.at(260, 30, 96), o.at(940, 30, 96), o.at(940, 400, 96), o.at(260, 400, 96)]
    castShadow(p, bookShadow, dx: 26, dy: 18, steps: 8, alpha: 0.06)
    casedBook(p, o, x0: 280, x1: 870, d0: 40, d1: 390, y0: 96, y1: 232, coverDepth: 150, rng: &rng)
    let platenShadow = [o.at(240, 180, 232), o.at(910, 180, 232), o.at(910, 400, 232), o.at(240, 400, 232)]
    p.shape(platenShadow, Hue(r: 0, g: 0, b: 0, a: 0.30))
    walnutBlock(p, o, x0: 240, x1: 910, d0: 190, d1: 400, y0: 232, y1: 292, rng: &rng, chamfer: 8)
    walnutBlock(p, o, x0: 950, x1: 1060, d0: 150, d1: 250, y0: 96, y1: 560, rng: &rng, chamfer: 0)
    brassCylinder(p, o, cx: 560, cd: 250, y0: 292, y1: 560, radius: 30, threads: true, rng: &rng)
    let foot = ringOf(cx: Double(o.at(560, 250, 292).x), cy: Double(o.at(560, 250, 292).y), rx: 46, ry: 18, steps: 36)
    p.shape(foot, Pot.brass.dk(0.2))
    radialInto(p, pathOf(foot), from: pt(Double(o.at(560, 250, 292).x) - 14, Double(o.at(560, 250, 292).y) - 8), inner: Pot.brassPale, outer: Pot.brass.dk(0.55), radius: 52)
    penEdge(p, foot, weight: 1.2, colour: Hue(r: 0.10, g: 0.05, b: 0.0, a: 0.8), seed: rng.next())
    walnutBlock(p, o, x0: 10, x1: 1080, d0: 130, d1: 270, y0: 560, y1: 660, rng: &rng, chamfer: 10)
    let nutC = o.at(560, 200, 660)
    let nut = ringOf(cx: Double(nutC.x), cy: Double(nutC.y), rx: 66, ry: 26, steps: 40)
    p.shape(nut, Pot.brass.dk(0.15))
    radialInto(p, pathOf(nut), from: pt(Double(nutC.x) - 20, Double(nutC.y) - 10), inner: Pot.brassPale, outer: Pot.brass.dk(0.55), radius: 74)
    penEdge(p, nut, weight: 1.2, colour: Hue(r: 0.10, g: 0.05, b: 0.0, a: 0.8), seed: rng.next())
    brassCylinder(p, o, cx: 560, cd: 200, y0: 660, y1: 1080, radius: 30, threads: true, rng: &rng)
    let hub = o.at(560, 200, 880)
    let armL = o.at(320, 200, 880), armR = o.at(800, 200, 880)
    let armF = o.at(560, -80, 880), armB = o.at(560, 480, 880)
    brassBar(p, from: armB, to: hub, radius: 15, rng: &rng)
    brassBar(p, from: armL, to: armR, radius: 16, rng: &rng)
    brassBar(p, from: hub, to: armF, radius: 16, rng: &rng)
    let hubRing = ringOf(cx: Double(hub.x), cy: Double(hub.y), rx: 32, ry: 32, steps: 36)
    p.shape(hubRing, Pot.brass)
    radialInto(p, pathOf(hubRing), from: pt(Double(hub.x) - 12, Double(hub.y) - 12), inner: Pot.brassPale.lt(0.5), outer: Pot.brass.dk(0.55), radius: 44)
    penEdge(p, hubRing, weight: 1.3, colour: Hue(r: 0.10, g: 0.05, b: 0.0, a: 0.85), seed: rng.next())
    iconBoneFolder(p, at: pt(230, 975), angle: -0.36, length: 520, rng: &rng)
    softGlowAt(p, cx: 1010, cy: 1020, radius: 780, colour: Hue(r: 1, g: 0.78, b: 0.50), strength: 0.15)
    softGlowAt(p, cx: 90, cy: 60, radius: 560, colour: Hue(r: 1, g: 0.95, b: 0.84), strength: 0.12)
    filmGrain(p, amplitude: 0.05, seed: rng.next())
    radialFree(p, 500, 470, 0, 860, [Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.46)], [0.55, 1], extend: true)
    p.writePNG(dir, "AppIcon-1024")
    if let img = p.image() {
        for size in [512, 120, 60] {
            let small = Leaf(size, size)
            small.flipDown()
            small.drawImage(img, into: CGRect(x: 0, y: 0, width: size, height: size))
            small.writePNG(scratch, "icon_\(size)")
        }
        let cropA = Leaf(400, 400)
        cropA.flipDown()
        cropA.drawImage(img, into: CGRect(x: -900, y: -60, width: 2048, height: 2048))
        cropA.writePNG(scratch, "icon_crop_screw")
        let cropB = Leaf(400, 400)
        cropB.flipDown()
        cropB.drawImage(img, into: CGRect(x: -900, y: -1400, width: 2048, height: 2048))
        cropB.writePNG(scratch, "icon_crop_book")
    }
    sheetScale = previous
}
