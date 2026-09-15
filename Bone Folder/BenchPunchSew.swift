import SwiftUI

struct PunchStage: View {
    @EnvironmentObject var bindery: Bindery
    @State private var awlAt: CGPoint? = nil
    @State private var message = "Tap each mark with the awl, straight on the fold, in order from the head."
    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ScrollView {
        VStack(spacing: 10) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Quire.walnut.opacity(0.92))
                    PlateFill(name: "dc_benchTop").cornerRadius(8).opacity(0.9)
                    Canvas { ctx, size in
                        drawCradle(&ctx, size: size)
                        if let a = awlAt {
                            var awl = Path()
                            awl.move(to: a); awl.addLine(to: CGPoint(x: a.x + 46, y: a.y - 70))
                            ctx.stroke(awl, with: .color(Quire.steel), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            var handle = Path()
                            handle.move(to: CGPoint(x: a.x + 46, y: a.y - 70)); handle.addLine(to: CGPoint(x: a.x + 74, y: a.y - 112))
                            ctx.stroke(handle, with: .color(Quire.walnutLight), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 0).onEnded { v in tap(v.location, size: geo.size) })
            }
            .frame(height: Quire.isPad ? 400 : 300)
            .padding(.horizontal, Quire.gutter)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "Station \(min(bench.stationMarks.count, (bench.s?.punchErrors.count ?? 0) + 1)) of \(bench.stationMarks.count)", trailing: bench.structure.family == .stab ? "through the stack" : "through the fold")
                    Text(message).font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                    if let errors = bench.s?.punchErrors, !errors.isEmpty {
                        HStack(spacing: 5) {
                            ForEach(Array(errors.enumerated()), id: \.offset) { _, e in
                                Text(String(format: "%.1f", e)).font(Quire.title(11)).foregroundColor(e <= 2 ? Quire.good : Quire.thread)
                                    .padding(.horizontal, 6).padding(.vertical, 3)
                                    .background(RoundedRectangle(cornerRadius: 3).fill((e <= 2 ? Quire.good : Quire.thread).opacity(0.12)))
                            }
                            Text("mm off").font(Quire.note(11)).foregroundColor(Quire.inkFaint)
                        }
                    }
                }
            }
            .padding(.horizontal, Quire.gutter)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        }
    }

    private func layout(_ size: CGSize) -> (CGRect, Double) {
        let heightMM = bench.signatureHeightMM
        let widthMM = bench.structure.family == .stab ? min(heightMM * 0.7, bench.signatureHeightMM * 0.72) : heightMM * 1.4
        let scale = min(Double(size.width - 60) / widthMM, Double(size.height - 60) / heightMM)
        let w = widthMM * scale, h = heightMM * scale
        return (CGRect(x: (Double(size.width) - w) / 2, y: (Double(size.height) - h) / 2, width: w, height: h), scale)
    }

    private func markPoint(_ index: Int, in size: CGSize) -> CGPoint {
        let (rect, scale) = layout(size)
        let marks = bench.stationMarks
        guard index < marks.count else { return CGPoint(x: rect.midX, y: rect.midY) }
        if bench.structure.family == .stab {
            let holes = StitchGrammar.holes(bench.structure)
            let h = holes[index]
            return CGPoint(x: rect.minX + CGFloat(h.x * scale), y: rect.minY + CGFloat(marks[index] * scale))
        }
        return CGPoint(x: rect.midX, y: rect.minY + CGFloat(marks[index] * scale))
    }

    private func drawCradle(_ ctx: inout GraphicsContext, size: CGSize) {
        let (rect, scale) = layout(size)
        let stab = bench.structure.family == .stab
        if stab {
            ctx.fill(Path(rect.offsetBy(dx: 6, dy: 8)), with: .color(Color.black.opacity(0.25)))
            for k in stride(from: 8, through: 1, by: -1) {
                ctx.fill(Path(rect.offsetBy(dx: CGFloat(k) * 1.2, dy: CGFloat(k) * 1.2)), with: .color(Color.tint(bench.paper.tone).opacity(0.95)))
            }
            ctx.fill(Path(rect), with: .color(Color.tint(bench.paper.tone)))
            ctx.stroke(Path(rect), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1)
            var edge = Path()
            edge.move(to: CGPoint(x: rect.minX, y: rect.minY)); edge.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            ctx.stroke(edge, with: .color(Quire.ink.opacity(0.8)), lineWidth: 2)
            ctx.draw(Text("spine edge").font(Quire.note(11)).foregroundColor(Quire.inkFaint), at: CGPoint(x: rect.minX + 30, y: rect.maxY + 14))
        } else {
            let left = CGRect(x: rect.minX, y: rect.minY - 10, width: rect.width / 2, height: rect.height + 20)
            let right = CGRect(x: rect.midX, y: rect.minY - 10, width: rect.width / 2, height: rect.height + 20)
            ctx.fill(Path(CGRect(x: rect.minX - 24, y: rect.minY - 26, width: rect.width + 48, height: rect.height + 52)), with: .color(Quire.walnutLight.opacity(0.9)))
            ctx.stroke(Path(CGRect(x: rect.minX - 24, y: rect.minY - 26, width: rect.width + 48, height: rect.height + 52)), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1.2)
            ctx.fill(Path(left), with: .linearGradient(Gradient(colors: [Color.tint(bench.paper.tone).opacity(0.85), Color.tint(bench.paper.tone)]), startPoint: CGPoint(x: left.minX, y: 0), endPoint: CGPoint(x: left.maxX, y: 0)))
            ctx.fill(Path(right), with: .linearGradient(Gradient(colors: [Color.tint(bench.paper.tone), Color.tint(bench.paper.tone).opacity(0.85)]), startPoint: CGPoint(x: right.minX, y: 0), endPoint: CGPoint(x: right.maxX, y: 0)))
            ctx.stroke(Path(left), with: .color(Quire.ink.opacity(0.5)), lineWidth: 0.8)
            ctx.stroke(Path(right), with: .color(Quire.ink.opacity(0.5)), lineWidth: 0.8)
            var fold = Path()
            fold.move(to: CGPoint(x: rect.midX, y: rect.minY - 10)); fold.addLine(to: CGPoint(x: rect.midX, y: rect.maxY + 10))
            ctx.stroke(fold, with: .color(Quire.ink.opacity(0.75)), lineWidth: 1.6)
        }
        let marks = bench.stationMarks
        let punched = bench.s?.punchErrors.count ?? 0
        for i in 0..<marks.count {
            let q = markPoint(i, in: size)
            let tick: CGFloat = 9
            var m = Path()
            m.move(to: CGPoint(x: q.x - tick, y: q.y)); m.addLine(to: CGPoint(x: q.x + tick, y: q.y))
            ctx.stroke(m, with: .color(i == punched ? Quire.thread : Quire.ink.opacity(0.55)), lineWidth: i == punched ? 2 : 1)
            if i < punched {
                ctx.fill(Path(ellipseIn: CGRect(x: q.x - 3.5, y: q.y - 3.5, width: 7, height: 7)), with: .color(Quire.ink))
            } else if i == punched {
                ctx.stroke(Path(ellipseIn: CGRect(x: q.x - 12, y: q.y - 12, width: 24, height: 24)), with: .color(Quire.thread.opacity(0.7)), lineWidth: 1.2)
            }
            ctx.draw(Text("\(i + 1)").font(Quire.note(11)).foregroundColor(Quire.inkFaint), at: CGPoint(x: q.x + (stab ? 22 : 24), y: q.y))
        }
        _ = scale
    }

    private func tap(_ p: CGPoint, size: CGSize) {
        let index = bench.s?.punchErrors.count ?? 0
        guard index < bench.stationMarks.count else { return }
        let (_, scale) = layout(size)
        let q = markPoint(index, in: size)
        let errorMM = Double(hypot(p.x - q.x, p.y - q.y)) / scale
        guard errorMM < 25 else { message = "That is nowhere near the mark. The awl goes on the tick at station \(index + 1)."; return }
        bench.punch(errorMM: errorMM)
        awlAt = p
        Knock.crisp()
        message = errorMM <= 2 ? "Station \(index + 1): \(String(format: "%.1f", errorMM)) mm off the mark. Clean." : "Station \(index + 1): \(String(format: "%.1f", errorMM)) mm off. A crooked station; the stitch will step there."
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { withAnimation { awlAt = nil } }
    }
}

struct SewStage: View {
    @ObservedObject var session: BenchSession
    @State private var dragPoints: [CGPoint] = []
    @State private var finger: CGPoint? = nil
    @State private var needle = 0
    @State private var message = ""
    @State private var lastPull: TensionResult? = nil
    private var bench: BenchSession { session }

    var body: some View {
        ScrollView {
        VStack(spacing: 10) {
            if bench.structure.needles == 2 {
                HStack(spacing: 8) {
                    ForEach(0..<max(2, (bench.s?.stations ?? 4)), id: \.self) { n in
                        let on = needle == n
                        Button(action: { Knock.light(); needle = n }) {
                            Text(n % 2 == 0 ? "Left needle, pair \(n / 2 + 1)" : "Right needle, pair \(n / 2 + 1)")
                                .font(Quire.title(11)).foregroundColor(on ? Quire.card : Quire.inkSoft)
                                .padding(.horizontal, 9).padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 5).fill(on ? (n % 2 == 0 ? Quire.thread : Quire.indigo) : Quire.ink.opacity(0.06)))
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Quire.gutter)
            }
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(Quire.walnut.opacity(0.92))
                    PlateFill(name: "dc_benchTop").cornerRadius(8).opacity(0.9)
                    Canvas { ctx, size in
                        let frame = StitchFrame.make(in: size, structure: bench.structure, signatures: bench.rows, stations: bench.s?.stations ?? 4)
                        let done = bench.s?.stitchIndex ?? 0
                        if bench.structure.family == .stab {
                            StitchPainter.drawStab(&ctx, frame: frame, thread: bench.thread, done: done, expected: bench.expectedStep, highlight: true, coverTone: Color.tint(bench.cover.tone))
                        } else {
                            StitchPainter.drawSpine(&ctx, frame: frame, thread: bench.thread, done: done, expected: bench.expectedStep, tears: bench.s?.tears ?? [], torn: true, tapes: true, highlight: true)
                        }
                        let tone = StitchPainter.threadColor(bench.thread, needle: bench.expectedStep?.needle ?? 0)
                        if bench.s?.pendingPull == true {
                            let from = currentPoint(frame)
                            if let f = finger {
                                StitchPainter.drawLiveThread(&ctx, from: from, to: f, tone: tone)
                                let tension = min(1, Double(hypot(f.x - from.x, f.y - from.y)) / 220)
                                let w = bench.thread.tensionWindow
                                let bar = CGRect(x: size.width * 0.15, y: size.height - 22, width: size.width * 0.7, height: 10)
                                ctx.fill(Path(roundedRect: bar, cornerRadius: 5), with: .color(Quire.card.opacity(0.7)))
                                let win = CGRect(x: bar.minX + bar.width * CGFloat(w.lowerBound), y: bar.minY, width: bar.width * CGFloat(w.upperBound - w.lowerBound), height: bar.height)
                                ctx.fill(Path(roundedRect: win, cornerRadius: 5), with: .color(Quire.good.opacity(0.55)))
                                let x = bar.minX + bar.width * CGFloat(tension)
                                ctx.fill(Path(ellipseIn: CGRect(x: x - 7, y: bar.midY - 7, width: 14, height: 14)), with: .color(tension < w.lowerBound ? Quire.brass : (tension > w.upperBound ? Quire.thread : Quire.good)))
                            } else {
                                ctx.draw(Text("pull the thread away from the spine").font(Quire.note(12)).foregroundColor(Quire.card), at: CGPoint(x: size.width / 2, y: size.height - 16))
                            }
                        } else if let f = finger, bench.expectedStep != nil {
                            let from = currentPoint(frame)
                            StitchPainter.drawLiveThread(&ctx, from: from, to: f, tone: tone)
                            StitchPainter.drawNeedle(&ctx, at: f, angle: -0.9, length: 44)
                        } else if bench.expectedStep != nil {
                            let from = currentPoint(frame)
                            StitchPainter.drawNeedle(&ctx, at: CGPoint(x: from.x + 18, y: from.y - 26), angle: -0.9, length: 40)
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 4)
                    .onChanged { v in
                        finger = v.location
                        dragPoints.append(v.location)
                    }
                    .onEnded { v in
                        let frame = StitchFrame.make(in: geo.size, structure: bench.structure, signatures: bench.rows, stations: bench.s?.stations ?? 4)
                        release(v, frame: frame)
                        finger = nil
                        dragPoints = []
                    })
            }
            .frame(height: Quire.isPad ? 440 : 320)
            .padding(.horizontal, Quire.gutter)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: bench.sewingDone ? "Sewn" : "Pass \((bench.s?.stitchIndex ?? 0) + 1) of \(bench.path.count)", trailing: "\(bench.s?.stitchFaults ?? 0) faults")
                    if bench.s?.pendingPull == true {
                        Text("Pull the thread: drag from the station away from the spine until the pull lands in the window, then let go.")
                            .font(Quire.body(13)).foregroundColor(Quire.thread).fixedSize(horizontal: false, vertical: true)
                    } else if let e = bench.expectedStep {
                        Text(StitchGrammar.instruction(bench.structure, step: e, previous: bench.previousStep, stations: bench.s?.stations ?? 4, rows: bench.rows))
                            .font(Quire.body(13)).foregroundColor(Quire.ink).fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Every station sewn. The thread is tied off inside the fold.").font(Quire.body(13)).foregroundColor(Quire.good)
                    }
                    if !message.isEmpty {
                        Text(message).font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                    }
                    HStack(spacing: 4) {
                        ForEach(Array(bench.tensionResults.enumerated()), id: \.offset) { _, t in
                            Circle().fill(t == .good ? Quire.good : (t == .loose ? Quire.brass : Quire.thread)).frame(width: 9, height: 9)
                        }
                        if !bench.tensionResults.isEmpty { Text("pulls").font(Quire.note(11)).foregroundColor(Quire.inkFaint) }
                    }
                }
            }
            .padding(.horizontal, Quire.gutter)
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        }
    }

    private func currentPoint(_ frame: StitchFrame) -> CGPoint {
        let index = bench.s?.stitchIndex ?? 0
        let steps = bench.path
        if bench.structure.family == .stab {
            if index == 0 { return CGPoint(x: frame.rect.minX - 30, y: frame.rect.midY) }
            let last = steps[min(index, steps.count) - 1]
            return StitchPainter.stabPoint(frame, last.station)
        }
        if index == 0 { return CGPoint(x: frame.rect.minX - 24, y: frame.rect.maxY - frame.rowH * 0.5) }
        let last = steps[min(index, steps.count) - 1]
        return frame.point(row: last.row, station: last.station) ?? CGPoint(x: frame.rect.midX, y: frame.rect.midY)
    }

    private func linkAnchor(_ step: StitchStep, _ frame: StitchFrame) -> CGPoint? {
        guard step.link.needsPass, let node = frame.point(row: step.row, station: step.station) else { return nil }
        switch step.link {
        case .frenchLink:
            let prev = bench.previousStep
            let px = prev.flatMap { frame.point(row: $0.row, station: $0.station) }?.x ?? node.x
            return CGPoint(x: (node.x + px) / 2, y: node.y + frame.rowH * 0.5)
        case .underCoverStitch:
            return frame.point(row: 0, station: step.station)
        default:
            return CGPoint(x: node.x, y: node.y + frame.rowH * 0.5)
        }
    }

    private func release(_ v: DragGesture.Value, frame: StitchFrame) {
        if bench.s?.pendingPull == true {
            let from = currentPoint(frame)
            let tension = min(1, Double(hypot(v.location.x - from.x, v.location.y - from.y)) / 220)
            let result = bench.pull(tension)
            lastPull = result
            switch result {
            case .good: Knock.firm(); message = "The pull is in the window."
            case .loose: Knock.light(); message = "Too loose: the signature gapes and the spine will be baggy."
            case .tight: Knock.hard(); message = "Too tight: the thread tore the paper at the station."
            }
            return
        }
        guard let expected = bench.expectedStep else { return }
        if bench.structure.family == .stab {
            if expected.link.isWrap {
                let r = frame.rect
                let crossed: Bool
                switch expected.link {
                case .aroundSpine: crossed = dragPoints.contains { $0.x < r.minX - 14 }
                case .aroundHead: crossed = dragPoints.contains { $0.y < r.minY - 14 }
                default: crossed = dragPoints.contains { $0.y > r.maxY + 14 }
                }
                let home = StitchPainter.stabPoint(frame, expected.station)
                let back = hypot(v.location.x - home.x, v.location.y - home.y) < 34
                if crossed && back {
                    _ = bench.wrapDone(station: expected.station)
                    Knock.firm()
                    message = "Wrapped."
                } else {
                    message = crossed ? "Bring the thread back through the same hole." : "Take the thread out past the \(expected.link == .aroundSpine ? "spine edge" : (expected.link == .aroundHead ? "head" : "tail")) and back to the hole."
                    Knock.light()
                }
                return
            }
            guard let hole = StitchPainter.nearestStab(frame, v.location, within: 30) else { message = "Let go on a hole."; return }
            let result = bench.attempt(row: 0, station: hole, passedLink: true)
            react(result, expected: expected)
            return
        }
        guard let node = frame.nearest(v.location, within: 30) else { message = "Let go on a station."; return }
        var passed = true
        if let anchor = linkAnchor(expected, frame) {
            passed = dragPoints.contains { hypot($0.x - anchor.x, $0.y - anchor.y) < 24 }
        }
        let result = bench.attempt(row: node.row, station: node.station, passedLink: passed, needle: needle)
        react(result, expected: expected)
    }

    private func react(_ result: StitchAttempt, expected: StitchStep) {
        switch result {
        case .accepted, .finished:
            Knock.firm()
            message = result == .finished ? "Tied off." : ""
        case .acceptedNoLink:
            Knock.light()
            message = "The station was right but the link was skipped: loop under the row below before going in."
        case .wrongStation:
            Knock.hard()
            message = "A skipped station. The thread is drawn back; \(StitchGrammar.instruction(bench.structure, step: expected, previous: bench.previousStep, stations: bench.s?.stations ?? 4, rows: bench.rows).lowercased())"
        case .needsPull:
            message = "Pull the thread first."
        case .wrongNeedle:
            Knock.light()
            message = "That is the other needle's pass. Change needles."
        }
    }
}
