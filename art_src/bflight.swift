import Foundation
import CoreGraphics

struct Run {
    var pts: [CGPoint]
    var power: [Double]
}

struct Tx {
    var cx: Double
    var cy: Double
    var scale: Double
    var squash: Double = 1.0
    var rot: Double = 0

    func at(_ x: Double, _ y: Double) -> CGPoint {
        let rx = x * cos(rot) - y * sin(rot)
        let ry = x * sin(rot) + y * cos(rot)
        return pt(cx + rx * scale, cy + ry * scale * squash)
    }

    func len(_ r: Double) -> Double { r * scale }
    func lifted(_ dy: Double) -> Tx { Tx(cx: cx, cy: cy - dy, scale: scale, squash: squash, rot: rot) }
}

func signedTwiceArea(_ pts: [CGPoint]) -> Double {
    var twice = 0.0
    for i in 0..<pts.count {
        let a = pts[i], b = pts[(i + 1) % pts.count]
        twice += Double(a.x) * Double(b.y) - Double(b.x) * Double(a.y)
    }
    return twice
}

func smoothFall(_ v: Double, _ gate: Double) -> Double {
    let c = max(0.0, min(1.0, v))
    guard gate > 0, gate < 0.999 else { return c }
    let t = max(0.0, min(1.0, (c - gate) / (1.0 - gate)))
    return t * t * (3.0 - 2.0 * t)
}

func rimRunsOf(_ pts: [CGPoint], light: Double, enter: Double, leave: Double,
               window: Int = 11, bridge: Int = 14, minRun: Int = 16,
               inset: Double = 0, gate: Double = 0) -> [Run] {
    let n = pts.count
    guard n > 8 else { return [] }
    let turn: Double = signedTwiceArea(pts) > 0 ? -(.pi / 2) : (.pi / 2)
    let reach = max(1, min(n / 8, 4))
    var nx = [Double](repeating: 0, count: n)
    var ny = [Double](repeating: 0, count: n)
    var raw = [Double](repeating: 0, count: n)
    var carry = 0.0
    for i in 0..<n {
        let a = pts[(i + n - reach) % n], b = pts[(i + reach) % n]
        let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
        if dx * dx + dy * dy > 1e-9 { carry = atan2(dy, dx) }
        let na = carry + turn
        nx[i] = cos(na)
        ny[i] = sin(na)
        raw[i] = cos(na - light)
    }
    var facing = [Double](repeating: 0, count: n)
    let half = max(1, min(window / 2, n / 3))
    for i in 0..<n {
        var acc = 0.0, mass = 0.0
        for k in -half...half {
            let w = 1.0 - Double(abs(k)) / Double(half + 1)
            acc += raw[(i + k + n) % n] * w
            mass += w
        }
        facing[i] = acc / mass
    }
    var seedIdx = 0
    var peak = facing[0]
    for i in 1..<n {
        if facing[i] < facing[seedIdx] { seedIdx = i }
        if facing[i] > peak { peak = facing[i] }
    }
    var lit = [Bool](repeating: false, count: n)
    var on = facing[seedIdx] > enter
    for k in 0..<n {
        let i = (seedIdx + k) % n
        if on {
            if facing[i] < leave { on = false }
        } else if facing[i] > enter {
            on = true
        }
        lit[i] = on
    }
    guard lit.contains(true) else { return [] }
    if lit.contains(false) {
        var fill: [Int] = []
        for i in 0..<n where !lit[i] && lit[(i + n - 1) % n] {
            var len = 0
            while len < n && !lit[(i + len) % n] { len += 1 }
            if len <= bridge { for k in 0..<len { fill.append((i + k) % n) } }
        }
        for i in fill { lit[i] = true }
    }
    var runs: [(Int, Int)] = []
    if lit.contains(false) {
        for i in 0..<n where lit[i] && !lit[(i + n - 1) % n] {
            var len = 0
            while len < n && lit[(i + len) % n] { len += 1 }
            runs.append((i, len))
        }
    } else {
        runs = [(0, n)]
    }
    let spread = max(0.14, peak - leave)
    var out: [Run] = []
    for (start, len) in runs where len >= minRun {
        var line: [CGPoint] = []
        var lift: [Double] = []
        for k in 0..<len {
            let i = (start + k) % n
            let lam = smoothFall((facing[i] - leave) / spread, gate)
            line.append(pt(Double(pts[i].x) - nx[i] * inset * lam, Double(pts[i].y) - ny[i] * inset * lam))
            lift.append(lam)
        }
        out.append(Run(pts: line, power: lift))
    }
    return out
}

func runResample(_ g: Run, count: Int) -> Run {
    guard g.pts.count > 1, count > 1 else { return g }
    var marks: [Double] = [0]
    var total = 0.0
    for i in 1..<g.pts.count {
        let dx = Double(g.pts[i].x - g.pts[i - 1].x), dy = Double(g.pts[i].y - g.pts[i - 1].y)
        total += (dx * dx + dy * dy).squareRoot()
        marks.append(total)
    }
    guard total > 0 else { return g }
    var line: [CGPoint] = []
    var lift: [Double] = []
    var seg = 1
    for k in 0..<count {
        let target = total * Double(k) / Double(count - 1)
        while seg < marks.count - 1 && marks[seg] < target { seg += 1 }
        let l0 = marks[seg - 1], l1 = marks[seg]
        let t = l1 > l0 ? (target - l0) / (l1 - l0) : 0
        let a = g.pts[seg - 1], b = g.pts[seg]
        line.append(CGPoint(x: a.x + (b.x - a.x) * CGFloat(t), y: a.y + (b.y - a.y) * CGFloat(t)))
        lift.append(g.power[seg - 1] + (g.power[seg] - g.power[seg - 1]) * t)
    }
    return Run(pts: line, power: lift)
}

func rimStroke(_ p: Leaf, _ g: Run, weight: Double, colour: Hue, sharp: Double = 1.0,
               wobble: Double = 0.0, seed: UInt64 = 9) {
    guard g.pts.count > 1, weight > 0 else { return }
    var total = 0.0
    for i in 1..<g.pts.count {
        let dx = Double(g.pts[i].x - g.pts[i - 1].x), dy = Double(g.pts[i].y - g.pts[i - 1].y)
        total += (dx * dx + dy * dy).squareRoot()
    }
    guard total > 3 else { return }
    let n = max(28, min(420, Int(total / 3.0)))
    let s = runResample(g, count: n)
    var rng = Chip(seed)
    let f1 = rng.r(1.4, 3.0), f2 = rng.r(4.0, 7.4)
    let ph1 = rng.r(0, 6.283185), ph2 = rng.r(0, 6.283185)
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for i in 0..<n {
        let t = Double(i) / Double(n - 1)
        let a = s.pts[max(0, i - 1)], b = s.pts[min(n - 1, i + 1)]
        var tx = Double(b.x - a.x), ty = Double(b.y - a.y)
        let len = (tx * tx + ty * ty).squareRoot()
        if len > 0 { tx /= len; ty /= len } else { tx = 1; ty = 0 }
        let px = -ty, py = tx
        let ends = pow(sin(.pi * t), 0.42)
        let lam = pow(max(0.0, min(1.0, s.power[i])), sharp)
        let ripple = 1.0 + 0.13 * sin(t * f1 * 6.283185 + ph1) + 0.06 * sin(t * f2 * 6.283185 + ph2)
        let hw = max(0.0, weight * 0.5 * ends * lam * ripple)
        let off = sin(t * f2 * 3.141593 + ph2) * wobble
        let cx = Double(s.pts[i].x) + px * off
        let cy = Double(s.pts[i].y) + py * off
        left.append(pt(cx + px * hw, cy + py * hw))
        right.append(pt(cx - px * hw, cy - py * hw))
    }
    p.shape(left + right.reversed(), colour)
}

func rimLight(_ p: Leaf, _ poly: [CGPoint], light: Double, weight: Double, colour: Hue, dark: Hue? = nil,
              step: Double = 3, seed: UInt64) {
    var rng = Chip(seed)
    let dense = densify(poly, step: step)
    let clip = pathOf(poly)
    p.inside(clip) {
        for run in rimRunsOf(dense, light: light, enter: 0.30, leave: 0.05, window: 11, bridge: 12, minRun: 14, inset: weight * 0.45, gate: 0.25) {
            rimStroke(p, run, weight: weight * 2.0, colour: colour.al(colour.a * 0.30), sharp: 0.6, wobble: 0.3, seed: rng.next())
            rimStroke(p, run, weight: weight, colour: colour, sharp: 1.3, wobble: 0.15, seed: rng.next())
        }
        if let dark = dark {
            for run in rimRunsOf(dense, light: light + .pi, enter: 0.28, leave: 0.04, window: 11, bridge: 12, minRun: 14, inset: weight * 0.4, gate: 0.25) {
                rimStroke(p, run, weight: weight * 1.4, colour: dark, sharp: 0.9, wobble: 0.2, seed: rng.next())
            }
        }
    }
}

func radialInto(_ p: Leaf, _ clip: CGPath, from: CGPoint, inner: Hue, outer: Hue, radius: Double) {
    guard let g = CGGradient(colorsSpace: deviceRGB, colors: [cg(inner), cg(outer)] as CFArray, locations: [0, 1]) else { return }
    p.inside(clip) {
        p.ctx.drawRadialGradient(g, startCenter: from, startRadius: 0, endCenter: from, endRadius: CGFloat(radius), options: [.drawsAfterEndLocation])
    }
}

func linearInto(_ p: Leaf, _ clip: CGPath, from: CGPoint, to: CGPoint, colours: [Hue], locations: [CGFloat]) {
    guard let g = CGGradient(colorsSpace: deviceRGB, colors: colours.map { cg($0) } as CFArray, locations: locations) else { return }
    p.inside(clip) {
        p.ctx.drawLinearGradient(g, start: from, end: to, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    }
}

func radialFree(_ p: Leaf, _ cx: Double, _ cy: Double, _ r0: Double, _ r1: Double, _ colours: [Hue], _ locations: [CGFloat], extend: Bool = false) {
    guard let g = CGGradient(colorsSpace: deviceRGB, colors: colours.map { cg($0) } as CFArray, locations: locations) else { return }
    p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: cx, y: cy), startRadius: CGFloat(r0),
                             endCenter: CGPoint(x: cx, y: cy), endRadius: CGFloat(r1),
                             options: extend ? [.drawsBeforeStartLocation, .drawsAfterEndLocation] : [])
}

func linearFree(_ p: Leaf, _ a: CGPoint, _ b: CGPoint, _ colours: [Hue], _ locations: [CGFloat]) {
    guard let g = CGGradient(colorsSpace: deviceRGB, colors: colours.map { cg($0) } as CFArray, locations: locations) else { return }
    p.ctx.drawLinearGradient(g, start: a, end: b, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
}

func softGlowAt(_ p: Leaf, cx: Double, cy: Double, radius: Double, colour: Hue, strength: Double) {
    guard radius > 1, let g = CGGradient(colorsSpace: deviceRGB,
                                          colors: [cg(colour.al(strength)), cg(colour.al(strength * 0.34)), cg(colour.al(0))] as CFArray,
                                          locations: [0, 0.44, 1]) else { return }
    p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: cx, y: cy), startRadius: 0,
                             endCenter: CGPoint(x: cx, y: cy), endRadius: CGFloat(radius), options: [])
}

func batchSegments(_ p: Leaf, _ segs: [CGPoint], colour: Hue, width: Double) {
    guard segs.count > 1 else { return }
    p.ctx.setStrokeColor(cg(colour))
    p.ctx.setLineWidth(CGFloat(width))
    p.ctx.setLineCap(.round)
    p.ctx.strokeLineSegments(between: segs)
}

func streaks(_ p: Leaf, _ clip: CGPath, count: Int, angle: Double, lenMin: Double, lenMax: Double,
             light: Hue, dark: Hue, alphaMin: Double, alphaMax: Double, weightMax: Double, rng: inout Chip) {
    let box = clip.boundingBox
    p.inside(clip) {
        for _ in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let a = angle + rng.signed() * 0.03
            let len = rng.r(lenMin, lenMax)
            let tone = rng.chance(0.5) ? light : dark
            p.ctx.setStrokeColor(cg(tone.al(rng.r(alphaMin, alphaMax))))
            p.ctx.setLineWidth(CGFloat(rng.r(0.5, weightMax)))
            p.ctx.beginPath()
            p.ctx.move(to: pt(x - cos(a) * len * 0.5, y - sin(a) * len * 0.5))
            p.ctx.addLine(to: pt(x + cos(a) * len * 0.5, y + sin(a) * len * 0.5))
            p.ctx.strokePath()
        }
    }
}

func filmGrain(_ p: Leaf, amplitude: Double, seed: UInt64) {
    let w = 512, h = 512
    var bytes = [UInt8](repeating: 128, count: w * h * 4)
    var rng = Chip(seed)
    let amp = Int(amplitude * 255)
    for i in 0..<(w * h) {
        let v = 128 + rng.i(-amp, amp)
        bytes[i * 4] = UInt8(clamping: v)
        bytes[i * 4 + 1] = UInt8(clamping: v + rng.i(-1, 1))
        bytes[i * 4 + 2] = UInt8(clamping: v + rng.i(-2, 1))
        bytes[i * 4 + 3] = 255
    }
    guard let provider = CGDataProvider(data: Data(bytes) as CFData),
          let img = CGImage(width: w, height: h, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: w * 4,
                            space: deviceRGB, bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                            provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent) else { return }
    p.ctx.saveGState()
    p.ctx.setBlendMode(.overlay)
    p.ctx.setAlpha(0.55)
    p.ctx.draw(img, in: CGRect(x: 0, y: 0, width: w, height: h), byTiling: true)
    p.ctx.restoreGState()
}

func densify(_ pts: [CGPoint], step: Double) -> [CGPoint] {
    var out: [CGPoint] = []
    for i in 0..<pts.count {
        let a = pts[i], b = pts[(i + 1) % pts.count]
        let dx = Double(b.x - a.x), dy = Double(b.y - a.y)
        let len = (dx * dx + dy * dy).squareRoot()
        let n = max(1, Int(len / step))
        for k in 0..<n {
            let t = Double(k) / Double(n)
            out.append(pt(Double(a.x) + dx * t, Double(a.y) + dy * t))
        }
    }
    return out
}

func extrudeSides(_ p: Leaf, _ top: [CGPoint], dx: Double, dy: Double, light: Double, base: Hue,
                  brushAngle: Double?, rng: inout Chip, bevel: Bool = true) {
    let n = top.count
    guard n > 2 else { return }
    let turn: Double = signedTwiceArea(top) > 0 ? -(.pi / 2) : (.pi / 2)
    for i in 0..<n {
        let a = top[i], b = top[(i + 1) % n]
        let ex = Double(b.x - a.x), ey = Double(b.y - a.y)
        guard ex * ex + ey * ey > 0.5 else { continue }
        let na = atan2(ey, ex) + turn
        let nxv = cos(na), nyv = sin(na)
        guard nxv * dx + nyv * dy > 0.002 else { continue }
        let facing = cos(na - light)
        let level = 0.5 + 0.5 * facing
        var tone = base.dk(0.62 * (1 - level))
        if level > 0.5 { tone = tone.lt((level - 0.5) * 0.5) }
        let quad = [a, b, pt(Double(b.x) + dx, Double(b.y) + dy), pt(Double(a.x) + dx, Double(a.y) + dy)]
        p.shape(quad, tone)
        let path = pathOf(quad)
        linearInto(p, path, from: a, to: pt(Double(a.x) + dx, Double(a.y) + dy),
                   colours: [Hue(r: 1, g: 1, b: 1, a: 0.10 * level), Hue(r: 0, g: 0, b: 0, a: 0.0), Hue(r: 0, g: 0, b: 0, a: 0.32)],
                   locations: [0, 0.35, 1])
        if let ba = brushAngle {
            streaks(p, path, count: Int(Double(path.boundingBox.width + path.boundingBox.height) * 1.6), angle: ba,
                    lenMin: 4, lenMax: 16, light: Hue(r: 1, g: 1, b: 1), dark: Hue(r: 0.02, g: 0.03, b: 0.05),
                    alphaMin: 0.03, alphaMax: 0.12, weightMax: 1.3, rng: &rng)
        }
        if bevel {
            pen(p, [a, b], weight: 2.2, colour: Hue(r: 1, g: 0.99, b: 0.96, a: 0.22 + 0.55 * level), wobble: 0.2, taper: true, seed: rng.next())
            pen(p, [pt(Double(a.x) + dx, Double(a.y) + dy), pt(Double(b.x) + dx, Double(b.y) + dy)], weight: 2.6,
                colour: Hue(r: 0, g: 0, b: 0, a: 0.55), wobble: 0.2, taper: false, seed: rng.next())
        }
    }
}

func stipple(_ p: Leaf, _ path: CGPath, density: Double, size: Double, colour: Hue = Pot.ink,
             light: Double = 2.3, falloff: Double = 1.0, seed: UInt64 = 37) {
    guard !path.isEmpty else { return }
    var rng = Chip(seed)
    let box = path.boundingBox
    let count = Int(Double(box.width * box.height) * density)
    let lx = cos(light), ly = sin(light)
    let cx = Double(box.midX), cy = Double(box.midY)
    let span = max(1.0, Double(max(box.width, box.height)) * 0.5)
    p.inside(path) {
        for _ in 0..<max(0, min(30000, count)) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let facing = ((x - cx) * lx + (y - cy) * ly) / span
            let keep = 0.5 - facing * 0.5 * falloff
            if rng.d() < keep {
                p.dot(x, y, size * rng.r(0.5, 1.2), colour.al(rng.r(0.35, 0.85)))
            }
        }
    }
}

func woodGrain(_ p: Leaf, _ clip: CGPath, axis: Double, base: Hue, lines: Int, wave: Double, rng: inout Chip) {
    let box = clip.boundingBox
    let cx = Double(box.midX), cy = Double(box.midY)
    let span = Double(box.width + box.height)
    let dx = cos(axis), dy = sin(axis)
    let qx = -dy, qy = dx
    p.inside(clip) {
        for k in 0..<lines {
            let o = -span / 2 + span * Double(k) / Double(lines) + rng.r(-2, 2)
            let phase = rng.r(0, 6.283)
            let amp = rng.r(wave * 0.3, wave)
            let period = rng.r(0.004, 0.011)
            var pts: [CGPoint] = []
            var s = -span / 2
            while s <= span / 2 {
                let dev = sin(s * period + phase) * amp + sin(s * 0.03 + phase * 3) * amp * 0.15
                pts.append(pt(cx + dx * s + qx * (o + dev), cy + dy * s + qy * (o + dev)))
                s += span / 40
            }
            let dark = rng.chance(0.6)
            let alpha = dark ? rng.r(0.10, 0.30) : rng.r(0.05, 0.14)
            pen(p, pts, weight: rng.r(0.8, 2.6), colour: (dark ? base.dk(0.55) : base.lt(0.35)).al(alpha),
                wobble: 0.5, taper: false, seed: rng.next())
        }
        var flecks: [CGPoint] = []
        for _ in 0..<Int(Double(box.width * box.height) / 900) {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let len = rng.r(3, 12)
            flecks.append(pt(x, y)); flecks.append(pt(x + dx * len, y + dy * len))
        }
        batchSegments(p, flecks, colour: base.lt(0.4).al(0.10), width: 1.0)
    }
}

func clothWeave(_ p: Leaf, _ clip: CGPath, base: Hue, pitch: Double, rng: inout Chip, sheen: Double = 0.0) {
    let box = clip.boundingBox
    p.inside(clip) {
        var warp: [CGPoint] = []
        var weft: [CGPoint] = []
        var x = Double(box.minX)
        while x < Double(box.maxX) {
            warp.append(pt(x, Double(box.minY))); warp.append(pt(x, Double(box.maxY)))
            x += pitch
        }
        var y = Double(box.minY)
        while y < Double(box.maxY) {
            weft.append(pt(Double(box.minX), y)); weft.append(pt(Double(box.maxX), y))
            y += pitch
        }
        batchSegments(p, warp, colour: base.dk(0.35).al(0.32), width: pitch * 0.42)
        batchSegments(p, weft, colour: base.dk(0.30).al(0.26), width: pitch * 0.38)
        var lights: [CGPoint] = []
        for _ in 0..<Int(Double(box.width * box.height) / (pitch * pitch * 2.2)) {
            let px = Double(box.minX) + rng.d() * Double(box.width)
            let py = Double(box.minY) + rng.d() * Double(box.height)
            let along = rng.chance(0.5)
            lights.append(pt(px, py)); lights.append(pt(px + (along ? pitch * 0.7 : 0), py + (along ? 0 : pitch * 0.7)))
        }
        batchSegments(p, lights, colour: base.lt(0.5).al(0.12 + sheen * 0.2), width: pitch * 0.3)
        var fibres: [CGPoint] = []
        for _ in 0..<Int(Double(box.width * box.height) / 700) {
            let px = Double(box.minX) + rng.d() * Double(box.width)
            let py = Double(box.minY) + rng.d() * Double(box.height)
            let a = rng.r(0, 6.283)
            fibres.append(pt(px, py)); fibres.append(pt(px + cos(a) * 3, py + sin(a) * 3))
        }
        batchSegments(p, fibres, colour: base.lt(0.7).al(0.08), width: 0.7)
    }
}

func leatherGrain(_ p: Leaf, _ clip: CGPath, base: Hue, pebble: Double, count: Int, rng: inout Chip) {
    let box = clip.boundingBox
    p.inside(clip) {
        for _ in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let r = pebble * rng.r(0.5, 1.4)
            let lump = lumpy(cx: x, cy: y, rx: r, ry: r * rng.r(0.6, 1.0), rough: 0.25, steps: 9, seed: rng.next())
            p.shape(lump, base.dk(0.45).al(rng.r(0.08, 0.22)))
            p.shape(shifted(lump, -r * 0.35, -r * 0.35), base.lt(0.30).al(rng.r(0.05, 0.14)))
        }
        var creases: [CGPoint] = []
        for _ in 0..<count / 10 {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let a = rng.r(0, 6.283), len = rng.r(pebble * 3, pebble * 9)
            creases.append(pt(x, y)); creases.append(pt(x + cos(a) * len, y + sin(a) * len))
        }
        batchSegments(p, creases, colour: base.dk(0.6).al(0.18), width: 0.9)
    }
}

func paperFibres(_ p: Leaf, _ clip: CGPath, base: Hue, laid: Bool, count: Int, rng: inout Chip) {
    let box = clip.boundingBox
    p.inside(clip) {
        if laid {
            var lines: [CGPoint] = []
            var y = Double(box.minY)
            while y < Double(box.maxY) {
                lines.append(pt(Double(box.minX), y)); lines.append(pt(Double(box.maxX), y))
                y += rng.r(3.6, 4.8)
            }
            batchSegments(p, lines, colour: base.dk(0.25).al(0.20), width: 0.8)
            var chains: [CGPoint] = []
            var x = Double(box.minX) + rng.r(10, 40)
            while x < Double(box.maxX) {
                chains.append(pt(x, Double(box.minY))); chains.append(pt(x, Double(box.maxY)))
                x += rng.r(60, 80)
            }
            batchSegments(p, chains, colour: base.lt(0.4).al(0.32), width: 1.4)
        }
        for _ in 0..<count {
            let x = Double(box.minX) + rng.d() * Double(box.width)
            let y = Double(box.minY) + rng.d() * Double(box.height)
            let a = rng.r(0, 6.283), len = rng.r(3, 16)
            let mid = pt(x + cos(a + 0.3) * len * 0.5, y + sin(a + 0.3) * len * 0.5)
            pen(p, [pt(x, y), mid, pt(x + cos(a) * len, y + sin(a) * len)], weight: rng.r(0.5, 1.2),
                colour: (rng.chance(0.7) ? base.dk(0.3) : base.lt(0.5)).al(rng.r(0.15, 0.45)), wobble: 0.4, taper: true, seed: rng.next())
        }
    }
}

func brushedMetal(_ p: Leaf, _ clip: CGPath, base: Hue, axis: Double, light: Double, rng: inout Chip) {
    let box = clip.boundingBox
    let lx = Double(box.midX) + cos(light) * Double(box.width) * 0.5
    let ly = Double(box.midY) + sin(light) * Double(box.height) * 0.5
    p.fillPath(clip, base)
    radialInto(p, clip, from: pt(lx, ly), inner: base.lt(0.5), outer: base.dk(0.45), radius: Double(max(box.width, box.height)) * 1.2)
    streaks(p, clip, count: Int(Double(box.width * box.height) / 60), angle: axis, lenMin: 6, lenMax: 30,
            light: Hue(r: 1, g: 1, b: 1), dark: Hue(r: 0.03, g: 0.04, b: 0.06), alphaMin: 0.04, alphaMax: 0.14, weightMax: 1.2, rng: &rng)
}

func castShadow(_ p: Leaf, _ poly: [CGPoint], dx: Double, dy: Double, steps: Int = 8, alpha: Double = 0.06) {
    for k in stride(from: steps, through: 1, by: -1) {
        let f = Double(k) / Double(steps)
        p.shape(shifted(poly, dx * f, dy * f), Hue(r: 0.02, g: 0.015, b: 0.01, a: alpha))
    }
}
