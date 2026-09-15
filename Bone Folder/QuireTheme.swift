import SwiftUI

enum Quire {
    static let page = Color(red: 0.945, green: 0.914, blue: 0.839)
    static let pageDeep = Color(red: 0.878, green: 0.831, blue: 0.741)
    static let card = Color(red: 0.980, green: 0.965, blue: 0.929)
    static let ink = Color(red: 0.098, green: 0.086, blue: 0.078)
    static let inkSoft = Color(red: 0.290, green: 0.259, blue: 0.227)
    static let inkFaint = Color(red: 0.510, green: 0.467, blue: 0.420)
    static let linen = Color(red: 0.788, green: 0.706, blue: 0.553)
    static let linenPale = Color(red: 0.878, green: 0.827, blue: 0.706)
    static let walnut = Color(red: 0.357, green: 0.239, blue: 0.153)
    static let walnutDark = Color(red: 0.200, green: 0.125, blue: 0.075)
    static let walnutLight = Color(red: 0.545, green: 0.392, blue: 0.263)
    static let indigo = Color(red: 0.180, green: 0.231, blue: 0.357)
    static let indigoDeep = Color(red: 0.098, green: 0.129, blue: 0.220)
    static let thread = Color(red: 0.698, green: 0.227, blue: 0.165)
    static let paste = Color(red: 0.910, green: 0.863, blue: 0.769)
    static let brass = Color(red: 0.722, green: 0.573, blue: 0.267)
    static let brassPale = Color(red: 0.910, green: 0.792, blue: 0.478)
    static let bone = Color(red: 0.914, green: 0.878, blue: 0.792)
    static let steel = Color(red: 0.541, green: 0.557, blue: 0.580)
    static let moss = Color(red: 0.360, green: 0.420, blue: 0.310)
    static let good = Color(red: 0.298, green: 0.443, blue: 0.325)
    static let warn = Color(red: 0.706, green: 0.502, blue: 0.180)
    static let greyboard = Color(red: 0.600, green: 0.580, blue: 0.540)

    static func title(_ size: CGFloat) -> Font { .custom("Cochin-Bold", size: size) }
    static func body(_ size: CGFloat) -> Font { .custom("Cochin", size: size) }
    static func note(_ size: CGFloat) -> Font { .custom("Cochin-Italic", size: size) }

    static var isPad: Bool { UIScreen.main.bounds.width >= 700 }
    static var isNarrow: Bool { UIScreen.main.bounds.width <= 340 }
    static var gutter: CGFloat { isPad ? 32 : (isNarrow ? 12 : 17) }
    static var plateHeight: CGFloat { isPad ? 300 : 200 }
}

enum Knock {
    static func light() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func firm() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func hard() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    static func crisp() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
}

struct RiseIn: ViewModifier {
    let index: Int
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.easeOut(duration: 0.38).delay(Double(index) * 0.05)) { shown = true }
            }
    }
}

extension View {
    func rising(_ index: Int) -> some View { modifier(RiseIn(index: index)) }
}

extension Color {
    static func blend(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let ua = UIColor(a), ub = UIColor(b)
        var r0: CGFloat = 0, g0: CGFloat = 0, b0: CGFloat = 0, a0: CGFloat = 0
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        ua.getRed(&r0, green: &g0, blue: &b0, alpha: &a0)
        ub.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        let k = CGFloat(max(0, min(1, t)))
        return Color(red: Double(r0 + (r1 - r0) * k), green: Double(g0 + (g1 - g0) * k),
                     blue: Double(b0 + (b1 - b0) * k), opacity: Double(a0 + (a1 - a0) * k))
    }

    static func tint(_ t: Tint) -> Color { Color(red: t.r, green: t.g, blue: t.b) }
}

enum Clock {
    static func hourNow(_ date: Date = Date()) -> Double {
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: date))
        let m = Double(cal.component(.minute, from: date))
        let s = Double(cal.component(.second, from: date))
        return h + m / 60 + s / 3600
    }

    static func monthNow(_ date: Date = Date()) -> Int { Calendar.current.component(.month, from: date) }

    static func hourWords(_ hour: Double) -> String {
        switch Int(hour) {
        case 0..<5: return "The bindery is dark and the lamp is doing the work"
        case 5..<8: return "First light on the bench, the paste pot still cold"
        case 8..<11: return "The best hour for sewing, before the hand tires"
        case 11..<14: return "Full light across the bench"
        case 14..<17: return "The light has crossed to the press"
        case 17..<20: return "Low sun on the window, the kettle on"
        case 20..<23: return "The lamp again, and only folding now"
        default: return "Late, and the paste is skinning over"
        }
    }

    static func plateIndex(_ hour: Double) -> Int {
        switch Int(hour) {
        case 0..<5: return 0
        case 5..<8: return 1
        case 8..<11: return 2
        case 11..<14: return 3
        case 14..<17: return 4
        case 17..<20: return 5
        default: return 6
        }
    }

    static func durationWords(_ seconds: Double) -> String {
        let s = max(0, Int(seconds))
        let h = s / 3600, m = (s % 3600) / 60
        if h > 0 { return m > 0 ? "\(h) h \(m) min" : "\(h) h" }
        if m > 0 { return "\(m) min" }
        return "\(s) s"
    }
}
