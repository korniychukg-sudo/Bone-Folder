import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

struct Chip {
    var s: UInt64
    init(_ seed: UInt64) { s = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 { s ^= s << 13; s ^= s >> 7; s ^= s << 17; return s }
    mutating func d() -> Double { Double(next() % 1_000_000) / 1_000_000.0 }
    mutating func r(_ a: Double, _ b: Double) -> Double { a + d() * (b - a) }
    mutating func i(_ a: Int, _ b: Int) -> Int { a + Int(next() % UInt64(max(1, b - a + 1))) }
    mutating func chance(_ p: Double) -> Bool { d() < p }
    mutating func signed() -> Double { d() * 2 - 1 }
}

func bits(_ v: Int) -> UInt64 { UInt64(bitPattern: Int64(v)) }

func hashOf(_ name: String) -> UInt64 {
    var h: UInt64 = 14695981039346656037
    for b in name.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
    return h
}

struct Hue {
    var r: Double, g: Double, b: Double, a: Double = 1
    func al(_ v: Double) -> Hue { Hue(r: r, g: g, b: b, a: v) }
    func mix(_ o: Hue, _ t: Double) -> Hue {
        Hue(r: r + (o.r - r) * t, g: g + (o.g - g) * t, b: b + (o.b - b) * t, a: a + (o.a - a) * t)
    }
    func lt(_ t: Double) -> Hue { mix(Hue(r: 1, g: 1, b: 1, a: a), t) }
    func dk(_ t: Double) -> Hue { mix(Hue(r: 0, g: 0, b: 0, a: a), t) }
    static func of(_ t: Tint) -> Hue { Hue(r: t.r, g: t.g, b: t.b) }
}

let deviceRGB = CGColorSpaceCreateDeviceRGB()

func cg(_ c: Hue) -> CGColor {
    CGColor(colorSpace: deviceRGB, components: [CGFloat(c.r), CGFloat(c.g), CGFloat(c.b), CGFloat(c.a)])!
}

enum Pot {
    static let paper      = Hue(r: 0.945, g: 0.914, b: 0.839)
    static let paperWarm  = Hue(r: 0.953, g: 0.910, b: 0.812)
    static let paperCool  = Hue(r: 0.914, g: 0.906, b: 0.859)
    static let paperDeep  = Hue(r: 0.878, g: 0.831, b: 0.741)
    static let linen      = Hue(r: 0.788, g: 0.706, b: 0.553)
    static let linenPale  = Hue(r: 0.878, g: 0.827, b: 0.706)
    static let walnut     = Hue(r: 0.357, g: 0.239, b: 0.153)
    static let walnutDark = Hue(r: 0.200, g: 0.125, b: 0.075)
    static let walnutLight = Hue(r: 0.545, g: 0.392, b: 0.263)
    static let indigo     = Hue(r: 0.180, g: 0.231, b: 0.357)
    static let indigoDeep = Hue(r: 0.098, g: 0.129, b: 0.220)
    static let threadRed  = Hue(r: 0.698, g: 0.227, b: 0.165)
    static let paste      = Hue(r: 0.910, g: 0.863, b: 0.769)
    static let ink        = Hue(r: 0.098, g: 0.086, b: 0.078)
    static let inkSoft    = Hue(r: 0.240, g: 0.215, b: 0.190)
    static let inkPale    = Hue(r: 0.430, g: 0.400, b: 0.360)
    static let sepia      = Hue(r: 0.341, g: 0.251, b: 0.169)
    static let brass      = Hue(r: 0.722, g: 0.573, b: 0.267)
    static let brassPale  = Hue(r: 0.910, g: 0.792, b: 0.478)
    static let steel      = Hue(r: 0.541, g: 0.557, b: 0.580)
    static let steelLight = Hue(r: 0.800, g: 0.812, b: 0.827)
    static let bone       = Hue(r: 0.914, g: 0.878, b: 0.792)
    static let boneDeep   = Hue(r: 0.741, g: 0.686, b: 0.573)
    static let greyboard  = Hue(r: 0.600, g: 0.580, b: 0.540)
    static let daySky     = Hue(r: 0.741, g: 0.804, b: 0.855)
    static let nightSky   = Hue(r: 0.090, g: 0.105, b: 0.180)
    static let lamp       = Hue(r: 1.000, g: 0.847, b: 0.545)
    static let shadowInk  = Hue(r: 0.070, g: 0.055, b: 0.045)
    static let moss       = Hue(r: 0.360, g: 0.420, b: 0.310)
    static let ochre      = Hue(r: 0.780, g: 0.600, b: 0.300)
}

var sheetScale: Double = 1.42

final class Leaf {
    let ctx: CGContext
    let w: Double
    let h: Double
    var light: Double = 2.30

    init(_ wi: Int, _ hi: Int) {
        w = Double(wi); h = Double(hi)
        let pw = Int((Double(wi) * sheetScale).rounded())
        let ph = Int((Double(hi) * sheetScale).rounded())
        ctx = CGContext(data: nil, width: pw, height: ph, bitsPerComponent: 8,
                        bytesPerRow: pw * 4, space: deviceRGB,
                        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
        ctx.scaleBy(x: CGFloat(sheetScale), y: CGFloat(sheetScale))
        ctx.setShouldAntialias(true)
        ctx.interpolationQuality = .high
    }

    func flipDown() {
        ctx.translateBy(x: 0, y: CGFloat(h))
        ctx.scaleBy(x: 1, y: -1)
    }

    func fillAll(_ c: Hue) {
        ctx.setFillColor(cg(c)); ctx.fill(CGRect(x: -2, y: -2, width: w + 4, height: h + 4))
    }

    func box(_ x: Double, _ y: Double, _ rw: Double, _ rh: Double, _ c: Hue) {
        ctx.setFillColor(cg(c)); ctx.fill(CGRect(x: x, y: y, width: rw, height: rh))
    }

    func dot(_ x: Double, _ y: Double, _ rad: Double, _ c: Hue) {
        ctx.setFillColor(cg(c))
        ctx.fillEllipse(in: CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2))
    }

    func egg(_ x: Double, _ y: Double, _ rx: Double, _ ry: Double, _ c: Hue) {
        ctx.setFillColor(cg(c))
        ctx.fillEllipse(in: CGRect(x: x - rx, y: y - ry, width: rx * 2, height: ry * 2))
    }

    func hoop(_ x: Double, _ y: Double, _ rad: Double, _ width: Double, _ c: Hue) {
        ctx.setStrokeColor(cg(c)); ctx.setLineWidth(CGFloat(width))
        ctx.strokeEllipse(in: CGRect(x: x - rad, y: y - rad, width: rad * 2, height: rad * 2))
    }

    func shape(_ pts: [CGPoint], _ c: Hue) {
        guard pts.count > 2 else { return }
        ctx.setFillColor(cg(c)); ctx.beginPath(); ctx.move(to: pts[0])
        for p in pts.dropFirst() { ctx.addLine(to: p) }
        ctx.closePath(); ctx.fillPath()
    }

    func fillPath(_ path: CGPath, _ c: Hue) {
        guard !path.isEmpty else { return }
        ctx.setFillColor(cg(c)); ctx.beginPath(); ctx.addPath(path); ctx.fillPath()
    }

    func strokePath(_ path: CGPath, _ width: Double, _ c: Hue) {
        guard !path.isEmpty else { return }
        ctx.setStrokeColor(cg(c)); ctx.setLineWidth(CGFloat(width)); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        ctx.beginPath(); ctx.addPath(path); ctx.strokePath()
    }

    func rule(_ a: CGPoint, _ b: CGPoint, _ width: Double, _ c: Hue, dash: [CGFloat] = []) {
        ctx.saveGState()
        ctx.setStrokeColor(cg(c)); ctx.setLineWidth(CGFloat(width)); ctx.setLineCap(.round)
        if !dash.isEmpty { ctx.setLineDash(phase: 0, lengths: dash) }
        ctx.beginPath(); ctx.move(to: a); ctx.addLine(to: b); ctx.strokePath()
        ctx.restoreGState()
    }

    func polyline(_ pts: [CGPoint], _ width: Double, _ c: Hue, dash: [CGFloat] = []) {
        guard pts.count > 1 else { return }
        ctx.saveGState()
        ctx.setStrokeColor(cg(c)); ctx.setLineWidth(CGFloat(width)); ctx.setLineCap(.round); ctx.setLineJoin(.round)
        if !dash.isEmpty { ctx.setLineDash(phase: 0, lengths: dash) }
        ctx.beginPath(); ctx.move(to: pts[0])
        for p in pts.dropFirst() { ctx.addLine(to: p) }
        ctx.strokePath()
        ctx.restoreGState()
    }

    func inside(_ path: CGPath, _ body: () -> Void) {
        guard !path.isEmpty else { return }
        ctx.saveGState(); ctx.beginPath(); ctx.addPath(path); ctx.clip(); body(); ctx.restoreGState()
    }

    func insideBoth(_ a: CGPath, _ b: CGPath, _ body: () -> Void) {
        guard !a.isEmpty, !b.isEmpty else { return }
        ctx.saveGState()
        ctx.beginPath(); ctx.addPath(a); ctx.clip()
        ctx.beginPath(); ctx.addPath(b); ctx.clip()
        body()
        ctx.restoreGState()
    }

    func insideRect(_ r: CGRect, _ body: () -> Void) {
        ctx.saveGState(); ctx.clip(to: r); body(); ctx.restoreGState()
    }

    func image() -> CGImage? { ctx.makeImage() }

    func drawImage(_ image: CGImage, into rect: CGRect) {
        ctx.saveGState()
        ctx.translateBy(x: rect.minX, y: rect.maxY)
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: rect.width, height: rect.height))
        ctx.restoreGState()
    }

    func writeJPG(_ dir: String, _ name: String, quality: Double = 0.86) {
        guard let img = ctx.makeImage() else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).jpg")
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, img,
                                   [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        CGImageDestinationFinalize(dest)
    }

    func writePNG(_ dir: String, _ name: String) {
        guard let img = ctx.makeImage() else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
        guard let dest = CGImageDestinationCreateWithURL(
            url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
        CGImageDestinationAddImage(dest, img, nil)
        CGImageDestinationFinalize(dest)
    }
}

func pt(_ x: Double, _ y: Double) -> CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }

func pathOf(_ pts: [CGPoint], close: Bool = true) -> CGPath {
    let p = CGMutablePath()
    guard let first = pts.first else { return p }
    p.move(to: first)
    for q in pts.dropFirst() { p.addLine(to: q) }
    if close { p.closeSubpath() }
    return p
}

func rectPath(_ x: Double, _ y: Double, _ w: Double, _ h: Double) -> CGPath {
    pathOf([pt(x, y), pt(x + w, y), pt(x + w, y + h), pt(x, y + h)])
}

func shifted(_ pts: [CGPoint], _ dx: Double, _ dy: Double) -> [CGPoint] {
    pts.map { pt(Double($0.x) + dx, Double($0.y) + dy) }
}

func resample(_ pts: [CGPoint], count: Int) -> [CGPoint] {
    guard pts.count > 1, count > 1 else { return pts }
    var lengths: [Double] = [0]
    var total = 0.0
    for i in 1..<pts.count {
        let dx = Double(pts[i].x - pts[i - 1].x), dy = Double(pts[i].y - pts[i - 1].y)
        total += (dx * dx + dy * dy).squareRoot()
        lengths.append(total)
    }
    guard total > 0 else { return pts }
    var out: [CGPoint] = []
    var seg = 1
    for k in 0..<count {
        let target = total * Double(k) / Double(count - 1)
        while seg < lengths.count - 1 && lengths[seg] < target { seg += 1 }
        let l0 = lengths[seg - 1], l1 = lengths[seg]
        let t = l1 > l0 ? (target - l0) / (l1 - l0) : 0
        let a = pts[seg - 1], b = pts[seg]
        out.append(CGPoint(x: a.x + (b.x - a.x) * CGFloat(t), y: a.y + (b.y - a.y) * CGFloat(t)))
    }
    return out
}

func catmull(_ pts: [CGPoint], steps: Int = 12) -> [CGPoint] {
    guard pts.count > 2 else { return pts }
    var out: [CGPoint] = []
    for i in 0..<(pts.count - 1) {
        let p0 = pts[max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(pts.count - 1, i + 2)]
        for s in 0..<steps {
            let t = Double(s) / Double(steps)
            let t2 = t * t, t3 = t2 * t
            let x = 0.5 * (2 * Double(p1.x) + (-Double(p0.x) + Double(p2.x)) * t
                           + (2 * Double(p0.x) - 5 * Double(p1.x) + 4 * Double(p2.x) - Double(p3.x)) * t2
                           + (-Double(p0.x) + 3 * Double(p1.x) - 3 * Double(p2.x) + Double(p3.x)) * t3)
            let y = 0.5 * (2 * Double(p1.y) + (-Double(p0.y) + Double(p2.y)) * t
                           + (2 * Double(p0.y) - 5 * Double(p1.y) + 4 * Double(p2.y) - Double(p3.y)) * t2
                           + (-Double(p0.y) + 3 * Double(p1.y) - 3 * Double(p2.y) + Double(p3.y)) * t3)
            out.append(pt(x, y))
        }
    }
    out.append(pts[pts.count - 1])
    return out
}

func layPaper(_ p: Leaf, seed: UInt64, tone: Hue = Pot.paper, laid: Bool = true) {
    var rng = Chip(seed)
    p.fillAll(tone)
    for _ in 0..<20 {
        let x = rng.d() * p.w, y = rng.d() * p.h
        let rr = rng.r(p.w * 0.05, p.w * 0.18)
        let warm = rng.chance(0.6)
        if let g = CGGradient(colorsSpace: deviceRGB,
                              colors: [cg(warm ? tone.lt(0.045).al(0.22) : tone.dk(0.036).al(0.17)),
                                       cg(tone.al(0))] as CFArray, locations: [0, 1]) {
            p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: x, y: y), startRadius: 0,
                                     endCenter: CGPoint(x: x, y: y), endRadius: rr, options: [])
        }
    }
    if laid {
        var y = 0.0
        while y < p.h {
            p.box(0, y, p.w, 1.0 / sheetScale, tone.dk(0.058).al(0.30))
            y += rng.r(4.0, 5.6)
        }
        var x = rng.r(0, 90)
        while x < p.w {
            p.box(x, 0, 1.4 / sheetScale, p.h, tone.lt(0.10).al(0.26))
            x += rng.r(70, 94)
        }
    }
    for _ in 0..<Int(p.w * p.h * sheetScale * sheetScale / 3600) {
        let fx = rng.d() * p.w, fy = rng.d() * p.h
        let a = rng.r(0, 6.283), len = rng.r(3, 14)
        p.ctx.setStrokeColor(cg(tone.dk(rng.r(0.05, 0.18)).al(rng.r(0.14, 0.42))))
        p.ctx.setLineWidth(rng.r(0.6, 1.3))
        p.ctx.beginPath()
        p.ctx.move(to: CGPoint(x: fx, y: fy))
        p.ctx.addLine(to: CGPoint(x: fx + cos(a) * len, y: fy + sin(a) * len))
        p.ctx.strokePath()
    }
    for _ in 0..<rng.i(2, 4) {
        let sx = rng.d() * p.w, sy = rng.d() * p.h
        let rr = rng.r(p.w * 0.05, p.w * 0.15)
        var band: [CGPoint] = []
        var a = 0.0
        while a < 6.283 {
            band.append(CGPoint(x: sx + cos(a) * rr * rng.r(0.80, 1.20),
                                y: sy + sin(a) * rr * rng.r(0.80, 1.20)))
            a += 0.34
        }
        p.shape(band, Hue(r: 0.514, g: 0.431, b: 0.306, a: 0.055))
    }
    if let g = CGGradient(colorsSpace: deviceRGB,
                          colors: [cg(tone.dk(0.17).al(0)), cg(tone.dk(0.17).al(0.52))] as CFArray,
                          locations: [0.58, 1]) {
        p.ctx.drawRadialGradient(g, startCenter: CGPoint(x: p.w / 2, y: p.h / 2), startRadius: 0,
                                 endCenter: CGPoint(x: p.w / 2, y: p.h / 2),
                                 endRadius: max(p.w, p.h) * 0.74, options: [.drawsAfterEndLocation])
    }
}

func wash(_ p: Leaf, _ region: [CGPoint], _ colour: Hue,
          strength: Double = 0.42, bleed: Double = 6, seed: UInt64) {
    guard region.count > 2 else { return }
    var rng = Chip(seed)
    var edge: [CGPoint] = []
    for q in resample(region + [region[0]], count: max(24, region.count * 3)) {
        edge.append(CGPoint(x: q.x + CGFloat(rng.signed() * bleed), y: q.y + CGFloat(rng.signed() * bleed)))
    }
    let path = pathOf(edge)
    p.ctx.setFillColor(cg(colour.al(strength)))
    p.ctx.beginPath(); p.ctx.addPath(path); p.ctx.fillPath()
    p.ctx.setStrokeColor(cg(colour.dk(0.20).al(strength * 0.54)))
    p.ctx.setLineWidth(CGFloat(bleed * 1.6))
    p.ctx.setLineJoin(.round)
    p.ctx.beginPath(); p.ctx.addPath(path); p.ctx.strokePath()
    p.inside(path) {
        let boxRect = path.boundingBox
        let unit = Double(min(boxRect.width, boxRect.height))
        let count = Int(Double(boxRect.width * boxRect.height) / (unit * unit * 0.5)) + 18
        for _ in 0..<min(170, count) {
            let x = Double(boxRect.minX) + rng.d() * Double(boxRect.width)
            let y = Double(boxRect.minY) + rng.d() * Double(boxRect.height)
            let rx = rng.r(unit * 0.020, unit * 0.085)
            let ry = rx * rng.r(0.35, 0.85)
            p.egg(x, y, rx, ry, rng.chance(0.62)
                  ? colour.dk(0.15).al(strength * 0.14)
                  : colour.lt(0.26).al(strength * 0.10))
        }
    }
}

func washBand(_ p: Leaf, from y0: Double, to y1: Double, _ colour: Hue,
              strength: Double, seed: UInt64) {
    var rng = Chip(seed)
    let over = p.w * 0.09
    var top: [CGPoint] = []
    var x = -over
    while x <= p.w + over {
        top.append(CGPoint(x: x, y: y1 + CGFloat(rng.signed() * (abs(y1 - y0) * 0.10 + 4))))
        x += p.w / 22
    }
    var region: [CGPoint] = [CGPoint(x: CGFloat(-over), y: CGFloat(y0))]
    region.append(contentsOf: top)
    region.append(CGPoint(x: CGFloat(p.w + over), y: CGFloat(y0)))
    wash(p, region, colour, strength: strength, bleed: max(3, abs(y1 - y0) * 0.05), seed: seed &+ 5)
}

func pen(_ p: Leaf, _ pts: [CGPoint], weight: Double, colour: Hue = Pot.ink,
         wobble: Double = 1.0, taper: Bool = true, seed: UInt64 = 7) {
    guard pts.count > 1, weight > 0 else { return }
    var rng = Chip(seed)
    let n = max(10, min(96, Int(weight * 14)))
    let spine = resample(pts, count: n)
    var left: [CGPoint] = []
    var right: [CGPoint] = []
    for i in 0..<spine.count {
        let t = Double(i) / Double(spine.count - 1)
        let a = spine[max(0, i - 1)], b = spine[min(spine.count - 1, i + 1)]
        var tx = Double(b.x - a.x), ty = Double(b.y - a.y)
        let len = (tx * tx + ty * ty).squareRoot()
        if len > 0 { tx /= len; ty /= len } else { tx = 1; ty = 0 }
        let nx = -ty, ny = tx
        let swell = taper ? pow(sin(.pi * t), 0.42) : 1.0
        let hw = max(0.32, weight * 0.5 * (0.55 + 0.45 * swell)) * rng.r(0.88, 1.12)
        let off = rng.signed() * wobble
        let cx = Double(spine[i].x) + nx * off
        let cy = Double(spine[i].y) + ny * off
        left.append(CGPoint(x: cx + nx * hw, y: cy + ny * hw))
        right.append(CGPoint(x: cx - nx * hw, y: cy - ny * hw))
    }
    p.shape(left + right.reversed(), colour)
}

func penBroken(_ p: Leaf, _ pts: [CGPoint], weight: Double, colour: Hue = Pot.ink,
               pieces: Int = 3, gap: Double = 0.10, wobble: Double = 0.9, seed: UInt64 = 11) {
    var rng = Chip(seed)
    let spine = resample(pts, count: 60)
    var t = 0.0
    var k = 0
    while t < 1.0 {
        let run = rng.r(0.7, 1.3) / Double(max(1, pieces))
        let end = min(1.0, t + run)
        let i0 = Int(t * 59), i1 = Int(end * 59)
        if i1 > i0 + 1 {
            pen(p, Array(spine[i0...i1]), weight: weight * rng.r(0.82, 1.12),
                colour: colour, wobble: wobble, taper: true, seed: seed &+ UInt64(k) &+ 1)
        }
        t = end + rng.r(gap * 0.4, gap * 1.4)
        k += 1
    }
}

func penEdge(_ p: Leaf, _ pts: [CGPoint], weight: Double, colour: Hue = Pot.ink, seed: UInt64 = 13) {
    guard pts.count > 2 else { return }
    let closed = pts + [pts[0]]
    for i in 0..<(closed.count - 1) {
        let a = closed[i], b = closed[i + 1]
        let ang = atan2(Double(b.y - a.y), Double(b.x - a.x))
        let facing = cos(ang + .pi / 2 - p.light)
        let wt = weight * (0.60 + 0.66 * max(0, -facing))
        pen(p, [a, b], weight: wt, colour: colour, wobble: weight * 0.28,
            taper: false, seed: seed &+ UInt64(i * 17 + 3))
    }
}

func rules(_ p: Leaf, _ path: CGPath, angle: Double, spacing: Double,
           weight: Double = 1.1, colour: Hue = Pot.inkSoft,
           coverage: Double = 0.88, bound: CGPath? = nil, seed: UInt64 = 17) {
    guard !path.isEmpty else { return }
    var rng = Chip(seed)
    let boxRect = path.boundingBox.insetBy(dx: -6, dy: -6)
    guard boxRect.width > 1, boxRect.height > 1 else { return }
    let dx = cos(angle), dy = sin(angle)
    let span = Double(boxRect.width + boxRect.height) * 1.2
    let body: () -> Void = {
        var t = -span / 2
        while t < span / 2 {
            if rng.d() <= coverage {
                let cx = Double(boxRect.midX) - dy * t
                let cy = Double(boxRect.midY) + dx * t
                let pieces = rng.i(2, 4)
                var u = -0.5 + rng.r(0, 0.10)
                for k in 0..<pieces {
                    let run = rng.r(0.08, 0.20)
                    let a = CGPoint(x: cx + dx * span * u, y: cy + dy * span * u)
                    let b = CGPoint(x: cx + dx * span * (u + run), y: cy + dy * span * (u + run))
                    pen(p, [a, b], weight: weight * rng.r(0.7, 1.25),
                        colour: colour.al(rng.r(0.55, 0.95)), wobble: 0.85, taper: true,
                        seed: seed &+ bits(Int(t) &* 31 &+ k &+ 101))
                    u += run + rng.r(0.03, 0.13)
                }
            }
            t += spacing * rng.r(0.86, 1.18)
        }
    }
    if let b = bound { p.insideBoth(path, b, body) } else { p.inside(path, body) }
}

func crossHatch(_ p: Leaf, _ path: CGPath, depth: Int, spacing: Double,
                colour: Hue = Pot.inkSoft, bound: CGPath? = nil, seed: UInt64 = 23) {
    let base = p.light + .pi / 2
    rules(p, path, angle: base, spacing: spacing, weight: 1.05, colour: colour,
          coverage: 0.92, bound: bound, seed: seed)
    if depth >= 2 {
        rules(p, path, angle: base + 1.0, spacing: spacing * 1.15, weight: 0.95,
              colour: colour, coverage: 0.78, bound: bound, seed: seed &+ 71)
    }
    if depth >= 3 {
        rules(p, path, angle: base - 0.9, spacing: spacing * 1.35, weight: 0.85,
              colour: colour, coverage: 0.62, bound: bound, seed: seed &+ 131)
    }
}

func roundShade(_ p: Leaf, _ pts: [CGPoint], inset: Double, depth: Int, spacing: Double,
                colour: Hue = Pot.inkSoft, seed: UInt64 = 53) {
    guard pts.count > 3 else { return }
    var cx = 0.0, cy = 0.0
    for q in pts { cx += Double(q.x); cy += Double(q.y) }
    cx /= Double(pts.count); cy /= Double(pts.count)
    let lx = cos(p.light), ly = sin(p.light)
    var outer: [CGPoint] = []
    var inner: [CGPoint] = []
    for q in pts {
        var dx = Double(q.x) - cx, dy = Double(q.y) - cy
        let len = (dx * dx + dy * dy).squareRoot()
        guard len > 0 else { continue }
        dx /= len; dy /= len
        let facing = dx * lx + dy * ly
        guard facing < 0.12 else { continue }
        let pull = inset * min(1.0, -facing + 0.12) * 1.4
        outer.append(q)
        inner.append(CGPoint(x: q.x - CGFloat(dx * pull), y: q.y - CGFloat(dy * pull)))
    }
    guard outer.count > 2 else { return }
    crossHatch(p, pathOf(outer + inner.reversed()), depth: depth, spacing: spacing,
               colour: colour, bound: pathOf(pts), seed: seed)
}

func grit(_ p: Leaf, _ path: CGPath, density: Double, sizeMin: Double, sizeMax: Double,
          colour: Hue = Pot.inkSoft, seed: UInt64 = 29) {
    guard !path.isEmpty else { return }
    var rng = Chip(seed)
    let boxRect = path.boundingBox
    let count = Int(Double(boxRect.width * boxRect.height) * density)
    p.inside(path) {
        for _ in 0..<max(0, min(24000, count)) {
            let x = Double(boxRect.minX) + rng.d() * Double(boxRect.width)
            let y = Double(boxRect.minY) + rng.d() * Double(boxRect.height)
            p.dot(x, y, rng.r(sizeMin, sizeMax), colour.al(rng.r(0.28, 0.85)))
        }
    }
}

func ringOf(cx: Double, cy: Double, rx: Double, ry: Double, steps: Int) -> [CGPoint] {
    var out: [CGPoint] = []
    for i in 0..<steps {
        let a = Double(i) / Double(steps) * 6.283185
        out.append(CGPoint(x: cx + cos(a) * rx, y: cy + sin(a) * ry))
    }
    return out
}

func lumpy(cx: Double, cy: Double, rx: Double, ry: Double, rough: Double,
           steps: Int = 28, seed: UInt64 = 41) -> [CGPoint] {
    var rng = Chip(seed)
    var out: [CGPoint] = []
    for i in 0..<steps {
        let a = Double(i) / Double(steps) * 6.283185
        let k = 1.0 + rng.signed() * rough
        out.append(CGPoint(x: cx + cos(a) * rx * k, y: cy + sin(a) * ry * k))
    }
    return out
}

func rrect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double, _ r: Double) -> [CGPoint] {
    var out: [CGPoint] = []
    let corners: [(Double, Double, Double)] = [(x1 - r, y0 + r, -Double.pi / 2), (x1 - r, y1 - r, 0),
                                                 (x0 + r, y1 - r, Double.pi / 2), (x0 + r, y0 + r, Double.pi)]
    for (cx, cy, a0) in corners {
        for k in 0...5 {
            let a = a0 + Double(k) / 5 * Double.pi / 2
            out.append(pt(cx + cos(a) * r, cy + sin(a) * r))
        }
    }
    return out
}

enum Justify { case left, centre, right }

func letter(_ p: Leaf, _ text: String, at x: Double, _ y: Double, size: Double,
            colour: Hue = Pot.ink, face: String = "Cochin", align: Justify = .centre,
            tracking: Double = 0, rotate: Double = 0) {
    guard !text.isEmpty else { return }
    let font = CTFontCreateWithName(face as CFString, CGFloat(size), nil)
    var attrs: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): cg(colour)
    ]
    if tracking != 0 {
        attrs[NSAttributedString.Key(kCTKernAttributeName as String)] = CGFloat(tracking)
    }
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attrs))
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    var dx = 0.0
    switch align {
    case .left: dx = 0
    case .centre: dx = -Double(bounds.width) / 2
    case .right: dx = -Double(bounds.width)
    }
    p.ctx.saveGState()
    p.ctx.translateBy(x: CGFloat(x), y: CGFloat(y))
    if rotate != 0 { p.ctx.rotate(by: CGFloat(rotate)) }
    p.ctx.scaleBy(x: 1, y: -1)
    p.ctx.textPosition = CGPoint(x: CGFloat(dx), y: 0)
    CTLineDraw(line, p.ctx)
    p.ctx.restoreGState()
}

func letterWidth(_ text: String, size: Double, face: String = "Cochin") -> Double {
    let font = CTFontCreateWithName(face as CFString, CGFloat(size), nil)
    let line = CTLineCreateWithAttributedString(
        NSAttributedString(string: text, attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font]))
    return Double(CTLineGetBoundsWithOptions(line, .useOpticalBounds).width)
}

func wrapText(_ text: String, width: Double, size: Double, face: String = "Cochin") -> [String] {
    var lines: [String] = []
    var current = ""
    for word in text.split(separator: " ") {
        let trial = current.isEmpty ? String(word) : current + " " + String(word)
        if letterWidth(trial, size: size, face: face) > width && !current.isEmpty {
            lines.append(current); current = String(word)
        } else {
            current = trial
        }
    }
    if !current.isEmpty { lines.append(current) }
    return lines
}

func borderRule(_ p: Leaf, inset: Double, seed: UInt64) {
    var rng = Chip(seed)
    func frame(_ i: Double, _ wgt: Double, _ shade: Hue) {
        let c: [CGPoint] = [pt(i, i), pt(p.w - i, i), pt(p.w - i, p.h - i), pt(i, p.h - i)]
        for k in 0..<4 {
            pen(p, [c[k], c[(k + 1) % 4]], weight: wgt, colour: shade,
                wobble: 0.7, taper: false, seed: seed &+ UInt64(k * 7 + 1))
        }
    }
    frame(inset, 2.4, Pot.ink)
    frame(inset + rng.r(8, 12), 1.1, Pot.inkSoft)
}

func plateGround(_ p: Leaf, seed: UInt64, tone: Hue = Pot.paperWarm, border: Bool = true) {
    layPaper(p, seed: seed, tone: tone)
    p.flipDown()
    p.light = 2.34
    if border { borderRule(p, inset: 30, seed: seed &+ 3) }
}

func plateCaption(_ p: Leaf, title: String, sub: String, y: Double, size: Double = 40) {
    p.box(p.w * 0.10, y, p.w * 0.80, 1.5, Pot.ink.al(0.32))
    letter(p, title, at: p.w / 2, y + size * 1.3, size: size, colour: Pot.ink, face: "Cochin-Bold", align: .centre)
    if !sub.isEmpty {
        for (i, line) in wrapText(sub, width: p.w * 0.78, size: size * 0.6, face: "Cochin-Italic").prefix(3).enumerated() {
            letter(p, line, at: p.w / 2, y + size * 2.3 + Double(i) * size * 0.8, size: size * 0.6, colour: Pot.inkSoft,
                   face: "Cochin-Italic", align: .centre)
        }
    }
}

func contactSheet(_ dir: String, _ name: String, tiles: [(String, CGImage)], columns: Int, tile: Int) {
    let rows = (tiles.count + columns - 1) / columns
    let tw = Double(tile), th = Double(tile) * 0.75 + 26
    let previous = sheetScale
    sheetScale = 1.0
    let sheet = Leaf(columns * tile + 16, Int(th) * max(1, rows) + 16)
    sheet.fillAll(Hue(r: 0.92, g: 0.92, b: 0.92))
    sheet.flipDown()
    for (k, (label, img)) in tiles.enumerated() {
        let col = k % columns, row = k / columns
        let x = 8 + Double(col) * tw, y = 8 + Double(row) * th
        sheet.drawImage(img, into: CGRect(x: x + 3, y: y + 3, width: tw - 6, height: tw * 0.75 - 6))
        letter(sheet, label, at: x + tw / 2, y + tw * 0.75 + 16, size: 14, colour: Pot.ink, face: "AvenirNext-Medium")
    }
    sheet.writeJPG(dir, name, quality: 0.8)
    sheetScale = previous
}
