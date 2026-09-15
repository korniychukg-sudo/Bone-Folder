import SwiftUI

struct BinderyTone {
    var sky: Color
    var wall: Color
    var bench: Color
    var shaft: Double
    var lamp: Double
    var warm: Double
}

enum BinderyLight {
    static let frames: [(Double, BinderyTone)] = [
        (0, BinderyTone(sky: Color(red: 0.08, green: 0.10, blue: 0.18), wall: Color(red: 0.30, green: 0.26, blue: 0.22), bench: Color(red: 0.20, green: 0.13, blue: 0.08), shaft: 0.0, lamp: 1.0, warm: 0.9)),
        (5.5, BinderyTone(sky: Color(red: 0.55, green: 0.50, blue: 0.60), wall: Color(red: 0.66, green: 0.58, blue: 0.50), bench: Color(red: 0.29, green: 0.20, blue: 0.13), shaft: 0.30, lamp: 0.35, warm: 0.6)),
        (8.5, BinderyTone(sky: Color(red: 0.66, green: 0.76, blue: 0.84), wall: Color(red: 0.86, green: 0.80, blue: 0.70), bench: Color(red: 0.36, green: 0.24, blue: 0.15), shaft: 0.75, lamp: 0.0, warm: 0.2)),
        (12.5, BinderyTone(sky: Color(red: 0.60, green: 0.74, blue: 0.88), wall: Color(red: 0.93, green: 0.88, blue: 0.78), bench: Color(red: 0.40, green: 0.28, blue: 0.18), shaft: 0.95, lamp: 0.0, warm: 0.1)),
        (16.0, BinderyTone(sky: Color(red: 0.70, green: 0.74, blue: 0.78), wall: Color(red: 0.90, green: 0.82, blue: 0.68), bench: Color(red: 0.38, green: 0.26, blue: 0.17), shaft: 0.70, lamp: 0.0, warm: 0.35)),
        (19.0, BinderyTone(sky: Color(red: 0.46, green: 0.36, blue: 0.44), wall: Color(red: 0.68, green: 0.52, blue: 0.40), bench: Color(red: 0.31, green: 0.21, blue: 0.13), shaft: 0.35, lamp: 0.55, warm: 0.8)),
        (22.0, BinderyTone(sky: Color(red: 0.14, green: 0.15, blue: 0.24), wall: Color(red: 0.42, green: 0.34, blue: 0.28), bench: Color(red: 0.23, green: 0.15, blue: 0.10), shaft: 0.05, lamp: 1.0, warm: 0.9))
    ]

    static func at(_ hour: Double) -> BinderyTone {
        let h = hour.truncatingRemainder(dividingBy: 24)
        var lower = frames[frames.count - 1]
        var upper = frames[0]
        var lowerHour = lower.0 - 24
        var upperHour = upper.0
        for i in 0..<frames.count where frames[i].0 <= h {
            lower = frames[i]
            lowerHour = frames[i].0
            if i + 1 < frames.count { upper = frames[i + 1]; upperHour = frames[i + 1].0 }
            else { upper = frames[0]; upperHour = 24 + frames[0].0 }
        }
        let span = max(0.001, upperHour - lowerHour)
        let t = (h - lowerHour) / span
        let a = lower.1, b = upper.1
        return BinderyTone(sky: Color.blend(a.sky, b.sky, t), wall: Color.blend(a.wall, b.wall, t), bench: Color.blend(a.bench, b.bench, t),
                           shaft: a.shaft + (b.shaft - a.shaft) * t, lamp: a.lamp + (b.lamp - a.lamp) * t, warm: a.warm + (b.warm - a.warm) * t)
    }
}

struct Mote {
    let u: Double
    let v: Double
    let speed: Double
    let phase: Double
    let size: Double
}

struct Drop {
    let x: Double
    let phase: Double
    let speed: Double
    let length: Double
}

enum LiveBits {
    static let motes: [Mote] = {
        var rng = Bobbin(seedOf("motes"))
        return (0..<30).map { _ in Mote(u: rng.unit(), v: rng.unit(), speed: rng.range(0.012, 0.03), phase: rng.range(0, 6.283), size: rng.range(0.8, 1.9)) }
    }()

    static let drops: [Drop] = {
        var rng = Bobbin(seedOf("rain"))
        return (0..<46).map { _ in Drop(x: rng.unit(), phase: rng.unit(), speed: rng.range(0.6, 1.3), length: rng.range(8, 22)) }
    }()

    static let flakes: [Drop] = {
        var rng = Bobbin(seedOf("snow"))
        return (0..<36).map { _ in Drop(x: rng.unit(), phase: rng.unit(), speed: rng.range(0.08, 0.16), length: rng.range(2, 4)) }
    }()
}

struct LiveBindery: View {
    var hour: Double
    var weather: Weather
    var pressRemaining: Double?
    var pressTotal: Double
    var pressBookTone: Color?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { ctx, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let tone = BinderyLight.at(hour)
                let w = size.width, h = size.height
                let win = CGRect(x: w * 0.07 - w * 0.022, y: h * 0.05 - h * 0.027, width: w * 0.26 + w * 0.044, height: h * 0.50 + h * 0.054)
                if weather.cloud > 0.5 {
                    ctx.fill(Path(win), with: .color(Color(red: 0.55, green: 0.56, blue: 0.58).opacity((weather.cloud - 0.5) * 0.7)))
                }
                if weather.kind == .rain || weather.kind == .storm {
                    var streaks = Path()
                    for d in LiveBits.drops {
                        let life = (t * d.speed * 0.4 + d.phase).truncatingRemainder(dividingBy: 1)
                        let x = win.minX + CGFloat(d.x) * win.width + CGFloat(sin(t * 0.7) * 3 * weather.wind)
                        let y = win.minY + CGFloat(life) * win.height
                        streaks.move(to: CGPoint(x: x, y: y))
                        streaks.addLine(to: CGPoint(x: x - CGFloat(weather.wind * 3), y: y + CGFloat(d.length)))
                    }
                    var clipped = ctx
                    clipped.clip(to: Path(win))
                    clipped.stroke(streaks, with: .color(Color.white.opacity(weather.kind == .storm ? 0.55 : 0.38)), lineWidth: 1.1)
                    if weather.kind == .storm {
                        let flash = sin(t * 0.9) > 0.985 ? 0.35 : 0.0
                        if flash > 0 { clipped.fill(Path(win), with: .color(Color.white.opacity(flash))) }
                    }
                    for k in 0..<5 {
                        let f = ((t * 0.25) + Double(k) * 0.2).truncatingRemainder(dividingBy: 1)
                        let x = win.minX + win.width * CGFloat(0.15 + Double(k) * 0.18)
                        let y = win.minY + win.height * CGFloat(f)
                        clipped.fill(Path(ellipseIn: CGRect(x: x - 1.5, y: y - 3, width: 3, height: 6)), with: .color(Color.white.opacity(0.5)))
                    }
                }
                if weather.kind == .snow {
                    var clipped = ctx
                    clipped.clip(to: Path(win))
                    for f in LiveBits.flakes {
                        let life = (t * f.speed + f.phase).truncatingRemainder(dividingBy: 1)
                        let x = win.minX + CGFloat(f.x) * win.width + CGFloat(sin(t * 1.3 + f.phase * 7) * 6)
                        let y = win.minY + CGFloat(life) * win.height
                        clipped.fill(Path(ellipseIn: CGRect(x: x - CGFloat(f.length) / 2, y: y - CGFloat(f.length) / 2, width: CGFloat(f.length), height: CGFloat(f.length))), with: .color(Color.white.opacity(0.75)))
                    }
                }
                if tone.shaft > 0.05 && weather.cloud < 0.7 {
                    let top = CGPoint(x: win.midX, y: win.minY + 20)
                    let bottom = h * 0.9
                    for m in LiveBits.motes {
                        let life = (t * m.speed + m.phase).truncatingRemainder(dividingBy: 1)
                        let v = 1 - life
                        let half = 20 + 160 * v
                        let sway = sin(t * 0.9 + m.phase * 3) * 6
                        let px = Double(top.x) + (m.u * 2 - 1) * half * Double(w) / 1200 + sway + v * Double(w) * 0.25
                        let py = Double(top.y) + v * (Double(bottom) - Double(top.y))
                        let twinkle = 0.35 + 0.65 * max(0, sin(t * 2.3 + m.phase * 5))
                        let s = CGFloat(m.size) * w / 600
                        ctx.fill(Path(ellipseIn: CGRect(x: px - Double(s), y: py - Double(s), width: Double(s) * 2, height: Double(s) * 2)), with: .color(Color(red: 1.0, green: 0.92, blue: 0.7).opacity(twinkle * 0.55 * tone.shaft * (1 - weather.cloud))))
                    }
                }
                let kettleX = w * 0.57, kettleY = h * 0.62 + 42 * h / 820 - 60 * h / 820
                for k in 0..<4 {
                    let life = (t * 0.22 + Double(k) * 0.25).truncatingRemainder(dividingBy: 1)
                    let x = kettleX + w * 0.02 + CGFloat(sin(t * 1.7 + Double(k)) * 8 + life * 14)
                    let y = kettleY - CGFloat(life) * h * 0.18
                    let r = CGFloat(6 + life * 16) * w / 600
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r * 0.7, width: r * 2, height: r * 1.4)), with: .color(Color.white.opacity(0.22 * (1 - life))))
                }
                if tone.lamp > 0.05 {
                    let lx = w * 0.94, ly = h * 0.62 - h * 0.11
                    let flicker = 0.88 + 0.12 * sin(t * 23.0) * sin(t * 7.3)
                    let glow = tone.lamp * flicker
                    ctx.fill(Path(ellipseIn: CGRect(x: lx - w * 0.28, y: ly - w * 0.22, width: w * 0.56, height: w * 0.44)),
                             with: .radialGradient(Gradient(colors: [Color(red: 1.0, green: 0.82, blue: 0.5).opacity(0.28 * glow), Color.clear]), center: CGPoint(x: lx, y: ly), startRadius: 0, endRadius: w * 0.28))
                    let fh = CGFloat(10 + 3 * flicker) * h / 820
                    var flame = Path()
                    flame.move(to: CGPoint(x: lx, y: ly - fh * 3.4))
                    flame.addQuadCurve(to: CGPoint(x: lx, y: ly - fh * 1.2), control: CGPoint(x: lx + fh * 0.6, y: ly - fh * 2))
                    flame.addQuadCurve(to: CGPoint(x: lx, y: ly - fh * 3.4), control: CGPoint(x: lx - fh * 0.6, y: ly - fh * 2))
                    ctx.fill(flame, with: .color(Color(red: 1.0, green: 0.86, blue: 0.55).opacity(0.9 * glow)))
                }
                if let remaining = pressRemaining {
                    let strip = CGRect(x: w * 0.66, y: h * 0.80, width: w * 0.28, height: h * 0.028)
                    ctx.fill(Path(roundedRect: strip, cornerRadius: 3), with: .color(Quire.card.opacity(0.85)))
                    let f = CGFloat(max(0, min(1, 1 - remaining / max(1, pressTotal))))
                    ctx.fill(Path(roundedRect: CGRect(x: strip.minX, y: strip.minY, width: strip.width * f, height: strip.height), cornerRadius: 3), with: .color(Quire.brass))
                    ctx.stroke(Path(roundedRect: strip, cornerRadius: 3), with: .color(Quire.ink.opacity(0.6)), lineWidth: 0.8)
                    let label = remaining > 0 ? "\(Clock.durationWords(remaining)) left" : "done"
                    ctx.draw(Text(label).font(Quire.note(10)).foregroundColor(Quire.card), at: CGPoint(x: strip.midX, y: strip.minY - 8))
                    if let bt = pressBookTone {
                        let book = CGRect(x: w * 0.735, y: h * 0.655, width: w * 0.13, height: h * 0.05)
                        ctx.fill(Path(book), with: .color(bt))
                        ctx.stroke(Path(book), with: .color(Quire.ink.opacity(0.6)), lineWidth: 0.8)
                    }
                }
                let unix = timeline.date.timeIntervalSince1970
                let sec = Double(Calendar.current.component(.second, from: timeline.date)) + (unix - floor(unix))
                let cx = w * 0.42, cy = h * 0.16, r = w * 0.028
                ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(Quire.card.opacity(0.9)))
                ctx.stroke(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1)
                let hourA = (hour / 12) * 2 * .pi - .pi / 2
                let minA = ((hour * 60).truncatingRemainder(dividingBy: 60) / 60) * 2 * .pi - .pi / 2
                let secA = sec / 60 * 2 * .pi - .pi / 2
                var hands = Path()
                hands.move(to: CGPoint(x: cx, y: cy)); hands.addLine(to: CGPoint(x: cx + CGFloat(cos(hourA)) * r * 0.5, y: cy + CGFloat(sin(hourA)) * r * 0.5))
                hands.move(to: CGPoint(x: cx, y: cy)); hands.addLine(to: CGPoint(x: cx + CGFloat(cos(minA)) * r * 0.78, y: cy + CGFloat(sin(minA)) * r * 0.78))
                ctx.stroke(hands, with: .color(Quire.ink), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                var second = Path()
                second.move(to: CGPoint(x: cx, y: cy)); second.addLine(to: CGPoint(x: cx + CGFloat(cos(secA)) * r * 0.85, y: cy + CGFloat(sin(secA)) * r * 0.85))
                ctx.stroke(second, with: .color(Quire.thread), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
            }
        }
        .allowsHitTesting(false)
    }
}
