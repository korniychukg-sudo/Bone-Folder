import SwiftUI

struct SheetStage: View {
    @EnvironmentObject var bindery: Bindery
    @State private var showBack = false
    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ScrollView {
            Column {
                SheetCard(padding: 10) {
                    VStack(spacing: 8) {
                        SheetCanvas(imposition: bench.imposition, sheet: bench.sheetSize, paper: bench.paper, back: showBack, state: nil, moves: [])
                            .frame(height: Quire.isPad ? 360 : 250)
                        HStack {
                            Text(showBack ? "The back of the sheet" : "The front of the sheet").font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                            Spacer()
                            SealButton(title: showBack ? "Turn to the front" : "Turn over", tone: Quire.inkSoft, filled: false) { withAnimation { showBack.toggle() } }
                                .frame(width: 150)
                        }
                    }
                }
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "The sheet")
                        Text("\(bench.sheetSize.name), \(Int(bench.imposition.sheetPortrait ? bench.sheetSize.shortMM : bench.sheetSize.longMM)) by \(Int(bench.imposition.sheetPortrait ? bench.sheetSize.longMM : bench.sheetSize.shortMM)) mm, laid \(bench.imposition.sheetPortrait ? "portrait" : "landscape"). \(bench.sheetSize.note)")
                            .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        Text("\(bench.imposition.name): \(bench.imposition.note)")
                            .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        Text("\(bench.paper.name), \(bench.paper.spec). \(bench.paper.note)")
                            .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        if bench.grainAcross {
                            NoticeBar(text: "The grain of this paper runs across the spine fold. The fold will crack and the book will not open flat. Pick a paper with the grain \(bench.imposition.correctGrain == .long ? "long" : "short") on the bench, or carry on and take the fault.", tone: Quire.thread)
                        } else {
                            NoticeBar(text: "The grain runs with the spine. The fold will crease clean.", tone: Quire.good)
                        }
                        if bench.structure.family == .stab {
                            Text("For a stab binding each leaf is folded once with the fold at the fore-edge: a pouch. The stack of \(bench.s?.signatures ?? 0) leaves is then punched through the side.")
                                .font(Quire.note(12.5)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.bottom, 20)
        }
    }
}

struct SheetCanvas: View {
    var imposition: Imposition
    var sheet: SheetSize
    var paper: Material
    var back: Bool
    var state: FoldState?
    var moves: [FoldMove]
    var lift: (FoldMove, CGFloat)? = nil
    var uncreased: FoldMove? = nil

    var body: some View {
        Canvas { ctx, size in
            let map = Imposer.map(imposition)
            let st = state ?? FoldState(imposition: imposition)
            let sheetW = imposition.sheetPortrait ? sheet.shortMM : sheet.longMM
            let sheetH = imposition.sheetPortrait ? sheet.longMM : sheet.shortMM
            let cellW = sheetW / Double(imposition.cols), cellH = sheetH / Double(imposition.rows)
            let footW = cellW * Double(st.cols), footH = cellH * Double(st.rows)
            let scale = min(Double(size.width - 40) / footW, Double(size.height - 40) / footH)
            let w = footW * scale, h = footH * scale
            let ox = (Double(size.width) - w) / 2, oy = (Double(size.height) - h) / 2
            let tone = Color.tint(paper.tone)
            let layers = st.stacks.first?.count ?? 1
            for k in stride(from: min(layers, 6) - 1, through: 1, by: -1) {
                let d = CGFloat(k) * 2.2
                ctx.fill(Path(CGRect(x: ox + Double(d), y: oy + Double(d), width: w, height: h)), with: .color(tone.opacity(0.9)))
                ctx.stroke(Path(CGRect(x: ox + Double(d), y: oy + Double(d), width: w, height: h)), with: .color(Quire.ink.opacity(0.25)), lineWidth: 0.6)
            }
            ctx.fill(Path(CGRect(x: ox + 5, y: oy + 7, width: w, height: h)), with: .color(Color.black.opacity(0.18)))
            ctx.fill(Path(CGRect(x: ox, y: oy, width: w, height: h)), with: .color(tone))
            var grain = Path()
            let along = paper.grain == .long ? (sheetW >= sheetH) : (sheetW < sheetH)
            if along {
                var y = oy + 6.0
                while y < oy + h { grain.move(to: CGPoint(x: ox + 3, y: y)); grain.addLine(to: CGPoint(x: ox + w - 3, y: y)); y += 9 }
            } else {
                var x = ox + 6.0
                while x < ox + w { grain.move(to: CGPoint(x: x, y: oy + 3)); grain.addLine(to: CGPoint(x: x, y: oy + h - 3)); x += 9 }
            }
            ctx.stroke(grain, with: .color(Quire.ink.opacity(0.07)), lineWidth: 0.8)
            let cw = w / Double(st.cols), ch = h / Double(st.rows)
            for r in 0..<st.rows {
                for c in 0..<st.cols {
                    let stack = st.stacks[r * st.cols + c]
                    guard let top = stack.last else { continue }
                    var page = top.frontUp ? map.front[top.cell] : map.back[top.cell]
                    var turn = (page.turn + top.turn) % 4
                    if back && state == nil {
                        page = map.back[top.cell]
                        turn = page.turn
                    }
                    let cx = ox + cw * (Double(c) + 0.5), cy = oy + ch * (Double(r) + 0.5)
                    let rect = CGRect(x: ox + cw * Double(c), y: oy + ch * Double(r), width: cw, height: ch)
                    ctx.stroke(Path(rect), with: .color(Quire.ink.opacity(0.28)), style: StrokeStyle(lineWidth: 0.7, dash: [3, 3]))
                    var sub = ctx
                    sub.translateBy(x: cx, y: cy)
                    sub.rotate(by: .degrees(Double(turn) * 90))
                    let fontSize = max(14, min(cw, ch) * 0.34)
                    sub.draw(Text("\(page.number)").font(Quire.title(fontSize)).foregroundColor(Quire.ink.opacity(0.85)), at: .zero)
                    var lines = Path()
                    for k in 0..<3 {
                        let ly = fontSize * 0.75 + Double(k) * fontSize * 0.28
                        lines.move(to: CGPoint(x: -cw * 0.22, y: ly)); lines.addLine(to: CGPoint(x: cw * 0.22, y: ly))
                    }
                    sub.stroke(lines, with: .color(Quire.ink.opacity(0.22)), lineWidth: 1.2)
                }
            }
            ctx.stroke(Path(CGRect(x: ox, y: oy, width: w, height: h)), with: .color(Quire.ink.opacity(0.75)), lineWidth: 1.2)
            if let u = uncreased {
                var edge = Path()
                switch u {
                case .rightOverLeft: edge.move(to: CGPoint(x: ox, y: oy)); edge.addLine(to: CGPoint(x: ox, y: oy + h))
                case .leftOverRight: edge.move(to: CGPoint(x: ox + w, y: oy)); edge.addLine(to: CGPoint(x: ox + w, y: oy + h))
                case .bottomOverTop: edge.move(to: CGPoint(x: ox, y: oy)); edge.addLine(to: CGPoint(x: ox + w, y: oy))
                case .topOverBottom: edge.move(to: CGPoint(x: ox, y: oy + h)); edge.addLine(to: CGPoint(x: ox + w, y: oy + h))
                }
                ctx.stroke(edge, with: .color(Quire.paste), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                ctx.stroke(edge, with: .color(Quire.ink.opacity(0.5)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                var crease = Path()
                switch u {
                case .rightOverLeft: crease.move(to: CGPoint(x: ox + w, y: oy)); crease.addLine(to: CGPoint(x: ox + w, y: oy + h))
                case .leftOverRight: crease.move(to: CGPoint(x: ox, y: oy)); crease.addLine(to: CGPoint(x: ox, y: oy + h))
                case .bottomOverTop: crease.move(to: CGPoint(x: ox, y: oy + h)); crease.addLine(to: CGPoint(x: ox + w, y: oy + h))
                case .topOverBottom: crease.move(to: CGPoint(x: ox, y: oy)); crease.addLine(to: CGPoint(x: ox + w, y: oy))
                }
                ctx.stroke(crease, with: .color(Quire.thread.opacity(0.85)), style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [8, 5]))
            }
            if let (move, progress) = lift, progress > 0 {
                let f = Double(min(1, max(0, progress)))
                var flap: CGRect
                switch move {
                case .rightOverLeft: flap = CGRect(x: ox + w / 2 - w / 2 * f, y: oy, width: w / 2, height: h)
                case .leftOverRight: flap = CGRect(x: ox + w / 2 * f, y: oy, width: w / 2, height: h)
                case .bottomOverTop: flap = CGRect(x: ox, y: oy + h / 2 - h / 2 * f, width: w, height: h / 2)
                case .topOverBottom: flap = CGRect(x: ox, y: oy + h / 2 * f, width: w, height: h / 2)
                }
                ctx.fill(Path(flap.offsetBy(dx: 4, dy: 6)), with: .color(Color.black.opacity(0.25)))
                ctx.fill(Path(flap), with: .color(tone.opacity(0.96)))
                ctx.stroke(Path(flap), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1.2)
            }
        }
    }
}

struct FoldStage: View {
    @EnvironmentObject var bindery: Bindery
    @State private var message: String = ""
    private var bench: BenchSession { bindery.bench }

    var body: some View {
        if bench.structure == .accordion {
            AccordionFoldStage()
        } else {
            sheetFold
        }
    }

    private var uncreased: Bool {
        guard let last = bench.s?.foldRecords.last else { return false }
        return last.crease < 0.2
    }

    private var sheetFold: some View {
        ScrollView {
            VStack(spacing: 10) {
                FoldBoard(imposition: bench.imposition, sheet: bench.sheetSize, paper: bench.paper, moves: (bench.s?.foldMoves ?? []).compactMap { FoldMove(rawValue: $0) }, needsCrease: uncreased,
                          onFold: { move, offset in
                              if bench.fold(move, offsetMM: offset) {
                                  Knock.firm()
                                  message = offset < 1.5 ? "Square on the edge, \(String(format: "%.1f", offset)) mm off. Now crease it." : "Landed \(String(format: "%.1f", offset)) mm off the edge. Crease it and mind the next one."
                              }
                          },
                          onCrease: { covered, speed in
                              if covered < 0.3 {
                                  message = "That stroke did not run the fold. Swipe along the dashed line, end to end."
                                  Knock.light()
                                  return
                              }
                              let pressure = min(1, speed / 700)
                              let quality = min(1, covered * 1.1) * (0.45 + 0.55 * pressure)
                              bench.crease(quality)
                              message = quality > 0.7 ? "A firm crease; the fold stays down." : (quality > 0.4 ? "A soft crease. Faster and firmer next time." : "The fold springs half open.")
                              Knock.firm()
                          },
                          onMessage: { message = $0 })
                    .frame(height: Quire.isPad ? 400 : 300)
                    .padding(.horizontal, Quire.gutter)
                statusCard
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }

    private var statusCard: some View {
        let r = bench.readout
        let done = bench.foldState.folded
        return SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HeadRule(text: done ? "Folded down" : "Fold \((bench.s?.foldMoves.count ?? 0) + 1) of \(bench.imposition.folds)")
                    if bench.grainAcross { StampTag(text: "across the grain", tone: Quire.thread) }
                }
                if uncreased {
                    Text("Crease it: swipe along the dashed fold with the folder, fast and firm, end to end.")
                        .font(Quire.body(13)).foregroundColor(Quire.thread).fixedSize(horizontal: false, vertical: true)
                } else if !done {
                    Text("Drag an edge of the sheet across to the opposite edge. The fold must land square on the far edge.")
                        .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: 4) {
                        ForEach(Array(r.pages.enumerated()), id: \.offset) { i, page in
                            Text("\(page)").font(Quire.title(12)).foregroundColor(r.upright[i] ? Quire.ink : Quire.thread)
                                .rotationEffect(.degrees(r.upright[i] ? 0 : 180))
                                .frame(minWidth: 18, minHeight: 22)
                                .background(RoundedRectangle(cornerRadius: 3).fill(page == i + 1 && r.upright[i] ? Quire.good.opacity(0.15) : Quire.thread.opacity(0.12)))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Text(r.correct ? "Pages 1 to \(bench.imposition.pages), every one upright. The signature is right." : (r.fault ?? ""))
                        .font(Quire.body(13)).foregroundColor(r.correct ? Quire.good : Quire.thread).fixedSize(horizontal: false, vertical: true)
                    if !r.correct {
                        SealButton(title: "Unfold and start again", tone: Quire.inkSoft, filled: false) { bench.unfoldAll() }
                    }
                }
                if !message.isEmpty {
                    Text(message).font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
                if let last = bench.s?.foldRecords.last, last.crease > 0.2 {
                    MeterBar(label: "Last crease", value: last.crease, tone: last.crease > 0.7 ? Quire.good : Quire.brass)
                }
            }
        }
        .padding(.horizontal, Quire.gutter)
    }
}

struct AccordionFoldStage: View {
    @EnvironmentObject var bindery: Bindery
    @State private var message = "Fold 1 is a mountain: drag the fold upward. Then valley, then mountain, in rhythm."
    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ScrollView {
        VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Quire.walnut.opacity(0.92))
                    PlateFill(name: "dc_benchTop").cornerRadius(8).opacity(0.9)
                    Canvas { ctx, size in
                        AccordionPainter.draw(&ctx, size: size, panels: bench.s?.stations ?? 8, results: bench.s?.accordionResults, progress: bench.s?.accordionResults.count ?? 0)
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 12).onEnded { v in
                    let panels = bench.s?.stations ?? 8
                    let inset: CGFloat = 24
                    let pw = (geo.size.width - inset * 2) / CGFloat(panels)
                    let index = Int((v.startLocation.x - inset + pw * 0.5) / pw) - 1
                    let expected = bench.s?.accordionResults.count ?? 0
                    guard index == expected else {
                        message = index < expected ? "That fold is done. Fold \(expected + 1) is next." : "Folds go in order. Fold \(expected + 1) is next."
                        Knock.light()
                        return
                    }
                    let mountain = v.translation.height < -10
                    let valley = v.translation.height > 10
                    guard mountain || valley else { return }
                    let ok = bench.accordionFold(index, mountain: mountain)
                    Knock.firm()
                    let next = expected + 1
                    let total = panels - 1
                    if ok {
                        message = next < total ? "Good. Fold \(next + 1) is a \(next % 2 == 0 ? "mountain: drag up" : "valley: drag down")." : "All \(total) folds in rhythm."
                    } else {
                        message = "Wrong way: that was a \(mountain ? "mountain" : "valley") where a \(mountain ? "valley" : "mountain") belongs. It counts against the book."
                    }
                })
            }
            .frame(height: Quire.isPad ? 360 : 260)
            .padding(.horizontal, Quire.gutter)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "Mountain, valley")
                    Text(message).font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                    Text("A concertina is a strip folded back and forth: each crease alternates. Drag up to raise a mountain, down to sink a valley.")
                        .font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Quire.gutter)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        }
    }
}
