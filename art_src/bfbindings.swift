import Foundation
import CoreGraphics

func bindingLook(_ b: HistoricBinding) -> BookLook {
    let cover = Hue.of(b.cover)
    var kind: CoverKind = .leather
    var gilt = false
    var stations = 4
    var signatures = 8
    switch b.key {
    case "copticCodex": kind = .leather; stations = 4; signatures = 7
    case "ethiopian": kind = .wood; stations = 4; signatures = 6
    case "islamicFlap": kind = .leather; gilt = true
    case "carolingian", "romanesque": kind = .vellum
    case "gothicClasps": kind = .leather
    case "limpVellum": kind = .vellum
    case "girdleBook": kind = .leather
    case "chainedBook": kind = .leather
    case "fukuroToji", "stabBinding": kind = .paper
    case "butterfly", "whirlwind", "orihon": kind = .paper
    case "longStitchBinding": kind = .leather; stations = 4; signatures = 6
    case "frenchLinkBinding": kind = .cloth; stations = 6
    case "tightBack", "fullLeather", "hollowBack": kind = .leather; gilt = true
    case "bradel": kind = .paper
    case "publishersCloth", "libraryBuckram", "frenchGroove": kind = .cloth; gilt = true
    case "springback": kind = .leather
    case "quarterLeather", "halfLeather": kind = .paper
    case "secretBelgianBinding": kind = .cloth; stations = 4; signatures = 6
    case "dosADos": kind = .cloth
    case "perfectBinding": kind = .paper
    case "pamphletBinding": kind = .paper; stations = 3; signatures = 1
    default: break
    }
    return BookLook(cover: cover, kind: kind, look: b.look, structure: b.structure, signatures: signatures, stations: stations,
                    boardMM: kind == .wood ? 0.14 : 0.06, title: "", gilt: gilt)
}

func drawConcertina(_ p: Leaf, cx: Double, cy: Double, rng: inout Chip, cover: Hue) {
    let panels = 7
    let pw = 104.0, ph = 300.0
    var x = cx - pw * Double(panels) / 2
    let ground = [pt(x - 30, cy + ph * 0.5 + 40), pt(x + pw * Double(panels) + 40, cy + ph * 0.5 + 40), pt(x + pw * Double(panels) + 70, cy + ph * 0.5 + 70), pt(x - 10, cy + ph * 0.5 + 70)]
    castShadow(p, ground, dx: 6, dy: 8, steps: 5, alpha: 0.05)
    for k in 0..<panels {
        let mountain = k % 2 == 0
        let top = cy - ph * 0.5 + (mountain ? 0 : 22)
        let quad = [pt(x, top + 8), pt(x + pw, top - 8 + (mountain ? 14 : -14)), pt(x + pw + 12, top + ph - 8 + (mountain ? 14 : -14)), pt(x + 12, top + ph + 8)]
        let path = pathOf(quad)
        p.fillPath(path, mountain ? Pot.paper.lt(0.1) : Pot.paper.dk(0.14))
        paperFibres(p, path, base: Pot.paper, laid: true, count: 60, rng: &rng)
        linearInto(p, path, from: quad[0], to: quad[1], colours: mountain ? [Hue(r: 1, g: 1, b: 1, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.20)] : [Hue(r: 0, g: 0, b: 0, a: 0.22), Hue(r: 1, g: 1, b: 1, a: 0.05)], locations: [0, 1])
        for i in 0..<4 {
            let ly = top + 40 + Double(i) * 34
            pen(p, [pt(x + 14, ly + Double(i) * 0.5), pt(x + pw - 10, ly - 4)], weight: 1.0, colour: Pot.inkSoft.al(0.5), wobble: 0.6, taper: true, seed: rng.next())
        }
        penEdge(p, quad, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
        x += pw
    }
    let boardA = [pt(cx - pw * Double(panels) / 2 - 26, cy - ph * 0.5 - 4), pt(cx - pw * Double(panels) / 2 + 4, cy - ph * 0.5 - 10), pt(cx - pw * Double(panels) / 2 + 16, cy + ph * 0.5 + 6), pt(cx - pw * Double(panels) / 2 - 14, cy + ph * 0.5 + 12)]
    let look = BookLook(cover: cover, kind: .cloth, look: .concertina, structure: .accordion)
    coverMaterial(p, pathOf(boardA), look, light: p.light, rng: &rng)
    penEdge(p, boardA, weight: 1.4, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawWhirlwind(_ p: Leaf, cx: Double, cy: Double, rng: inout Chip, cover: Hue) {
    let roll = ringOf(cx: cx - 250, cy: cy + 30, rx: 46, ry: 46, steps: 40)
    let rollBody = [pt(cx - 250, cy - 16), pt(cx - 250, cy + 76), pt(cx + 170, cy + 76 - 30), pt(cx + 170, cy - 16 - 30)]
    castShadow(p, rollBody, dx: 8, dy: 14, steps: 6, alpha: 0.05)
    p.shape(rollBody, Pot.paper.dk(0.06))
    paperFibres(p, pathOf(rollBody), base: Pot.paper, laid: false, count: 200, rng: &rng)
    for k in 0..<9 {
        let x0 = cx - 180 + Double(k) * 40
        let leafPoly = [pt(x0, cy - 10 - Double(k) * 3), pt(x0 + 120 + Double(k) * 14, cy - 34 - Double(k) * 3), pt(x0 + 122 + Double(k) * 14, cy + 30 - Double(k) * 3), pt(x0 + 2, cy + 54 - Double(k) * 3)]
        let path = pathOf(leafPoly)
        p.fillPath(path, Pot.paper.lt(0.05 + Double(k) * 0.01))
        paperFibres(p, path, base: Pot.paper, laid: false, count: 30, rng: &rng)
        for i in 0..<5 {
            pen(p, [pt(x0 + 12 + Double(i) * 18, cy - 4 - Double(k) * 3 - Double(i) * 3.6), pt(x0 + 12 + Double(i) * 18, cy + 40 - Double(k) * 3 - Double(i) * 3.6)], weight: 0.9, colour: Pot.inkSoft.al(0.45), wobble: 0.5, taper: true, seed: rng.next())
        }
        penEdge(p, leafPoly, weight: 1.1, colour: Pot.ink.al(0.75), seed: rng.next())
    }
    p.shape(roll, Pot.paper.dk(0.04))
    radialInto(p, pathOf(roll), from: pt(cx - 268, cy + 12), inner: Pot.paper.lt(0.2), outer: Pot.paper.dk(0.4), radius: 70)
    for r in stride(from: 40.0, to: 6.0, by: -7.0) {
        p.hoop(cx - 250, cy + 30, r, 1.1, Pot.ink.al(0.35))
    }
    let rod = [pt(cx - 254, cy - 30), pt(cx - 246, cy - 30), pt(cx - 246, cy + 92), pt(cx - 254, cy + 92)]
    p.shape(rod, cover.dk(0.2))
    penEdge(p, roll, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
}

func drawButterfly(_ p: Leaf, cx: Double, cy: Double, rng: inout Chip, cover: Hue) {
    let spineX = cx
    let left = [pt(spineX, cy - 120), pt(spineX - 240, cy - 70), pt(spineX - 250, cy + 140), pt(spineX, cy + 100)]
    let right = [pt(spineX, cy - 120), pt(spineX + 240, cy - 70), pt(spineX + 250, cy + 140), pt(spineX, cy + 100)]
    castShadow(p, left + right.reversed(), dx: 10, dy: 14, steps: 6, alpha: 0.05)
    for (poly, isLeft) in [(left, true), (right, false)] {
        let path = pathOf(poly)
        p.fillPath(path, Pot.paper)
        paperFibres(p, path, base: Pot.paper, laid: false, count: 220, rng: &rng)
        linearInto(p, path, from: pt(spineX, cy), to: pt(spineX + (isLeft ? -120 : 120), cy), colours: [Hue(r: 0, g: 0, b: 0, a: 0.22), Hue(r: 0, g: 0, b: 0, a: 0.0)], locations: [0, 1])
        for col in 0..<6 {
            let x = spineX + (isLeft ? -40 : 40) + Double(col) * (isLeft ? -32 : 32)
            for row in 0..<7 {
                let y = cy - 60 + Double(row) * 22 + Double(col) * (isLeft ? 3 : -3) * 0.4
                p.box(x - 6, y, 12, 12, Pot.ink.al(rng.r(0.5, 0.85)))
            }
        }
        penEdge(p, poly, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
    }
    for k in 0..<7 {
        let y = cy - 112 + Double(k) * 34
        pen(p, [pt(spineX - 3, y), pt(spineX + 3, y + 30)], weight: 1.0, colour: Pot.ink.al(0.5), wobble: 0.3, taper: true, seed: rng.next())
    }
    pen(p, [pt(spineX, cy - 120), pt(spineX, cy + 100)], weight: 2.0, colour: Pot.ink.al(0.85), wobble: 0.4, taper: false, seed: rng.next())
    let wrapper = [pt(spineX - 262, cy + 150), pt(spineX + 262, cy + 150), pt(spineX + 272, cy + 172), pt(spineX - 252, cy + 172)]
    let look = BookLook(cover: cover, kind: .paper, look: .butterfly, structure: nil)
    coverMaterial(p, pathOf(wrapper), look, light: p.light, rng: &rng)
    penEdge(p, wrapper, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
}

func drawDosADos(_ p: Leaf, cx: Double, cy: Double, rng: inout Chip, look: BookLook) {
    var lookA = look
    lookA.look = .hollowBack
    lookA.gilt = true
    let poseA = BookPose.lying(cx: cx - 120, cy: cy + 30, scale: 1.0, width: 260, height: 400, thick: 76)
    paintBook(p, poseA, lookA, rng: &rng)
    var lookB = lookA
    lookB.cover = look.cover.dk(0.25)
    let poseB = BookPose(ox: Double(poseA.at(0, 260, 0).x), oy: Double(poseA.at(0, 260, 0).y), eH: poseA.eH, eW: poseA.eW, eT: poseA.eT, width: 260, height: 400, thick: 76)
    let stack = BookPose(ox: poseB.ox, oy: poseB.oy - 76, eH: poseB.eH, eW: poseB.eW, eT: poseB.eT, width: 260, height: 400, thick: 76)
    paintBook(p, stack, lookB, rng: &rng, shadow: false)
}

func drawPamphlet(_ p: Leaf, cx: Double, cy: Double, rng: inout Chip, cover: Hue) {
    let pose = BookPose.lying(cx: cx, cy: cy, scale: 1.0, width: 320, height: 440, thick: 12)
    var look = BookLook(cover: cover, kind: .paper, look: .pamphlet, structure: .pamphlet3, signatures: 1, stations: 3)
    look.boardMM = 0.0
    paintBook(p, pose, look, rng: &rng)
    for h in [0.12, 0.5, 0.88] {
        let q = pose.at(pose.height * h, 0, pose.thick * 0.5)
        p.dot(Double(q.x), Double(q.y), 2.4, Pot.ink.al(0.8))
    }
    pen(p, [pose.at(pose.height * 0.12, 0, 4.5), pose.at(pose.height * 0.88, 0, 4.5)], weight: 2.4, colour: Pot.threadRed, wobble: 0.2, taper: false, seed: rng.next())
    let tail = pose.at(pose.height * 0.5, 0, 4.5)
    pen(p, [tail, pt(Double(tail.x) + 18, Double(tail.y) + 26), pt(Double(tail.x) + 6, Double(tail.y) + 44)], weight: 2.2, colour: Pot.threadRed, wobble: 0.4, taper: true, seed: rng.next())
}

func leatherParts(_ p: Leaf, _ pose: BookPose, leather: Hue, corners: Bool, rng: inout Chip) {
    let strip = [pose.at(0, 0, 0), pose.at(pose.height, 0, 0), pose.at(pose.height, pose.width * 0.22, 0), pose.at(0, pose.width * 0.22, 0)]
    let look = BookLook(cover: leather, kind: .leather, look: .tapes, structure: nil)
    coverMaterial(p, pathOf(strip), look, light: p.light, rng: &rng)
    pen(p, [strip[3], strip[2]], weight: 1.3, colour: Pot.ink.al(0.75), wobble: 0.3, taper: false, seed: rng.next())
    let spine = pose.spineFace
    coverMaterial(p, pathOf(spine), look, light: p.light, rng: &rng)
    linearInto(p, pathOf(spine), from: pose.at(0, 0, 0), to: pose.at(0, 0, pose.thick), colours: [Hue(r: 1, g: 1, b: 1, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.34)], locations: [0, 0.4, 1])
    for k in 0..<5 {
        let h = pose.height * (0.14 + 0.72 * Double(k) / 4)
        pen(p, [pose.at(h, 0, 0), pose.at(h, 0, pose.thick)], weight: 4.4, colour: leather.lt(0.28), wobble: 0.2, taper: false, seed: rng.next())
        pen(p, [pose.at(h - 5, 0, 1.5), pose.at(h - 5, 0, pose.thick - 1.5)], weight: 1.1, colour: Pot.brassPale.al(0.85), wobble: 0.1, taper: true, seed: rng.next())
    }
    penEdge(p, spine, weight: 1.3, colour: Pot.ink.al(0.75), seed: rng.next())
    if corners {
        let c = pose.width * 0.22
        for h in [0.0, pose.height] {
            let sgn = h == 0 ? 1.0 : -1.0
            let tri = [pose.at(h, pose.width, 0), pose.at(h + sgn * c * 1.1, pose.width, 0), pose.at(h, pose.width - c, 0)]
            coverMaterial(p, pathOf(tri), look, light: p.light, rng: &rng)
            pen(p, [tri[1], tri[2]], weight: 1.2, colour: Pot.ink.al(0.7), wobble: 0.3, taper: false, seed: rng.next())
        }
    }
}

func drawStandingPlate(_ p: Leaf, _ b: HistoricBinding, look: BookLook, rng: inout Chip) {
    var bands = 5
    var label = ""
    var thick = 120.0
    var height = 520.0
    switch b.key {
    case "carolingian": bands = 2; thick = 150
    case "romanesque": bands = 3; thick = 170
    case "tightBack": bands = 5
    case "libraryBuckram": bands = 0; label = "823 W"
    case "springback": bands = 0; thick = 150; label = "LEDGER"
    case "hollowBack": bands = 4
    case "bradel": bands = 0; thick = 90
    default: break
    }
    let pose = StandPose(x: 330, y: 740, height: height, thick: thick, depth: 340, lean: 0.02)
    paintStandingBook(p, pose, look, rng: &rng, bands: bands, label: label)
    if b.key == "romanesque" {
        for h in [pose.height - 6.0, 6.0] {
            let tab = [pose.spine(h, 8), pose.spine(h, pose.thick - 8), pose.spine(h + (h > 100 ? 26 : -26), pose.thick - 12), pose.spine(h + (h > 100 ? 26 : -26), 12)]
            p.shape(tab, look.cover.dk(0.2))
            penEdge(p, tab, weight: 1.1, colour: Pot.ink.al(0.8), seed: rng.next())
        }
    }
    if b.key == "springback" {
        let hump = [pose.spine(0, -14), pose.spine(pose.height, -14), pose.spine(pose.height, pose.thick + 14), pose.spine(0, pose.thick + 14)]
        var lookH = look
        lookH.cover = look.cover.dk(0.1)
        coverMaterial(p, pathOf(hump), lookH, light: p.light, rng: &rng)
        linearInto(p, pathOf(hump), from: pose.spine(0, -14), to: pose.spine(0, pose.thick + 14), colours: [Hue(r: 0, g: 0, b: 0, a: 0.4), Hue(r: 1, g: 1, b: 1, a: 0.18), Hue(r: 0, g: 0, b: 0, a: 0.45)], locations: [0, 0.4, 1])
        penEdge(p, hump, weight: 1.4, colour: Pot.ink.al(0.85), seed: rng.next())
        let lab = [pose.spine(pose.height * 0.62, -8), pose.spine(pose.height * 0.62, pose.thick + 8), pose.spine(pose.height * 0.80, pose.thick + 8), pose.spine(pose.height * 0.80, -8)]
        p.shape(lab, Pot.threadRed.dk(0.2))
        penEdge(p, lab, weight: 0.9, colour: Pot.ink.al(0.6), seed: rng.next())
        let c = pose.spine(pose.height * 0.71, pose.thick / 2)
        letter(p, "LEDGER", at: Double(c.x), Double(c.y) + 6, size: 22, colour: Pot.brassPale, face: "Cochin-Bold", rotate: -.pi / 2)
    }
    if b.key == "bradel" {
        let strip = [pose.board(0, 0), pose.board(pose.height, 0), pose.board(pose.height, pose.depth * 0.14), pose.board(0, pose.depth * 0.14)]
        let cloth = BookLook(cover: Pot.indigo, kind: .cloth, look: .tapes, structure: nil)
        coverMaterial(p, pathOf(strip), cloth, light: p.light, rng: &rng)
        coverMaterial(p, pathOf(pose.spineFace), cloth, light: p.light, rng: &rng)
        penEdge(p, pose.spineFace, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
        pen(p, [strip[3], strip[2]], weight: 1.2, colour: Pot.ink.al(0.7), wobble: 0.3, taper: false, seed: rng.next())
    }
}

func drawBindingPlate(_ b: HistoricBinding, dir: String) -> CGImage? {
    let p = Leaf(1200, 900)
    var rng = benchScene(p, seed: hashOf("binding." + b.key), exclude: "", horizon: 0.36, props: 3)
    p.light = 2.34
    let cx = 600.0, cy = 420.0
    let look = bindingLook(b)
    switch b.look {
    case .concertina: drawConcertina(p, cx: cx, cy: cy, rng: &rng, cover: look.cover)
    case .whirlwind: drawWhirlwind(p, cx: cx, cy: cy, rng: &rng, cover: look.cover)
    case .butterfly: drawButterfly(p, cx: cx, cy: cy - 20, rng: &rng, cover: look.cover)
    case .dosados: drawDosADos(p, cx: cx, cy: cy, rng: &rng, look: look)
    case .pamphlet: drawPamphlet(p, cx: cx, cy: cy + 20, rng: &rng, cover: look.cover)
    case _ where ["carolingian", "romanesque", "tightBack", "libraryBuckram", "springback", "hollowBack", "bradel"].contains(b.key):
        drawStandingPlate(p, b, look: look, rng: &rng)
    default:
        var thick = 96.0
        var width = 330.0
        var height = 470.0
        switch b.look {
        case .exposedChain: thick = 110
        case .limp: thick = 66
        case .girdle: thick = 78; width = 220; height = 320
        case .stab, .pouch: thick = 44; width = 300; height = 430
        case .perfect: thick = 60; width = 230; height = 340
        case .springback: thick = 112; width = 360; height = 520
        case .flap: thick = 70
        default: break
        }
        let pose = BookPose.lying(cx: cx + (b.look == .girdle ? 90 : 0), cy: cy + 10, scale: 1.0, width: width, height: height, thick: thick)
        var drawLook = look
        if b.key == "frenchLinkBinding" { drawLook.look = .exposedLong; drawLook.kind = .bare; drawLook.structure = .frenchLink; drawLook.stations = 6; drawLook.signatures = 6 }
        paintBook(p, pose, drawLook, rng: &rng)
        if b.key == "quarterLeather" { leatherParts(p, pose, leather: Pot.walnut, corners: false, rng: &rng) }
        if b.key == "halfLeather" { leatherParts(p, pose, leather: Hue(r: 0.36, g: 0.18, b: 0.10), corners: true, rng: &rng) }
        if b.key == "fullLeather" {
            let c = pose.at(pose.height * 0.5, pose.width * 0.5, 0)
            let loz = [pose.at(pose.height * 0.5, pose.width * 0.30, 0), pose.at(pose.height * 0.62, pose.width * 0.5, 0), pose.at(pose.height * 0.5, pose.width * 0.70, 0), pose.at(pose.height * 0.38, pose.width * 0.5, 0)]
            for k in 0..<4 { pen(p, [loz[k], loz[(k + 1) % 4]], weight: 1.8, colour: Pot.brassPale.al(0.95), wobble: 0.2, taper: false, seed: rng.next()) }
            for k in 0..<4 { pen(p, [c, loz[k]], weight: 1.0, colour: Pot.brassPale.al(0.8), wobble: 0.2, taper: true, seed: rng.next()) }
            let inner = [pose.at(pose.height * 0.16, pose.width * 0.16, 0), pose.at(pose.height * 0.84, pose.width * 0.16, 0), pose.at(pose.height * 0.84, pose.width * 0.84, 0), pose.at(pose.height * 0.16, pose.width * 0.84, 0)]
            for k in 0..<4 { pen(p, [inner[k], inner[(k + 1) % 4]], weight: 1.4, colour: Pot.brassPale.al(0.9), wobble: 0.2, taper: false, seed: rng.next()) }
        }
        if b.key == "gothicClasps" {
            for (h, w) in [(pose.height * 0.20, pose.width * 0.20), (pose.height * 0.80, pose.width * 0.20), (pose.height * 0.20, pose.width * 0.80), (pose.height * 0.80, pose.width * 0.80), (pose.height * 0.5, pose.width * 0.5)] {
                let c = pose.at(h, w, 0)
                p.dot(Double(c.x) + 2, Double(c.y) + 3, 11, Hue(r: 0, g: 0, b: 0, a: 0.4))
                p.dot(Double(c.x), Double(c.y), 11, Pot.brass)
                radialInto(p, pathOf(ringOf(cx: Double(c.x), cy: Double(c.y), rx: 11, ry: 11, steps: 24)), from: pt(Double(c.x) - 4, Double(c.y) - 4), inner: Pot.brassPale, outer: Pot.brass.dk(0.5), radius: 16)
            }
        }
    }
    captionLabel(p, title: b.name, sub: "\(b.date). \(b.region)", y: 736, size: 38)
    p.writeJPG(dir, b.plate, quality: 0.86)
    return p.image()
}
