import SwiftUI

struct BenchMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var top = Path()
            top.move(to: CGPoint(x: w * 0.06, y: h * 0.50))
            top.addLine(to: CGPoint(x: w * 0.94, y: h * 0.50))
            top.addLine(to: CGPoint(x: w * 0.86, y: h * 0.60))
            top.addLine(to: CGPoint(x: w * 0.14, y: h * 0.60))
            top.closeSubpath()
            ctx.fill(top, with: .color(color))
            for x in [0.20, 0.80] {
                ctx.fill(Path(CGRect(x: w * x - w * 0.03, y: h * 0.60, width: w * 0.06, height: h * 0.28)), with: .color(color.opacity(0.8)))
            }
            var block = Path()
            block.move(to: CGPoint(x: w * 0.30, y: h * 0.48))
            block.addLine(to: CGPoint(x: w * 0.30, y: h * 0.28))
            block.addLine(to: CGPoint(x: w * 0.66, y: h * 0.28))
            block.addLine(to: CGPoint(x: w * 0.66, y: h * 0.48))
            block.closeSubpath()
            ctx.fill(block, with: .color(color.opacity(0.55)))
            var stitches = Path()
            for k in 0..<3 {
                let y = h * (0.32 + Double(k) * 0.06)
                stitches.move(to: CGPoint(x: w * 0.34, y: y))
                stitches.addLine(to: CGPoint(x: w * 0.62, y: y))
            }
            ctx.stroke(stitches, with: .color(color), lineWidth: w * 0.03)
            var needle = Path()
            needle.move(to: CGPoint(x: w * 0.62, y: h * 0.26))
            needle.addLine(to: CGPoint(x: w * 0.86, y: h * 0.08))
            ctx.stroke(needle, with: .color(color), style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct TodayMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let frame = Path(CGRect(x: w * 0.14, y: h * 0.10, width: w * 0.50, height: h * 0.62))
            ctx.stroke(frame, with: .color(color), lineWidth: w * 0.07)
            var bars = Path()
            bars.move(to: CGPoint(x: w * 0.39, y: h * 0.10)); bars.addLine(to: CGPoint(x: w * 0.39, y: h * 0.72))
            bars.move(to: CGPoint(x: w * 0.14, y: h * 0.41)); bars.addLine(to: CGPoint(x: w * 0.64, y: h * 0.41))
            ctx.stroke(bars, with: .color(color), lineWidth: w * 0.05)
            ctx.fill(Path(CGRect(x: w * 0.04, y: h * 0.78, width: w * 0.92, height: h * 0.10)), with: .color(color))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.72, y: h * 0.56, width: w * 0.18, height: h * 0.20)), with: .color(color.opacity(0.85)))
        }
        .frame(width: size, height: size)
    }
}

struct RegisterMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            ctx.stroke(Path(CGRect(x: w * 0.10, y: h * 0.12, width: w * 0.80, height: h * 0.76)), with: .color(color), lineWidth: w * 0.07)
            for k in 0..<3 {
                let y = h * (0.28 + Double(k) * 0.20)
                ctx.fill(Path(CGRect(x: w * 0.22, y: y, width: w * 0.56, height: h * 0.07)), with: .color(color.opacity(0.85)))
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: y + h * 0.10, width: w * 0.08, height: h * 0.06)), with: .color(color.opacity(0.6)))
            }
        }
        .frame(width: size, height: size)
    }
}

struct ShelfMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            let spines: [(Double, Double, Double)] = [(0.12, 0.14, 0.30), (0.28, 0.16, 0.22), (0.46, 0.13, 0.34), (0.61, 0.17, 0.26)]
            for (x, sw, top) in spines {
                ctx.fill(Path(CGRect(x: w * x, y: h * top, width: w * sw, height: h * (0.78 - top))), with: .color(color.opacity(0.85)))
            }
            var lean = Path()
            lean.move(to: CGPoint(x: w * 0.80, y: h * 0.78))
            lean.addLine(to: CGPoint(x: w * 0.92, y: h * 0.26))
            lean.addLine(to: CGPoint(x: w * 0.98, y: h * 0.30))
            lean.addLine(to: CGPoint(x: w * 0.90, y: h * 0.78))
            lean.closeSubpath()
            ctx.fill(lean, with: .color(color.opacity(0.7)))
            ctx.fill(Path(CGRect(x: w * 0.04, y: h * 0.78, width: w * 0.92, height: h * 0.09)), with: .color(color))
        }
        .frame(width: size, height: size)
    }
}

struct BookMark: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var left = Path()
            left.move(to: CGPoint(x: w * 0.50, y: h * 0.22))
            left.addQuadCurve(to: CGPoint(x: w * 0.08, y: h * 0.18), control: CGPoint(x: w * 0.30, y: h * 0.08))
            left.addLine(to: CGPoint(x: w * 0.08, y: h * 0.82))
            left.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.88), control: CGPoint(x: w * 0.30, y: h * 0.74))
            left.closeSubpath()
            ctx.fill(left, with: .color(color.opacity(0.85)))
            var right = Path()
            right.move(to: CGPoint(x: w * 0.50, y: h * 0.22))
            right.addQuadCurve(to: CGPoint(x: w * 0.92, y: h * 0.18), control: CGPoint(x: w * 0.70, y: h * 0.08))
            right.addLine(to: CGPoint(x: w * 0.92, y: h * 0.82))
            right.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.88), control: CGPoint(x: w * 0.70, y: h * 0.74))
            right.closeSubpath()
            ctx.fill(right, with: .color(color.opacity(0.85)))
            var spine = Path()
            spine.move(to: CGPoint(x: w * 0.50, y: h * 0.22))
            spine.addLine(to: CGPoint(x: w * 0.50, y: h * 0.88))
            ctx.stroke(spine, with: .color(color), lineWidth: w * 0.06)
        }
        .frame(width: size, height: size)
    }
}

struct ChevGlyph: View {
    var size: CGFloat
    var color: Color
    var right: Bool = false
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            if right {
                p.move(to: CGPoint(x: w * 0.34, y: h * 0.16))
                p.addLine(to: CGPoint(x: w * 0.68, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.34, y: h * 0.84))
            } else {
                p.move(to: CGPoint(x: w * 0.66, y: h * 0.16))
                p.addLine(to: CGPoint(x: w * 0.32, y: h * 0.50))
                p.addLine(to: CGPoint(x: w * 0.66, y: h * 0.84))
            }
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w * 0.13, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct CrossGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.22, y: h * 0.22)); p.addLine(to: CGPoint(x: w * 0.78, y: h * 0.78))
            p.move(to: CGPoint(x: w * 0.78, y: h * 0.22)); p.addLine(to: CGPoint(x: w * 0.22, y: h * 0.78))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w * 0.12, lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct CheckGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.18, y: h * 0.54))
            p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.76))
            p.addLine(to: CGPoint(x: w * 0.84, y: h * 0.26))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w * 0.13, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct GearlessCog: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            var p = Path()
            p.move(to: CGPoint(x: w * 0.20, y: h * 0.30)); p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.30))
            p.move(to: CGPoint(x: w * 0.20, y: h * 0.50)); p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.50))
            p.move(to: CGPoint(x: w * 0.20, y: h * 0.70)); p.addLine(to: CGPoint(x: w * 0.80, y: h * 0.70))
            ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: w * 0.11, lineCap: .round))
            for (x, y) in [(0.36, 0.30), (0.62, 0.50), (0.44, 0.70)] {
                ctx.fill(Path(ellipseIn: CGRect(x: w * x - w * 0.09, y: h * y - h * 0.09, width: w * 0.18, height: h * 0.18)), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

struct RibbonGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.22, y: h * 0.08, width: w * 0.56, height: h * 0.56)), with: .color(color))
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.34, y: h * 0.20, width: w * 0.32, height: h * 0.32)), with: .color(Quire.card.opacity(0.5)))
            var tails = Path()
            tails.move(to: CGPoint(x: w * 0.36, y: h * 0.58)); tails.addLine(to: CGPoint(x: w * 0.26, y: h * 0.94)); tails.addLine(to: CGPoint(x: w * 0.44, y: h * 0.84))
            tails.move(to: CGPoint(x: w * 0.64, y: h * 0.58)); tails.addLine(to: CGPoint(x: w * 0.74, y: h * 0.94)); tails.addLine(to: CGPoint(x: w * 0.56, y: h * 0.84))
            ctx.stroke(tails, with: .color(color), style: StrokeStyle(lineWidth: w * 0.10, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct SpoolGlyph: View {
    var size: CGFloat
    var color: Color
    var body: some View {
        Canvas { ctx, area in
            let w = Double(area.width), h = Double(area.height)
            ctx.fill(Path(CGRect(x: w * 0.28, y: h * 0.22, width: w * 0.44, height: h * 0.56)), with: .color(color.opacity(0.75)))
            ctx.fill(Path(CGRect(x: w * 0.18, y: h * 0.12, width: w * 0.64, height: h * 0.12)), with: .color(color))
            ctx.fill(Path(CGRect(x: w * 0.18, y: h * 0.76, width: w * 0.64, height: h * 0.12)), with: .color(color))
            var winds = Path()
            for k in 0..<4 {
                let y = h * (0.32 + Double(k) * 0.11)
                winds.move(to: CGPoint(x: w * 0.30, y: y)); winds.addLine(to: CGPoint(x: w * 0.70, y: y + h * 0.03))
            }
            ctx.stroke(winds, with: .color(Quire.card.opacity(0.6)), lineWidth: w * 0.03)
        }
        .frame(width: size, height: size)
    }
}
