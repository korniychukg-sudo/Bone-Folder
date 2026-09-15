import Foundation
import CoreGraphics

func lit(_ base: Hue, _ t: Double) -> Hue { t < 0.5 ? base.dk((0.5 - t) * 1.2) : base.lt((t - 0.5) * 0.9) }

func rodShade(_ p: Leaf, _ a: CGPoint, _ b: CGPoint, w0: Double, w1: Double, base: Hue, light: Double, bands: Int = 9, rng: inout Chip) {
    let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
    let len = max(1e-6, (dx * dx + dy * dy).squareRoot())
    let nx = -dy / len, ny = dx / len
    let facing = cos(atan2(ny, nx) - light)
    for k in 0..<bands {
        let f0 = -0.5 + Double(k) / Double(bands), f1 = -0.5 + Double(k + 1) / Double(bands)
        let u = (f0 + f1) / 2
        let shade = 0.5 + 0.5 * cos(u * .pi) * (0.55 + 0.45 * facing) - (u * facing) * 0.6
        let quad = [pt(Double(a.x) + nx * w0 * f0, Double(a.y) + ny * w0 * f0), pt(Double(b.x) + nx * w1 * f0, Double(b.y) + ny * w1 * f0),
                    pt(Double(b.x) + nx * w1 * f1, Double(b.y) + ny * w1 * f1), pt(Double(a.x) + nx * w0 * f1, Double(a.y) + ny * w0 * f1)]
        p.shape(quad, lit(base, max(0.05, min(0.98, shade))))
    }
    let poly = [pt(Double(a.x) + nx * w0 * -0.5, Double(a.y) + ny * w0 * -0.5), pt(Double(b.x) + nx * w1 * -0.5, Double(b.y) + ny * w1 * -0.5),
                pt(Double(b.x) + nx * w1 * 0.5, Double(b.y) + ny * w1 * 0.5), pt(Double(a.x) + nx * w0 * 0.5, Double(a.y) + ny * w0 * 0.5)]
    penEdge(p, poly, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
}

func propShadow(_ p: Leaf, _ poly: [CGPoint], _ rng: inout Chip) {
    castShadow(p, poly, dx: 7, dy: 9, steps: 5, alpha: 0.06)
    p.shape(shifted(poly, 2, 3), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.22))
}

func drawBoneFolder(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let nx = -dy, ny = dx
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for k in 0...24 {
        let t = Double(k) / 24
        let x = Double(c.x) + dx * (t - 0.5) * length
        let y = Double(c.y) + dy * (t - 0.5) * length
        let w = length * 0.075 * (t < 0.15 ? (0.35 + t / 0.15 * 0.65) : (t > 0.72 ? max(0.06, 1 - (t - 0.72) / 0.28) : 1.0))
        left.append(pt(x + nx * w, y + ny * w)); right.append(pt(x - nx * w, y - ny * w))
    }
    let poly = left + right.reversed()
    propShadow(p, poly, &rng)
    let path = pathOf(poly)
    p.fillPath(path, Pot.bone)
    let box = path.boundingBox
    linearInto(p, path, from: pt(Double(c.x) + nx * length * 0.08, Double(c.y) + ny * length * 0.08), to: pt(Double(c.x) - nx * length * 0.08, Double(c.y) - ny * length * 0.08),
               colours: [Pot.bone.dk(0.32), Pot.bone.lt(0.25), Pot.bone.lt(0.5), Pot.bone.dk(0.05)], locations: [0, 0.35, 0.55, 1])
    p.inside(path) {
        var veins: [CGPoint] = []
        for _ in 0..<Int(Double(box.width * box.height) / 260) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let l = rng.r(4, 14)
            veins.append(pt(x, y)); veins.append(pt(x + dx * l, y + dy * l))
        }
        batchSegments(p, veins, colour: Pot.boneDeep.al(0.22), width: 0.8)
    }
    rimLight(p, poly, light: p.light, weight: 2.6, colour: Hue(r: 1, g: 1, b: 0.96, a: 0.85), dark: Pot.boneDeep.dk(0.3).al(0.5), seed: rng.next())
    penEdge(p, poly, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawAwl(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let handleEnd = pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5)
    let ferrule = pt(Double(c.x) + dx * length * 0.05, Double(c.y) + dy * length * 0.05)
    let tip = pt(Double(c.x) + dx * length * 0.5, Double(c.y) + dy * length * 0.5)
    let nx = -dy, ny = dx
    let w = length * 0.11
    var handle: [CGPoint] = []
    for k in 0...16 {
        let t = Double(k) / 16
        let bulge = w * (0.55 + 0.45 * sin(t * .pi) * (1.0 - t * 0.3))
        handle.append(pt(Double(handleEnd.x) + dx * t * length * 0.55 + nx * bulge, Double(handleEnd.y) + dy * t * length * 0.55 + ny * bulge))
    }
    for k in stride(from: 16, through: 0, by: -1) {
        let t = Double(k) / 16
        let bulge = w * (0.55 + 0.45 * sin(t * .pi) * (1.0 - t * 0.3))
        handle.append(pt(Double(handleEnd.x) + dx * t * length * 0.55 - nx * bulge, Double(handleEnd.y) + dy * t * length * 0.55 - ny * bulge))
    }
    propShadow(p, handle + [ferrule, tip], &rng)
    let hpath = pathOf(handle)
    p.fillPath(hpath, Pot.walnutLight)
    woodGrain(p, hpath, axis: angle, base: Pot.walnutLight, lines: 26, wave: 2, rng: &rng)
    linearInto(p, hpath, from: pt(Double(c.x) + nx * w, Double(c.y) + ny * w), to: pt(Double(c.x) - nx * w, Double(c.y) - ny * w),
               colours: [Hue(r: 0, g: 0, b: 0, a: 0.35), Hue(r: 1, g: 1, b: 1, a: 0.16), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.3)], locations: [0, 0.3, 0.55, 1])
    penEdge(p, handle, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
    rodShade(p, pt(Double(ferrule.x) - dx * length * 0.06, Double(ferrule.y) - dy * length * 0.06), ferrule, w0: w * 1.05, w1: w * 0.9, base: Pot.brass, light: p.light, rng: &rng)
    rodShade(p, ferrule, tip, w0: length * 0.03, w1: 0.6, base: Pot.steelLight, light: p.light, rng: &rng)
}

func drawNeedle(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip, thread: Hue? = nil) {
    let dx = cos(angle), dy = sin(angle)
    let eye = pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5)
    let tip = pt(Double(c.x) + dx * length * 0.5, Double(c.y) + dy * length * 0.5)
    pen(p, [pt(Double(eye.x) + 3, Double(eye.y) + 4), pt(Double(tip.x) + 3, Double(tip.y) + 4)], weight: length * 0.035, colour: Hue(r: 0, g: 0, b: 0, a: 0.25), wobble: 0.1, taper: false, seed: rng.next())
    rodShade(p, eye, tip, w0: length * 0.05, w1: 0.5, base: Pot.steelLight, light: p.light, bands: 7, rng: &rng)
    let eyeC = pt(Double(eye.x) + dx * length * 0.06, Double(eye.y) + dy * length * 0.06)
    pen(p, [pt(Double(eyeC.x) - dx * length * 0.03, Double(eyeC.y) - dy * length * 0.03), pt(Double(eyeC.x) + dx * length * 0.03, Double(eyeC.y) + dy * length * 0.03)], weight: length * 0.018, colour: Pot.ink.al(0.9), wobble: 0.1, taper: true, seed: rng.next())
    if let t = thread {
        let ex = Double(eyeC.x), ey = Double(eyeC.y)
        let nx = -dy, ny = dx
        let path = catmull([pt(ex, ey), pt(ex + nx * 30 - dx * 20, ey + ny * 30 - dy * 20), pt(ex + nx * 70 - dx * 60, ey + ny * 70 - dy * 60), pt(ex + nx * 60 - dx * 140, ey + ny * 60 - dy * 140)], steps: 10)
        pen(p, shifted(path, 2, 3), weight: 3.2, colour: Hue(r: 0, g: 0, b: 0, a: 0.25), wobble: 0.3, taper: false, seed: rng.next())
        pen(p, path, weight: 2.8, colour: t, wobble: 0.35, taper: false, seed: rng.next())
        pen(p, shifted(path, -0.6, -0.8), weight: 1.0, colour: t.lt(0.45).al(0.8), wobble: 0.3, taper: false, seed: rng.next())
    }
}

func drawSpool(_ p: Leaf, at c: CGPoint, radius: Double, thread: Hue, rng: inout Chip, height: Double? = nil) {
    let h = height ?? radius * 1.5
    let cx = Double(c.x), cy = Double(c.y)
    let ry = radius * 0.42
    let bottom = ringOf(cx: cx, cy: cy + h * 0.5, rx: radius, ry: ry, steps: 40)
    propShadow(p, bottom.map { pt(Double($0.x) * 1.0, Double($0.y)) }, &rng)
    let body = [pt(cx - radius * 0.78, cy - h * 0.5), pt(cx + radius * 0.78, cy - h * 0.5), pt(cx + radius * 0.78, cy + h * 0.5), pt(cx - radius * 0.78, cy + h * 0.5)]
    let bodyPath = pathOf(body)
    p.fillPath(bodyPath, thread)
    linearInto(p, bodyPath, from: pt(cx - radius * 0.78, cy), to: pt(cx + radius * 0.78, cy),
               colours: [thread.dk(0.55), thread.lt(0.10), thread.lt(0.35), thread.dk(0.05), thread.dk(0.5)], locations: [0, 0.25, 0.42, 0.7, 1])
    p.inside(bodyPath) {
        var winds: [CGPoint] = []
        var y = cy - h * 0.5
        while y < cy + h * 0.5 {
            winds.append(pt(cx - radius * 0.8, y)); winds.append(pt(cx + radius * 0.8, y + rng.r(-1.5, 1.5)))
            y += rng.r(2.0, 3.2)
        }
        batchSegments(p, winds, colour: thread.dk(0.4).al(0.35), width: 0.9)
        var lights: [CGPoint] = []
        y = cy - h * 0.5
        while y < cy + h * 0.5 {
            lights.append(pt(cx - radius * 0.35, y + 1)); lights.append(pt(cx + radius * 0.1, y + 1 + rng.r(-1, 1)))
            y += rng.r(2.0, 3.2)
        }
        batchSegments(p, lights, colour: thread.lt(0.5).al(0.3), width: 0.7)
    }
    for (yy, top) in [(cy + h * 0.5, false), (cy - h * 0.5, true)] {
        let disc = ringOf(cx: cx, cy: yy, rx: radius, ry: ry, steps: 40)
        let rim = [pt(cx - radius, yy), pt(cx + radius, yy), pt(cx + radius, yy + ry * 0.45), pt(cx - radius, yy + ry * 0.45)]
        if !top {
            p.shape(rim, Pot.walnutLight.dk(0.4))
            p.shape(ringOf(cx: cx, cy: yy + ry * 0.45, rx: radius, ry: ry, steps: 40), Pot.walnutLight.dk(0.45))
        }
        p.shape(disc, Pot.walnutLight)
        woodGrain(p, pathOf(disc), axis: 0.0, base: Pot.walnutLight, lines: 14, wave: 2, rng: &rng)
        radialInto(p, pathOf(disc), from: pt(cx - radius * 0.4, yy - ry * 0.4), inner: Pot.walnutLight.lt(0.35), outer: Pot.walnutLight.dk(0.35), radius: radius * 1.6)
        penEdge(p, disc, weight: 1.2, colour: Pot.ink.al(0.85), seed: rng.next())
        if top { p.dot(cx, yy, radius * 0.18, Pot.walnutDark) }
    }
    rimLight(p, body, light: p.light, weight: 2.2, colour: thread.lt(0.6).al(0.7), dark: nil, seed: rng.next())
    pen(p, [pt(cx - radius * 0.78, cy - h * 0.5), pt(cx - radius * 0.78, cy + h * 0.5)], weight: 1.2, colour: Pot.ink.al(0.8), wobble: 0.2, taper: false, seed: rng.next())
    pen(p, [pt(cx + radius * 0.78, cy - h * 0.5), pt(cx + radius * 0.78, cy + h * 0.5)], weight: 1.2, colour: Pot.ink.al(0.8), wobble: 0.2, taper: false, seed: rng.next())
}

func drawBeeswax(_ p: Leaf, at c: CGPoint, radius: Double, rng: inout Chip) {
    let cx = Double(c.x), cy = Double(c.y)
    let ry = radius * 0.5
    let h = radius * 0.5
    let base = ringOf(cx: cx, cy: cy + h, rx: radius, ry: ry, steps: 40)
    propShadow(p, base, &rng)
    let wax = Hue(r: 0.84, g: 0.66, b: 0.28)
    let side = [pt(cx - radius, cy), pt(cx + radius, cy), pt(cx + radius, cy + h), pt(cx - radius, cy + h)]
    p.shape(side, wax.dk(0.3))
    p.shape(base, wax.dk(0.35))
    linearInto(p, pathOf(side), from: pt(cx - radius, cy), to: pt(cx + radius, cy), colours: [wax.dk(0.5), wax.dk(0.1), wax.dk(0.45)], locations: [0, 0.35, 1])
    let top = ringOf(cx: cx, cy: cy, rx: radius, ry: ry, steps: 40)
    p.shape(top, wax)
    radialInto(p, pathOf(top), from: pt(cx - radius * 0.35, cy - ry * 0.4), inner: wax.lt(0.35), outer: wax.dk(0.25), radius: radius * 1.5)
    p.inside(pathOf(top)) {
        for _ in 0..<7 {
            let a = rng.r(0, 6.283), r = rng.r(0, radius * 0.7)
            let x = cx + cos(a) * r, y = cy + sin(a) * r * 0.5
            pen(p, [pt(x - 8, y + 2), pt(x + 8, y - 2)], weight: 2.4, colour: wax.dk(0.35).al(0.5), wobble: 0.4, taper: true, seed: rng.next())
        }
    }
    penEdge(p, top, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
    pen(p, [side[0], side[3]], weight: 1.1, colour: Pot.ink.al(0.7), wobble: 0.2, taper: false, seed: rng.next())
    pen(p, [side[1], side[2]], weight: 1.1, colour: Pot.ink.al(0.7), wobble: 0.2, taper: false, seed: rng.next())
    pen(p, [base[20], base[0]], weight: 0.0, colour: Pot.ink, wobble: 0, taper: false, seed: 1)
    var arc: [CGPoint] = []
    for k in 0...20 { arc.append(base[k]) }
    pen(p, arc, weight: 1.2, colour: Pot.ink.al(0.8), wobble: 0.2, taper: false, seed: rng.next())
}

func drawKnife(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let nx = -dy, ny = dx
    let handleEnd = pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5)
    let neck = pt(Double(c.x) + dx * length * 0.12, Double(c.y) + dy * length * 0.12)
    let tip = pt(Double(c.x) + dx * length * 0.5, Double(c.y) + dy * length * 0.5)
    let w = length * 0.05
    let handle = [pt(Double(handleEnd.x) + nx * w, Double(handleEnd.y) + ny * w), pt(Double(neck.x) + nx * w * 0.8, Double(neck.y) + ny * w * 0.8),
                  pt(Double(neck.x) - nx * w * 0.8, Double(neck.y) - ny * w * 0.8), pt(Double(handleEnd.x) - nx * w, Double(handleEnd.y) - ny * w)]
    let blade = [pt(Double(neck.x) + nx * w * 0.7, Double(neck.y) + ny * w * 0.7), tip, pt(Double(neck.x) - nx * w * 0.6, Double(neck.y) - ny * w * 0.6)]
    propShadow(p, handle + [tip], &rng)
    rodShade(p, handleEnd, neck, w0: w * 2, w1: w * 1.6, base: Pot.steel.dk(0.1), light: p.light, rng: &rng)
    p.inside(pathOf(handle)) {
        var knurl: [CGPoint] = []
        var t = 0.05
        while t < 0.6 {
            let a = pt(Double(handleEnd.x) + dx * t * length * 0.62 + nx * w * 0.9, Double(handleEnd.y) + dy * t * length * 0.62 + ny * w * 0.9)
            let b = pt(Double(handleEnd.x) + dx * t * length * 0.62 - nx * w * 0.9, Double(handleEnd.y) + dy * t * length * 0.62 - ny * w * 0.9)
            knurl.append(a); knurl.append(b)
            t += 0.05
        }
        batchSegments(p, knurl, colour: Pot.ink.al(0.35), width: 0.8)
    }
    let bpath = pathOf(blade)
    p.fillPath(bpath, Pot.steelLight)
    linearInto(p, bpath, from: pt(Double(neck.x) + nx * w, Double(neck.y) + ny * w), to: pt(Double(neck.x) - nx * w, Double(neck.y) - ny * w),
               colours: [Pot.steel.dk(0.2), Pot.steelLight.lt(0.6), Pot.steel.lt(0.1)], locations: [0, 0.45, 1])
    pen(p, [blade[1], blade[2]], weight: 1.4, colour: Hue(r: 1, g: 1, b: 1, a: 0.9), wobble: 0.1, taper: true, seed: rng.next())
    penEdge(p, blade, weight: 1.1, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawStraightedge(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let nx = -dy, ny = dx
    let w = length * 0.045
    let a = pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5)
    let b = pt(Double(c.x) + dx * length * 0.5, Double(c.y) + dy * length * 0.5)
    let poly = [pt(Double(a.x) + nx * w, Double(a.y) + ny * w), pt(Double(b.x) + nx * w, Double(b.y) + ny * w), pt(Double(b.x) - nx * w, Double(b.y) - ny * w), pt(Double(a.x) - nx * w, Double(a.y) - ny * w)]
    propShadow(p, poly, &rng)
    let path = pathOf(poly)
    brushedMetal(p, path, base: Pot.steel, axis: angle, light: p.light, rng: &rng)
    let bevel = [poly[0], poly[1], pt(Double(b.x) + nx * w * 0.45, Double(b.y) + ny * w * 0.45), pt(Double(a.x) + nx * w * 0.45, Double(a.y) + ny * w * 0.45)]
    p.shape(bevel, Pot.steelLight.lt(0.3).al(0.6))
    p.inside(path) {
        var ticks: [CGPoint] = []
        var t = 0.03
        var k = 0
        while t < 0.97 {
            let tall = k % 10 == 0 ? 0.9 : (k % 5 == 0 ? 0.6 : 0.35)
            let x = Double(a.x) + dx * t * length, y = Double(a.y) + dy * t * length
            ticks.append(pt(x - nx * w, y - ny * w)); ticks.append(pt(x - nx * w * (1 - tall), y - ny * w * (1 - tall)))
            t += 0.0094
            k += 1
        }
        batchSegments(p, ticks, colour: Pot.ink.al(0.75), width: 0.9)
    }
    penEdge(p, poly, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawPasteBrush(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let nx = -dy, ny = dx
    let handleEnd = pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5)
    let ferrule = pt(Double(c.x) + dx * length * 0.08, Double(c.y) + dy * length * 0.08)
    let ferruleEnd = pt(Double(c.x) + dx * length * 0.22, Double(c.y) + dy * length * 0.22)
    let bristleEnd = pt(Double(c.x) + dx * length * 0.5, Double(c.y) + dy * length * 0.5)
    let w = length * 0.09
    propShadow(p, [pt(Double(handleEnd.x) + nx * w * 0.5, Double(handleEnd.y) + ny * w * 0.5), pt(Double(bristleEnd.x) + nx * w, Double(bristleEnd.y) + ny * w), pt(Double(bristleEnd.x) - nx * w, Double(bristleEnd.y) - ny * w), pt(Double(handleEnd.x) - nx * w * 0.5, Double(handleEnd.y) - ny * w * 0.5)], &rng)
    rodShade(p, handleEnd, ferrule, w0: w * 0.9, w1: w * 1.15, base: Pot.walnutLight, light: p.light, rng: &rng)
    rodShade(p, ferrule, ferruleEnd, w0: w * 1.3, w1: w * 1.3, base: Pot.brass, light: p.light, rng: &rng)
    for _ in 0..<160 {
        let off = rng.r(-1, 1)
        let start = pt(Double(ferruleEnd.x) + nx * w * 0.6 * off, Double(ferruleEnd.y) + ny * w * 0.6 * off)
        let flare = off * (1 + rng.r(0.2, 0.7))
        let end = pt(Double(bristleEnd.x) + nx * w * 0.9 * flare + dx * rng.r(-8, 4), Double(bristleEnd.y) + ny * w * 0.9 * flare + dy * rng.r(-8, 4))
        let mid = pt((Double(start.x) + Double(end.x)) / 2 + nx * rng.r(-2, 2), (Double(start.y) + Double(end.y)) / 2 + ny * rng.r(-2, 2))
        pen(p, [start, mid, end], weight: rng.r(0.6, 1.4), colour: (rng.chance(0.5) ? Pot.linen.dk(0.3) : Pot.linen.lt(0.2)).al(rng.r(0.5, 0.95)), wobble: 0.3, taper: true, seed: rng.next())
    }
}

func drawPastePot(_ p: Leaf, at c: CGPoint, radius: Double, rng: inout Chip, brush: Bool = true) {
    let cx = Double(c.x), cy = Double(c.y)
    let h = radius * 1.3
    let ry = radius * 0.4
    let base = ringOf(cx: cx, cy: cy + h * 0.5, rx: radius * 0.92, ry: ry, steps: 40)
    propShadow(p, base, &rng)
    var body: [CGPoint] = []
    for k in 0...14 {
        let t = Double(k) / 14
        let r = radius * (0.92 + 0.08 * sin(t * .pi))
        body.append(pt(cx + r, cy + h * 0.5 - t * h))
    }
    for k in stride(from: 14, through: 0, by: -1) {
        let t = Double(k) / 14
        let r = radius * (0.92 + 0.08 * sin(t * .pi))
        body.append(pt(cx - r, cy + h * 0.5 - t * h))
    }
    let glaze = Hue(r: 0.62, g: 0.64, b: 0.58)
    let bpath = pathOf(body)
    p.fillPath(bpath, glaze)
    linearInto(p, bpath, from: pt(cx - radius, cy), to: pt(cx + radius, cy), colours: [glaze.dk(0.55), glaze.lt(0.05), glaze.lt(0.45), glaze.dk(0.1), glaze.dk(0.5)], locations: [0, 0.22, 0.38, 0.7, 1])
    p.shape(base, glaze.dk(0.4))
    p.egg(cx - radius * 0.42, cy - h * 0.2, radius * 0.10, radius * 0.28, Hue(r: 1, g: 1, b: 1, a: 0.55))
    p.inside(bpath) {
        for _ in 0..<14 {
            let x = cx + rng.r(-radius, radius), y = cy + rng.r(-h * 0.5, h * 0.5)
            pen(p, [pt(x, y), pt(x + rng.r(-6, 6), y + rng.r(4, 14))], weight: 0.8, colour: Pot.ink.al(0.25), wobble: 0.5, taper: true, seed: rng.next())
        }
    }
    let mouth = ringOf(cx: cx, cy: cy - h * 0.5, rx: radius * 0.92, ry: ry, steps: 40)
    p.shape(mouth, Pot.paste.dk(0.05))
    radialInto(p, pathOf(mouth), from: pt(cx - radius * 0.3, cy - h * 0.5 - ry * 0.3), inner: Pot.paste.lt(0.4), outer: Pot.paste.dk(0.2), radius: radius * 1.4)
    p.egg(cx - radius * 0.25, cy - h * 0.5 - ry * 0.15, radius * 0.22, ry * 0.3, Hue(r: 1, g: 1, b: 1, a: 0.5))
    penEdge(p, mouth, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
    penEdge(p, body, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
    if brush {
        drawPasteBrush(p, at: pt(cx + radius * 0.5, cy - h * 0.6), angle: -1.15, length: radius * 3.2, rng: &rng)
    }
}

func drawHammer(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let nx = -dy, ny = dx
    let handleEnd = pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5)
    let neck = pt(Double(c.x) + dx * length * 0.32, Double(c.y) + dy * length * 0.32)
    let headC = pt(Double(c.x) + dx * length * 0.40, Double(c.y) + dy * length * 0.40)
    let hw = length * 0.16, hh = length * 0.10
    let head = [pt(Double(headC.x) + nx * hw + dx * hh * 0.4, Double(headC.y) + ny * hw + dy * hh * 0.4), pt(Double(headC.x) + nx * hw * 1.05 - dx * hh, Double(headC.y) + ny * hw * 1.05 - dy * hh),
                pt(Double(headC.x) - nx * hw * 1.05 - dx * hh, Double(headC.y) - ny * hw * 1.05 - dy * hh), pt(Double(headC.x) - nx * hw + dx * hh * 0.4, Double(headC.y) - ny * hw + dy * hh * 0.4)]
    propShadow(p, head + [handleEnd], &rng)
    rodShade(p, handleEnd, neck, w0: length * 0.07, w1: length * 0.085, base: Pot.walnutLight, light: p.light, rng: &rng)
    let hpath = pathOf(head)
    brushedMetal(p, hpath, base: Pot.steel.dk(0.15), axis: angle + .pi / 2, light: p.light, rng: &rng)
    extrudeSides(p, head, dx: 3, dy: 6, light: p.light, base: Pot.steel.dk(0.5), brushAngle: nil, rng: &rng, bevel: false)
    p.fillPath(hpath, Pot.steel.dk(0.05))
    brushedMetal(p, hpath, base: Pot.steel, axis: angle + .pi / 2, light: p.light, rng: &rng)
    rimLight(p, head, light: p.light, weight: 3.0, colour: Hue(r: 1, g: 1, b: 1, a: 0.85), dark: Hue(r: 0, g: 0, b: 0, a: 0.5), seed: rng.next())
    penEdge(p, head, weight: 1.4, colour: Pot.ink.al(0.9), seed: rng.next())
}

func drawPress(_ p: Leaf, at c: CGPoint, width: Double, rng: inout Chip, book: BookLook?, open: Double = 0.35) {
    let cx = Double(c.x), cy = Double(c.y)
    let w = width, h = width * 1.05
    let iron = Hue(r: 0.20, g: 0.19, b: 0.19)
    let baseTop = [pt(cx - w * 0.55, cy + h * 0.32), pt(cx + w * 0.55, cy + h * 0.32), pt(cx + w * 0.62, cy + h * 0.42), pt(cx - w * 0.48, cy + h * 0.42)]
    propShadow(p, baseTop, &rng)
    extrudeSides(p, baseTop, dx: 0, dy: h * 0.07, light: p.light, base: iron, brushAngle: nil, rng: &rng, bevel: false)
    p.shape(baseTop, iron.lt(0.12))
    radialInto(p, pathOf(baseTop), from: pt(cx - w * 0.3, cy + h * 0.3), inner: iron.lt(0.3), outer: iron.dk(0.3), radius: w)
    penEdge(p, baseTop, weight: 1.3, colour: Pot.ink.al(0.9), seed: rng.next())
    for side in [-1.0, 1.0] {
        let x = cx + side * w * 0.44
        let post = [pt(x - w * 0.04, cy - h * 0.48), pt(x + w * 0.04, cy - h * 0.48), pt(x + w * 0.04, cy + h * 0.32), pt(x - w * 0.04, cy + h * 0.32)]
        p.shape(post, iron)
        linearInto(p, pathOf(post), from: pt(x - w * 0.04, cy), to: pt(x + w * 0.04, cy), colours: [iron.dk(0.4), iron.lt(0.35), iron.dk(0.1), iron.dk(0.5)], locations: [0, 0.3, 0.6, 1])
        penEdge(p, post, weight: 1.2, colour: Pot.ink.al(0.85), seed: rng.next())
    }
    let crown = [pt(cx - w * 0.52, cy - h * 0.48), pt(cx + w * 0.52, cy - h * 0.48), pt(cx + w * 0.52, cy - h * 0.36), pt(cx - w * 0.52, cy - h * 0.36)]
    p.shape(crown, iron.lt(0.05))
    linearInto(p, pathOf(crown), from: pt(cx, cy - h * 0.48), to: pt(cx, cy - h * 0.36), colours: [iron.lt(0.4), iron.dk(0.1), iron.dk(0.5)], locations: [0, 0.5, 1])
    penEdge(p, crown, weight: 1.3, colour: Pot.ink.al(0.9), seed: rng.next())
    let platenY = cy + h * 0.32 - h * 0.55 * open
    let screwTop = cy - h * 0.36
    let screw = [pt(cx - w * 0.05, screwTop), pt(cx + w * 0.05, screwTop), pt(cx + w * 0.05, platenY), pt(cx - w * 0.05, platenY)]
    p.shape(screw, Pot.steel.dk(0.2))
    linearInto(p, pathOf(screw), from: pt(cx - w * 0.05, cy), to: pt(cx + w * 0.05, cy), colours: [Pot.steel.dk(0.5), Pot.steelLight, Pot.steel.dk(0.1), Pot.steel.dk(0.55)], locations: [0, 0.3, 0.6, 1])
    p.inside(pathOf(screw)) {
        var threads: [CGPoint] = []
        var y = screwTop
        while y < platenY { threads.append(pt(cx - w * 0.05, y)); threads.append(pt(cx + w * 0.05, y + 3)); y += 6 }
        batchSegments(p, threads, colour: Pot.ink.al(0.5), width: 1.0)
    }
    let platen = [pt(cx - w * 0.42, platenY), pt(cx + w * 0.42, platenY), pt(cx + w * 0.48, platenY + h * 0.06), pt(cx - w * 0.36, platenY + h * 0.06)]
    extrudeSides(p, platen, dx: 0, dy: h * 0.04, light: p.light, base: iron, brushAngle: nil, rng: &rng, bevel: false)
    p.shape(platen, iron.lt(0.15))
    penEdge(p, platen, weight: 1.3, colour: Pot.ink.al(0.9), seed: rng.next())
    let wheelY = screwTop - h * 0.06
    let wheel = ringOf(cx: cx, cy: wheelY, rx: w * 0.34, ry: w * 0.07, steps: 48)
    p.shape(wheel, Pot.brass.dk(0.1))
    radialInto(p, pathOf(wheel), from: pt(cx - w * 0.15, wheelY - w * 0.03), inner: Pot.brassPale, outer: Pot.brass.dk(0.5), radius: w * 0.4)
    p.shape(ringOf(cx: cx, cy: wheelY, rx: w * 0.26, ry: w * 0.05, steps: 48), iron.lt(0.1))
    for k in 0..<4 {
        let a = Double(k) / 4 * .pi
        pen(p, [pt(cx + cos(a) * w * 0.3, wheelY + sin(a) * w * 0.06), pt(cx - cos(a) * w * 0.3, wheelY - sin(a) * w * 0.06)], weight: 4, colour: Pot.brass.dk(0.2), wobble: 0.1, taper: false, seed: rng.next())
    }
    penEdge(p, wheel, weight: 1.3, colour: Pot.ink.al(0.9), seed: rng.next())
    if let look = book {
        let pose = BookPose(ox: cx - w * 0.30, oy: cy + h * 0.32 - w * 0.28, eH: (1.0, 0.0), eW: (0.55, -0.42), eT: (0, 1), width: w * 0.32, height: w * 0.6, thick: w * 0.11)
        var boardLook = look
        boardLook.title = ""
        paintBook(p, pose, boardLook, rng: &rng, shadow: false)
    }
}
