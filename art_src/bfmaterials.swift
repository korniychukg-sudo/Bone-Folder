import Foundation
import CoreGraphics

func roughRect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, rough: Double, rng: inout Chip) -> [CGPoint] {
    var out: [CGPoint] = []
    let step = 18.0
    var x = x0
    while x < x1 { out.append(pt(x, y0 + rng.signed() * rough)); x += step }
    var y = y0
    while y < y1 { out.append(pt(x1 + rng.signed() * rough, y)); y += step }
    x = x1
    while x > x0 { out.append(pt(x, y1 + rng.signed() * rough)); x -= step }
    y = y1
    while y > y0 { out.append(pt(x0 + rng.signed() * rough, y)); y -= step }
    return out
}

func paperTone(_ m: Material) -> Hue {
    let t = Hue.of(m.tone)
    let grey = (t.r + t.g + t.b) / 3
    return Hue(r: grey + (t.r - grey) * 2.2, g: grey + (t.g - grey) * 2.2, b: grey + (t.b - grey) * 2.2)
}

func paperSwatch(_ p: Leaf, _ m: Material, poly: [CGPoint], rng: inout Chip) {
    let base = paperTone(m)
    let path = pathOf(poly)
    let thin = ["kozo", "gampi", "mitsumata", "glassine", "newsprint"].contains(m.key)
    p.fillPath(path, thin ? base.al(m.key == "kozo" ? 0.55 : (m.key == "glassine" ? 0.35 : 0.72)) : base)
    let box = path.boundingBox
    switch m.key {
    case "kozo", "gampi", "mitsumata", "glassine":
        p.inside(path) {
            for _ in 0..<(m.key == "glassine" ? 40 : 900) {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                let a = rng.r(0, 6.283), l = rng.r(10, 60)
                let mid = pt(x + cos(a + 0.5) * l * 0.5, y + sin(a + 0.5) * l * 0.5)
                pen(p, [pt(x, y), mid, pt(x + cos(a) * l, y + sin(a) * l)], weight: rng.r(0.5, 1.4), colour: base.lt(0.6).al(rng.r(0.2, 0.6)), wobble: 0.6, taper: true, seed: rng.next())
            }
            if m.key == "glassine" {
                linearInto(p, path, from: pt(Double(box.minX), Double(box.minY)), to: pt(Double(box.maxX), Double(box.maxY)), colours: [Hue(r: 1, g: 1, b: 1, a: 0.35), Hue(r: 1, g: 1, b: 1, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.06)], locations: [0, 0.5, 1])
            }
        }
    case "marbled":
        p.inside(path) {
            let tones: [Hue] = [Pot.indigo, Pot.threadRed.dk(0.1), Pot.ochre, Pot.moss, Pot.paper]
            for k in 0..<160 {
                let y = Double(box.minY) + Double(k) * Double(box.height) / 160
                var pts: [CGPoint] = []
                var x = Double(box.minX) - 10
                while x < Double(box.maxX) + 10 {
                    let dev = sin(x * 0.045 + Double(k) * 0.3) * 9 + sin(x * 0.012 + Double(k) * 0.05) * 22 + cos(x * 0.09) * 3
                    pts.append(pt(x, y + dev)); x += 6
                }
                pen(p, pts, weight: rng.r(2.5, 5.5), colour: tones[k % tones.count].al(rng.r(0.5, 0.9)), wobble: 0.6, taper: false, seed: rng.next())
            }
            for _ in 0..<70 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                p.egg(x, y, rng.r(3, 9), rng.r(3, 9), tones[rng.i(0, 3)].al(0.7))
            }
        }
    case "pastePaper":
        p.fillPath(path, Pot.indigo.mix(Pot.paper, 0.35))
        p.inside(path) {
            var y = Double(box.minY) + 8
            var k = 0
            while y < Double(box.maxY) {
                var pts: [CGPoint] = []
                var x = Double(box.minX)
                while x < Double(box.maxX) { pts.append(pt(x, y + sin(x * 0.05 + Double(k)) * 6)); x += 8 }
                pen(p, pts, weight: 7, colour: Pot.indigo.dk(0.3).al(0.45), wobble: 0.4, taper: false, seed: rng.next())
                pen(p, shifted(pts, 0, 3), weight: 2, colour: Pot.paper.al(0.35), wobble: 0.4, taper: false, seed: rng.next())
                y += 16; k += 1
            }
            for _ in 0..<26 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                var arc: [CGPoint] = []
                var a = 0.0
                while a < 4.5 { arc.append(pt(x + cos(a) * 26, y + sin(a) * 26)); a += 0.3 }
                pen(p, arc, weight: 5, colour: Pot.paper.al(0.5), wobble: 0.5, taper: true, seed: rng.next())
            }
        }
    case "teaChest":
        brushedMetal(p, path, base: Hue(r: 0.72, g: 0.70, b: 0.66), axis: 0.3, light: p.light, rng: &rng)
        p.inside(path) {
            for _ in 0..<30 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                let poly = [pt(x, y), pt(x + rng.r(20, 60), y + rng.r(-10, 10)), pt(x + rng.r(10, 50), y + rng.r(10, 30))]
                p.shape(poly, Hue(r: 1, g: 1, b: 1, a: rng.r(0.1, 0.3)))
            }
        }
    default:
        paperFibres(p, path, base: base, laid: m.texture == .laid, count: Int(Double(box.width * box.height) / (m.texture == .kozo ? 300 : 700)), rng: &rng)
        if m.texture == .rag || m.key == "coldPressed" {
            grit(p, path, density: 0.012, sizeMin: 0.6, sizeMax: 1.6, colour: base.dk(0.3).al(0.5), seed: rng.next())
        }
        if m.key == "khadi" || m.key == "lokta" {
            p.inside(path) {
                for _ in 0..<30 {
                    let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                    p.egg(x, y, rng.r(10, 40), rng.r(6, 20), (rng.chance(0.5) ? base.dk(0.15) : base.lt(0.25)).al(0.25))
                }
            }
        }
        if m.key == "newsprint" {
            p.inside(path) {
                var lines: [CGPoint] = []
                var y = Double(box.minY) + 30
                while y < Double(box.maxY) - 20 {
                    var x = Double(box.minX) + 30
                    while x < Double(box.maxX) - 30 { let l = rng.r(8, 30); lines.append(pt(x, y)); lines.append(pt(x + l, y)); x += l + rng.r(4, 9) }
                    y += 9
                }
                batchSegments(p, lines, colour: Pot.ink.al(0.35), width: 2.0)
            }
        }
    }
    let lx = Double(box.minX) + Double(box.width) * 0.2, ly = Double(box.minY) + Double(box.height) * 0.2
    radialInto(p, path, from: pt(lx, ly), inner: Hue(r: 1, g: 1, b: 1, a: 0.12), outer: Hue(r: 0, g: 0, b: 0, a: 0.10), radius: Double(box.width) * 1.1)
    paperMarks(p, m, path: path, base: base, rng: &rng)
    if m.grain == .long {
        rules(p, path, angle: 0.02, spacing: 26, weight: 0.7, colour: base.dk(0.35).al(0.20), coverage: 0.6, seed: rng.next())
    } else {
        rules(p, path, angle: 1.57, spacing: 26, weight: 0.7, colour: base.dk(0.35).al(0.20), coverage: 0.6, seed: rng.next())
    }
}

func paperMarks(_ p: Leaf, _ m: Material, path: CGPath, base: Hue, rng: inout Chip) {
    let box = path.boundingBox
    let cx = Double(box.midX), cy = Double(box.midY)
    switch m.key {
    case "ragLaid", "laidWriting":
        p.inside(path) {
            var lines: [CGPoint] = []
            var y = Double(box.minY)
            while y < Double(box.maxY) { lines.append(pt(Double(box.minX), y)); lines.append(pt(Double(box.maxX), y)); y += 4.2 }
            batchSegments(p, lines, colour: base.dk(0.4).al(m.key == "ragLaid" ? 0.30 : 0.22), width: 0.9)
            var chains: [CGPoint] = []
            var x = Double(box.minX) + 30
            while x < Double(box.maxX) { chains.append(pt(x, Double(box.minY))); chains.append(pt(x, Double(box.maxY))); x += 68 }
            batchSegments(p, chains, colour: base.dk(0.45).al(0.4), width: 1.6)
            if m.key == "laidWriting" {
                letter(p, "BF", at: cx + 120, cy + 40, size: 90, colour: base.lt(0.5).al(0.7), face: "Cochin-Bold")
                letter(p, "BF", at: cx + 121, cy + 41, size: 90, colour: base.dk(0.2).al(0.2), face: "Cochin-Bold")
            }
        }
    case "ragWove", "textWove", "bookWove":
        if m.key == "bookWove" {
            for i in 0..<9 {
                let y = Double(box.minY) + 60 + Double(i) * 30
                pen(p, [pt(Double(box.minX) + 70, y), pt(Double(box.maxX) - 70 - Double(i % 3) * 40, y)], weight: 6, colour: Pot.ink.al(0.55), wobble: 0.3, taper: false, seed: rng.next())
            }
        } else if m.key == "textWove" {
            for i in 0..<12 {
                let y = Double(box.minY) + 50 + Double(i) * 24
                var x = Double(box.minX) + 60
                while x < Double(box.maxX) - 60 { let l = rng.r(14, 40); p.box(x, y, l, 4, Pot.ink.al(0.45)); x += l + 8 }
            }
        }
    case "mouldMade":
        p.inside(path) {
            var fuzz: [CGPoint] = []
            for q in resample(Array(path.boundingBox.width > 0 ? [pt(Double(box.minX), Double(box.minY)), pt(Double(box.maxX), Double(box.minY)), pt(Double(box.maxX), Double(box.maxY)), pt(Double(box.minX), Double(box.maxY)), pt(Double(box.minX), Double(box.minY))] : []), count: 160) {
                fuzz.append(q); fuzz.append(pt(Double(q.x) + rng.r(-9, 9), Double(q.y) + rng.r(-9, 9)))
            }
            batchSegments(p, fuzz, colour: base.dk(0.3).al(0.5), width: 1.2)
        }
        linearInto(p, path, from: pt(Double(box.minX), Double(box.minY)), to: pt(Double(box.minX), Double(box.maxY)), colours: [Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.12)], locations: [0, 1])
    case "hotPressed":
        linearInto(p, path, from: pt(Double(box.minX), Double(box.minY)), to: pt(Double(box.maxX), Double(box.maxY)), colours: [Hue(r: 1, g: 1, b: 1, a: 0.45), Hue(r: 1, g: 1, b: 1, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.08)], locations: [0, 0.4, 1])
        pen(p, [pt(cx - 200, cy + 60), pt(cx - 120, cy - 40), pt(cx - 40, cy + 30), pt(cx + 60, cy - 70), pt(cx + 180, cy + 40)], weight: 3.2, colour: Pot.ink.al(0.8), wobble: 0.4, taper: true, seed: rng.next())
    case "coldPressed":
        p.inside(path) {
            for _ in 0..<Int(Double(box.width * box.height) / 60) {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                p.egg(x, y, rng.r(2, 5), rng.r(1.5, 4), base.dk(0.22).al(0.35))
                p.egg(x - 1.5, y - 1.5, rng.r(1.5, 3.5), rng.r(1, 3), base.lt(0.5).al(0.4))
            }
        }
        wash(p, ringOf(cx: cx + 60, cy: cy, rx: 120, ry: 70, steps: 24), Pot.indigo, strength: 0.35, bleed: 12, seed: rng.next())
    case "khadi":
        p.inside(path) {
            for _ in 0..<40 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                pen(p, [pt(x, y), pt(x + rng.r(-14, 14), y + rng.r(-6, 6))], weight: rng.r(1.5, 3), colour: Pot.indigo.al(0.35), wobble: 0.5, taper: true, seed: rng.next())
                p.dot(x + 10, y + 4, rng.r(1, 2.5), Pot.threadRed.al(0.4))
            }
        }
    case "lokta":
        p.inside(path) {
            for _ in 0..<50 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                p.egg(x, y, rng.r(20, 70), rng.r(10, 30), (rng.chance(0.5) ? base.dk(0.25) : base.lt(0.3)).al(0.3))
            }
        }
    case "bamboo":
        p.inside(path) {
            var fibres: [CGPoint] = []
            for _ in 0..<600 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                fibres.append(pt(x, y)); fibres.append(pt(x + rng.r(10, 50), y + rng.r(-2, 2)))
            }
            batchSegments(p, fibres, colour: Pot.ochre.dk(0.2).al(0.30), width: 1.0)
        }
    case "hemp":
        p.inside(path) {
            var fibres: [CGPoint] = []
            for _ in 0..<500 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                let a = rng.r(-0.5, 0.5)
                fibres.append(pt(x, y)); fibres.append(pt(x + cos(a) * rng.r(15, 60), y + sin(a) * rng.r(15, 60)))
            }
            batchSegments(p, fibres, colour: Pot.moss.dk(0.3).al(0.30), width: 1.4)
        }
    case "vellum", "parchment":
        p.inside(path) {
            for _ in 0..<50 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                p.egg(x, y, rng.r(20, 60), rng.r(8, 22), (rng.chance(0.5) ? base.dk(0.22) : base.lt(0.35)).al(0.22))
            }
            var veins: [CGPoint] = []
            for _ in 0..<120 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                let a = rng.r(0, 6.283)
                veins.append(pt(x, y)); veins.append(pt(x + cos(a) * rng.r(10, 50), y + sin(a) * rng.r(4, 16)))
            }
            batchSegments(p, veins, colour: base.dk(0.4).al(0.22), width: 1.0)
            if m.key == "parchment" {
                for _ in 0..<300 {
                    let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                    p.dot(x, y, 1.2, base.dk(0.5).al(0.5))
                }
            }
        }
        let corner = [pt(Double(box.maxX), Double(box.maxY)), pt(Double(box.maxX) - 120, Double(box.maxY)), pt(Double(box.maxX) - 40, Double(box.maxY) - 100)]
        castShadow(p, corner, dx: -4, dy: -4, steps: 3, alpha: 0.1)
        p.shape(corner, base.lt(0.3))
        penEdge(p, corner, weight: 1.1, colour: Pot.ink.al(0.7), seed: rng.next())
    case "kraft":
        p.inside(path) {
            var fibres: [CGPoint] = []
            for _ in 0..<900 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                fibres.append(pt(x, y)); fibres.append(pt(x + rng.r(6, 26), y + rng.r(-1, 1)))
            }
            batchSegments(p, fibres, colour: base.dk(0.4).al(0.25), width: 1.0)
        }
    case "blotting":
        p.inside(path) {
            for _ in 0..<6 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                let blot = lumpy(cx: x, cy: y, rx: rng.r(18, 50), ry: rng.r(12, 36), rough: 0.35, steps: 22, seed: rng.next())
                p.shape(blot, Pot.indigo.al(0.35))
                p.shape(lumpy(cx: x, cy: y, rx: rng.r(10, 28), ry: rng.r(8, 20), rough: 0.3, steps: 16, seed: rng.next()), Pot.indigo.al(0.4))
            }
        }
    default: break
    }
}

func clothSwatch(_ p: Leaf, _ m: Material, poly: [CGPoint], rng: inout Chip) {
    let base = Hue.of(m.tone)
    let path = pathOf(poly)
    let box = path.boundingBox
    p.fillPath(path, base)
    let pitch: Double
    switch m.key {
    case "buckram": pitch = 5.0
    case "canvas": pitch = 6.5
    case "linen": pitch = 5.5
    case "silkCloth", "japaneseSilk", "rayon", "moire": pitch = 2.4
    case "velvet": pitch = 2.0
    case "oilcloth": pitch = 4.0
    case "leatherette": pitch = 3.0
    default: pitch = 3.6
    }
    let lx = Double(box.minX) + Double(box.width) * 0.2, ly = Double(box.minY) + Double(box.height) * 0.15
    radialInto(p, path, from: pt(lx, ly), inner: base.lt(0.25), outer: base.dk(0.28), radius: Double(box.width) * 1.2)
    if m.key == "leatherette" {
        leatherGrain(p, path, base: base, pebble: 2.2, count: Int(Double(box.width * box.height) / 40), rng: &rng)
        linearInto(p, path, from: pt(Double(box.minX), Double(box.minY)), to: pt(Double(box.maxX), Double(box.maxY)), colours: [Hue(r: 1, g: 1, b: 1, a: 0.18), Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.1)], locations: [0, 0.5, 1])
    } else if m.key == "velvet" {
        p.inside(path) {
            var pile: [CGPoint] = []
            for _ in 0..<Int(Double(box.width * box.height) / 18) {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                pile.append(pt(x, y)); pile.append(pt(x + rng.r(-1.5, 1.5), y + rng.r(-3, 3)))
            }
            batchSegments(p, pile, colour: base.lt(0.5).al(0.10), width: 1.0)
            let sweep = [pt(Double(box.minX), Double(box.minY) + Double(box.height) * 0.3), pt(Double(box.maxX), Double(box.minY) + Double(box.height) * 0.55), pt(Double(box.maxX), Double(box.minY) + Double(box.height) * 0.75), pt(Double(box.minX), Double(box.minY) + Double(box.height) * 0.5)]
            p.shape(sweep, base.lt(0.35).al(0.35))
            let sweep2 = [pt(Double(box.minX) + Double(box.width) * 0.5, Double(box.minY)), pt(Double(box.maxX), Double(box.minY)), pt(Double(box.maxX), Double(box.minY) + Double(box.height) * 0.25), pt(Double(box.minX) + Double(box.width) * 0.6, Double(box.minY) + Double(box.height) * 0.3)]
            p.shape(sweep2, base.dk(0.3).al(0.3))
        }
    } else {
        clothWeave(p, path, base: base, pitch: pitch, rng: &rng, sheen: m.key == "silkCloth" || m.key == "rayon" || m.key == "japaneseSilk" ? 0.9 : 0.1)
        if m.key == "moire" {
            p.inside(path) {
                for k in 0..<28 {
                    var pts: [CGPoint] = []
                    var y = Double(box.minY)
                    let x0 = Double(box.minX) + Double(k) * Double(box.width) / 28
                    while y < Double(box.maxY) { pts.append(pt(x0 + sin(y * 0.02 + Double(k) * 0.7) * 22 + sin(y * 0.07) * 5, y)); y += 8 }
                    pen(p, pts, weight: 9, colour: (k % 2 == 0 ? base.lt(0.4) : base.dk(0.3)).al(0.22), wobble: 0.3, taper: false, seed: rng.next())
                }
            }
        }
        if m.key == "oilcloth" {
            linearInto(p, path, from: pt(Double(box.minX), Double(box.minY)), to: pt(Double(box.maxX), Double(box.minY) + Double(box.height)), colours: [Hue(r: 1, g: 1, b: 1, a: 0.28), Hue(r: 1, g: 1, b: 1, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.12)], locations: [0, 0.45, 1])
        }
        if m.key == "silkCloth" || m.key == "japaneseSilk" || m.key == "rayon" {
            linearInto(p, path, from: pt(Double(box.minX), Double(box.minY) + Double(box.height) * 0.3), to: pt(Double(box.minX) + Double(box.width) * 0.6, Double(box.minY) + Double(box.height) * 0.9), colours: [Hue(r: 1, g: 1, b: 1, a: 0.0), Hue(r: 1, g: 1, b: 1, a: 0.30), Hue(r: 1, g: 1, b: 1, a: 0.0)], locations: [0.3, 0.5, 0.7])
        }
        if m.key == "japaneseSilk" {
            p.inside(path) {
                for _ in 0..<22 {
                    let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                    let flower = ringOf(cx: x, cy: y, rx: 9, ry: 9, steps: 5)
                    for q in flower { p.dot(Double(q.x), Double(q.y), 4.5, Pot.brassPale.al(0.55)) }
                    p.dot(x, y, 3, Pot.threadRed.al(0.6))
                }
            }
        }
    }
    p.inside(path) {
        var fray: [CGPoint] = []
        for q in poly {
            for _ in 0..<2 { fray.append(q); fray.append(pt(Double(q.x) + rng.r(-6, 6), Double(q.y) + rng.r(-6, 6))) }
        }
        batchSegments(p, fray, colour: base.lt(0.5).al(0.6), width: 1.0)
    }
}

func leatherSwatch(_ p: Leaf, _ m: Material, poly: [CGPoint], rng: inout Chip) {
    let base = Hue.of(m.tone)
    let path = pathOf(poly)
    let box = path.boundingBox
    p.fillPath(path, base)
    let lx = Double(box.minX) + Double(box.width) * 0.25, ly = Double(box.minY) + Double(box.height) * 0.2
    radialInto(p, path, from: pt(lx, ly), inner: base.lt(0.32), outer: base.dk(0.42), radius: Double(box.width) * 1.15)
    switch m.key {
    case "goatskin": leatherGrain(p, path, base: base, pebble: 4.2, count: Int(Double(box.width * box.height) / 60), rng: &rng)
    case "calfskin":
        leatherGrain(p, path, base: base, pebble: 1.3, count: Int(Double(box.width * box.height) / 90), rng: &rng)
        linearInto(p, path, from: pt(Double(box.minX), Double(box.minY)), to: pt(Double(box.maxX), Double(box.maxY)), colours: [Hue(r: 1, g: 1, b: 1, a: 0.22), Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.12)], locations: [0, 0.5, 1])
    case "pigskin":
        leatherGrain(p, path, base: base, pebble: 1.6, count: Int(Double(box.width * box.height) / 120), rng: &rng)
        p.inside(path) {
            for _ in 0..<Int(Double(box.width * box.height) / 700) {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                for k in 0..<3 { p.dot(x + Double(k) * 4 + rng.r(-1, 1), y + rng.r(-1.5, 1.5), 1.3, base.dk(0.6).al(0.7)) }
            }
        }
    case "sheepskin": leatherGrain(p, path, base: base, pebble: 3.0, count: Int(Double(box.width * box.height) / 80), rng: &rng)
    case "alumTawed", "vellumSkin":
        p.inside(path) {
            for _ in 0..<50 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                p.egg(x, y, rng.r(10, 50), rng.r(5, 20), (rng.chance(0.5) ? base.dk(0.15) : base.lt(0.3)).al(0.12))
            }
            var veins: [CGPoint] = []
            for _ in 0..<80 {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                let a = rng.r(0, 6.283)
                veins.append(pt(x, y)); veins.append(pt(x + cos(a) * rng.r(10, 50), y + sin(a) * rng.r(4, 16)))
            }
            batchSegments(p, veins, colour: base.dk(0.3).al(0.14), width: 1.0)
        }
        if m.key == "alumTawed" { grit(p, path, density: 0.01, sizeMin: 0.5, sizeMax: 1.2, colour: base.dk(0.4).al(0.4), seed: rng.next()) }
    case "suede":
        p.inside(path) {
            var nap: [CGPoint] = []
            for _ in 0..<Int(Double(box.width * box.height) / 14) {
                let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
                nap.append(pt(x, y)); nap.append(pt(x + rng.r(-2, 2), y + rng.r(-2, 2)))
            }
            batchSegments(p, nap, colour: base.lt(0.4).al(0.12), width: 1.0)
            let stroke = [pt(Double(box.minX) + Double(box.width) * 0.3, Double(box.minY)), pt(Double(box.minX) + Double(box.width) * 0.5, Double(box.minY)), pt(Double(box.minX) + Double(box.width) * 0.35, Double(box.maxY)), pt(Double(box.minX) + Double(box.width) * 0.15, Double(box.maxY))]
            p.shape(stroke, base.dk(0.25).al(0.4))
        }
    case "fishSkin":
        p.inside(path) {
            var row = 0
            var y = Double(box.minY) - 6
            while y < Double(box.maxY) + 6 {
                var x = Double(box.minX) - 6 + (row % 2 == 0 ? 0 : 7)
                while x < Double(box.maxX) + 6 {
                    var arc: [CGPoint] = []
                    var a = 0.2
                    while a < 2.95 { arc.append(pt(x + cos(a) * 7, y + sin(a) * 6)); a += 0.25 }
                    pen(p, arc, weight: 1.3, colour: base.dk(0.5).al(0.7), wobble: 0.2, taper: true, seed: rng.next())
                    pen(p, shifted(arc, 0, -1.5), weight: 0.8, colour: base.lt(0.5).al(0.6), wobble: 0.2, taper: true, seed: rng.next())
                    x += 14
                }
                y += 7; row += 1
            }
        }
    default: leatherGrain(p, path, base: base, pebble: 2.5, count: Int(Double(box.width * box.height) / 70), rng: &rng)
    }
    p.inside(path) {
        for _ in 0..<6 {
            let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
            var crease: [CGPoint] = [pt(x, y)]
            for k in 1...5 { crease.append(pt(x + Double(k) * rng.r(10, 30), y + rng.r(-10, 10))) }
            pen(p, crease, weight: 1.6, colour: base.dk(0.55).al(0.35), wobble: 0.6, taper: true, seed: rng.next())
        }
    }
}

func drawMaterialPlate(_ m: Material, dir: String) -> CGImage? {
    let p = Leaf(900, 600)
    var rng = Chip(hashOf("material." + m.key))
    plateGround(p, seed: rng.next(), tone: Pot.paperWarm, border: false)
    let benchPath = rectPath(-10, 300, p.w + 20, 320)
    p.fillPath(benchPath, Pot.walnut)
    linearInto(p, benchPath, from: pt(0, 300), to: pt(0, 600), colours: [Pot.walnut.lt(0.2), Pot.walnut.dk(0.25)], locations: [0, 1])
    woodGrain(p, benchPath, axis: 0.01, base: Pot.walnut, lines: 40, wave: 4, rng: &rng)
    pen(p, [pt(0, 302), pt(p.w, 298)], weight: 1.8, colour: Pot.ink.al(0.7), wobble: 0.5, taper: false, seed: rng.next())
    p.light = 2.34
    switch m.kind {
    case .thread:
        if let t = m.thread, t == .tape12 {
            var tape: [CGPoint] = []
            for k in 0...40 {
                let f = Double(k) / 40
                tape.append(pt(150 + f * 600, 270 + sin(f * 6.5) * 40 + f * 40))
            }
            let band = tape.map { pt(Double($0.x), Double($0.y) - 22) } + tape.reversed().map { pt(Double($0.x), Double($0.y) + 22) }
            castShadow(p, band, dx: 6, dy: 8, steps: 5, alpha: 0.06)
            let path = pathOf(band)
            p.fillPath(path, Hue.of(m.tone))
            clothWeave(p, path, base: Hue.of(m.tone), pitch: 3.0, rng: &rng)
            penEdge(p, band, weight: 1.1, colour: Pot.ink.al(0.75), seed: rng.next())
        } else {
            let tone = Hue.of(m.tone)
            let d = m.thread?.diameterMM ?? 0.5
            let k = (d - 0.30) / 0.42
            drawSpool(p, at: pt(280, 250), radius: 70 + 40 * k, thread: tone, rng: &rng, height: 120 + 60 * k)
            drawSkein(p, at: pt(620, 300), width: 240 + 120 * k, thread: tone, rng: &rng)
            drawNeedle(p, at: pt(560, 130), angle: -0.25, length: 200 + 120 * k, rng: &rng, thread: tone)
            let tag = [pt(150, 380), pt(300, 372), pt(304, 430), pt(154, 438)]
            p.shape(shifted(tag, 2, 3), Hue(r: 0, g: 0, b: 0, a: 0.25))
            p.shape(tag, Pot.paper)
            penEdge(p, tag, weight: 0.9, colour: Pot.ink.al(0.6), seed: rng.next())
            letter(p, m.name.replacingOccurrences(of: "Linen ", with: ""), at: 227, 415, size: 26, colour: Pot.ink, face: "Cochin-Bold")
        }
    case .board:
        let thick = 6 + m.boardMM * 14
        let poly = [pt(150, 130), pt(700, 110), pt(760, 330), pt(210, 350)]
        castShadow(p, shifted(poly, 0, thick), dx: 8, dy: 10, steps: 6, alpha: 0.06)
        let base = Hue.of(m.tone)
        extrudeSides(p, poly, dx: 0, dy: thick, light: p.light, base: base.dk(0.2), brushAngle: nil, rng: &rng, bevel: false)
        if m.key == "corrugated" {
            let side = [poly[3], poly[2], pt(Double(poly[2].x), Double(poly[2].y) + thick), pt(Double(poly[3].x), Double(poly[3].y) + thick)]
            p.inside(pathOf(side)) {
                var x = Double(poly[3].x)
                while x < Double(poly[2].x) {
                    p.hoop(x, Double(poly[3].y) + thick * 0.5, thick * 0.4, 1.6, base.dk(0.5).al(0.8))
                    x += thick * 0.8
                }
            }
        }
        let path = pathOf(poly)
        p.fillPath(path, base)
        radialInto(p, path, from: pt(250, 150), inner: base.lt(0.15), outer: base.dk(0.2), radius: 700)
        if m.key == "wood" {
            woodGrain(p, path, axis: 0.05, base: base, lines: 50, wave: 5, rng: &rng)
        } else {
            grit(p, path, density: m.key == "bristol" ? 0.004 : 0.03, sizeMin: 0.5, sizeMax: 1.6, colour: base.dk(0.5).al(0.5), seed: rng.next())
            paperFibres(p, path, base: base, laid: false, count: 300, rng: &rng)
        }
        penEdge(p, poly, weight: 1.4, colour: Pot.ink.al(0.85), seed: rng.next())
        pen(p, [pt(Double(poly[3].x), Double(poly[3].y) + thick), pt(Double(poly[2].x), Double(poly[2].y) + thick)], weight: 1.4, colour: Pot.ink.al(0.8), wobble: 0.3, taper: false, seed: rng.next())
        if m.kind == .board && m.boardMM > 0 && m.key != "wood" {
            letter(p, String(format: "%.1f mm", m.boardMM).replacingOccurrences(of: ".0 mm", with: " mm"), at: 600, 300, size: 46, colour: Pot.ink.al(0.55), face: "Cochin-Italic", rotate: -0.06)
            pen(p, [pt(520, 316), pt(690, 306)], weight: 1.6, colour: Pot.ink.al(0.45), wobble: 0.8, taper: true, seed: rng.next())
        }
        drawKnife(p, at: pt(760, 440), angle: -0.5, length: 220, rng: &rng)
    default:
        let poly = roughRect(120, 90, 780, 400, rough: m.kind == .paper && (m.key == "khadi" || m.key == "mouldMade" || m.key == "lokta") ? 6 : 1.5, rng: &rng)
        let lifted = poly.map { q -> CGPoint in
            let f = (Double(q.x) - 120) / 660
            return pt(Double(q.x), Double(q.y) - f * 30 + (Double(q.y) - 90) * 0.06 * f)
        }
        castShadow(p, lifted, dx: 10, dy: 14, steps: 8, alpha: 0.05)
        p.shape(shifted(lifted, 2, 4), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.3))
        switch m.kind {
        case .cloth: clothSwatch(p, m, poly: lifted, rng: &rng)
        case .leather: leatherSwatch(p, m, poly: lifted, rng: &rng)
        default: paperSwatch(p, m, poly: lifted, rng: &rng)
        }
        let curl = [lifted[0], lifted[1], pt(Double(lifted[1].x) - 30, Double(lifted[1].y) + 40), pt(Double(lifted[0].x) + 30, Double(lifted[0].y) + 40)]
        linearInto(p, pathOf(lifted), from: pt(400, 90), to: pt(400, 160), colours: [Hue(r: 1, g: 1, b: 1, a: 0.16), Hue(r: 0, g: 0, b: 0, a: 0)], locations: [0, 1])
        _ = curl
        rimLight(p, lifted, light: p.light, weight: 2.2, colour: Hue(r: 1, g: 0.98, b: 0.92, a: 0.5), dark: Hue(r: 0, g: 0, b: 0, a: 0.25), seed: rng.next())
        penEdge(p, lifted, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
        if m.kind == .paper && m.benchOK {
            drawBoneFolder(p, at: pt(700, 430), angle: -0.3, length: 190, rng: &rng)
        } else if m.kind == .cloth {
            drawKnife(p, at: pt(740, 450), angle: -0.4, length: 200, rng: &rng)
        } else if m.kind == .leather {
            drawPasteBrush(p, at: pt(760, 430), angle: -0.9, length: 170, rng: &rng)
        }
    }
    captionLabel(p, title: m.name, sub: m.spec, y: 470, size: 30)
    p.writeJPG(dir, m.plate, quality: 0.86)
    return p.image()
}
