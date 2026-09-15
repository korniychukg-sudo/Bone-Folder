import Foundation
import CoreGraphics

let labelCloths: [Hue] = [Pot.indigo, Pot.walnut, Pot.threadRed.dk(0.25), Pot.moss.dk(0.1), Pot.indigoDeep, Pot.sepia, Pot.ochre.dk(0.35), Hue(r: 0.28, g: 0.22, b: 0.30)]

func giltText(_ p: Leaf, _ text: String, at x: Double, _ y: Double, size: Double, face: String, rng: inout Chip) {
    letter(p, text, at: x + 1.5, y + 2, size: size, colour: Hue(r: 0, g: 0, b: 0, a: 0.5), face: face)
    letter(p, text, at: x, y, size: size, colour: Pot.brass.dk(0.15), face: face)
    letter(p, text, at: x - 0.8, y - 1.0, size: size, colour: Pot.brassPale, face: face)
    let w = letterWidth(text, size: size, face: face)
    for _ in 0..<Int(w / 12) {
        let gx = x - w / 2 + rng.d() * w, gy = y - size * rng.r(0.15, 0.7)
        p.dot(gx, gy, rng.r(0.6, 1.4), Hue(r: 1, g: 0.98, b: 0.85, a: rng.r(0.3, 0.8)))
    }
}

func blindText(_ p: Leaf, _ text: String, at x: Double, _ y: Double, size: Double, face: String, base: Hue) {
    letter(p, text, at: x + 2.2, y + 2.6, size: size, colour: base.lt(0.55).al(0.9), face: face)
    letter(p, text, at: x - 1.4, y - 1.6, size: size, colour: base.dk(0.75).al(0.95), face: face)
    letter(p, text, at: x, y, size: size, colour: base.dk(0.5), face: face)
}

func drawLabelInto(_ p: Leaf, _ t: BookTitle, index: Int, rng: inout Chip) {
    let w = p.w, h = p.h
    let cloth = labelCloths[index % labelCloths.count]
    let size = 44.0
    switch t.label {
    case .paperLabel:
        let bg = BookLook(cover: cloth, kind: .cloth, look: .tapes, structure: nil)
        coverMaterial(p, rectPath(0, 0, w, h), bg, light: p.light, rng: &rng)
        let label = roughRect(w * 0.12, h * 0.20, w * 0.88, h * 0.80, rough: 1.2, rng: &rng)
        castShadow(p, label, dx: 3, dy: 4, steps: 3, alpha: 0.12)
        let path = pathOf(label)
        p.fillPath(path, Pot.paper.lt(0.15))
        paperFibres(p, path, base: Pot.paper, laid: true, count: 60, rng: &rng)
        let inner = [pt(w * 0.15, h * 0.26), pt(w * 0.85, h * 0.26), pt(w * 0.85, h * 0.74), pt(w * 0.15, h * 0.74)]
        for k in 0..<4 { pen(p, [inner[k], inner[(k + 1) % 4]], weight: 1.6, colour: Pot.ink.al(0.8), wobble: 0.3, taper: false, seed: rng.next()) }
        let inner2 = [pt(w * 0.165, h * 0.29), pt(w * 0.835, h * 0.29), pt(w * 0.835, h * 0.71), pt(w * 0.165, h * 0.71)]
        for k in 0..<4 { pen(p, [inner2[k], inner2[(k + 1) % 4]], weight: 0.8, colour: Pot.ink.al(0.6), wobble: 0.3, taper: false, seed: rng.next()) }
        letter(p, t.title.uppercased(), at: w / 2, h * 0.53, size: size * 0.78, colour: Pot.ink, face: "Cochin-Bold", tracking: 3)
        letter(p, "bound by hand", at: w / 2, h * 0.65, size: 16, colour: Pot.inkSoft, face: "Cochin-Italic")
        penEdge(p, label, weight: 1.0, colour: Pot.ink.al(0.5), seed: rng.next())
    case .giltCloth:
        let bg = BookLook(cover: cloth, kind: .cloth, look: .tapes, structure: nil)
        coverMaterial(p, rectPath(0, 0, w, h), bg, light: p.light, rng: &rng)
        for y in [h * 0.22, h * 0.78] {
            pen(p, [pt(w * 0.12, y + 1.5), pt(w * 0.88, y + 1.5)], weight: 2.4, colour: Hue(r: 0, g: 0, b: 0, a: 0.4), wobble: 0.2, taper: true, seed: rng.next())
            pen(p, [pt(w * 0.12, y), pt(w * 0.88, y)], weight: 2.0, colour: Pot.brassPale, wobble: 0.2, taper: true, seed: rng.next())
        }
        giltText(p, t.title, at: w / 2, h * 0.55, size: size, face: "Cochin-Bold", rng: &rng)
        let orn = [pt(w * 0.5 - 14, h * 0.68), pt(w * 0.5, h * 0.64), pt(w * 0.5 + 14, h * 0.68), pt(w * 0.5, h * 0.72)]
        p.shape(shifted(orn, 1, 1.5), Hue(r: 0, g: 0, b: 0, a: 0.4))
        p.shape(orn, Pot.brassPale)
    case .blindStamp:
        let leather = BookLook(cover: cloth.mix(Pot.walnutLight, 0.55).lt(0.12), kind: .leather, look: .tapes, structure: nil)
        coverMaterial(p, rectPath(0, 0, w, h), leather, light: p.light, rng: &rng)
        let base = leather.cover
        let frame = [pt(w * 0.10, h * 0.18), pt(w * 0.90, h * 0.18), pt(w * 0.90, h * 0.82), pt(w * 0.10, h * 0.82)]
        for k in 0..<4 {
            pen(p, shifted([frame[k], frame[(k + 1) % 4]], -1, -1), weight: 1.6, colour: base.lt(0.4).al(0.7), wobble: 0.2, taper: false, seed: rng.next())
            pen(p, shifted([frame[k], frame[(k + 1) % 4]], 1, 1), weight: 1.8, colour: base.dk(0.6).al(0.8), wobble: 0.2, taper: false, seed: rng.next())
        }
        blindText(p, t.title.uppercased(), at: w / 2, h * 0.55, size: size * 0.74, face: "Cochin-Bold", base: base)
    case .handLettered:
        layPaper(p, seed: rng.next(), tone: Pot.paperWarm)
        washBand(p, from: h * 0.30, to: h * 0.72, Pot.linenPale, strength: 0.25, seed: rng.next())
        letter(p, t.title, at: w / 2 + 3, h * 0.52, size: size * 1.05, colour: Pot.ink.al(0.9), face: "Cochin-Italic", rotate: -0.03)
        var flourish: [CGPoint] = []
        let fw = min(w * 0.7, letterWidth(t.title, size: size * 1.05, face: "Cochin-Italic") + 40)
        for k in 0...24 {
            let f = Double(k) / 24
            flourish.append(pt(w / 2 - fw / 2 + f * fw, h * 0.62 + sin(f * .pi * 2) * 5 - f * 6))
        }
        pen(p, flourish, weight: 2.4, colour: Pot.ink.al(0.85), wobble: 0.5, taper: true, seed: rng.next())
        letter(p, "for \(t.client)", at: w / 2, h * 0.76, size: 18, colour: Pot.inkSoft, face: "Cochin-Italic")
        for _ in 0..<3 {
            let x = rng.r(w * 0.1, w * 0.9), y = rng.r(h * 0.1, h * 0.9)
            p.dot(x, y, rng.r(1, 2.2), Pot.ink.al(0.35))
        }
    }
    linearFree(p, pt(0, 0), pt(w, h), [Hue(r: 1, g: 1, b: 1, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.14)], [0, 0.5, 1])
}

func drawLabelPlate(_ t: BookTitle, dir: String) -> CGImage? {
    let p = Leaf(600, 360)
    var rng = Chip(hashOf("label." + t.key))
    p.fillAll(Pot.paper)
    p.flipDown()
    p.light = 2.34
    let index = Register.titles.firstIndex { $0.key == t.key } ?? 0
    drawLabelInto(p, t, index: index, rng: &rng)
    p.writeJPG(dir, t.plate, quality: 0.86)
    return p.image()
}
