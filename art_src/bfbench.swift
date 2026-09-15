import Foundation
import CoreGraphics

func captionLabel(_ p: Leaf, title: String, sub: String, y: Double, size: Double = 38) {
    var rng = Chip(hashOf(title) &+ 91)
    let subLines = sub.isEmpty ? [] : wrapText(sub, width: p.w * 0.70, size: size * 0.58, face: "Cochin-Italic").prefix(2)
    let height = size * 1.9 + Double(subLines.count) * size * 0.72
    let x0 = p.w * 0.14, x1 = p.w * 0.86
    var edge: [CGPoint] = []
    var x = x0
    while x <= x1 { edge.append(pt(x, y + rng.r(-2.5, 2.5))); x += 24 }
    edge.append(pt(x1 + rng.r(-2, 2), y + height * 0.5))
    x = x1
    while x >= x0 { edge.append(pt(x, y + height + rng.r(-2.5, 2.5))); x -= 24 }
    edge.append(pt(x0 + rng.r(-2, 2), y + height * 0.5))
    castShadow(p, edge, dx: 4, dy: 6, steps: 4, alpha: 0.08)
    let path = pathOf(edge)
    p.fillPath(path, Pot.paper.lt(0.2))
    paperFibres(p, path, base: Pot.paper.lt(0.2), laid: true, count: 120, rng: &rng)
    linearInto(p, path, from: pt(x0, y), to: pt(x1, y + height), colours: [Hue(r: 1, g: 1, b: 1, a: 0.15), Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.08)], locations: [0, 0.5, 1])
    penEdge(p, edge, weight: 1.0, colour: Pot.ink.al(0.55), seed: rng.next())
    p.box(x0 + 26, y + size * 1.32 + 6, x1 - x0 - 52, 1.2, Pot.ink.al(0.35))
    letter(p, title, at: p.w / 2, y + size * 1.22, size: size, colour: Pot.ink, face: "Cochin-Bold", align: .centre)
    for (i, line) in subLines.enumerated() {
        letter(p, line, at: p.w / 2, y + size * 1.32 + 6 + size * 0.68 + Double(i) * size * 0.72, size: size * 0.58, colour: Pot.inkSoft, face: "Cochin-Italic", align: .centre)
    }
}

func wallShelf(_ p: Leaf, y: Double, rng: inout Chip, haze: Double = 0.45, fromX: Double = 0) {
    let shelfH = 12.0
    let books = rng.i(7, 11)
    var x = max(fromX, p.w * 0.06) + rng.r(0, 40)
    let tones: [Hue] = [Pot.indigo, Pot.walnut, Pot.threadRed.dk(0.2), Pot.moss, Pot.linen.dk(0.2), Pot.ochre.dk(0.2), Pot.indigoDeep, Pot.sepia]
    let bottom = y - 2
    for _ in 0..<books {
        let w = rng.r(22, 44), h = rng.r(120, 190)
        guard x + w < p.w * 0.94 else { break }
        let lean = rng.chance(0.15) ? rng.r(-0.12, 0.12) : 0
        let poly = [pt(x + lean * 40, bottom - h), pt(x + w + lean * 40, bottom - h + rng.r(-3, 3)), pt(x + w, bottom), pt(x, bottom)]
        let tone = tones[rng.i(0, tones.count - 1)].mix(Pot.paperWarm, haze)
        let path = pathOf(poly)
        p.fillPath(path, tone)
        linearInto(p, path, from: pt(x, bottom), to: pt(x + w, bottom), colours: [tone.dk(0.35), tone.lt(0.15), tone.dk(0.25)], locations: [0, 0.4, 1])
        if rng.chance(0.6) {
            for f in [0.12, 0.88] {
                pen(p, [pt(x + 3, bottom - h * f), pt(x + w - 3, bottom - h * f)], weight: 1.0, colour: Pot.brassPale.mix(Pot.paperWarm, haze * 0.5).al(0.7), wobble: 0.1, taper: true, seed: rng.next())
            }
        }
        if rng.chance(0.5) {
            let ly = bottom - h * rng.r(0.35, 0.6)
            p.box(x + 4, ly - 10, w - 8, 20, Pot.paper.mix(Pot.paperWarm, haze * 0.6))
        }
        penEdge(p, poly, weight: 0.9, colour: Pot.ink.al(0.5 * (1 - haze * 0.5)), seed: rng.next())
        x += w + rng.r(0, 3)
    }
    let shelf = [pt(fromX, y), pt(p.w, y), pt(p.w, y + shelfH), pt(fromX, y + shelfH)]
    p.shape(shelf, Pot.walnut.mix(Pot.paperWarm, haze * 0.6))
    pen(p, [pt(fromX, y), pt(p.w, y)], weight: 1.2, colour: Pot.ink.al(0.55), wobble: 0.5, taper: false, seed: rng.next())
    pen(p, [pt(fromX, y + shelfH), pt(p.w, y + shelfH)], weight: 1.4, colour: Pot.ink.al(0.6), wobble: 0.5, taper: false, seed: rng.next())
    p.insideRect(CGRect(x: fromX, y: y + shelfH, width: p.w - fromX, height: 40)) {
        linearFree(p, pt(0, y + shelfH), pt(0, y + shelfH + 40), [Hue(r: 0, g: 0, b: 0, a: 0.14), Hue(r: 0, g: 0, b: 0, a: 0)], [0, 1])
    }
}

func paperOffcuts(_ p: Leaf, at c: CGPoint, rng: inout Chip, count: Int = 3) {
    for k in 0..<count {
        let cx = Double(c.x) + rng.r(-40, 40), cy = Double(c.y) + rng.r(-14, 14) + Double(k) * 4
        let w = rng.r(60, 140), h = rng.r(18, 40)
        let a = rng.r(-0.3, 0.3)
        let dx = cos(a), dy = sin(a)
        let poly = [pt(cx - dx * w / 2 + dy * h / 2, cy - dy * w / 2 - dx * h / 2), pt(cx + dx * w / 2 + dy * h / 2, cy + dy * w / 2 - dx * h / 2),
                    pt(cx + dx * w / 2 - dy * h / 2, cy + dy * w / 2 + dx * h / 2), pt(cx - dx * w / 2 - dy * h / 2, cy - dy * w / 2 + dx * h / 2)]
        p.shape(shifted(poly, 2, 3), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.25))
        let path = pathOf(poly)
        p.fillPath(path, Pot.paper.lt(0.1))
        paperFibres(p, path, base: Pot.paper, laid: true, count: 20, rng: &rng)
        penEdge(p, poly, weight: 0.9, colour: Pot.ink.al(0.6), seed: rng.next())
    }
}

func threadSnippet(_ p: Leaf, at c: CGPoint, rng: inout Chip, tone: Hue) {
    var pts: [CGPoint] = []
    var x = Double(c.x) - 60, y = Double(c.y)
    for _ in 0..<7 {
        pts.append(pt(x, y))
        x += rng.r(10, 26); y += rng.r(-14, 14)
    }
    let path = catmull(pts, steps: 8)
    pen(p, shifted(path, 1.5, 2), weight: 2.6, colour: Hue(r: 0, g: 0, b: 0, a: 0.25), wobble: 0.3, taper: false, seed: rng.next())
    pen(p, path, weight: 2.2, colour: tone, wobble: 0.35, taper: false, seed: rng.next())
    pen(p, shifted(path, -0.5, -0.7), weight: 0.8, colour: tone.lt(0.5).al(0.8), wobble: 0.3, taper: false, seed: rng.next())
}

func benchProps(_ p: Leaf, rng: inout Chip, exclude: String, zone: CGRect, count: Int = 3) {
    var kinds = ["spool", "needle", "boneFolder", "awl", "beeswax", "offcuts", "thread", "knife", "brush"]
    kinds.removeAll { $0 == exclude }
    var used = Set<String>()
    let spots: [CGPoint] = [pt(Double(zone.minX) + Double(zone.width) * 0.10, Double(zone.minY) + Double(zone.height) * 0.78),
                            pt(Double(zone.minX) + Double(zone.width) * 0.90, Double(zone.minY) + Double(zone.height) * 0.72),
                            pt(Double(zone.minX) + Double(zone.width) * 0.86, Double(zone.minY) + Double(zone.height) * 0.20),
                            pt(Double(zone.minX) + Double(zone.width) * 0.12, Double(zone.minY) + Double(zone.height) * 0.22)]
    for k in 0..<min(count, spots.count) {
        var kind = kinds[rng.i(0, kinds.count - 1)]
        var tries = 0
        while used.contains(kind) && tries < 6 { kind = kinds[rng.i(0, kinds.count - 1)]; tries += 1 }
        used.insert(kind)
        let c = spots[k]
        let far = Double(c.y) < Double(zone.minY) + Double(zone.height) * 0.5
        let s = far ? 0.72 : 1.0
        switch kind {
        case "spool": drawSpool(p, at: c, radius: 34 * s, thread: rng.chance(0.5) ? Pot.linen : Pot.threadRed, rng: &rng)
        case "needle": drawNeedle(p, at: c, angle: rng.r(-0.6, 0.4), length: 130 * s, rng: &rng, thread: Pot.linen)
        case "boneFolder": drawBoneFolder(p, at: c, angle: rng.r(-0.5, 0.5), length: 200 * s, rng: &rng)
        case "awl": drawAwl(p, at: c, angle: rng.r(-0.7, 0.5), length: 190 * s, rng: &rng)
        case "beeswax": drawBeeswax(p, at: c, radius: 42 * s, rng: &rng)
        case "offcuts": paperOffcuts(p, at: c, rng: &rng)
        case "thread": threadSnippet(p, at: c, rng: &rng, tone: rng.chance(0.5) ? Pot.threadRed : Pot.linen)
        case "knife": drawKnife(p, at: c, angle: rng.r(-0.5, 0.5), length: 170 * s, rng: &rng)
        default: drawPasteBrush(p, at: c, angle: rng.r(-0.8, 0.2), length: 160 * s, rng: &rng)
        }
    }
}

func benchScene(_ p: Leaf, seed: UInt64, exclude: String, horizon: Double = 0.36, props: Int = 3, shelf: Bool = true) -> Chip {
    var rng = Chip(seed)
    benchGround(p, seed: rng.next(), horizon: horizon)
    if shelf { wallShelf(p, y: p.h * horizon * 0.62, rng: &rng) }
    let zone = CGRect(x: p.w * 0.06, y: p.h * horizon + 20, width: p.w * 0.88, height: p.h * 0.72 - p.h * horizon)
    benchProps(p, rng: &rng, exclude: exclude, zone: zone, count: props)
    return rng
}
