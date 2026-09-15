import Foundation
import CoreGraphics

struct HourTone {
    var sky: Hue
    var skyLow: Hue
    var wall: Hue
    var bench: Hue
    var shaft: Double
    var lamp: Double
    var warm: Double
}

let hourTones: [HourTone] = [
    HourTone(sky: Hue(r: 0.08, g: 0.10, b: 0.18), skyLow: Hue(r: 0.12, g: 0.13, b: 0.20), wall: Hue(r: 0.30, g: 0.26, b: 0.22), bench: Pot.walnut.dk(0.45), shaft: 0.0, lamp: 1.0, warm: 0.9),
    HourTone(sky: Hue(r: 0.55, g: 0.50, b: 0.60), skyLow: Hue(r: 0.90, g: 0.66, b: 0.50), wall: Hue(r: 0.66, g: 0.58, b: 0.50), bench: Pot.walnut.dk(0.18), shaft: 0.30, lamp: 0.35, warm: 0.6),
    HourTone(sky: Hue(r: 0.66, g: 0.76, b: 0.84), skyLow: Hue(r: 0.86, g: 0.88, b: 0.84), wall: Hue(r: 0.86, g: 0.80, b: 0.70), bench: Pot.walnut, shaft: 0.75, lamp: 0.0, warm: 0.2),
    HourTone(sky: Hue(r: 0.60, g: 0.74, b: 0.88), skyLow: Hue(r: 0.88, g: 0.92, b: 0.94), wall: Hue(r: 0.93, g: 0.88, b: 0.78), bench: Pot.walnut.lt(0.08), shaft: 0.95, lamp: 0.0, warm: 0.1),
    HourTone(sky: Hue(r: 0.70, g: 0.74, b: 0.78), skyLow: Hue(r: 0.94, g: 0.86, b: 0.72), wall: Hue(r: 0.90, g: 0.82, b: 0.68), bench: Pot.walnut.lt(0.04), shaft: 0.70, lamp: 0.0, warm: 0.35),
    HourTone(sky: Hue(r: 0.46, g: 0.36, b: 0.44), skyLow: Hue(r: 0.92, g: 0.56, b: 0.32), wall: Hue(r: 0.68, g: 0.52, b: 0.40), bench: Pot.walnut.dk(0.12), shaft: 0.35, lamp: 0.55, warm: 0.8),
    HourTone(sky: Hue(r: 0.14, g: 0.15, b: 0.24), skyLow: Hue(r: 0.20, g: 0.18, b: 0.26), wall: Hue(r: 0.42, g: 0.34, b: 0.28), bench: Pot.walnut.dk(0.35), shaft: 0.05, lamp: 1.0, warm: 0.9)
]

func drawKettle(_ p: Leaf, at c: CGPoint, size: Double, rng: inout Chip, copper: Hue = Hue(r: 0.72, g: 0.42, b: 0.26)) {
    let cx = Double(c.x), cy = Double(c.y)
    let body = ringOf(cx: cx, cy: cy, rx: size * 0.5, ry: size * 0.38, steps: 40)
    propShadow(p, body.map { pt(Double($0.x), Double($0.y) + size * 0.1) }, &rng)
    p.shape(body, copper)
    radialInto(p, pathOf(body), from: pt(cx - size * 0.2, cy - size * 0.2), inner: copper.lt(0.45), outer: copper.dk(0.5), radius: size * 0.7)
    streaks(p, pathOf(body), count: 500, angle: 0.0, lenMin: 4, lenMax: 20, light: Hue(r: 1, g: 0.9, b: 0.8), dark: Hue(r: 0.2, g: 0.08, b: 0.02), alphaMin: 0.04, alphaMax: 0.14, weightMax: 1.2, rng: &rng)
    let lid = ringOf(cx: cx, cy: cy - size * 0.36, rx: size * 0.26, ry: size * 0.09, steps: 30)
    p.shape(lid, copper.lt(0.1))
    penEdge(p, lid, weight: 1.1, colour: Pot.ink.al(0.8), seed: rng.next())
    p.dot(cx, cy - size * 0.44, size * 0.04, Pot.walnutDark)
    let spout = [pt(cx + size * 0.42, cy - size * 0.05), pt(cx + size * 0.66, cy - size * 0.38), pt(cx + size * 0.72, cy - size * 0.34), pt(cx + size * 0.50, cy + size * 0.06)]
    p.shape(spout, copper.dk(0.1))
    penEdge(p, spout, weight: 1.1, colour: Pot.ink.al(0.8), seed: rng.next())
    var handle: [CGPoint] = []
    for k in 0...20 {
        let a = .pi + Double(k) / 20 * .pi
        handle.append(pt(cx + cos(a) * size * 0.36, cy - size * 0.30 + sin(a) * size * 0.34))
    }
    pen(p, handle, weight: size * 0.045, colour: Pot.walnutDark, wobble: 0.2, taper: false, seed: rng.next())
    pen(p, shifted(handle, -1, -1.5), weight: size * 0.012, colour: Pot.walnutLight.lt(0.3).al(0.7), wobble: 0.2, taper: true, seed: rng.next())
    penEdge(p, body, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
}

func drawLamp(_ p: Leaf, at c: CGPoint, size: Double, power: Double, rng: inout Chip) {
    let cx = Double(c.x), cy = Double(c.y)
    if power > 0.05 {
        softGlowAt(p, cx: cx, cy: cy - size * 0.5, radius: size * 3.2, colour: Pot.lamp, strength: 0.32 * power)
    }
    let base = ringOf(cx: cx, cy: cy, rx: size * 0.32, ry: size * 0.12, steps: 30)
    propShadow(p, base, &rng)
    p.shape(base, Pot.brass.dk(0.2))
    radialInto(p, pathOf(base), from: pt(cx - size * 0.1, cy - size * 0.05), inner: Pot.brassPale, outer: Pot.brass.dk(0.5), radius: size * 0.4)
    penEdge(p, base, weight: 1.1, colour: Pot.ink.al(0.8), seed: rng.next())
    let stem = [pt(cx - size * 0.05, cy - size * 0.02), pt(cx + size * 0.05, cy - size * 0.02), pt(cx + size * 0.04, cy - size * 0.36), pt(cx - size * 0.04, cy - size * 0.36)]
    p.shape(stem, Pot.brass)
    linearInto(p, pathOf(stem), from: pt(cx - size * 0.05, cy), to: pt(cx + size * 0.05, cy), colours: [Pot.brass.dk(0.5), Pot.brassPale, Pot.brass.dk(0.4)], locations: [0, 0.4, 1])
    let font = ringOf(cx: cx, cy: cy - size * 0.46, rx: size * 0.2, ry: size * 0.14, steps: 30)
    p.shape(font, Pot.brass.lt(0.05))
    radialInto(p, pathOf(font), from: pt(cx - size * 0.08, cy - size * 0.52), inner: Pot.brassPale, outer: Pot.brass.dk(0.5), radius: size * 0.3)
    penEdge(p, font, weight: 1.1, colour: Pot.ink.al(0.8), seed: rng.next())
    var chimney: [CGPoint] = []
    for k in 0...12 {
        let t = Double(k) / 12
        let r = size * (0.11 + 0.05 * sin(t * .pi) - t * 0.03)
        chimney.append(pt(cx + r, cy - size * 0.58 - t * size * 0.55))
    }
    for k in stride(from: 12, through: 0, by: -1) {
        let t = Double(k) / 12
        let r = size * (0.11 + 0.05 * sin(t * .pi) - t * 0.03)
        chimney.append(pt(cx - r, cy - size * 0.58 - t * size * 0.55))
    }
    let glass = Hue(r: 0.9, g: 0.92, b: 0.92)
    p.shape(chimney, glass.al(0.28))
    if power > 0.05 {
        let flame = [pt(cx, cy - size * 0.62), pt(cx + size * 0.05, cy - size * 0.74), pt(cx, cy - size * 0.98), pt(cx - size * 0.05, cy - size * 0.74)]
        p.shape(flame, Pot.lamp.al(0.95 * power))
        p.shape(shifted(flame, 0, 4).map { pt(Double($0.x), Double($0.y) * 1.0) }, Hue(r: 1, g: 0.97, b: 0.85, a: 0.7 * power))
        softGlowAt(p, cx: cx, cy: cy - size * 0.78, radius: size * 0.6, colour: Pot.lamp, strength: 0.7 * power)
    }
    penEdge(p, chimney, weight: 1.0, colour: Pot.ink.al(0.55), seed: rng.next())
    pen(p, [pt(cx - size * 0.06, cy - size * 0.62), pt(cx - size * 0.04, cy - size * 1.05)], weight: 1.2, colour: Hue(r: 1, g: 1, b: 1, a: 0.6), wobble: 0.2, taper: true, seed: rng.next())
}

func drawWindow(_ p: Leaf, rect: CGRect, tone: HourTone, rng: inout Chip) {
    let x0 = Double(rect.minX), y0 = Double(rect.minY), x1 = Double(rect.maxX), y1 = Double(rect.maxY)
    let frameOut = rectPath(x0 - 22, y0 - 22, x1 - x0 + 44, y1 - y0 + 44)
    p.fillPath(frameOut, Pot.paper.dk(0.08).mix(tone.wall, 0.4))
    let glass = rectPath(x0, y0, x1 - x0, y1 - y0)
    linearInto(p, glass, from: pt(x0, y0), to: pt(x0, y1), colours: [tone.sky, tone.skyLow], locations: [0, 1])
    p.inside(glass) {
        for _ in 0..<12 {
            let x = rng.r(x0, x1), y = rng.r(y0, y1)
            p.egg(x, y, rng.r(20, 60), rng.r(6, 16), tone.skyLow.lt(0.2).al(0.14))
        }
        let sill = y1 - (y1 - y0) * 0.22
        let roofs = [pt(x0, y1), pt(x0, sill + 20), pt(x0 + 60, sill), pt(x0 + 60, sill - 30), pt(x0 + 110, sill - 10), pt(x0 + 150, sill + 10), pt(x0 + 200, sill - 24), pt(x0 + 240, sill + 6), pt(x1, sill + 14), pt(x1, y1)]
        p.shape(roofs, tone.sky.dk(0.55).mix(tone.skyLow, 0.2).al(0.75))
        linearInto(p, glass, from: pt(x0, y0), to: pt(x1, y1), colours: [Hue(r: 1, g: 1, b: 1, a: 0.16), Hue(r: 1, g: 1, b: 1, a: 0.0), Hue(r: 1, g: 1, b: 1, a: 0.08)], locations: [0, 0.5, 1])
    }
    let mullion = Pot.paper.dk(0.3).mix(tone.wall, 0.3)
    for k in 1..<3 {
        let x = x0 + (x1 - x0) * Double(k) / 3
        p.box(x - 5, y0, 10, y1 - y0, mullion)
    }
    for k in 1..<4 {
        let y = y0 + (y1 - y0) * Double(k) / 4
        p.box(x0, y - 5, x1 - x0, 10, mullion)
    }
    let frame = [pt(x0 - 22, y0 - 22), pt(x1 + 22, y0 - 22), pt(x1 + 22, y1 + 22), pt(x0 - 22, y1 + 22)]
    penEdge(p, frame, weight: 1.6, colour: Pot.ink.al(0.8), seed: rng.next())
    penEdge(p, [pt(x0, y0), pt(x1, y0), pt(x1, y1), pt(x0, y1)], weight: 1.4, colour: Pot.ink.al(0.8), seed: rng.next())
    let sillBoard = [pt(x0 - 40, y1 + 22), pt(x1 + 40, y1 + 22), pt(x1 + 40, y1 + 40), pt(x0 - 40, y1 + 40)]
    p.shape(sillBoard, Pot.paper.dk(0.15).mix(tone.wall, 0.4))
    penEdge(p, sillBoard, weight: 1.3, colour: Pot.ink.al(0.8), seed: rng.next())
}

func drawBinderyScene(_ p: Leaf, hour index: Int, rng: inout Chip, pressBook: BookLook?) {
    let tone = hourTones[index]
    let w = p.w, h = p.h
    p.fillAll(tone.wall)
    p.flipDown()
    p.light = 2.34
    linearFree(p, pt(0, 0), pt(0, h * 0.62), [tone.wall.lt(0.10), tone.wall.dk(0.12)], [0, 1])
    let wallPath = rectPath(0, 0, w, h * 0.62)
    paperFibres(p, wallPath, base: tone.wall, laid: false, count: 500, rng: &rng)
    let win = CGRect(x: w * 0.07, y: h * 0.05, width: w * 0.26, height: h * 0.50)
    drawWindow(p, rect: win, tone: tone, rng: &rng)
    wallShelf(p, y: h * 0.30, rng: &rng, haze: 0.25 + (1 - tone.shaft) * 0.3, fromX: w * 0.40)
    let benchY = h * 0.62
    let benchPath = pathOf([pt(-10, benchY), pt(w + 10, benchY - 6), pt(w + 10, h + 10), pt(-10, h + 10)])
    p.fillPath(benchPath, tone.bench)
    linearInto(p, benchPath, from: pt(0, benchY), to: pt(0, h), colours: [tone.bench.lt(0.18), tone.bench, tone.bench.dk(0.30)], locations: [0, 0.3, 1])
    woodGrain(p, benchPath, axis: 0.01, base: tone.bench, lines: 70, wave: 6, rng: &rng)
    pen(p, [pt(0, benchY), pt(w, benchY - 6)], weight: 2.2, colour: Pot.ink.al(0.75), wobble: 0.6, taper: false, seed: rng.next())
    let apron = [pt(0, benchY + 4), pt(w, benchY - 2), pt(w, benchY + 30), pt(0, benchY + 36)]
    p.shape(apron, tone.bench.lt(0.25))
    pen(p, [pt(0, benchY + 36), pt(w, benchY + 30)], weight: 1.6, colour: Pot.ink.al(0.6), wobble: 0.5, taper: false, seed: rng.next())
    if tone.shaft > 0.05 {
        let shaft = [pt(Double(win.minX), Double(win.minY) + 20), pt(Double(win.maxX), Double(win.minY)), pt(Double(win.maxX) + w * 0.42, h + 10), pt(Double(win.minX) + w * 0.16, h + 10)]
        linearInto(p, pathOf(shaft), from: pt(Double(win.midX), Double(win.minY)), to: pt(Double(win.midX) + w * 0.3, h), colours: [Hue(r: 1, g: 0.96, b: 0.84, a: 0.30 * tone.shaft), Hue(r: 1, g: 0.96, b: 0.84, a: 0.04 * tone.shaft)], locations: [0, 1])
    }
    drawPress(p, at: pt(w * 0.80, benchY + 10), width: w * 0.24, rng: &rng, book: pressBook, open: pressBook == nil ? 0.5 : 0.22)
    drawPastePot(p, at: pt(w * 0.43, benchY + 40), radius: 46, rng: &rng)
    drawKettle(p, at: pt(w * 0.57, benchY + 42), size: 110, rng: &rng)
    drawSpool(p, at: pt(w * 0.24, benchY + 46), radius: 22, thread: Pot.linen, rng: &rng)
    drawSpool(p, at: pt(w * 0.30, benchY + 54), radius: 20, thread: Pot.threadRed, rng: &rng)
    drawSpool(p, at: pt(w * 0.27, benchY + 76), radius: 18, thread: Pot.indigo, rng: &rng)
    let sheet = sheetPose(cx: w * 0.14, cy: benchY + 120, w: 220, h: 150)
    flatSheet(p, sheet, tone: Pot.paper.lt(0.05), rng: &rng)
    drawBoneFolder(p, at: pt(w * 0.15, benchY + 120), angle: -0.25, length: 170, rng: &rng)
    drawAwl(p, at: pt(w * 0.40, benchY + 150), angle: 0.35, length: 150, rng: &rng)
    drawLamp(p, at: pt(w * 0.94, benchY + 30), size: 110, power: tone.lamp, rng: &rng)
    if tone.lamp > 0.05 {
        radialFree(p, w * 0.94, benchY - 40, 0, w * 0.5, [Pot.lamp.al(0.22 * tone.lamp), Pot.lamp.al(0.0)], [0, 1])
    }
    radialFree(p, w * 0.45, h * 0.45, w * 0.3, w * 0.95, [Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.30 + 0.25 * (1 - tone.shaft))], [0, 1], extend: true)
}

func drawHourPlate(_ index: Int, dir: String) -> CGImage? {
    let p = Leaf(1200, 820)
    var rng = Chip(hashOf("hour.\(index)"))
    let book = BookLook(cover: [Pot.indigo, Pot.threadRed.dk(0.2), Pot.moss, Pot.walnut][index % 4], kind: .cloth, look: .hollowBack, structure: .kettleTapes)
    drawBinderyScene(p, hour: index, rng: &rng, pressBook: book)
    p.writeJPG(dir, "hr_\(index)", quality: 0.86)
    return p.image()
}

func drawOnboardPlate(_ index: Int, dir: String) -> CGImage? {
    let p = Leaf(1200, 800)
    var rng = benchScene(p, seed: hashOf("onboard.\(index)"), exclude: "", horizon: 0.34, props: 2)
    p.light = 2.34
    switch index {
    case 0:
        let pose = BookPose.lying(cx: 600, cy: 430, scale: 1.0, width: 330, height: 470, thick: 100)
        paintBook(p, pose, BookLook(cover: Pot.indigo, kind: .cloth, look: .hollowBack, structure: .kettleTapes, gilt: true), rng: &rng)
        drawBoneFolder(p, at: pt(300, 640), angle: -0.3, length: 260, rng: &rng)
    case 1:
        let sheet = sheetPose(cx: 560, cy: 420, w: 700, h: 400)
        flatSheet(p, sheet, tone: Pot.paper.lt(0.12), rng: &rng)
        let map = Imposer.map(.quarto)
        for r in 0..<2 { for c in 0..<2 {
            let page = map.frontAt(r, c)
            let cx = 560 - 175 + Double(c) * 350 + 60 * Double(1 - r), cy = 420 + 100 - Double(r) * 200
            letter(p, "\(page.number)", at: cx, cy, size: 80, colour: Pot.ink.al(0.8), face: "Cochin-Bold", rotate: page.turn == 2 ? .pi : 0)
        } }
        drawBoneFolder(p, at: pt(920, 600), angle: -0.4, length: 260, rng: &rng)
    case 2:
        drawSewingFrame(p, at: pt(600, 400), width: 700, rng: &rng, tapes: 2, block: BookLook(cover: Pot.paper, kind: .bare, look: .tapes, structure: .kettleTapes, signatures: 5, stations: 6))
        drawNeedle(p, at: pt(300, 560), angle: -0.5, length: 220, rng: &rng, thread: Pot.threadRed)
    default:
        drawPress(p, at: pt(600, 420), width: 520, rng: &rng, book: BookLook(cover: Pot.threadRed.dk(0.2), kind: .cloth, look: .hollowBack, structure: .kettleTapes), open: 0.22)
    }
    p.writeJPG(dir, "ob_\(index)", quality: 0.86)
    return p.image()
}

let decorKeys: [String] = ["shelfWood", "shelfBack", "endMarbled", "endPaste", "headband", "clothBolt", "spools", "pastePot", "pressEmpty", "benchTop"]

func drawDecorPlate(_ index: Int, dir: String) -> CGImage? {
    let key = decorKeys[index]
    var rng = Chip(hashOf("decor." + key))
    let p: Leaf
    switch key {
    case "shelfWood":
        p = Leaf(1200, 300)
        p.fillAll(Pot.walnut)
        p.flipDown()
        let path = rectPath(0, 0, 1200, 300)
        linearInto(p, path, from: pt(0, 0), to: pt(0, 300), colours: [Pot.walnut.lt(0.25), Pot.walnut.lt(0.05), Pot.walnut.dk(0.25)], locations: [0, 0.5, 1])
        woodGrain(p, path, axis: 0.0, base: Pot.walnut, lines: 60, wave: 5, rng: &rng)
        pen(p, [pt(0, 4), pt(1200, 4)], weight: 2, colour: Pot.ink.al(0.6), wobble: 0.4, taper: false, seed: rng.next())
    case "shelfBack":
        p = Leaf(1200, 600)
        p.fillAll(Pot.walnutDark)
        p.flipDown()
        let path = rectPath(0, 0, 1200, 600)
        linearInto(p, path, from: pt(0, 0), to: pt(0, 600), colours: [Pot.walnutDark.lt(0.12), Pot.walnutDark.dk(0.1), Pot.walnutDark.dk(0.35)], locations: [0, 0.6, 1])
        woodGrain(p, path, axis: 1.57, base: Pot.walnutDark.lt(0.05), lines: 50, wave: 4, rng: &rng)
        for x in stride(from: 0.0, through: 1200, by: 240) {
            pen(p, [pt(x, 0), pt(x + 3, 600)], weight: 2.4, colour: Pot.ink.al(0.6), wobble: 0.5, taper: false, seed: rng.next())
        }
    case "endMarbled":
        p = Leaf(900, 600)
        p.fillAll(Pot.paper)
        p.flipDown()
        paperSwatch(p, Materials.find("marbled"), poly: [pt(0, 0), pt(900, 0), pt(900, 600), pt(0, 600)], rng: &rng)
    case "endPaste":
        p = Leaf(900, 600)
        p.fillAll(Pot.paper)
        p.flipDown()
        paperSwatch(p, Materials.find("pastePaper"), poly: [pt(0, 0), pt(900, 0), pt(900, 600), pt(0, 600)], rng: &rng)
    case "headband":
        p = Leaf(900, 300)
        p.fillAll(Pot.paper)
        p.flipDown()
        plateGround(p, seed: rng.next(), tone: Pot.paperWarm, border: false)
        let pairs: [(Hue, Hue)] = [(Pot.threadRed, Pot.paper), (Pot.indigo, Pot.brassPale), (Pot.moss, Pot.paper), (Pot.ochre, Pot.indigoDeep)]
        for (k, pair) in pairs.enumerated() {
            let y = 60 + Double(k) * 60
            for b in 0..<26 {
                let x = 80 + Double(b) * 28
                let bead = ringOf(cx: x, cy: y, rx: 13, ry: 16, steps: 20)
                p.shape(shifted(bead, 2, 3), Hue(r: 0, g: 0, b: 0, a: 0.3))
                let tone = b % 2 == 0 ? pair.0 : pair.1
                p.shape(bead, tone)
                radialInto(p, pathOf(bead), from: pt(x - 5, y - 6), inner: tone.lt(0.45), outer: tone.dk(0.35), radius: 22)
                for s in 0..<5 {
                    pen(p, [pt(x - 12 + Double(s) * 6, y - 16), pt(x - 10 + Double(s) * 6, y + 16)], weight: 1.0, colour: tone.dk(0.5).al(0.4), wobble: 0.2, taper: false, seed: rng.next())
                }
                penEdge(p, bead, weight: 0.9, colour: Pot.ink.al(0.6), seed: rng.next())
            }
        }
    case "clothBolt":
        p = Leaf(1200, 800)
        _ = benchScene(p, seed: rng.next(), exclude: "", horizon: 0.30, props: 1)
        for (k, tone) in [Pot.indigo, Pot.threadRed.dk(0.2), Pot.moss, Pot.ochre.dk(0.2), Pot.linen].enumerated() {
            let cx = 200 + Double(k) * 210, cy = 470 + Double(k % 2) * 40
            let roll = [pt(cx - 90, cy - 70), pt(cx + 90, cy - 90), pt(cx + 90, cy + 90), pt(cx - 90, cy + 110)]
            propShadow(p, roll, &rng)
            let look = BookLook(cover: tone, kind: .cloth, look: .tapes, structure: nil)
            coverMaterial(p, pathOf(roll), look, light: p.light, rng: &rng)
            linearInto(p, pathOf(roll), from: pt(cx - 90, cy), to: pt(cx + 90, cy), colours: [tone.dk(0.5), tone.lt(0.2), tone.dk(0.1), tone.dk(0.55)], locations: [0, 0.3, 0.6, 1])
            let end = ringOf(cx: cx + 90, cy: cy, rx: 24, ry: 90, steps: 40)
            p.shape(end, tone.dk(0.3))
            for r in stride(from: 80.0, to: 8.0, by: -12.0) { p.hoop(cx + 90, cy, r * 0.3, 1.2, tone.lt(0.3).al(0.5)) }
            penEdge(p, roll, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
            penEdge(p, end, weight: 1.1, colour: Pot.ink.al(0.7), seed: rng.next())
        }
    case "spools":
        p = Leaf(1200, 600)
        _ = benchScene(p, seed: rng.next(), exclude: "spool", horizon: 0.28, props: 0, shelf: false)
        for (k, tone) in [Pot.linen, Pot.threadRed, Pot.indigo, Pot.linen.dk(0.3), Pot.moss, Pot.ochre, Hue(r: 0.2, g: 0.2, b: 0.2), Pot.paper].enumerated() {
            drawSpool(p, at: pt(140 + Double(k) * 132, 330 + Double(k % 2) * 40), radius: 52, thread: tone, rng: &rng, height: 96)
        }
    case "pastePot":
        p = Leaf(900, 700)
        _ = benchScene(p, seed: rng.next(), exclude: "brush", horizon: 0.30, props: 1)
        drawPastePot(p, at: pt(450, 400), radius: 150, rng: &rng)
    case "pressEmpty":
        p = Leaf(900, 900)
        _ = benchScene(p, seed: rng.next(), exclude: "", horizon: 0.30, props: 1)
        drawPress(p, at: pt(450, 470), width: 520, rng: &rng, book: nil, open: 0.6)
    default:
        p = Leaf(1200, 800)
        p.fillAll(Pot.walnut)
        p.flipDown()
        let path = rectPath(0, 0, 1200, 800)
        linearInto(p, path, from: pt(0, 0), to: pt(0, 800), colours: [Pot.walnut.lt(0.16), Pot.walnut, Pot.walnut.dk(0.22)], locations: [0, 0.4, 1])
        woodGrain(p, path, axis: 0.01, base: Pot.walnut, lines: 90, wave: 7, rng: &rng)
        for _ in 0..<40 {
            let x = rng.r(0, 1200), y = rng.r(0, 800)
            p.egg(x, y, rng.r(10, 40), rng.r(4, 14), Pot.walnutDark.al(0.12))
        }
    }
    p.writeJPG(dir, "dc_" + key, quality: 0.86)
    return p.image()
}
