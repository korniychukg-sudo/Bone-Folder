import SwiftUI

struct PressStage: View {
    @EnvironmentObject var bindery: Bindery
    var onDone: () -> Void
    @State private var bookOffset: CGSize = .zero
    @State private var wheelAngle: Double = 0
    @State private var turned: Double = 0
    @State private var lastAngle: Double? = nil
    @State private var confirmEarly = false
    @State private var message = "Drag the book down between the platens."
    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ScrollView {
            Column {
                SheetCard(padding: 10) {
                    GeometryReader { geo in
                        ZStack {
                            PlateFill(name: "dc_pressEmpty").cornerRadius(6)
                            TimelineView(.periodic(from: Date(), by: 1.0)) { _ in
                                Canvas { ctx, size in
                                    let inPress = bench.s?.pressStart != nil
                                    if inPress {
                                        let book = CGRect(x: size.width * 0.32, y: size.height * 0.60, width: size.width * 0.36, height: size.height * 0.11)
                                        ctx.fill(Path(book.offsetBy(dx: 4, dy: 4)), with: .color(Color.black.opacity(0.3)))
                                        ctx.fill(Path(book), with: .color(Color.tint(bench.cover.tone)))
                                        ctx.stroke(Path(book), with: .color(Quire.ink.opacity(0.8)), lineWidth: 1)
                                        let platen = CGRect(x: size.width * 0.26, y: book.minY - 14, width: size.width * 0.48, height: 12)
                                        ctx.fill(Path(platen), with: .color(Color(red: 0.2, green: 0.19, blue: 0.19)))
                                    }
                                    let strip = CGRect(x: size.width * 0.12, y: size.height - 26, width: size.width * 0.76, height: 12)
                                    ctx.fill(Path(roundedRect: strip, cornerRadius: 3), with: .color(Quire.card.opacity(0.85)))
                                    let total = bench.pressNeeded * 3600
                                    let done = total - bench.pressRemaining
                                    let f = inPress ? CGFloat(min(1, done / max(1, total))) : 0
                                    ctx.fill(Path(roundedRect: CGRect(x: strip.minX, y: strip.minY, width: strip.width * f, height: strip.height), cornerRadius: 3), with: .color(Quire.brass))
                                    ctx.stroke(Path(roundedRect: strip, cornerRadius: 3), with: .color(Quire.ink.opacity(0.6)), lineWidth: 0.8)
                                    let text = inPress ? (bench.pressRemaining > 0 ? "\(Clock.durationWords(bench.pressRemaining)) left of \(Clock.durationWords(total))" : "done: the full \(Clock.durationWords(total))") : "the press is empty"
                                    ctx.draw(Text(text).font(Quire.note(11)).foregroundColor(Quire.card), at: CGPoint(x: size.width / 2, y: strip.minY - 10))
                                }
                            }
                            if bench.s?.pressStart == nil {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Color.tint(bench.cover.tone))
                                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Quire.ink.opacity(0.7), lineWidth: 1))
                                    .frame(width: geo.size.width * 0.36, height: geo.size.height * 0.11)
                                    .position(x: geo.size.width * 0.5, y: geo.size.height * 0.18)
                                    .offset(bookOffset)
                                    .gesture(DragGesture(minimumDistance: 4)
                                        .onChanged { v in bookOffset = v.translation }
                                        .onEnded { v in
                                            bookOffset = .zero
                                            if v.translation.height > geo.size.height * 0.3 {
                                                bench.pressIn()
                                                Knock.firm()
                                                message = "In. Now screw the platen down: turn the wheel a full turn."
                                            } else {
                                                message = "Drag it further down, between the platens."
                                            }
                                        })
                            }
                        }
                    }
                    .frame(height: Quire.isPad ? 380 : 280)
                }
                if bench.s?.pressStart != nil && bench.s?.pressScrewed != true {
                    SheetCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HeadRule(text: "Screw down", trailing: "\(Int(min(100, turned / (2 * .pi) * 100))) percent")
                            GeometryReader { wheelGeo in
                                ZStack {
                                    Circle().fill(Quire.brass).frame(width: 130, height: 130)
                                        .overlay(Circle().stroke(Quire.ink.opacity(0.6), lineWidth: 1.5))
                                    ForEach(0..<4, id: \.self) { k in
                                        Rectangle().fill(Quire.walnutDark).frame(width: 120, height: 8)
                                            .rotationEffect(.degrees(Double(k) * 45 + wheelAngle * 180 / .pi))
                                    }
                                    Circle().fill(Quire.steel).frame(width: 26, height: 26)
                                }
                                .frame(width: wheelGeo.size.width, height: wheelGeo.size.height)
                                .contentShape(Rectangle())
                                .gesture(DragGesture(minimumDistance: 2)
                                    .onChanged { v in
                                        let cx = wheelGeo.size.width / 2, cy = wheelGeo.size.height / 2
                                        let a = atan2(Double(v.location.y - cy), Double(v.location.x - cx))
                                        if let last = lastAngle {
                                            var d = a - last
                                            while d > .pi { d -= 2 * .pi }
                                            while d < -.pi { d += 2 * .pi }
                                            turned += abs(d)
                                            wheelAngle += d
                                        }
                                        lastAngle = a
                                        if turned >= 2 * .pi && bench.s?.pressScrewed != true {
                                            bench.screwDown()
                                            Knock.hard()
                                            message = "Screwed down. The book stays in for \(Clock.durationWords(bench.pressNeeded * 3600)); the Today page shows the time left. Come back when it is done, or take it out early and take the fault."
                                        }
                                    }
                                    .onEnded { _ in lastAngle = nil })
                            }
                            .frame(height: 150)
                            Text("Turn the wheel: drag round it in a circle.").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        }
                    }
                }
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "In the press", trailing: bench.structure.family == .supported ? "six hours" : Clock.durationWords(bench.pressNeeded * 3600))
                        Text(message).font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        if bench.s?.pressScrewed == true {
                            if bench.pressRemaining <= 0 {
                                SealButton(title: "Take it out and read the critique", tone: Quire.walnut) {
                                    bench.takeOut()
                                    onDone()
                                }
                            } else if confirmEarly {
                                NoticeBar(text: "Taken out now, the boards will warp toward the wet side. Take the fault?", tone: Quire.thread, action: ("Take it out", {
                                    bench.takeOut()
                                    confirmEarly = false
                                    onDone()
                                }))
                                SealButton(title: "Leave it in", tone: Quire.inkSoft, filled: false) { confirmEarly = false }
                            } else {
                                SealButton(title: "Take it out early", tone: Quire.inkSoft, filled: false) { confirmEarly = true }
                                Text("The press runs on the real clock. Fold, read or shelve while it dries; the book waits here.")
                                    .font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if bench.s?.pressedHours != nil {
                            SealButton(title: "Read the critique", tone: Quire.walnut) { onDone() }
                        }
                    }
                }
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.bottom, 20)
        }
    }
}
