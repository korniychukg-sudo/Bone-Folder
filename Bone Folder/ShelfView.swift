import SwiftUI

struct ShelfView: View {
    @EnvironmentObject var bindery: Bindery
    @State private var opened: BoundBook? = nil
    @State private var pulled: String? = nil
    @State private var now = Date()
    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var hour: Double { Clock.hourNow(now) }

    var body: some View {
        ScrollView {
            Column {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The shelf").font(Quire.title(24)).foregroundColor(Quire.ink)
                    Text(bindery.ledger.books.isEmpty ? "Nothing bound yet. The first book off the bench stands here, spine out, with its real width." : "\(bindery.ledger.books.count) book\(bindery.ledger.books.count == 1 ? "" : "s"), spine out, in the bindery's light at this hour. Pull one out to open it.")
                        .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                let books = bindery.ledger.books
                let perShelf = 24
                let shelves = max(1, (books.count + perShelf - 1) / perShelf)
                ForEach(0..<shelves, id: \.self) { i in
                    let slice = Array(books.dropFirst(i * perShelf).prefix(perShelf))
                    ShelfCanvas(books: slice, hour: hour, pulled: pulled, best: Set((bindery.ledger.bestIds ?? [:]).values)) { book in
                        Knock.firm()
                        withAnimation(.easeOut(duration: 0.18)) { pulled = book.id }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                            opened = book
                            pulled = nil
                        }
                    }
                    .frame(height: Quire.isPad ? 300 : 230)
                    .rising(i)
                }
                if books.isEmpty {
                    SealButton(title: "To the bench", tone: Quire.walnut) { bindery.wantedTab = 1 }
                }
                if !books.isEmpty { bestCard }
                SheetCard(padding: 0) {
                    PlateBox(name: "dc_clothBolt", height: Quire.isPad ? 220 : 150, corner: 7)
                }
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Quire.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(clock) { _ in now = Date() }
        .fullScreenCover(item: $opened) { book in
            BookOpenView(book: book) { opened = nil }.environmentObject(bindery)
        }
    }

    private var bestCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Best of each structure", trailing: "\((bindery.ledger.bestIds ?? [:]).count) of \(Structure.allCases.count)")
                ForEach(Structure.allCases, id: \.self) { s in
                    HStack(spacing: 10) {
                        Text(s.shortName).font(Quire.title(12.5)).foregroundColor(Quire.ink).frame(width: 96, alignment: .leading)
                        if let b = bindery.best(s) {
                            Text("\(b.score)").font(Quire.title(13)).foregroundColor(b.score >= 90 ? Quire.brass : Quire.ink).frame(width: 32)
                            Text(b.word).font(Quire.body(12)).foregroundColor(Quire.inkSoft)
                            Spacer()
                            Button(action: { Knock.light(); opened = b }) {
                                Text("Open").font(Quire.title(11)).foregroundColor(Quire.walnut)
                            }.buttonStyle(.plain)
                        } else {
                            Text("not yet bound").font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                            Spacer()
                        }
                    }
                }
                Text("A better attempt at the same structure takes the slot; the older copy stays on the shelf until it is full.")
                    .font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct ShelfCanvas: View {
    var books: [BoundBook]
    var hour: Double
    var pulled: String?
    var best: Set<String>
    var onPick: (BoundBook) -> Void

    private func layout(_ size: CGSize) -> [(BoundBook, CGRect)] {
        var out: [(BoundBook, CGRect)] = []
        let plank = size.height * 0.84
        let scale = min(2.6, (size.width - 40) / max(60, CGFloat(books.reduce(0.0) { $0 + max(6, $1.spineMM) + 1.5 })))
        var x = size.width * 0.05
        for b in books {
            let w = max(6, CGFloat(b.spineMM)) * scale
            let hMM = b.impositionKind.sheetPortrait ? b.sheetSize.longMM / 2 : b.sheetSize.shortMM
            let h = min(size.height * 0.72, CGFloat(hMM) * scale * 0.68)
            out.append((b, CGRect(x: x, y: plank - h, width: w, height: h)))
            x += w + 1.5 * scale
        }
        return out
    }

    var body: some View {
        let tone = BinderyLight.at(hour)
        GeometryReader { geo in
            ZStack {
                PlateFill(name: "dc_shelfBack").cornerRadius(7)
                Rectangle().fill(tone.wall.opacity(0.28 + 0.3 * (1 - tone.shaft))).cornerRadius(7)
                Canvas { ctx, size in
                    let plankY = size.height * 0.84
                    ctx.fill(Path(CGRect(x: 0, y: plankY, width: size.width, height: size.height - plankY)), with: .color(Quire.walnut))
                    ctx.fill(Path(CGRect(x: 0, y: plankY, width: size.width, height: 4)), with: .color(Quire.walnutLight.opacity(0.7)))
                    ctx.fill(Path(CGRect(x: 0, y: plankY + 4, width: size.width, height: 3)), with: .color(Quire.ink.opacity(0.5)))
                    for (b, r0) in layout(size) {
                        let r = pulled == b.id ? r0.offsetBy(dx: 0, dy: 10) : r0
                        let cover = Color.tint(b.cover.tone)
                        ctx.fill(Path(CGRect(x: r.minX + 3, y: r.minY + 3, width: r.width, height: r.height)), with: .color(Color.black.opacity(0.35)))
                        if b.kind.exposedSpine {
                            ctx.fill(Path(r), with: .color(Quire.paste))
                            let rows = max(1, b.kind.family == .stab ? 1 : b.signatures)
                            let rowH = r.height / CGFloat(rows)
                            var lines = Path()
                            for k in 0...rows { lines.move(to: CGPoint(x: r.minX, y: r.minY + rowH * CGFloat(k))); lines.addLine(to: CGPoint(x: r.maxX, y: r.minY + rowH * CGFloat(k))) }
                            ctx.stroke(lines, with: .color(Quire.ink.opacity(0.35)), lineWidth: 0.6)
                            let stations = max(2, b.stations)
                            for s in 0..<stations {
                                let x = r.minX + r.width * (0.2 + 0.6 * CGFloat(s) / CGFloat(max(1, stations - 1)))
                                var chain = Path()
                                chain.move(to: CGPoint(x: x, y: r.minY + 3)); chain.addLine(to: CGPoint(x: x, y: r.maxY - 3))
                                ctx.stroke(chain, with: .color(Color.tint(Materials.thread(b.threadKind).tone)), lineWidth: max(1, r.width * 0.12))
                            }
                        } else {
                            ctx.fill(Path(r), with: .color(cover))
                            ctx.fill(Path(r), with: .linearGradient(Gradient(colors: [Color.white.opacity(0.18), Color.clear, Color.black.opacity(0.28)]), startPoint: CGPoint(x: r.minX, y: 0), endPoint: CGPoint(x: r.maxX, y: 0)))
                            if b.kind.family == .supported {
                                for f in [0.12, 0.30, 0.48, 0.66, 0.84] {
                                    let y = r.minY + r.height * CGFloat(f)
                                    var band = Path()
                                    band.move(to: CGPoint(x: r.minX + 1, y: y)); band.addLine(to: CGPoint(x: r.maxX - 1, y: y))
                                    ctx.stroke(band, with: .color(Color.white.opacity(0.18)), lineWidth: 1.5)
                                }
                            }
                            let label = CGRect(x: r.minX + r.width * 0.15, y: r.minY + r.height * 0.55, width: r.width * 0.7, height: r.height * 0.2)
                            switch b.labelStyle {
                            case .paperLabel, .handLettered:
                                ctx.fill(Path(label), with: .color(Quire.card))
                            case .giltCloth:
                                ctx.stroke(Path(label), with: .color(Quire.brassPale), lineWidth: 1)
                                var t = Path()
                                t.move(to: CGPoint(x: label.midX, y: label.minY + 3)); t.addLine(to: CGPoint(x: label.midX, y: label.maxY - 3))
                                ctx.stroke(t, with: .color(Quire.brassPale), lineWidth: max(1, r.width * 0.18))
                            case .blindStamp:
                                ctx.fill(Path(label), with: .color(Color.black.opacity(0.2)))
                            }
                        }
                        ctx.stroke(Path(r), with: .color(Quire.ink.opacity(0.7)), lineWidth: 0.7)
                        if best.contains(b.id) {
                            ctx.fill(Path(ellipseIn: CGRect(x: r.midX - 3, y: r.minY + 6, width: 6, height: 6)), with: .color(Quire.brassPale))
                        }
                    }
                    if books.isEmpty {
                        ctx.draw(Text("an empty shelf").font(Quire.note(13)).foregroundColor(Quire.card.opacity(0.8)), at: CGPoint(x: size.width / 2, y: size.height * 0.5))
                    }
                    ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: size.height)), with: .linearGradient(Gradient(colors: [Color.black.opacity(0.05 + 0.25 * (1 - tone.shaft)), Color.clear]), startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: size.width, y: 0)))
                    if tone.lamp > 0.1 {
                        ctx.fill(Path(ellipseIn: CGRect(x: size.width * 0.6, y: -size.height * 0.4, width: size.width * 0.8, height: size.height * 1.6)), with: .radialGradient(Gradient(colors: [Quire.brassPale.opacity(0.16 * tone.lamp), Color.clear]), center: CGPoint(x: size.width, y: size.height * 0.4), startRadius: 0, endRadius: size.width * 0.5))
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                    for (b, r) in layout(geo.size) where r.insetBy(dx: -2, dy: -10).contains(v.startLocation) {
                        onPick(b)
                        return
                    }
                })
            }
            .clipped()
            .cornerRadius(7)
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(0.2), lineWidth: 0.8))
        }
    }
}
