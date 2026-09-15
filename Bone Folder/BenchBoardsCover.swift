import SwiftUI

struct BoardsStage: View {
    @EnvironmentObject var bindery: Bindery
    @State private var knifePath: [CGPoint] = []
    @State private var message = "Draw the knife down the ruled line on each board, top to bottom, against the straightedge."
    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ScrollView {
        VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Quire.walnut.opacity(0.92))
                    PlateFill(name: "dc_benchTop").cornerRadius(8).opacity(0.9)
                    Canvas { ctx, size in
                        let cuts = bench.s?.boardCuts.count ?? 0
                        for k in 0..<2 {
                            let rect = boardRect(k, size)
                            ctx.fill(Path(rect.offsetBy(dx: 5, dy: 7)), with: .color(Color.black.opacity(0.28)))
                            ctx.fill(Path(rect), with: .color(Color.tint(bench.board.tone)))
                            ctx.stroke(Path(rect), with: .color(Quire.ink.opacity(0.8)), lineWidth: 1.2)
                            let lineX = ruleX(k, size)
                            var rule = Path()
                            rule.move(to: CGPoint(x: lineX, y: rect.minY - 8)); rule.addLine(to: CGPoint(x: lineX, y: rect.maxY + 8))
                            ctx.stroke(rule, with: .color(Quire.ink.opacity(k == cuts ? 0.9 : 0.4)), style: StrokeStyle(lineWidth: 1, dash: [5, 3]))
                            if k < cuts {
                                let off = CGFloat((bench.s?.boardCuts[k] ?? 0) / mmPerPoint(size))
                                var cut = Path()
                                cut.move(to: CGPoint(x: lineX + off, y: rect.minY)); cut.addLine(to: CGPoint(x: lineX + off, y: rect.maxY))
                                ctx.stroke(cut, with: .color(Quire.ink), lineWidth: 2)
                                ctx.fill(Path(CGRect(x: lineX + off, y: rect.minY, width: rect.maxX - lineX - off, height: rect.height)), with: .color(Quire.walnut.opacity(0.35)))
                            }
                            ctx.draw(Text(k == 0 ? "front board" : "back board").font(Quire.note(11)).foregroundColor(Quire.card), at: CGPoint(x: rect.midX, y: rect.maxY + 18))
                            ctx.draw(Text("square 3 mm").font(Quire.note(10)).foregroundColor(Quire.ink.opacity(0.6)), at: CGPoint(x: lineX - 26, y: rect.minY + 14))
                        }
                        if knifePath.count > 1, let last = knifePath.last {
                            var p = Path()
                            p.move(to: knifePath[0])
                            for q in knifePath.dropFirst() { p.addLine(to: q) }
                            ctx.stroke(p, with: .color(Quire.steel.opacity(0.7)), lineWidth: 1.2)
                            var knife = Path()
                            knife.move(to: last); knife.addLine(to: CGPoint(x: last.x + 30, y: last.y - 60))
                            ctx.stroke(knife, with: .color(Quire.steel), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            var handle = Path()
                            handle.move(to: CGPoint(x: last.x + 30, y: last.y - 60)); handle.addLine(to: CGPoint(x: last.x + 52, y: last.y - 104))
                            ctx.stroke(handle, with: .color(Quire.ink), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 4)
                    .onChanged { v in knifePath.append(v.location) }
                    .onEnded { v in cut(geo.size); knifePath = [] })
            }
            .frame(height: Quire.isPad ? 400 : 300)
            .padding(.horizontal, Quire.gutter)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "Board \(min(2, (bench.s?.boardCuts.count ?? 0) + 1)) of 2", trailing: bench.board.name)
                    Text(message).font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                    Text("The board is cut to the block plus a square of three millimetres on head, tail and fore-edge. Two millimetres off the line shows across the room.")
                        .font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Quire.gutter)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        }
    }

    private func boardRect(_ k: Int, _ size: CGSize) -> CGRect {
        let w = size.width * 0.34, h = size.height * 0.68
        let x = k == 0 ? size.width * 0.10 : size.width * 0.56
        return CGRect(x: x, y: (size.height - h) / 2 - 8, width: w, height: h)
    }

    private func ruleX(_ k: Int, _ size: CGSize) -> CGFloat { boardRect(k, size).maxX - boardRect(k, size).width * 0.18 }

    private func mmPerPoint(_ size: CGSize) -> Double {
        let heightMM = bench.signatureHeightMM + 6
        return heightMM / Double(boardRect(0, size).height)
    }

    private func cut(_ size: CGSize) {
        let k = bench.s?.boardCuts.count ?? 0
        guard k < 2, knifePath.count > 4 else { return }
        let rect = boardRect(k, size)
        let lineX = ruleX(k, size)
        let inside = knifePath.filter { rect.insetBy(dx: -30, dy: -20).contains($0) }
        guard inside.count > 4 else { message = "Cut on board \(k + 1), along its ruled line."; return }
        let ys = inside.map { $0.y }
        let coverage = Double((ys.max()! - ys.min()!) / rect.height)
        guard coverage > 0.6 else { message = "The cut must run the whole board, top to bottom."; Knock.light(); return }
        let mean = inside.map { Double(abs($0.x - lineX)) }.reduce(0, +) / Double(inside.count)
        let errorMM = mean * mmPerPoint(size)
        bench.cutBoard(errorMM: errorMM)
        Knock.firm()
        message = errorMM < 0.8 ? "On the line: \(String(format: "%.1f", errorMM)) mm. A clean square." : (errorMM <= 2 ? "\(String(format: "%.1f", errorMM)) mm off the line; the square will be a little wide." : "\(String(format: "%.1f", errorMM)) mm off the line: that square will show.")
    }
}

struct CoverStage: View {
    @EnvironmentObject var bindery: Bindery
    @State private var pasted: Set<Int> = []
    @State private var message = "Brush the paste over the whole board, centre outward."
    @State private var blockOffset: CGSize = .zero
    @State private var nipping = false
    private var bench: BenchSession { bindery.bench }
    private let grid = 6

    var body: some View {
        ScrollView {
            Column {
                pasteCard
                turnInCard
                cornerCard
                if bench.structure.family == .supported { caseCard }
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.bottom, 20)
        }
    }

    private var pasteCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Paste", trailing: "\(Int((bench.s?.pasteCoverage ?? 0) * 100)) percent")
                GeometryReader { geo in
                    Canvas { ctx, size in
                        let rect = CGRect(x: 10, y: 8, width: size.width - 20, height: size.height - 16)
                        ctx.fill(Path(rect), with: .color(Color.tint(bench.cover.tone).opacity(0.85)))
                        let cw = rect.width / CGFloat(grid), ch = rect.height / CGFloat(grid)
                        for i in 0..<(grid * grid) {
                            let r = CGRect(x: rect.minX + cw * CGFloat(i % grid), y: rect.minY + ch * CGFloat(i / grid), width: cw, height: ch)
                            if pasted.contains(i) {
                                ctx.fill(Path(r.insetBy(dx: 1, dy: 1)), with: .color(Quire.paste.opacity(0.75)))
                            }
                        }
                        ctx.stroke(Path(rect), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1)
                        ctx.draw(Text("the back of the cloth").font(Quire.note(11)).foregroundColor(Quire.card), at: CGPoint(x: rect.midX, y: rect.maxY - 12))
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 2).onChanged { v in
                        let rect = CGRect(x: 10, y: 8, width: geo.size.width - 20, height: geo.size.height - 16)
                        guard rect.contains(v.location) else { return }
                        let cw = rect.width / CGFloat(grid), ch = rect.height / CGFloat(grid)
                        let i = Int((v.location.y - rect.minY) / ch) * grid + Int((v.location.x - rect.minX) / cw)
                        if !pasted.contains(i) {
                            pasted.insert(i)
                            bench.paste(coverage: Double(pasted.count) / Double(grid * grid))
                        }
                    }.onEnded { _ in
                        let c = bench.s?.pasteCoverage ?? 0
                        message = c > 0.9 ? "Pasted to the edges." : "Paste \(Int(c * 100)) percent; the corners and edges still want the brush."
                        Knock.light()
                    })
                }
                .frame(height: 150)
                Text(message).font(Quire.body(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
        .onAppear {
            let c = bench.s?.pasteCoverage ?? 0
            if c > 0 && pasted.isEmpty { pasted = Set(0..<Int(c * Double(grid * grid))) }
        }
    }

    private var turnInCard: some View {
        let turns = bench.s?.turnIns ?? []
        return SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Turn-ins", trailing: "\(turns.count) of 4")
                GeometryReader { geo in
                    Canvas { ctx, size in
                        let board = CGRect(x: size.width * 0.22, y: size.height * 0.22, width: size.width * 0.56, height: size.height * 0.56)
                        let cloth = board.insetBy(dx: -size.width * 0.16, dy: -size.height * 0.18)
                        ctx.fill(Path(cloth), with: .color(Color.tint(bench.cover.tone)))
                        ctx.fill(Path(board), with: .color(Color.tint(bench.board.tone)))
                        ctx.stroke(Path(board), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1)
                        let names = ["head", "tail", "fore-edge", "spine side"]
                        for (i, w) in turns.enumerated() {
                            let depth = CGFloat(w / 15.0) * (cloth.height - board.height) / 2
                            var r: CGRect
                            switch i {
                            case 0: r = CGRect(x: board.minX, y: board.minY, width: board.width, height: depth)
                            case 1: r = CGRect(x: board.minX, y: board.maxY - depth, width: board.width, height: depth)
                            case 2: r = CGRect(x: board.maxX - depth, y: board.minY, width: depth, height: board.height)
                            default: r = CGRect(x: board.minX, y: board.minY, width: depth, height: board.height)
                            }
                            ctx.fill(Path(r), with: .color(Color.tint(bench.cover.tone).opacity(0.9)))
                            ctx.stroke(Path(r), with: .color(Quire.ink.opacity(0.5)), lineWidth: 0.8)
                        }
                        if turns.count < 4 {
                            ctx.draw(Text("drag the \(names[turns.count]) edge in over the board").font(Quire.note(11)).foregroundColor(Quire.ink.opacity(0.7)), at: CGPoint(x: board.midX, y: board.midY))
                        } else {
                            ctx.draw(Text("turned in").font(Quire.note(11)).foregroundColor(Quire.ink.opacity(0.7)), at: CGPoint(x: board.midX, y: board.midY))
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 8).onEnded { v in
                        guard turns.count < 4 else { return }
                        let board = CGRect(x: geo.size.width * 0.22, y: geo.size.height * 0.22, width: geo.size.width * 0.56, height: geo.size.height * 0.56)
                        let margin = geo.size.height * 0.18
                        let dist: CGFloat
                        switch turns.count {
                        case 0: dist = v.translation.height
                        case 1: dist = -v.translation.height
                        case 2: dist = -v.translation.width
                        default: dist = v.translation.width
                        }
                        guard dist > 8 else { message = "Drag the edge inward, over the board."; return }
                        let mm = Double(dist / margin) * 15.0 * 1.0
                        _ = board
                        bench.turnIn(widthMM: mm)
                        Knock.firm()
                        message = abs(mm - 15) < 3 ? "Turned in \(Int(mm)) mm." : (mm < 15 ? "Only \(Int(mm)) mm: it will not hold." : "\(Int(mm)) mm: too much cloth inside; it will show under the pastedown.")
                    })
                }
                .frame(height: 170)
            }
        }
    }

    private var cornerCard: some View {
        let kind = bench.s?.cornerKind ?? "library"
        let steps = bench.s?.cornerSteps ?? 0
        let names = kind == "library" ? ["fold the tip in over the corner", "turn the head edge over it", "turn the fore-edge over it"] : ["cut the corner at 45 degrees", "turn the head edge in", "turn the fore-edge in to meet it"]
        return SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Corner", trailing: "\(steps) of 3")
                HStack(spacing: 8) {
                    ForEach(["library", "universal"], id: \.self) { k in
                        Button(action: { Knock.light(); bench.chooseCorner(k) }) {
                            Text(k == "library" ? "Library corner" : "Universal corner").font(Quire.title(11.5))
                                .foregroundColor(kind == k ? Quire.card : Quire.inkSoft)
                                .padding(.horizontal, 10).padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: 5).fill(kind == k ? Quire.walnut : Quire.ink.opacity(0.06)))
                        }.buttonStyle(.plain)
                    }
                }
                Text(kind == "library" ? "Three layers at the tip: strong, for cased books." : "Cut off at forty five degrees, a board and a half from the tip: flatter, for thin cloth.")
                    .font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                Canvas { ctx, size in
                    let board = CGRect(x: size.width * 0.1, y: size.height * 0.25, width: size.width * 0.55, height: size.height * 0.7)
                    let cloth = CGRect(x: board.minX, y: 4, width: board.width + size.width * 0.28, height: board.height + size.height * 0.5)
                    ctx.fill(Path(cloth), with: .color(Color.tint(bench.cover.tone)))
                    ctx.fill(Path(board), with: .color(Color.tint(bench.board.tone)))
                    let tip = CGPoint(x: board.maxX, y: board.minY)
                    if steps >= 1 {
                        var tri = Path()
                        if kind == "library" {
                            tri.move(to: CGPoint(x: tip.x + 40, y: tip.y - 40)); tri.addLine(to: CGPoint(x: tip.x - 30, y: tip.y + 30)); tri.addLine(to: tip); tri.closeSubpath()
                            ctx.fill(tri, with: .color(Color.tint(bench.cover.tone).opacity(0.85)))
                        } else {
                            tri.move(to: CGPoint(x: tip.x + 12, y: cloth.minY)); tri.addLine(to: CGPoint(x: cloth.maxX, y: tip.y + 12)); tri.addLine(to: CGPoint(x: cloth.maxX, y: cloth.minY)); tri.closeSubpath()
                            ctx.fill(tri, with: .color(Quire.walnut.opacity(0.9)))
                        }
                    }
                    if steps >= 2 {
                        ctx.fill(Path(CGRect(x: board.minX, y: board.minY, width: board.width, height: 22)), with: .color(Color.tint(bench.cover.tone).opacity(0.9)))
                    }
                    if steps >= 3 {
                        ctx.fill(Path(CGRect(x: board.maxX - 22, y: board.minY, width: 22, height: board.height)), with: .color(Color.tint(bench.cover.tone).opacity(0.9)))
                    }
                    ctx.stroke(Path(board), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1)
                }
                .frame(height: 110)
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Button(action: {
                            guard steps < 3 else { return }
                            let ok = bench.cornerStep(i)
                            Knock.light()
                            message = ok ? "Step \(i + 1): \(names[i])." : "Out of order: \(names[steps]) comes first."
                        }) {
                            Text("\(i + 1)").font(Quire.title(13)).foregroundColor(i < steps ? Quire.card : Quire.ink)
                                .frame(maxWidth: .infinity).padding(.vertical, 8)
                                .background(RoundedRectangle(cornerRadius: 5).fill(i < steps ? Quire.good : Quire.ink.opacity(0.07)))
                        }.buttonStyle(.plain)
                    }
                }
                Text(steps < 3 ? "Next: \(names[steps]). Tap the flaps in the right order." : "The corner is made.").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var caseCard: some View {
        let offset = bench.s?.caseOffsetMM ?? -1
        return SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Casing in", trailing: offset < 0 ? "block loose" : (bench.s?.nipped == true ? "nipped" : String(format: "%.1f mm off", offset)))
                GeometryReader { geo in
                    ZStack {
                        Canvas { ctx, size in
                            let caseRect = CGRect(x: size.width * 0.3, y: 10, width: size.width * 0.4, height: size.height - 20)
                            ctx.fill(Path(caseRect), with: .color(Color.tint(bench.cover.tone)))
                            ctx.stroke(Path(caseRect.insetBy(dx: 6, dy: 6)), with: .color(Quire.ink.opacity(0.4)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                            ctx.draw(Text("the open case").font(Quire.note(10)).foregroundColor(Quire.card), at: CGPoint(x: caseRect.midX, y: caseRect.maxY - 10))
                        }
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Quire.paste)
                            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Quire.ink.opacity(0.7), lineWidth: 1))
                            .overlay(Text("block").font(Quire.note(10)).foregroundColor(Quire.ink))
                            .frame(width: geo.size.width * 0.4 - 12, height: geo.size.height - 32)
                            .position(x: offset < 0 ? geo.size.width * 0.12 : geo.size.width * 0.5 + CGFloat(offset) * 2, y: geo.size.height / 2)
                            .offset(offset < 0 ? blockOffset : .zero)
                            .gesture(DragGesture(minimumDistance: 4)
                                .onChanged { v in if offset < 0 { blockOffset = v.translation } }
                                .onEnded { v in
                                    guard offset < 0 else { return }
                                    let endX = geo.size.width * 0.12 + v.translation.width
                                    let target = geo.size.width * 0.5
                                    blockOffset = .zero
                                    if abs(endX - target) < geo.size.width * 0.16 {
                                        let mm = Double(abs(endX - target)) / 2.0
                                        bench.caseIn(offsetMM: mm)
                                        Knock.firm()
                                        message = mm < 1.5 ? "Dropped in square. Now nip it: press and hold." : "Dropped in \(String(format: "%.1f", mm)) mm off centre; the squares are unequal. Now nip it."
                                    } else {
                                        message = "Drop the block into the case."
                                    }
                                })
                    }
                }
                .frame(height: 150)
                if offset >= 0 && bench.s?.nipped != true {
                    Text(nipping ? "Holding..." : "Press and hold to nip the joints in the press.").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                    RoundedRectangle(cornerRadius: 6).fill(nipping ? Quire.brass : Quire.walnut)
                        .frame(height: 44)
                        .overlay(Text("Nip").font(Quire.title(15)).foregroundColor(Quire.card))
                        .onLongPressGesture(minimumDuration: 1.4, pressing: { p in nipping = p }, perform: {
                            bench.nip()
                            Knock.hard()
                            message = "Nipped. The joints are set."
                        })
                }
                Text(message).font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
