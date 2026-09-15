import Foundation
import CoreGraphics

func flatSheet(_ p: Leaf, _ poly: [CGPoint], tone: Hue, rng: inout Chip, laid: Bool = true) {
    castShadow(p, poly, dx: 8, dy: 10, steps: 6, alpha: 0.05)
    p.shape(shifted(poly, 2, 3), Hue(r: 0.02, g: 0.015, b: 0.01, a: 0.28))
    let path = pathOf(poly)
    p.fillPath(path, tone)
    paperFibres(p, path, base: tone, laid: laid, count: Int(Double(path.boundingBox.width * path.boundingBox.height) / 900), rng: &rng)
    linearInto(p, path, from: poly[0], to: poly[2], colours: [Hue(r: 1, g: 1, b: 1, a: 0.14), Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.10)], locations: [0, 0.5, 1])
    penEdge(p, poly, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
}

func sheetPose(cx: Double, cy: Double, w: Double, h: Double) -> [CGPoint] {
    [pt(cx - w * 0.5, cy + h * 0.5), pt(cx + w * 0.5, cy + h * 0.5 - h * 0.08), pt(cx + w * 0.5 + w * 0.22, cy - h * 0.5 - h * 0.08), pt(cx - w * 0.5 + w * 0.22, cy - h * 0.5)]
}

func lessonGrain(_ p: Leaf, rng: inout Chip) {
    let a = sheetPose(cx: 380, cy: 400, w: 400, h: 300)
    flatSheet(p, a, tone: Pot.paper.lt(0.1), rng: &rng)
    p.inside(pathOf(a)) {
        var fibres: [CGPoint] = []
        for _ in 0..<1400 {
            let x = rng.r(140, 700), y = rng.r(230, 580)
            fibres.append(pt(x, y)); fibres.append(pt(x + rng.r(8, 30), y - rng.r(1, 4)))
        }
        batchSegments(p, fibres, colour: Pot.inkSoft.al(0.28), width: 1.0)
    }
    let crease = [pt(255, 540), pt(420, 262)]
    pen(p, crease, weight: 2.6, colour: Pot.ink.al(0.6), wobble: 0.3, taper: false, seed: rng.next())
    letter(p, "with the grain: a clean fold", at: 330, 610, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
    let b = sheetPose(cx: 830, cy: 400, w: 400, h: 300)
    flatSheet(p, b, tone: Pot.paper.lt(0.1), rng: &rng)
    p.inside(pathOf(b)) {
        var fibres: [CGPoint] = []
        for _ in 0..<1400 {
            let x = rng.r(600, 1120), y = rng.r(230, 580)
            fibres.append(pt(x, y)); fibres.append(pt(x + rng.r(-2, 2), y + rng.r(8, 30)))
        }
        batchSegments(p, fibres, colour: Pot.inkSoft.al(0.28), width: 1.0)
    }
    let crack = [pt(700, 540), pt(866, 262)]
    pen(p, crack, weight: 2.8, colour: Pot.ink.al(0.75), wobble: 1.4, taper: false, seed: rng.next())
    for k in 0..<18 {
        let f = Double(k) / 18
        let x = 700 + f * 166, y = 540 - f * 278
        pen(p, [pt(x - 6, y), pt(x + 7, y + 2)], weight: 2.0, colour: Pot.paper.lt(0.6), wobble: 0.5, taper: true, seed: rng.next())
        pen(p, [pt(x - 4, y + 1), pt(x + 4, y + 3)], weight: 1.0, colour: Pot.ink.al(0.5), wobble: 0.5, taper: true, seed: rng.next())
    }
    letter(p, "across the grain: the fold cracks", at: 860, 610, size: 24, colour: Pot.threadRed, face: "Cochin-Italic")
    drawBoneFolder(p, at: pt(600, 640), angle: -0.15, length: 260, rng: &rng)
}

func lessonImposition(_ p: Leaf, rng: inout Chip) {
    let sheet = sheetPose(cx: 600, cy: 400, w: 720, h: 400)
    flatSheet(p, sheet, tone: Pot.paper.lt(0.12), rng: &rng)
    let map = Imposer.map(.octavo)
    let ox = Double(sheet[0].x), oy = Double(sheet[0].y)
    let ex = (Double(sheet[1].x) - ox, Double(sheet[1].y) - oy)
    let ey = (Double(sheet[3].x) - ox, Double(sheet[3].y) - oy)
    for r in 0..<2 {
        for c in 0..<4 {
            let u0 = Double(c) / 4, u1 = Double(c + 1) / 4
            let v0 = Double(1 - r) / 2, v1 = Double(2 - r) / 2
            let cell = [pt(ox + ex.0 * u0 + ey.0 * v0, oy + ex.1 * u0 + ey.1 * v0), pt(ox + ex.0 * u1 + ey.0 * v0, oy + ex.1 * u1 + ey.1 * v0),
                        pt(ox + ex.0 * u1 + ey.0 * v1, oy + ex.1 * u1 + ey.1 * v1), pt(ox + ex.0 * u0 + ey.0 * v1, oy + ex.1 * u0 + ey.1 * v1)]
            penEdge(p, cell, weight: 0.9, colour: Pot.ink.al(0.35), seed: rng.next())
            let page = map.frontAt(r, c)
            let cx = ox + ex.0 * (u0 + u1) / 2 + ey.0 * (v0 + v1) / 2
            let cy = oy + ex.1 * (u0 + u1) / 2 + ey.1 * (v0 + v1) / 2
            letter(p, "\(page.number)", at: cx, cy + 16, size: 52, colour: Pot.ink.al(0.85), face: "Cochin-Bold", rotate: page.turn == 2 ? .pi : 0)
            for k in 0..<5 {
                let ly = cy - 40 + Double(k) * 9 + (page.turn == 2 ? 50 : 0)
                p.box(cx - 30, ly, 60, 2, Pot.ink.al(0.25))
            }
        }
    }
    let arrow1 = [pt(ox + ex.0 * 0.5 + ey.0 * 0.5 + 250, oy + ex.1 * 0.5 + ey.1 * 0.5 - 200), pt(ox + ex.0 * 0.5 + ey.0 * 0.5 + 90, oy + ex.1 * 0.5 + ey.1 * 0.5 - 200)]
    pen(p, arrow1, weight: 3.0, colour: Pot.threadRed, wobble: 0.3, taper: true, seed: rng.next())
    pen(p, [arrow1[1], pt(Double(arrow1[1].x) + 26, Double(arrow1[1].y) - 14)], weight: 3.0, colour: Pot.threadRed, wobble: 0.2, taper: true, seed: rng.next())
    pen(p, [arrow1[1], pt(Double(arrow1[1].x) + 26, Double(arrow1[1].y) + 14)], weight: 3.0, colour: Pot.threadRed, wobble: 0.2, taper: true, seed: rng.next())
    letter(p, "first fold: right over left", at: Double(arrow1[0].x) - 80, Double(arrow1[0].y) - 22, size: 22, colour: Pot.threadRed, face: "Cochin-Italic")
    letter(p, "octavo: sixteen pages on one sheet, half of them printed head to head", at: 600, 680, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func lessonFolder(_ p: Leaf, rng: inout Chip) {
    let sheet = [pt(220, 560), pt(760, 520), pt(900, 260), pt(360, 300)]
    flatSheet(p, sheet, tone: Pot.paper.lt(0.1), rng: &rng)
    let folded = [pt(360, 300), pt(900, 260), pt(760, 220), pt(220, 262)]
    let fpath = pathOf(folded)
    p.fillPath(fpath, Pot.paper.dk(0.06))
    paperFibres(p, fpath, base: Pot.paper, laid: true, count: 120, rng: &rng)
    linearInto(p, fpath, from: pt(500, 262), to: pt(500, 300), colours: [Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.22)], locations: [0, 1])
    penEdge(p, folded, weight: 1.2, colour: Pot.ink.al(0.75), seed: rng.next())
    pen(p, [pt(360, 300), pt(900, 260)], weight: 2.8, colour: Pot.ink.al(0.8), wobble: 0.4, taper: false, seed: rng.next())
    drawBoneFolder(p, at: pt(640, 300), angle: -0.08, length: 520, rng: &rng)
    for k in 0..<4 {
        let x = 400 + Double(k) * 38
        pen(p, [pt(x, 340), pt(x + 60, 336)], weight: 2.0, colour: Pot.threadRed.al(0.8 - Double(k) * 0.15), wobble: 0.3, taper: true, seed: rng.next())
    }
    letter(p, "from the middle outward, one firm stroke each way", at: 600, 660, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func lessonStations(_ p: Leaf, rng: inout Chip) {
    drawCradle(p, at: pt(560, 420), width: 720, rng: &rng, signature: true)
    let template = [pt(780, 540), pt(1060, 500), pt(1064, 540), pt(784, 580)]
    flatSheet(p, template, tone: Pot.paper.dk(0.1), rng: &rng, laid: false)
    for f in [0.08, 0.35, 0.65, 0.92] {
        let x = 784 + (1060 - 784) * f, y = 560 - 40 * f
        pen(p, [pt(x, y - 12), pt(x, y + 12)], weight: 1.8, colour: Pot.ink.al(0.85), wobble: 0.2, taper: false, seed: rng.next())
    }
    letter(p, "template", at: 920, 610, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic")
    drawAwl(p, at: pt(560, 240), angle: 1.30, length: 300, rng: &rng)
    letter(p, "straight down through the fold, on the mark", at: 600, 680, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func lessonStitch(_ p: Leaf, _ s: Structure, rng: inout Chip, note: String) {
    spineDiagram(p, s, signatures: 3, stations: s.defaultStations, frame: CGRect(x: 260, y: 150, width: 760, height: 420), rng: &rng)
    letter(p, note, at: 600, 660, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func lessonTension(_ p: Leaf, rng: inout Chip) {
    spineDiagram(p, .copticOne, signatures: 2, stations: 4, frame: CGRect(x: 250, y: 200, width: 700, height: 260), rng: &rng)
    let station = pt(250 + 700 * 0.3466, 200 + 260 * 0.25)
    var thread: [CGPoint] = [station]
    for k in 1...8 { thread.append(pt(Double(station.x) + Double(k) * 30, Double(station.y) - Double(k) * 26 + sin(Double(k)) * 4)) }
    let path = catmull(thread, steps: 8)
    threadLine(p, path, weight: 5, tone: Pot.threadRed, rng: &rng)
    drawNeedle(p, at: pt(Double(station.x) + 270, Double(station.y) - 240), angle: -0.72, length: 150, rng: &rng)
    let tear = pt(250 + 700 * 0.08, 200 + 260 * 0.25)
    for k in 0..<5 {
        pen(p, [pt(Double(tear.x) - 4, Double(tear.y) + 4), pt(Double(tear.x) + 8 + Double(k) * 3, Double(tear.y) - 22 - Double(k) * 6)], weight: 1.6, colour: Pot.ink.al(0.7), wobble: 0.8, taper: true, seed: rng.next())
    }
    letter(p, "torn", at: Double(tear.x), Double(tear.y) - 40, size: 20, colour: Pot.threadRed, face: "Cochin-Italic")
    letter(p, "pull along the fold, into the window, and stop", at: 600, 620, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func lessonRounding(_ p: Leaf, rng: inout Chip) {
    drawLyingPress(p, at: pt(520, 470), width: 700, rng: &rng, block: true)
    drawHammer(p, at: pt(900, 300), angle: -0.9, length: 380, rng: &rng)
    var arc: [CGPoint] = []
    for k in 0...30 {
        let a = .pi * 0.2 + Double(k) / 30 * .pi * 0.6
        arc.append(pt(230 - cos(a) * 130, 250 - sin(a) * 90 + 60))
    }
    pen(p, arc, weight: 3, colour: Pot.ink.al(0.8), wobble: 0.3, taper: false, seed: rng.next())
    pen(p, [pt(100, 310), pt(360, 310)], weight: 1.4, colour: Pot.ink.al(0.5), wobble: 0.2, taper: false, seed: rng.next(), )
    letter(p, "a third of a circle", at: 230, 350, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic")
    letter(p, "small taps from the middle out, then the shoulders over the boards", at: 600, 680, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func lessonBoards(_ p: Leaf, rng: inout Chip) {
    for (k, x) in [200.0, 640.0].enumerated() {
        let board = [pt(x, 200), pt(x + 300, 190), pt(x + 330, 520), pt(x + 30, 530)]
        castShadow(p, board, dx: 8, dy: 10, steps: 6, alpha: 0.05)
        extrudeSides(p, board, dx: 0, dy: 12, light: p.light, base: Pot.greyboard.dk(0.25), brushAngle: nil, rng: &rng, bevel: false)
        let path = pathOf(board)
        p.fillPath(path, Pot.greyboard)
        grit(p, path, density: 0.03, sizeMin: 0.5, sizeMax: 1.5, colour: Pot.greyboard.dk(0.5).al(0.5), seed: rng.next())
        penEdge(p, board, weight: 1.4, colour: Pot.ink.al(0.85), seed: rng.next())
        if k == 0 {
            pen(p, [pt(x + 40, 205), pt(x + 66, 528)], weight: 1.2, colour: Pot.ink.al(0.6), wobble: 0.3, taper: false, seed: rng.next(), )
            letter(p, "square 3 mm", at: x + 150, 560, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic")
        }
    }
    let spinePiece = [pt(540, 205), pt(600, 203), pt(628, 522), pt(568, 526)]
    flatSheet(p, spinePiece, tone: Pot.paper.dk(0.15), rng: &rng, laid: false)
    letter(p, "spine piece", at: 590, 560, size: 20, colour: Pot.inkSoft, face: "Cochin-Italic")
    drawStraightedge(p, at: pt(600, 640), angle: -0.03, length: 700, rng: &rng)
    drawKnife(p, at: pt(1000, 380), angle: 1.2, length: 240, rng: &rng)
}

func lessonCovering(_ p: Leaf, rng: inout Chip) {
    let cloth = [pt(150, 180), pt(1050, 160), pt(1080, 560), pt(180, 580)]
    castShadow(p, cloth, dx: 6, dy: 8, steps: 5, alpha: 0.05)
    let look = BookLook(cover: Pot.indigo, kind: .cloth, look: .tapes, structure: nil)
    coverMaterial(p, pathOf(cloth), look, light: p.light, rng: &rng)
    penEdge(p, cloth, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
    for x in [240.0, 700.0] {
        let board = [pt(x, 240), pt(x + 300, 235), pt(x + 312, 505), pt(x + 12, 510)]
        extrudeSides(p, board, dx: 0, dy: 8, light: p.light, base: Pot.greyboard.dk(0.3), brushAngle: nil, rng: &rng, bevel: false)
        p.shape(board, Pot.greyboard)
        grit(p, pathOf(board), density: 0.02, sizeMin: 0.5, sizeMax: 1.4, colour: Pot.greyboard.dk(0.5).al(0.5), seed: rng.next())
        penEdge(p, board, weight: 1.3, colour: Pot.ink.al(0.85), seed: rng.next())
    }
    let spine = [pt(580, 238), pt(660, 237), pt(668, 507), pt(590, 508)]
    p.shape(spine, Pot.paper.dk(0.15))
    penEdge(p, spine, weight: 1.1, colour: Pot.ink.al(0.75), seed: rng.next())
    let turnIn = [pt(150, 180), pt(1050, 160), pt(1050, 232), pt(150, 250)]
    p.shape(turnIn, Pot.indigo.dk(0.2))
    clothWeave(p, pathOf(turnIn), base: Pot.indigo.dk(0.2), pitch: 3.4, rng: &rng)
    pen(p, [pt(150, 250), pt(1050, 232)], weight: 1.6, colour: Pot.ink.al(0.8), wobble: 0.4, taper: false, seed: rng.next())
    letter(p, "turn-in 15 mm", at: 600, 215, size: 20, colour: Pot.paper.lt(0.4), face: "Cochin-Italic")
    let corner = [pt(150, 580), pt(230, 580), pt(180, 520)]
    p.shape(corner, Pot.indigo.dk(0.25))
    penEdge(p, corner, weight: 1.2, colour: Pot.ink.al(0.8), seed: rng.next())
    letter(p, "library corner: the tip first, then the sides", at: 600, 660, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
    drawBoneFolder(p, at: pt(940, 640), angle: -0.3, length: 220, rng: &rng)
}

func lessonPress(_ p: Leaf, rng: inout Chip) {
    drawPress(p, at: pt(600, 400), width: 520, rng: &rng, book: BookLook(cover: Pot.threadRed.dk(0.2), kind: .cloth, look: .hollowBack, structure: .kettleTapes), open: 0.22)
    let clock = ringOf(cx: 1000, cy: 250, rx: 70, ry: 70, steps: 48)
    p.shape(shifted(clock, 3, 4), Hue(r: 0, g: 0, b: 0, a: 0.3))
    p.shape(clock, Pot.paper.lt(0.2))
    penEdge(p, clock, weight: 2.2, colour: Pot.ink.al(0.85), seed: rng.next())
    for k in 0..<12 {
        let a = Double(k) / 12 * 2 * .pi
        pen(p, [pt(1000 + cos(a) * 58, 250 + sin(a) * 58), pt(1000 + cos(a) * 64, 250 + sin(a) * 64)], weight: 1.6, colour: Pot.ink.al(0.8), wobble: 0.1, taper: false, seed: rng.next())
    }
    pen(p, [pt(1000, 250), pt(1000 + cos(-1.2) * 40, 250 + sin(-1.2) * 40)], weight: 3, colour: Pot.ink, wobble: 0.1, taper: true, seed: rng.next())
    pen(p, [pt(1000, 250), pt(1000 + cos(0.9) * 54, 250 + sin(0.9) * 54)], weight: 2, colour: Pot.ink, wobble: 0.1, taper: true, seed: rng.next())
    letter(p, "six hours", at: 1000, 350, size: 22, colour: Pot.inkSoft, face: "Cochin-Italic")
    letter(p, "the boards stay flat while the water leaves", at: 600, 680, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func lessonTimeline(_ p: Leaf, rng: inout Chip) {
    let specs: [(String, BookLook, Double)] = [
        ("4th c.", BookLook(cover: Pot.walnut, kind: .leather, look: .exposedChain, structure: .copticTwo, signatures: 5, stations: 4), 0),
        ("12th c.", BookLook(cover: Pot.bone, kind: .vellum, look: .cords, structure: .kettleTapes), 0),
        ("16th c.", BookLook(cover: Pot.bone.dk(0.05), kind: .vellum, look: .limp, structure: .longStitch), 0),
        ("18th c.", BookLook(cover: Hue(r: 0.36, g: 0.18, b: 0.10), kind: .leather, look: .tightBack, structure: .kettleTapes, gilt: true), 0),
        ("1830s", BookLook(cover: Pot.indigo, kind: .cloth, look: .hollowBack, structure: .kettleTapes, gilt: true), 0),
        ("1935", BookLook(cover: Hue(r: 0.86, g: 0.50, b: 0.22), kind: .paper, look: .perfect, structure: nil), 0)
    ]
    for (k, spec) in specs.enumerated() {
        let cx = 150 + Double(k) * 180
        let pose = BookPose.lying(cx: cx, cy: 380 + Double(k % 2) * 30, scale: 0.5, width: 240, height: 340, thick: spec.1.look == .perfect ? 50 : 80)
        paintBook(p, pose, spec.1, rng: &rng)
        letter(p, spec.0, at: cx, 560 + Double(k % 2) * 30, size: 22, colour: Pot.inkSoft, face: "Cochin-Italic")
    }
    letter(p, "from the chained codex to the glued paperback", at: 600, 680, size: 24, colour: Pot.inkSoft, face: "Cochin-Italic")
}

func drawLessonPlate(_ index: Int, dir: String) -> CGImage? {
    let p = Leaf(1200, 900)
    var rng = benchScene(p, seed: hashOf("lesson.\(index)"), exclude: "", horizon: 0.24, props: index == 11 ? 0 : 1, shelf: index != 11)
    p.light = 2.34
    switch index {
    case 0: lessonGrain(p, rng: &rng)
    case 1: lessonImposition(p, rng: &rng)
    case 2: lessonFolder(p, rng: &rng)
    case 3: lessonStations(p, rng: &rng)
    case 4: lessonStitch(p, .kettleTapes, rng: &rng, note: "the kettle: under the loop below at the change-over station")
    case 5: lessonStitch(p, .copticOne, rng: &rng, note: "out, under the loop below, back in, and along the fold")
    case 6: lessonTension(p, rng: &rng)
    case 7: lessonRounding(p, rng: &rng)
    case 8: lessonBoards(p, rng: &rng)
    case 9: lessonCovering(p, rng: &rng)
    case 10: lessonPress(p, rng: &rng)
    default: lessonTimeline(p, rng: &rng)
    }
    let lesson = Lessons.all[index]
    captionLabel(p, title: lesson.title, sub: lesson.summary, y: 736, size: 36)
    p.writeJPG(dir, "ls_\(index)", quality: 0.86)
    return p.image()
}
