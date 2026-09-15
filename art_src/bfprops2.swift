import Foundation
import CoreGraphics

func woodBlock(_ p: Leaf, _ top: [CGPoint], depth: Double, base: Hue, axis: Double, rng: inout Chip) {
    extrudeSides(p, top, dx: 0, dy: depth, light: p.light, base: base.dk(0.15), brushAngle: nil, rng: &rng, bevel: false)
    let path = pathOf(top)
    p.fillPath(path, base)
    woodGrain(p, path, axis: axis, base: base, lines: 40, wave: 4, rng: &rng)
    linearInto(p, path, from: top[0], to: top[2], colours: [Hue(r: 1, g: 1, b: 1, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.18)], locations: [0, 0.5, 1])
    penEdge(p, top, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawLyingPress(_ p: Leaf, at c: CGPoint, width: Double, rng: inout Chip, block: Bool) {
    let cx = Double(c.x), cy = Double(c.y)
    let w = width, d = width * 0.22
    let cheekH = width * 0.16
    let front = [pt(cx - w * 0.5, cy - cheekH * 0.5), pt(cx + w * 0.5, cy - cheekH * 0.5 - d * 0.3), pt(cx + w * 0.5 + d * 0.55, cy - cheekH * 0.5 - d * 0.3 - d * 0.62), pt(cx - w * 0.5 + d * 0.55, cy - cheekH * 0.5 - d * 0.62)]
    let back = shifted(front, d * 0.9, -d * 1.0)
    propShadow(p, shifted(front, 0, cheekH), &rng)
    woodBlock(p, back, depth: cheekH, base: Pot.walnutLight.dk(0.1), axis: -0.06, rng: &rng)
    if block {
        let blockTop = [pt(cx - w * 0.36, cy - cheekH * 0.5 - d * 0.31 - 12), pt(cx + w * 0.36, cy - cheekH * 0.5 - d * 0.31 - 12 - d * 0.22), pt(cx + w * 0.36 + d * 0.6, cy - cheekH * 0.5 - d * 0.31 - 12 - d * 0.22 - d * 0.5), pt(cx - w * 0.36 + d * 0.6, cy - cheekH * 0.5 - d * 0.31 - 12 - d * 0.5)]
        let path = pathOf(blockTop)
        p.fillPath(path, Pot.paper.dk(0.06))
        p.inside(path) {
            var lines: [CGPoint] = []
            for k in 0..<12 {
                let f = Double(k) / 12
                lines.append(pt(cx - w * 0.36 + f * d * 0.6, cy - cheekH * 0.5 - d * 0.31 - 12 - f * d * 0.5))
                lines.append(pt(cx + w * 0.36 + f * d * 0.6, cy - cheekH * 0.5 - d * 0.31 - 12 - d * 0.22 - f * d * 0.5))
            }
            batchSegments(p, lines, colour: Pot.ink.al(0.3), width: 0.8)
        }
        penEdge(p, blockTop, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
    }
    woodBlock(p, front, depth: cheekH, base: Pot.walnutLight, axis: -0.06, rng: &rng)
    for side in [-0.42, 0.42] {
        let x = cx + side * w
        let sy = cy - cheekH * 0.5 - d * 0.3 * (side > 0 ? 1 : 0)
        let screw = [pt(x - 9, sy - d * 1.6), pt(x + 9, sy - d * 1.6), pt(x + 9, sy + cheekH * 0.5), pt(x - 9, sy + cheekH * 0.5)]
        p.shape(screw, Pot.walnutLight.dk(0.25))
        linearInto(p, pathOf(screw), from: pt(x - 9, sy), to: pt(x + 9, sy), colours: [Pot.walnutLight.dk(0.5), Pot.walnutLight.lt(0.3), Pot.walnutLight.dk(0.4)], locations: [0, 0.4, 1])
        p.inside(pathOf(screw)) {
            var t: [CGPoint] = []
            var y = sy - d * 1.6
            while y < sy + cheekH * 0.5 { t.append(pt(x - 9, y)); t.append(pt(x + 9, y + 4)); y += 7 }
            batchSegments(p, t, colour: Pot.ink.al(0.5), width: 1.0)
        }
        penEdge(p, screw, weight: 1.2, colour: Pot.ink.al(0.85), seed: rng.next())
        let knob = ringOf(cx: x, cy: sy - d * 1.6, rx: 22, ry: 10, steps: 32)
        p.shape(knob, Pot.walnutLight)
        radialInto(p, pathOf(knob), from: pt(x - 8, sy - d * 1.6 - 4), inner: Pot.walnutLight.lt(0.4), outer: Pot.walnutLight.dk(0.4), radius: 30)
        penEdge(p, knob, weight: 1.2, colour: Pot.ink.al(0.85), seed: rng.next())
    }
}

func drawPlough(_ p: Leaf, at c: CGPoint, width: Double, rng: inout Chip) {
    let cx = Double(c.x), cy = Double(c.y)
    let w = width
    let cheek = [pt(cx - w * 0.5, cy - w * 0.05), pt(cx + w * 0.5, cy - w * 0.15), pt(cx + w * 0.5, cy + w * 0.05), pt(cx - w * 0.5, cy + w * 0.15)]
    propShadow(p, cheek, &rng)
    woodBlock(p, cheek, depth: w * 0.16, base: Pot.walnutLight, axis: -0.1, rng: &rng)
    let carriage = [pt(cx - w * 0.16, cy - w * 0.32), pt(cx + w * 0.16, cy - w * 0.36), pt(cx + w * 0.16, cy - w * 0.06), pt(cx - w * 0.16, cy - w * 0.02)]
    woodBlock(p, carriage, depth: w * 0.06, base: Pot.walnutLight.dk(0.05), axis: -0.1, rng: &rng)
    let screwA = pt(cx - w * 0.5, cy - w * 0.2), screwB = pt(cx + w * 0.5, cy - w * 0.3)
    rodShade(p, screwA, screwB, w0: w * 0.05, w1: w * 0.05, base: Pot.walnutLight.dk(0.2), light: p.light, rng: &rng)
    var threads: [CGPoint] = []
    for k in 0..<40 {
        let f = Double(k) / 40
        let x = Double(screwA.x) + (Double(screwB.x) - Double(screwA.x)) * f
        let y = Double(screwA.y) + (Double(screwB.y) - Double(screwA.y)) * f
        threads.append(pt(x, y - w * 0.025)); threads.append(pt(x + 3, y + w * 0.025))
    }
    batchSegments(p, threads, colour: Pot.ink.al(0.45), width: 1.0)
    let knob = ringOf(cx: cx - w * 0.52, cy: cy - w * 0.2, rx: w * 0.05, ry: w * 0.09, steps: 30)
    p.shape(knob, Pot.walnutLight)
    penEdge(p, knob, weight: 1.2, colour: Pot.ink.al(0.85), seed: rng.next())
    let blade = [pt(cx + w * 0.02, cy - w * 0.02), pt(cx + w * 0.10, cy - w * 0.04), pt(cx + w * 0.12, cy + w * 0.14), pt(cx + w * 0.04, cy + w * 0.16)]
    p.shape(blade, Pot.steelLight)
    linearInto(p, pathOf(blade), from: blade[0], to: blade[1], colours: [Pot.steel.dk(0.3), Pot.steelLight.lt(0.5), Pot.steel], locations: [0, 0.5, 1])
    penEdge(p, blade, weight: 1.1, colour: Pot.ink.al(0.85), seed: rng.next())
    let shavings = ringOf(cx: cx + w * 0.2, cy: cy + w * 0.22, rx: w * 0.08, ry: w * 0.03, steps: 20)
    for k in 0..<12 {
        let q = shavings[k]
        pen(p, [q, pt(Double(q.x) + rng.r(-10, 10), Double(q.y) + rng.r(2, 10))], weight: 1.4, colour: Pot.paper.dk(0.1), wobble: 0.6, taper: true, seed: rng.next())
    }
}

func drawSewingFrame(_ p: Leaf, at c: CGPoint, width: Double, rng: inout Chip, tapes: Int, block: BookLook?) {
    let cx = Double(c.x), cy = Double(c.y)
    let w = width
    let base = [pt(cx - w * 0.5, cy + w * 0.30), pt(cx + w * 0.5, cy + w * 0.24), pt(cx + w * 0.58, cy + w * 0.40), pt(cx - w * 0.42, cy + w * 0.46)]
    propShadow(p, base, &rng)
    woodBlock(p, base, depth: w * 0.05, base: Pot.walnutLight, axis: -0.06, rng: &rng)
    let slot = [pt(cx - w * 0.36, cy + w * 0.34), pt(cx + w * 0.36, cy + w * 0.30), pt(cx + w * 0.37, cy + w * 0.32), pt(cx - w * 0.35, cy + w * 0.36)]
    p.shape(slot, Pot.walnutDark)
    for side in [-1.0, 1.0] {
        let x = cx + side * w * 0.46
        let y0 = cy + w * 0.28 - side * w * 0.03
        rodShade(p, pt(x, y0), pt(x, y0 - w * 0.62), w0: w * 0.05, w1: w * 0.045, base: Pot.walnutLight, light: p.light, rng: &rng)
        var threads: [CGPoint] = []
        var y = y0 - w * 0.6
        while y < y0 - w * 0.2 { threads.append(pt(x - w * 0.022, y)); threads.append(pt(x + w * 0.022, y + 2)); y += 5 }
        batchSegments(p, threads, colour: Pot.ink.al(0.35), width: 0.9)
        let nut = [pt(x - w * 0.06, y0 - w * 0.40), pt(x + w * 0.06, y0 - w * 0.40), pt(x + w * 0.06, y0 - w * 0.35), pt(x - w * 0.06, y0 - w * 0.35)]
        p.shape(nut, Pot.walnutLight.dk(0.2))
        penEdge(p, nut, weight: 1.1, colour: Pot.ink.al(0.85), seed: rng.next())
    }
    let barA = pt(cx - w * 0.5, cy + w * 0.28 + w * 0.03 - w * 0.42), barB = pt(cx + w * 0.5, cy + w * 0.28 - w * 0.03 - w * 0.42)
    rodShade(p, barA, barB, w0: w * 0.05, w1: w * 0.05, base: Pot.walnutLight, light: p.light, rng: &rng)
    for t in 0..<tapes {
        let f = (Double(t) + 1) / Double(tapes + 1)
        let x = cx - w * 0.36 + w * 0.72 * f
        let top = Double(barA.y) + (Double(barB.y) - Double(barA.y)) * f
        let bottom = cy + w * 0.34 - w * 0.04 * f
        let tape = [pt(x - w * 0.018, top + w * 0.02), pt(x + w * 0.018, top + w * 0.02), pt(x + w * 0.018, bottom), pt(x - w * 0.018, bottom)]
        p.shape(tape, Pot.linenPale)
        clothWeave(p, pathOf(tape), base: Pot.linenPale, pitch: 2.2, rng: &rng)
        penEdge(p, tape, weight: 0.9, colour: Pot.ink.al(0.7), seed: rng.next())
    }
    if let look = block {
        let pose = BookPose(ox: cx - w * 0.34, oy: cy + w * 0.30 - w * 0.10, eH: (1.0, -0.06), eW: (0.5, -0.4), eT: (0, 1), width: w * 0.30, height: w * 0.62, thick: w * 0.10)
        paintBook(p, pose, look, rng: &rng, shadow: false)
    }
}

func drawCradle(_ p: Leaf, at c: CGPoint, width: Double, rng: inout Chip, signature: Bool) {
    let cx = Double(c.x), cy = Double(c.y)
    let w = width
    let leftTop = [pt(cx - w * 0.5, cy - w * 0.1), pt(cx - w * 0.03, cy + w * 0.12), pt(cx + w * 0.10, cy + w * 0.02), pt(cx - w * 0.37, cy - w * 0.20)]
    let rightTop = [pt(cx - w * 0.03, cy + w * 0.12), pt(cx + w * 0.5, cy - w * 0.08), pt(cx + w * 0.63, cy - w * 0.18), pt(cx + w * 0.10, cy + w * 0.02)]
    propShadow(p, [leftTop[0], rightTop[1], pt(cx + w * 0.5, cy + w * 0.16), pt(cx - w * 0.5, cy + w * 0.16)], &rng)
    let legL = [leftTop[0], leftTop[1], pt(cx - w * 0.03, cy + w * 0.30), pt(cx - w * 0.5, cy + w * 0.12)]
    let legR = [rightTop[0], rightTop[1], pt(cx + w * 0.5, cy + w * 0.12), pt(cx - w * 0.03, cy + w * 0.30)]
    p.shape(legL, Pot.walnutLight.dk(0.35))
    p.shape(legR, Pot.walnutLight.dk(0.5))
    woodBlock(p, leftTop, depth: 0, base: Pot.walnutLight, axis: 0.45, rng: &rng)
    woodBlock(p, rightTop, depth: 0, base: Pot.walnutLight.dk(0.1), axis: -0.4, rng: &rng)
    penEdge(p, legL, weight: 1.1, colour: Pot.ink.al(0.7), seed: rng.next())
    penEdge(p, legR, weight: 1.1, colour: Pot.ink.al(0.7), seed: rng.next())
    if signature {
        let sigL = [pt(cx - w * 0.40, cy - w * 0.11), pt(cx - w * 0.02, cy + w * 0.08), pt(cx + w * 0.10, cy - w * 0.01), pt(cx - w * 0.28, cy - w * 0.20)]
        let sigR = [pt(cx - w * 0.02, cy + w * 0.08), pt(cx + w * 0.40, cy - w * 0.09), pt(cx + w * 0.52, cy - w * 0.18), pt(cx + w * 0.10, cy - w * 0.01)]
        for (poly, shade) in [(sigL, 0.02), (sigR, 0.10)] {
            let path = pathOf(poly)
            p.fillPath(path, Pot.paper.dk(shade))
            paperFibres(p, path, base: Pot.paper, laid: true, count: 60, rng: &rng)
            penEdge(p, poly, weight: 1.1, colour: Pot.ink.al(0.8), seed: rng.next())
        }
        for f in [0.12, 0.37, 0.63, 0.88] {
            let x = cx - w * 0.02 + (w * 0.12) * f * 0 + (Double(f) - 0.5) * 0
            let q = pt(x + w * 0.12 * (f - 0.5) * 2 * 0.5 + w * 0.06 * (f - 0.5), cy + w * 0.08 - w * 0.09 * f)
            p.dot(Double(q.x), Double(q.y), 2.2, Pot.ink.al(0.85))
        }
    }
}

func drawCuttingMat(_ p: Leaf, at c: CGPoint, width: Double, rng: inout Chip) {
    let cx = Double(c.x), cy = Double(c.y)
    let w = width, h = width * 0.66
    let poly = [pt(cx - w * 0.5, cy - h * 0.5), pt(cx + w * 0.5, cy - h * 0.5), pt(cx + w * 0.5, cy + h * 0.5), pt(cx - w * 0.5, cy + h * 0.5)]
    propShadow(p, poly, &rng)
    let mat = Hue(r: 0.22, g: 0.36, b: 0.30)
    let path = pathOf(poly)
    p.fillPath(path, mat)
    radialInto(p, path, from: pt(cx - w * 0.3, cy - h * 0.3), inner: mat.lt(0.18), outer: mat.dk(0.25), radius: w)
    p.inside(path) {
        var grid: [CGPoint] = []
        var x = cx - w * 0.5 + w * 0.05
        while x < cx + w * 0.5 { grid.append(pt(x, cy - h * 0.45)); grid.append(pt(x, cy + h * 0.45)); x += w * 0.05 }
        var y = cy - h * 0.5 + h * 0.06
        while y < cy + h * 0.5 { grid.append(pt(cx - w * 0.45, y)); grid.append(pt(cx + w * 0.45, y)); y += h * 0.076 }
        batchSegments(p, grid, colour: Hue(r: 1, g: 1, b: 0.9, a: 0.35), width: 0.8)
        var cuts: [CGPoint] = []
        for _ in 0..<26 {
            let x0 = cx + rng.r(-w * 0.45, w * 0.45), y0 = cy + rng.r(-h * 0.45, h * 0.45)
            let a = rng.chance(0.7) ? rng.r(-0.1, 0.1) : rng.r(1.4, 1.7)
            let l = rng.r(20, 120)
            cuts.append(pt(x0, y0)); cuts.append(pt(x0 + cos(a) * l, y0 + sin(a) * l))
        }
        batchSegments(p, cuts, colour: mat.dk(0.6).al(0.5), width: 0.9)
    }
    penEdge(p, poly, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawBottle(_ p: Leaf, at c: CGPoint, height: Double, rng: inout Chip, label: String) {
    let cx = Double(c.x), cy = Double(c.y)
    let h = height, w = height * 0.42
    var body: [CGPoint] = []
    for k in 0...12 {
        let t = Double(k) / 12
        let r = t < 0.2 ? w * (0.32 + t / 0.2 * 0.18) : w * 0.5
        body.append(pt(cx + r, cy - h * 0.5 + t * h))
    }
    for k in stride(from: 12, through: 0, by: -1) {
        let t = Double(k) / 12
        let r = t < 0.2 ? w * (0.32 + t / 0.2 * 0.18) : w * 0.5
        body.append(pt(cx - r, cy - h * 0.5 + t * h))
    }
    propShadow(p, body, &rng)
    let white = Hue(r: 0.93, g: 0.93, b: 0.90)
    let bpath = pathOf(body)
    p.fillPath(bpath, white)
    linearInto(p, bpath, from: pt(cx - w * 0.5, cy), to: pt(cx + w * 0.5, cy), colours: [white.dk(0.35), white.lt(0.1), white.lt(0.3), white.dk(0.08), white.dk(0.4)], locations: [0, 0.25, 0.4, 0.7, 1])
    let cap = [pt(cx - w * 0.3, cy - h * 0.62), pt(cx + w * 0.3, cy - h * 0.62), pt(cx + w * 0.32, cy - h * 0.5), pt(cx - w * 0.32, cy - h * 0.5)]
    p.shape(cap, Pot.threadRed.dk(0.2))
    linearInto(p, pathOf(cap), from: cap[0], to: cap[1], colours: [Pot.threadRed.dk(0.5), Pot.threadRed.lt(0.2), Pot.threadRed.dk(0.4)], locations: [0, 0.4, 1])
    penEdge(p, cap, weight: 1.1, colour: Pot.ink.al(0.85), seed: rng.next())
    let lab = [pt(cx - w * 0.44, cy - h * 0.1), pt(cx + w * 0.44, cy - h * 0.1), pt(cx + w * 0.44, cy + h * 0.28), pt(cx - w * 0.44, cy + h * 0.28)]
    p.shape(lab, Pot.paper)
    penEdge(p, lab, weight: 0.9, colour: Pot.ink.al(0.6), seed: rng.next())
    letter(p, label, at: cx, cy + h * 0.12, size: h * 0.12, colour: Pot.ink, face: "Cochin-Bold")
    penEdge(p, body, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawTeflonFolder(_ p: Leaf, at c: CGPoint, angle: Double, length: Double, rng: inout Chip) {
    let dx = cos(angle), dy = sin(angle)
    let nx = -dy, ny = dx
    let w = length * 0.09
    let a = pt(Double(c.x) - dx * length * 0.5, Double(c.y) - dy * length * 0.5)
    let b = pt(Double(c.x) + dx * length * 0.5, Double(c.y) + dy * length * 0.5)
    let poly = [pt(Double(a.x) + nx * w * 0.6, Double(a.y) + ny * w * 0.6), pt(Double(b.x) + nx * w * 0.9, Double(b.y) + ny * w * 0.9), pt(Double(b.x) + dx * w * 0.6, Double(b.y) + dy * w * 0.6), pt(Double(b.x) - nx * w * 0.9, Double(b.y) - ny * w * 0.9), pt(Double(a.x) - nx * w * 0.6, Double(a.y) - ny * w * 0.6)]
    propShadow(p, poly, &rng)
    let white = Hue(r: 0.95, g: 0.95, b: 0.93)
    let path = pathOf(poly)
    p.fillPath(path, white)
    linearInto(p, path, from: pt(Double(c.x) + nx * w, Double(c.y) + ny * w), to: pt(Double(c.x) - nx * w, Double(c.y) - ny * w), colours: [white.dk(0.25), white.lt(0.2), white.dk(0.05), white.dk(0.3)], locations: [0, 0.35, 0.7, 1])
    penEdge(p, poly, weight: 1.2, colour: Pot.ink.al(0.75), seed: rng.next())
}

func drawSkein(_ p: Leaf, at c: CGPoint, width: Double, thread: Hue, rng: inout Chip) {
    let cx = Double(c.x), cy = Double(c.y)
    let outline = ringOf(cx: cx, cy: cy, rx: width * 0.5, ry: width * 0.2, steps: 40)
    propShadow(p, outline, &rng)
    for k in 0..<60 {
        let f = Double(k) / 60
        let ry = width * (0.14 + 0.06 * sin(f * 3.0))
        var loop: [CGPoint] = []
        var a = 0.0
        while a < 6.4 { loop.append(pt(cx + cos(a) * width * 0.5 * (0.9 + 0.1 * sin(a * 3 + f * 9)), cy + sin(a) * ry + (f - 0.5) * width * 0.06)); a += 0.25 }
        pen(p, loop, weight: 2.4, colour: (rng.chance(0.5) ? thread.dk(0.25) : thread.lt(0.15)).al(0.85), wobble: 0.5, taper: false, seed: rng.next())
    }
    let tie = [pt(cx - width * 0.06, cy - width * 0.2), pt(cx + width * 0.06, cy - width * 0.2), pt(cx + width * 0.08, cy + width * 0.2), pt(cx - width * 0.08, cy + width * 0.2)]
    p.shape(tie, thread.lt(0.5))
    penEdge(p, tie, weight: 1.0, colour: Pot.ink.al(0.7), seed: rng.next())
}

func drawToolPlate(_ t: Tool, dir: String) -> CGImage? {
    let p = Leaf(1200, 900)
    var rng = benchScene(p, seed: hashOf("tool." + t.key), exclude: t.key, horizon: 0.34, props: 2)
    p.light = 2.34
    let c = pt(600, 430)
    switch t.key {
    case "boneFolder": drawBoneFolder(p, at: c, angle: -0.35, length: 760, rng: &rng)
    case "teflonFolder": drawTeflonFolder(p, at: c, angle: -0.30, length: 600, rng: &rng)
    case "awl": drawAwl(p, at: c, angle: -0.42, length: 740, rng: &rng)
    case "needle": drawNeedle(p, at: c, angle: -0.30, length: 760, rng: &rng, thread: Pot.linen)
    case "beeswax": drawBeeswax(p, at: pt(600, 400), radius: 240, rng: &rng)
    case "thread":
        drawSpool(p, at: pt(430, 380), radius: 110, thread: Pot.linen, rng: &rng)
        drawSkein(p, at: pt(800, 430), width: 360, thread: Pot.threadRed, rng: &rng)
    case "cuttingMat":
        drawCuttingMat(p, at: pt(600, 400), width: 820, rng: &rng)
        drawKnife(p, at: pt(560, 420), angle: -0.5, length: 360, rng: &rng)
    case "knife": drawKnife(p, at: c, angle: -0.38, length: 740, rng: &rng)
    case "straightedge": drawStraightedge(p, at: c, angle: -0.22, length: 900, rng: &rng)
    case "pasteBrush": drawPasteBrush(p, at: c, angle: -0.45, length: 680, rng: &rng)
    case "wheatPaste": drawPastePot(p, at: pt(600, 430), radius: 190, rng: &rng)
    case "pva": drawBottle(p, at: pt(600, 400), height: 560, rng: &rng, label: "PVA")
    case "nippingPress": drawPress(p, at: pt(600, 420), width: 560, rng: &rng, book: BookLook(cover: Pot.indigo, kind: .cloth, look: .hollowBack, structure: .kettleTapes), open: 0.36)
    case "lyingPress": drawLyingPress(p, at: pt(600, 420), width: 760, rng: &rng, block: true)
    case "backingHammer": drawHammer(p, at: c, angle: -0.55, length: 700, rng: &rng)
    case "plough": drawPlough(p, at: pt(600, 400), width: 760, rng: &rng)
    case "sewingFrame": drawSewingFrame(p, at: pt(600, 400), width: 720, rng: &rng, tapes: 3, block: BookLook(cover: Pot.paper, kind: .bare, look: .tapes, structure: .kettleTapes, signatures: 6, stations: 8))
    case "punchingCradle": drawCradle(p, at: pt(600, 430), width: 800, rng: &rng, signature: true)
    default: drawBoneFolder(p, at: c, angle: -0.35, length: 600, rng: &rng)
    }
    captionLabel(p, title: t.name, sub: t.use, y: 736, size: 38)
    p.writeJPG(dir, t.plate, quality: 0.86)
    return p.image()
}
