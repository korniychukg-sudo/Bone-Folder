import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

private let keyLight = -2.30

private func iconBackground(_ p: Leaf, rng: inout Chip) {
    p.fillAll(Hue(r: 0.055, g: 0.040, b: 0.030))
    p.flipDown()
    radialFree(p, 300, 120, 0, 1150, [Hue(r: 0.30, g: 0.21, b: 0.14), Hue(r: 0.12, g: 0.085, b: 0.06), Hue(r: 0.035, g: 0.025, b: 0.02)], [0, 0.5, 1], extend: true)
    for _ in 0..<9000 {
        let x = rng.d() * 1024, y = rng.d() * 620
        let far = max(0.0, 1.0 - y / 620.0)
        let len = rng.r(3, 10) * (1 + far)
        let tone = rng.chance(0.5) ? Hue(r: 0.62, g: 0.48, b: 0.34) : Hue(r: 0.02, g: 0.015, b: 0.01)
        p.ctx.setStrokeColor(cg(tone.al(rng.r(0.03, 0.10))))
        p.ctx.setLineWidth(CGFloat(rng.r(0.6, 1.6)))
        p.ctx.beginPath()
        p.ctx.move(to: pt(x, y))
        p.ctx.addLine(to: pt(x + len, y + rng.r(-1, 1)))
        p.ctx.strokePath()
    }
    radialFree(p, 260, 300, 0, 420, [Hue(r: 0.60, g: 0.48, b: 0.34, a: 0.22), Hue(r: 0.60, g: 0.48, b: 0.34, a: 0)], [0, 1])
    linearFree(p, pt(0, 0), pt(0, 520), [Hue(r: 0, g: 0, b: 0, a: 0.50), Hue(r: 0, g: 0, b: 0, a: 0.0)], [0, 1])
    let benchY = 640.0
    let benchPath = pathOf([pt(-10, benchY), pt(1034, benchY - 26), pt(1034, 1034), pt(-10, 1034)])
    p.fillPath(benchPath, Pot.walnut.dk(0.22))
    linearInto(p, benchPath, from: pt(0, benchY), to: pt(0, 1024), colours: [Pot.walnut.lt(0.12), Pot.walnut.dk(0.10), Pot.walnut.dk(0.45)], locations: [0, 0.35, 1])
    woodGrain(p, benchPath, axis: -0.025, base: Pot.walnut.dk(0.15), lines: 110, wave: 7, rng: &rng)
    pen(p, [pt(0, benchY), pt(1024, benchY - 26)], weight: 2.2, colour: Hue(r: 0, g: 0, b: 0, a: 0.6), wobble: 0.6, taper: false, seed: rng.next())
    pen(p, [pt(0, benchY - 3), pt(1024, benchY - 29)], weight: 1.6, colour: Hue(r: 1, g: 0.9, b: 0.75, a: 0.30), wobble: 0.5, taper: false, seed: rng.next())
    radialFree(p, 1060, 1040, 0, 800, [Hue(r: 1.0, g: 0.72, b: 0.44, a: 0.16), Hue(r: 1.0, g: 0.72, b: 0.44, a: 0)], [0, 1])
}

private func frameUpright(_ p: Leaf, x: Double, top: Double, bottom: Double, w: Double, rng: inout Chip) {
    let poly = [pt(x - w / 2, top), pt(x + w / 2, top), pt(x + w / 2, bottom), pt(x - w / 2, bottom)]
    castShadow(p, poly, dx: 10, dy: 6, steps: 6, alpha: 0.06)
    let path = pathOf(poly)
    p.fillPath(path, Pot.walnutLight.dk(0.1))
    woodGrain(p, path, axis: 1.57, base: Pot.walnutLight.dk(0.1), lines: 30, wave: 2.5, rng: &rng)
    linearInto(p, path, from: pt(x - w / 2, top), to: pt(x + w / 2, top), colours: [Pot.walnutLight.dk(0.45), Pot.walnutLight.lt(0.25), Pot.walnutLight.dk(0.05), Pot.walnutLight.dk(0.55)], locations: [0, 0.3, 0.6, 1])
    var threads: [CGPoint] = []
    var y = top + 40
    while y < bottom - 60 { threads.append(pt(x - w * 0.42, y)); threads.append(pt(x + w * 0.42, y + 3)); y += 9 }
    batchSegments(p, threads, colour: Hue(r: 0, g: 0, b: 0, a: 0.35), width: 1.4)
    rimLight(p, poly, light: keyLight, weight: 3.0, colour: Hue(r: 1, g: 0.93, b: 0.78, a: 0.8), dark: Hue(r: 0, g: 0, b: 0, a: 0.5), seed: rng.next())
    penEdge(p, poly, weight: 1.4, colour: Hue(r: 0.05, g: 0.03, b: 0.02, a: 0.85), seed: rng.next())
}

private func tapeStrip(_ p: Leaf, x: Double, top: Double, bottom: Double, w: Double, rng: inout Chip) {
    let poly = [pt(x - w / 2, top), pt(x + w / 2, top), pt(x + w / 2 + 2, bottom), pt(x - w / 2 + 2, bottom)]
    p.shape(shifted(poly, 4, 5), Hue(r: 0, g: 0, b: 0, a: 0.35))
    let path = pathOf(poly)
    p.fillPath(path, Pot.linenPale)
    clothWeave(p, path, base: Pot.linenPale, pitch: 3.2, rng: &rng)
    linearInto(p, path, from: pt(x - w / 2, top), to: pt(x + w / 2, top), colours: [Hue(r: 0, g: 0, b: 0, a: 0.25), Hue(r: 1, g: 1, b: 1, a: 0.12), Hue(r: 0, g: 0, b: 0, a: 0.30)], locations: [0, 0.4, 1])
    penEdge(p, poly, weight: 1.0, colour: Hue(r: 0.1, g: 0.06, b: 0.03, a: 0.7), seed: rng.next())
}

private func signatureLayers(_ p: Leaf, pose: BookPose, count: Int, rng: inout Chip) {
    let face = pose.spineFace
    let path = pathOf(face)
    p.fillPath(path, Pot.paper.dk(0.12))
    let rowT = pose.thick / Double(count)
    for r in 0..<count {
        let t0 = pose.thick - rowT * Double(r + 1), t1 = pose.thick - rowT * Double(r)
        let band = [pose.at(0, 0, t0), pose.at(pose.height, 0, t0), pose.at(pose.height, 0, t1), pose.at(0, 0, t1)]
        let bpath = pathOf(band)
        p.fillPath(bpath, Pot.paper.dk(0.06 + Double(r % 2) * 0.03))
        paperFibres(p, bpath, base: Pot.paper, laid: false, count: 60, rng: &rng)
        linearInto(p, bpath, from: pose.at(0, 0, t0), to: pose.at(0, 0, t1), colours: [Hue(r: 1, g: 1, b: 1, a: 0.28), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.30), Hue(r: 0, g: 0, b: 0, a: 0.55)], locations: [0, 0.35, 0.8, 1])
        var leaves: [CGPoint] = []
        var t = t0 + 2
        while t < t1 - 1 { leaves.append(pose.at(0, 0, t)); leaves.append(pose.at(pose.height, 0, t)); t += 1.7 }
        batchSegments(p, leaves, colour: Hue(r: 0.25, g: 0.2, b: 0.15, a: 0.16), width: 0.7)
        pen(p, [pose.at(0, 0, t0), pose.at(pose.height, 0, t0)], weight: 1.4, colour: Hue(r: 0.08, g: 0.05, b: 0.03, a: 0.7), wobble: 0.4, taper: false, seed: rng.next())
    }
    linearInto(p, path, from: pose.at(0, 0, 0), to: pose.at(pose.height, 0, 0), colours: [Hue(r: 1, g: 0.95, b: 0.85, a: 0.10), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.42)], locations: [0, 0.4, 1])
}

private func linenThread(_ p: Leaf, _ pts: [CGPoint], weight: Double, rng: inout Chip, lit: Double = 1.0) {
    guard pts.count > 1 else { return }
    pen(p, shifted(pts, 2.2, 3.0), weight: weight * 1.25, colour: Hue(r: 0, g: 0, b: 0, a: 0.42), wobble: 0.2, taper: false, seed: rng.next())
    pen(p, pts, weight: weight, colour: Pot.linen.dk(0.30), wobble: 0.25, taper: false, seed: rng.next())
    pen(p, shifted(pts, -weight * 0.14, -weight * 0.18), weight: weight * 0.55, colour: Pot.linen.lt(0.10), wobble: 0.25, taper: false, seed: rng.next())
    pen(p, shifted(pts, -weight * 0.28, -weight * 0.34), weight: weight * 0.22, colour: Hue(r: 1, g: 0.98, b: 0.90, a: 0.85 * lit), wobble: 0.2, taper: true, seed: rng.next())
    var twist: [CGPoint] = []
    let dense = resample(pts, count: max(6, Int(Double(pts.count) * 3)))
    for i in stride(from: 0, to: dense.count - 1, by: 2) {
        let a = dense[i], b = dense[i + 1]
        let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
        let len = max(1e-6, (dx * dx + dy * dy).squareRoot())
        let nx = -dy / len, ny = dx / len
        twist.append(pt(Double(a.x) + nx * weight * 0.4, Double(a.y) + ny * weight * 0.4))
        twist.append(pt(Double(b.x) - nx * weight * 0.4, Double(b.y) - ny * weight * 0.4))
    }
    batchSegments(p, twist, colour: Hue(r: 0.25, g: 0.18, b: 0.10, a: 0.28), width: max(0.8, weight * 0.14))
}

private func chainStitches(_ p: Leaf, pose: BookPose, sewn: Int, count: Int, stations: [Double], rng: inout Chip) -> CGPoint {
    let rowT = pose.thick / Double(count)
    let weight = rowT * 0.30
    var last = pose.at(stations[0], 0, pose.thick - rowT * 0.5)
    for (si, s) in stations.enumerated() {
        for r in 0..<sewn {
            let tMid = pose.thick - rowT * (Double(r) + 0.5)
            let c = pose.at(s, 0, tMid)
            var loop: [CGPoint] = []
            var ang = -0.6
            while ang <= 3.75 { loop.append(pt(Double(c.x) + cos(ang) * rowT * 0.30, Double(c.y) + sin(ang) * rowT * 0.50)); ang += 0.2 }
            linenThread(p, loop, weight: weight, rng: &rng)
            if r > 0 {
                let below = pose.at(s, 0, tMid + rowT)
                linenThread(p, [pt(Double(below.x) - rowT * 0.12, Double(below.y) - rowT * 0.42), pt(Double(c.x) - rowT * 0.10, Double(c.y) + rowT * 0.10)], weight: weight * 0.95, rng: &rng)
            }
            p.dot(Double(c.x), Double(c.y) - rowT * 0.02, weight * 0.55, Hue(r: 0.06, g: 0.04, b: 0.02, a: 0.85))
            if si == 1 && r == sewn - 1 { last = c }
        }
    }
    return last
}

private func needleAndLoop(_ p: Leaf, from exit: CGPoint, rng: inout Chip) {
    let needleTip = pt(Double(exit.x) + 30, Double(exit.y) - 250)
    let needleEye = pt(Double(needleTip.x) + 190, Double(needleTip.y) - 118)
    let eyeCentre = pt(Double(needleEye.x) - 24, Double(needleEye.y) + 15)
    let raw: [CGPoint] = [exit, pt(Double(exit.x) - 16, Double(exit.y) - 60), pt(Double(exit.x) + 4, Double(exit.y) - 150), pt(Double(exit.x) + 70, Double(exit.y) - 205), pt(Double(exit.x) + 120, Double(exit.y) - 190), pt(Double(eyeCentre.x) - 30, Double(eyeCentre.y) + 30), eyeCentre]
    let thread = catmull(raw, steps: 12)
    linenThread(p, thread, weight: 9, rng: &rng, lit: 1.0)
    let tail = catmull([eyeCentre, pt(Double(eyeCentre.x) + 40, Double(eyeCentre.y) + 60), pt(Double(eyeCentre.x) + 20, Double(eyeCentre.y) + 150), pt(Double(eyeCentre.x) + 90, Double(eyeCentre.y) + 230), pt(Double(eyeCentre.x) + 200, Double(eyeCentre.y) + 300)], steps: 12)
    linenThread(p, tail, weight: 8.5, rng: &rng, lit: 0.7)
    let dx = Double(needleTip.x - needleEye.x), dy = Double(needleTip.y - needleEye.y)
    let len = (dx * dx + dy * dy).squareRoot()
    let ux = dx / len, uy = dy / len
    let nx = -uy, ny = ux
    pen(p, [pt(Double(needleEye.x) + 6, Double(needleEye.y) + 9), pt(Double(needleTip.x) + 6, Double(needleTip.y) + 9)], weight: 14, colour: Hue(r: 0, g: 0, b: 0, a: 0.30), wobble: 0.1, taper: false, seed: rng.next())
    var poly: [CGPoint] = []
    for k in 0...24 {
        let t = Double(k) / 24
        let w = t < 0.85 ? 13.0 - t * 4.0 : max(0.8, 9.0 - (t - 0.85) / 0.15 * 8.2)
        poly.append(pt(Double(needleEye.x) + ux * t * len + nx * w * 0.5, Double(needleEye.y) + uy * t * len + ny * w * 0.5))
    }
    for k in stride(from: 24, through: 0, by: -1) {
        let t = Double(k) / 24
        let w = t < 0.85 ? 13.0 - t * 4.0 : max(0.8, 9.0 - (t - 0.85) / 0.15 * 8.2)
        poly.append(pt(Double(needleEye.x) + ux * t * len - nx * w * 0.5, Double(needleEye.y) + uy * t * len - ny * w * 0.5))
    }
    let path = pathOf(poly)
    p.fillPath(path, Pot.steel)
    linearInto(p, path, from: pt(Double(needleEye.x) + nx * 7, Double(needleEye.y) + ny * 7), to: pt(Double(needleEye.x) - nx * 7, Double(needleEye.y) - ny * 7),
               colours: [Hue(r: 0.30, g: 0.32, b: 0.36), Hue(r: 0.96, g: 0.97, b: 1.0), Hue(r: 0.62, g: 0.65, b: 0.70), Hue(r: 0.22, g: 0.24, b: 0.28)], locations: [0, 0.32, 0.6, 1])
    streaks(p, path, count: 900, angle: atan2(uy, ux), lenMin: 6, lenMax: 30, light: Hue(r: 1, g: 1, b: 1), dark: Hue(r: 0.02, g: 0.03, b: 0.05), alphaMin: 0.04, alphaMax: 0.16, weightMax: 1.2, rng: &rng)
    pen(p, [pt(Double(needleEye.x) + nx * 3.2, Double(needleEye.y) + ny * 3.2), pt(Double(needleTip.x) + nx * 1.0, Double(needleTip.y) + ny * 1.0)], weight: 2.4, colour: Hue(r: 1, g: 1, b: 1, a: 0.95), wobble: 0.1, taper: true, seed: rng.next())
    let eyeA = pt(Double(eyeCentre.x) - ux * 11, Double(eyeCentre.y) - uy * 11), eyeB = pt(Double(eyeCentre.x) + ux * 11, Double(eyeCentre.y) + uy * 11)
    pen(p, [eyeA, eyeB], weight: 4.6, colour: Hue(r: 0.04, g: 0.03, b: 0.03, a: 0.95), wobble: 0.1, taper: true, seed: rng.next())
    pen(p, [pt(Double(eyeA.x) + nx * 1.6, Double(eyeA.y) + ny * 1.6), pt(Double(eyeB.x) + nx * 1.6, Double(eyeB.y) + ny * 1.6)], weight: 1.0, colour: Hue(r: 1, g: 1, b: 1, a: 0.7), wobble: 0.1, taper: true, seed: rng.next())
    penEdge(p, poly, weight: 1.1, colour: Hue(r: 0.03, g: 0.03, b: 0.04, a: 0.85), seed: rng.next())
    p.dot(Double(needleTip.x), Double(needleTip.y), 2.4, Hue(r: 1, g: 1, b: 1, a: 0.9))
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
        let w = length * 0.072 * (t < 0.12 ? (0.30 + t / 0.12 * 0.70) : (t > 0.70 ? max(0.05, 1 - pow((t - 0.70) / 0.30, 1.2)) : 1.0))
        left.append(pt(x + nx * w, y + ny * w)); right.append(pt(x - nx * w, y - ny * w))
    }
    let poly = left + right.reversed()
    castShadow(p, poly, dx: 14, dy: 12, steps: 8, alpha: 0.07)
    p.shape(shifted(poly, 3, 4), Hue(r: 0, g: 0, b: 0, a: 0.4))
    let path = pathOf(poly)
    p.fillPath(path, Pot.bone)
    linearInto(p, path, from: pt(Double(c.x) + nx * length * 0.07, Double(c.y) + ny * length * 0.07), to: pt(Double(c.x) - nx * length * 0.07, Double(c.y) - ny * length * 0.07),
               colours: [Pot.bone.dk(0.42), Pot.bone.lt(0.10), Pot.bone.lt(0.55), Pot.bone.lt(0.15), Pot.bone.dk(0.12)], locations: [0, 0.28, 0.5, 0.7, 1])
    let box = path.boundingBox
    p.inside(path) {
        var veins: [CGPoint] = []
        for _ in 0..<Int(Double(box.width * box.height) / 180) {
            let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
            let l = rng.r(4, 18)
            veins.append(pt(x, y)); veins.append(pt(x + dx * l, y + dy * l))
        }
        batchSegments(p, veins, colour: Pot.boneDeep.al(0.28), width: 0.9)
        for _ in 0..<40 {
            let x = Double(box.minX) + rng.d() * Double(box.width), y = Double(box.minY) + rng.d() * Double(box.height)
            p.egg(x, y, rng.r(6, 20), rng.r(2, 5), Pot.boneDeep.al(0.12))
        }
    }
    rimLight(p, poly, light: keyLight, weight: 4.0, colour: Hue(r: 1, g: 1, b: 0.96, a: 0.92), dark: Pot.boneDeep.dk(0.45).al(0.6), step: 3, seed: rng.next())
    penEdge(p, poly, weight: 1.4, colour: Hue(r: 0.08, g: 0.05, b: 0.03, a: 0.85), seed: rng.next())
}

func drawIcon(_ dir: String, _ scratch: String) {
    let previous = sheetScale
    sheetScale = 1.0
    let p = Leaf(1024, 1024)
    var rng = Chip(hashOf("bone-folder-icon-block-on-frame-2"))
    iconBackground(p, rng: &rng)
    p.light = keyLight
    let baseTop = [pt(40, 800), pt(1180, 742), pt(1240, 930), pt(100, 990)]
    castShadow(p, baseTop, dx: 24, dy: 30, steps: 10, alpha: 0.06)
    extrudeSides(p, baseTop, dx: 0, dy: 120, light: keyLight, base: Pot.walnutLight.dk(0.32), brushAngle: nil, rng: &rng, bevel: false)
    let basePath = pathOf(baseTop)
    p.fillPath(basePath, Pot.walnutLight.dk(0.05))
    woodGrain(p, basePath, axis: -0.05, base: Pot.walnutLight.dk(0.05), lines: 70, wave: 6, rng: &rng)
    linearInto(p, basePath, from: pt(40, 800), to: pt(1180, 900), colours: [Hue(r: 1, g: 0.95, b: 0.85, a: 0.22), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.40)], locations: [0, 0.4, 1])
    let slot = [pt(200, 816), pt(1100, 770), pt(1104, 786), pt(204, 832)]
    p.shape(slot, Hue(r: 0.06, g: 0.04, b: 0.02))
    rimLight(p, baseTop, light: keyLight, weight: 4.5, colour: Hue(r: 1, g: 0.94, b: 0.80, a: 0.8), dark: Hue(r: 0, g: 0, b: 0, a: 0.5), seed: rng.next())
    penEdge(p, baseTop, weight: 1.8, colour: Hue(r: 0.05, g: 0.03, b: 0.02, a: 0.85), seed: rng.next())
    frameUpright(p, x: 118, top: 40, bottom: 820, w: 50, rng: &rng)
    let bar = [pt(50, 62), pt(1100, 8), pt(1100, 56), pt(50, 110)]
    extrudeSides(p, bar, dx: 0, dy: 16, light: keyLight, base: Pot.walnutLight.dk(0.4), brushAngle: nil, rng: &rng, bevel: false)
    p.shape(bar, Pot.walnutLight.dk(0.08))
    woodGrain(p, pathOf(bar), axis: -0.052, base: Pot.walnutLight.dk(0.08), lines: 26, wave: 2, rng: &rng)
    linearInto(p, pathOf(bar), from: pt(500, 35), to: pt(500, 90), colours: [Pot.walnutLight.lt(0.3).al(0.6), Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.45)], locations: [0, 0.4, 1])
    rimLight(p, bar, light: keyLight, weight: 3.6, colour: Hue(r: 1, g: 0.94, b: 0.80, a: 0.85), dark: Hue(r: 0, g: 0, b: 0, a: 0.5), seed: rng.next())
    penEdge(p, bar, weight: 1.5, colour: Hue(r: 0.05, g: 0.03, b: 0.02, a: 0.85), seed: rng.next())
    tapeStrip(p, x: 430, top: 76, bottom: 810, w: 38, rng: &rng)
    tapeStrip(p, x: 790, top: 58, bottom: 792, w: 38, rng: &rng)
    frameUpright(p, x: 1050, top: 0, bottom: 790, w: 52, rng: &rng)

    let pose = BookPose(ox: 165, oy: 480, eH: (0.995, -0.050), eW: (0.48, -0.58), eT: (0.0, 1.0), width: 400, height: 780, thick: 310)
    let signatures = 5
    let sewn = 3
    let stations = [pose.height * 0.10, pose.height * 0.37, pose.height * 0.63, pose.height * 0.90]
    let ground = [pose.at(0, 0, pose.thick), pose.at(pose.height, 0, pose.thick), pose.at(pose.height, pose.width, pose.thick), pose.at(0, pose.width, pose.thick)]
    castShadow(p, ground, dx: 34, dy: 26, steps: 12, alpha: 0.07)
    p.shape(shifted(ground, 5, 5), Hue(r: 0, g: 0, b: 0, a: 0.5))
    let tail = pose.tailFace
    let tpath = pathOf(tail)
    p.fillPath(tpath, Pot.paper.dk(0.24))
    p.inside(tpath) {
        var lines: [CGPoint] = []
        var t = 1.0
        while t < pose.thick { lines.append(pose.at(0, 0, t)); lines.append(pose.at(0, pose.width, t)); t += 1.5 }
        batchSegments(p, lines, colour: Hue(r: 0.2, g: 0.15, b: 0.1, a: 0.30), width: 0.7)
        linearInto(p, tpath, from: pose.at(0, 0, 0), to: pose.at(0, pose.width, 0), colours: [Hue(r: 0, g: 0, b: 0, a: 0.25), Hue(r: 0, g: 0, b: 0, a: 0.6)], locations: [0, 1])
    }
    signatureLayers(p, pose: pose, count: signatures, rng: &rng)
    let top = pose.topFace
    let topPath = pathOf(top)
    p.fillPath(topPath, Pot.paper.lt(0.06))
    paperFibres(p, topPath, base: Pot.paper, laid: true, count: 1400, rng: &rng)
    linearInto(p, topPath, from: pose.at(0, 0, 0), to: pose.at(pose.height, pose.width, 0), colours: [Hue(r: 1, g: 0.98, b: 0.92, a: 0.34), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.44)], locations: [0, 0.4, 1])
    linearInto(p, topPath, from: pose.at(0, pose.width, 0), to: pose.at(0, pose.width * 0.6, 0), colours: [Hue(r: 0, g: 0, b: 0, a: 0.22), Hue(r: 0, g: 0, b: 0, a: 0.0)], locations: [0, 1])
    p.inside(topPath) {
        for _ in 0..<40 {
            let h = rng.r(0, pose.height), w = rng.r(0, pose.width)
            let q = pose.at(h, w, 0)
            p.egg(Double(q.x), Double(q.y), rng.r(14, 50), rng.r(4, 12), (rng.chance(0.5) ? Pot.paper.dk(0.10) : Pot.paper.lt(0.4)).al(0.05))
        }
    }
    var deckle: [CGPoint] = []
    for k in 0...140 {
        let f = Double(k) / 140
        let q = pose.at(pose.height * f, pose.width, 0)
        deckle.append(pt(Double(q.x), Double(q.y) + 1)); deckle.append(pt(Double(q.x) + rng.r(-1, 2), Double(q.y) - rng.r(0.5, 2.5)))
    }
    batchSegments(p, deckle, colour: Pot.paper.dk(0.05).al(0.7), width: 0.9)
    linearInto(p, topPath, from: pose.at(pose.height * 0.35, 0, 0), to: pose.at(pose.height, 0, 0), colours: [Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0.05, g: 0.03, b: 0.02, a: 0.26)], locations: [0, 1])
    linearInto(p, topPath, from: pose.at(0, 0, 0), to: pose.at(pose.height * 0.4, pose.width * 0.5, 0), colours: [Hue(r: 1, g: 0.98, b: 0.92, a: 0.28), Hue(r: 1, g: 0.98, b: 0.92, a: 0.0)], locations: [0, 1])
    pen(p, [pose.at(0, 0, 0), pose.at(pose.height, 0, 0)], weight: 2.6, colour: Hue(r: 0.08, g: 0.05, b: 0.03, a: 0.75), wobble: 0.5, taper: false, seed: rng.next())
    penEdge(p, top, weight: 1.4, colour: Hue(r: 0.08, g: 0.05, b: 0.03, a: 0.7), seed: rng.next())
    rimLight(p, top, light: keyLight, weight: 6.5, colour: Hue(r: 1, g: 0.97, b: 0.88, a: 0.95), dark: nil, step: 3, seed: rng.next())
    let exit = chainStitches(p, pose: pose, sewn: sewn, count: signatures, stations: stations, rng: &rng)
    let rowT = pose.thick / Double(signatures)
    let fourthT = pose.thick - rowT * (Double(sewn) + 0.5)
    let stationsFourth = stations.map { pose.at($0, 0, fourthT) }
    for q in stationsFourth { p.dot(Double(q.x), Double(q.y), rowT * 0.10, Hue(r: 0.06, g: 0.04, b: 0.02, a: 0.85)) }
    let start = stationsFourth[0]
    linenThread(p, [pt(Double(exit.x) - rowT * 0.10, Double(exit.y) - rowT * 0.40), pt(Double(start.x) + 4, Double(start.y) + 6)], weight: rowT * 0.3, rng: &rng)
    var loop: [CGPoint] = []
    var ang = -0.6
    while ang <= 3.75 { loop.append(pt(Double(start.x) + cos(ang) * rowT * 0.30, Double(start.y) + sin(ang) * rowT * 0.50)); ang += 0.2 }
    linenThread(p, loop, weight: rowT * 0.3, rng: &rng)
    needleAndLoop(p, from: stationsFourth[1], rng: &rng)
    let shade = [pose.at(pose.height * 0.45, 0, 0), pose.at(pose.height, 0, 0), pose.at(pose.height, 0, pose.thick), pose.at(pose.height * 0.45, 0, pose.thick)]
    linearInto(p, pathOf(shade), from: pose.at(pose.height * 0.45, 0, 0), to: pose.at(pose.height, 0, 0), colours: [Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0.03, g: 0.02, b: 0.02, a: 0.42)], locations: [0, 1])
    let under = [pose.at(0, 0, pose.thick * 0.7), pose.at(pose.height, 0, pose.thick * 0.7), pose.at(pose.height, 0, pose.thick), pose.at(0, 0, pose.thick)]
    linearInto(p, pathOf(under), from: pose.at(0, 0, pose.thick * 0.7), to: pose.at(0, 0, pose.thick), colours: [Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.34)], locations: [0, 1])
    let keyBand = [pose.at(0, 0, 0), pose.at(pose.height * 0.3, 0, 0), pose.at(pose.height * 0.3, 0, pose.thick), pose.at(0, 0, pose.thick)]
    linearInto(p, pathOf(keyBand), from: pose.at(0, 0, 0), to: pose.at(pose.height * 0.3, 0, 0), colours: [Hue(r: 1, g: 0.96, b: 0.86, a: 0.16), Hue(r: 1, g: 0.96, b: 0.86, a: 0.0)], locations: [0, 1])
    iconBoneFolder(p, at: pt(360, 985), angle: -0.30, length: 640, rng: &rng)
    softGlowAt(p, cx: 1010, cy: 1020, radius: 780, colour: Hue(r: 1, g: 0.78, b: 0.50), strength: 0.15)
    softGlowAt(p, cx: 90, cy: 60, radius: 560, colour: Hue(r: 1, g: 0.95, b: 0.84), strength: 0.12)
    filmGrain(p, amplitude: 0.055, seed: rng.next())
    radialFree(p, 480, 480, 0, 860, [Hue(r: 0, g: 0, b: 0, a: 0), Hue(r: 0, g: 0, b: 0, a: 0.46)], [0.55, 1], extend: true)
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
        cropA.drawImage(img, into: CGRect(x: -700, y: -300, width: 2048, height: 2048))
        cropA.writePNG(scratch, "icon_crop_thread")
        let cropB = Leaf(400, 400)
        cropB.flipDown()
        cropB.drawImage(img, into: CGRect(x: -300, y: -1500, width: 2048, height: 2048))
        cropB.writePNG(scratch, "icon_crop_folder")
    }
    sheetScale = previous
}
