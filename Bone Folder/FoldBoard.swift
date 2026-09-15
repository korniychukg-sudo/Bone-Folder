import SwiftUI

struct FoldBoard: View {
    var imposition: Imposition
    var sheet: SheetSize
    var paper: Material
    var moves: [FoldMove]
    var needsCrease: Bool
    var onFold: (FoldMove, Double) -> Void
    var onCrease: (Double, Double) -> Void
    var onMessage: (String) -> Void
    @State private var dragStart: CGPoint? = nil
    @State private var lift: (FoldMove, CGFloat)? = nil
    @State private var creaseStart: Date? = nil
    @State private var creaseMin: CGFloat = 1e9
    @State private var creaseMax: CGFloat = -1e9

    private var state: FoldState {
        var s = FoldState(imposition: imposition)
        for m in moves { s.fold(m) }
        return s
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Quire.walnut.opacity(0.92))
                PlateFill(name: "dc_benchTop").cornerRadius(8).opacity(0.9)
                SheetCanvas(imposition: imposition, sheet: sheet, paper: paper, back: false, state: state, moves: [], lift: lift, uncreased: needsCrease ? moves.last : nil)
                    .padding(6)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 6)
                .onChanged { v in handleChanged(v, in: geo.size) }
                .onEnded { v in handleEnded(v, in: geo.size) })
        }
    }

    private func footprint(in size: CGSize) -> CGRect {
        let st = state
        let sheetW = imposition.sheetPortrait ? sheet.shortMM : sheet.longMM
        let sheetH = imposition.sheetPortrait ? sheet.longMM : sheet.shortMM
        let cellW = sheetW / Double(imposition.cols), cellH = sheetH / Double(imposition.rows)
        let footW = cellW * Double(st.cols), footH = cellH * Double(st.rows)
        let inner = CGSize(width: size.width - 12, height: size.height - 12)
        let scale = min(Double(inner.width - 40) / footW, Double(inner.height - 40) / footH)
        let w = footW * scale, h = footH * scale
        return CGRect(x: 6 + (Double(inner.width) - w) / 2, y: 6 + (Double(inner.height) - h) / 2, width: w, height: h)
    }

    private func mmPerPoint(in size: CGSize) -> Double {
        let st = state
        let sheetW = imposition.sheetPortrait ? sheet.shortMM : sheet.longMM
        let footW = sheetW / Double(imposition.cols) * Double(st.cols)
        return footW / Double(footprint(in: size).width)
    }

    private func creaseLine(_ move: FoldMove, _ f: CGRect) -> (CGPoint, CGPoint) {
        switch move {
        case .rightOverLeft: return (CGPoint(x: f.maxX, y: f.minY), CGPoint(x: f.maxX, y: f.maxY))
        case .leftOverRight: return (CGPoint(x: f.minX, y: f.minY), CGPoint(x: f.minX, y: f.maxY))
        case .bottomOverTop: return (CGPoint(x: f.minX, y: f.maxY), CGPoint(x: f.maxX, y: f.maxY))
        case .topOverBottom: return (CGPoint(x: f.minX, y: f.minY), CGPoint(x: f.maxX, y: f.minY))
        }
    }

    private func handleChanged(_ v: DragGesture.Value, in size: CGSize) {
        let f = footprint(in: size)
        if needsCrease, let u = moves.last {
            if creaseStart == nil { creaseStart = Date(); creaseMin = 1e9; creaseMax = -1e9 }
            let (a, b) = creaseLine(u, f)
            let vertical = a.x == b.x
            let dist = vertical ? abs(v.location.x - a.x) : abs(v.location.y - a.y)
            if dist < 34 {
                let t = vertical ? v.location.y : v.location.x
                creaseMin = min(creaseMin, t)
                creaseMax = max(creaseMax, t)
            }
            return
        }
        let st = state
        guard !st.folded else { return }
        if dragStart == nil { dragStart = v.startLocation }
        guard let start = dragStart else { return }
        let dx = v.location.x - start.x, dy = v.location.y - start.y
        let horizontal = abs(dx) > abs(dy)
        if horizontal && st.canFold(.rightOverLeft) {
            if start.x > f.midX && dx < 0 { lift = (.rightOverLeft, min(1, -dx / (f.width / 2))) }
            else if start.x < f.midX && dx > 0 { lift = (.leftOverRight, min(1, dx / (f.width / 2))) }
            else { lift = nil }
        } else if !horizontal && st.canFold(.bottomOverTop) {
            if start.y > f.midY && dy < 0 { lift = (.bottomOverTop, min(1, -dy / (f.height / 2))) }
            else if start.y < f.midY && dy > 0 { lift = (.topOverBottom, min(1, dy / (f.height / 2))) }
            else { lift = nil }
        } else {
            lift = nil
        }
    }

    private func handleEnded(_ v: DragGesture.Value, in size: CGSize) {
        let f = footprint(in: size)
        if needsCrease, let u = moves.last {
            defer { creaseStart = nil }
            let (a, b) = creaseLine(u, f)
            let vertical = a.x == b.x
            let length = vertical ? (b.y - a.y) : (b.x - a.x)
            let covered = creaseMax > creaseMin ? Double((creaseMax - creaseMin) / max(1, length)) : 0
            let seconds = max(0.05, Date().timeIntervalSince(creaseStart ?? Date()))
            let speed = Double(max(0, creaseMax - creaseMin)) / seconds
            onCrease(covered, speed)
            return
        }
        defer { dragStart = nil; lift = nil }
        guard let (move, progress) = lift else { return }
        let dimension = move.axis == .vertical ? Double(f.width / 2) : Double(f.height / 2)
        guard progress > 0.55 else { onMessage("The edge did not reach across. Drag it all the way to the far edge."); return }
        let overshoot = move.axis == .vertical ? abs(Double(v.location.x - (dragStart?.x ?? 0))) : abs(Double(v.location.y - (dragStart?.y ?? 0)))
        let offset = abs(overshoot - dimension) * mmPerPoint(in: size)
        onFold(move, offset)
    }
}

struct FoldPractice: View {
    @EnvironmentObject var bindery: Bindery
    @State private var imposition: Imposition = .quarto
    @State private var moves: [FoldMove] = []
    @State private var creased = true
    @State private var message = "Fold the sheet so the pages come out in order. Every fold wants a crease."
    @State private var solved = 0
    @State private var tries = 0
    @Environment(\.presentationMode) private var presentation

    private var readout: FoldReadout { Imposer.readout(imposition, moves) }
    private var paper: Material { Materials.find(imposition.correctGrain == .long ? "bookWove" : "lokta") }

    var body: some View {
        ScrollView {
            Column {
                VStack(alignment: .leading, spacing: 4) {
                    Text("The folding puzzle").font(Quire.title(22)).foregroundColor(Quire.ink)
                    Text("The sheet is printed for its imposition. Drag the edges across; the block is right only when the pages read 1 to \(imposition.pages) with none on its head.")
                        .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ChoiceRow(items: Imposition.allCases, label: { "\($0.name) (\($0.folds) fold\($0.folds == 1 ? "" : "s"))" }, selection: $imposition)
                    .onChange(of: imposition) { _ in reset() }
                FoldBoard(imposition: imposition, sheet: imposition.sheetPortrait ? .a3 : .a3, paper: paper, moves: moves, needsCrease: !creased,
                          onFold: { move, offset in
                              moves.append(move)
                              creased = false
                              Knock.firm()
                              message = "Folded \(move.name), \(String(format: "%.1f", offset)) mm off the edge. Now crease it."
                          },
                          onCrease: { coverage, speed in
                              if coverage < 0.3 { message = "Swipe along the dashed fold, end to end."; return }
                              creased = true
                              Knock.light()
                              let r = readout
                              if r.complete {
                                  tries += 1
                                  if r.correct { solved += 1; message = "In order: pages 1 to \(imposition.pages). Solved \(solved) of \(tries)." }
                                  else { message = r.fault ?? "Out of order." }
                              } else {
                                  message = "Creased. Fold \(moves.count + 1) of \(imposition.folds)."
                              }
                          },
                          onMessage: { message = $0 })
                    .frame(height: Quire.isPad ? 380 : 280)
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: readout.complete ? (readout.correct ? "Right" : "Wrong") : "Fold \(min(imposition.folds, moves.count + 1)) of \(imposition.folds)", trailing: "\(solved) solved")
                        if readout.complete {
                            HStack(spacing: 4) {
                                ForEach(Array(readout.pages.enumerated()), id: \.offset) { i, page in
                                    Text("\(page)").font(Quire.title(12)).foregroundColor(readout.upright[i] ? Quire.ink : Quire.thread)
                                        .rotationEffect(.degrees(readout.upright[i] ? 0 : 180))
                                        .frame(minWidth: 16, minHeight: 20)
                                        .background(RoundedRectangle(cornerRadius: 3).fill(page == i + 1 && readout.upright[i] ? Quire.good.opacity(0.15) : Quire.thread.opacity(0.12)))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Text(message).font(Quire.body(13)).foregroundColor(readout.complete && !readout.correct ? Quire.thread : Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        SealButton(title: readout.complete ? "Another sheet" : "Unfold", tone: Quire.walnut, filled: readout.complete) { reset() }
                    }
                }
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "The rule")
                        Text(imposition.note).font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        Text("Right-angle folds, each at ninety degrees to the last, and the last fold is the spine. A mirror sequence puts page 1 on the back; a fold across the sheet at the end puts the spine at the head.")
                            .font(Quire.note(12.5)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Quire.page.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackChevron(label: "Book") { presentation.wrappedValue.dismiss() }
            }
        }
    }

    private func reset() {
        moves = []
        creased = true
        message = "Fold the sheet so the pages come out in order. Every fold wants a crease."
    }
}
