import SwiftUI

let silkTones: [Color] = [Quire.thread, Quire.card, Quire.indigo, Quire.brassPale, Quire.moss, Quire.walnut, Color(red: 0.86, green: 0.62, blue: 0.70), Color(red: 0.16, green: 0.15, blue: 0.14)]
let silkNames: [String] = ["red", "white", "indigo", "gold", "moss", "walnut", "rose", "black"]

struct SpineStage: View {
    @EnvironmentObject var bindery: Bindery
    @State private var hammerAt: CGPoint? = nil
    @State private var message = "Round the spine first: tap along it with the hammer, head, middle and tail, a little at a time."
    @State private var lastHeadTap: Date? = nil
    @State private var dragLining: String? = nil
    @State private var liningOffset: CGSize = .zero
    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ScrollView {
            Column {
                roundingCard
                backingCard
                liningCard
                headbandCard
                endpaperCard
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.bottom, 20)
        }
    }

    private var roundingCard: some View {
        let taps = bench.s?.roundingTaps ?? [0, 0, 0]
        let total = taps.reduce(0, +)
        return SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Rounding", trailing: "\(total) taps, \(bench.roundingNeeded) wanted")
                GeometryReader { geo in
                    Canvas { ctx, size in
                        let profile = bench.roundingProfile
                        let x0 = size.width * 0.08, x1 = size.width * 0.92
                        let base = size.height * 0.78
                        let arcH = size.height * 0.42
                        var target = Path()
                        target.move(to: CGPoint(x: x0, y: base))
                        target.addQuadCurve(to: CGPoint(x: x1, y: base), control: CGPoint(x: size.width / 2, y: base - arcH * 2))
                        ctx.stroke(target, with: .color(Quire.inkFaint.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        var spine = Path()
                        spine.move(to: CGPoint(x: x0, y: base))
                        let steps = 40
                        for k in 0...steps {
                            let f = Double(k) / Double(steps)
                            let zone = min(2, Int(f * 3))
                            let localLift = profile[zone]
                            let neighbour = zone == 0 ? profile[1] : (zone == 2 ? profile[1] : (profile[0] + profile[2]) / 2)
                            let blend = localLift * 0.7 + neighbour * 0.3
                            let y = base - sin(f * .pi) * arcH * CGFloat(blend)
                            spine.addLine(to: CGPoint(x: x0 + (x1 - x0) * CGFloat(f), y: y))
                        }
                        spine.addLine(to: CGPoint(x: x1, y: size.height))
                        spine.addLine(to: CGPoint(x: x0, y: size.height))
                        spine.closeSubpath()
                        ctx.fill(spine, with: .color(Quire.paste))
                        var leaves = Path()
                        var y = base + 4
                        while y < size.height { leaves.move(to: CGPoint(x: x0 + 2, y: y)); leaves.addLine(to: CGPoint(x: x1 - 2, y: y)); y += 3 }
                        ctx.stroke(leaves, with: .color(Quire.ink.opacity(0.14)), lineWidth: 0.6)
                        ctx.stroke(spine, with: .color(Quire.ink.opacity(0.8)), lineWidth: 1.4)
                        for (i, name) in ["head", "middle", "tail"].enumerated() {
                            let cx = x0 + (x1 - x0) * (CGFloat(i) + 0.5) / 3
                            ctx.draw(Text(name).font(Quire.note(11)).foregroundColor(Quire.inkFaint), at: CGPoint(x: cx, y: size.height - 10))
                            ctx.draw(Text("\(taps[i])").font(Quire.title(12)).foregroundColor(Quire.ink), at: CGPoint(x: cx, y: base + 16))
                        }
                        if let h = hammerAt {
                            var head = Path(roundedRect: CGRect(x: h.x - 16, y: h.y - 30, width: 32, height: 16), cornerRadius: 3)
                            ctx.fill(head, with: .color(Quire.steel))
                            head = Path()
                            head.move(to: CGPoint(x: h.x, y: h.y - 22)); head.addLine(to: CGPoint(x: h.x + 34, y: h.y - 70))
                            ctx.stroke(head, with: .color(Quire.walnutLight), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                        let zone = min(2, max(0, Int((v.location.x - geo.size.width * 0.08) / (geo.size.width * 0.84) * 3)))
                        bench.roundingTap(zone: zone)
                        hammerAt = v.location
                        Knock.crisp()
                        let t = (bench.s?.roundingTaps ?? [0, 0, 0]).reduce(0, +)
                        message = t < bench.roundingNeeded ? "Tap \(t) of \(bench.roundingNeeded). Spread them: head, middle, tail." : (t == bench.roundingNeeded ? "A third of a circle. Stop here." : "Over-tapping: the round is flattening back.")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { withAnimation { hammerAt = nil } }
                    })
                }
                .frame(height: 150)
                Text(message).font(Quire.body(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var backingCard: some View {
        let lip = bench.shoulderMM
        let target = bench.board.boardMM
        return SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Backing", trailing: String(format: "shoulder %.1f of %.1f mm", lip, target))
                GeometryReader { geo in
                    Canvas { ctx, size in
                        let cx = size.width / 2
                        let spineW = size.width * 0.5
                        let base = size.height * 0.75
                        let lipH = CGFloat(min(lip, target * 1.6) / max(0.5, target)) * size.height * 0.28
                        var block = Path()
                        block.move(to: CGPoint(x: cx - spineW / 2, y: size.height))
                        block.addLine(to: CGPoint(x: cx - spineW / 2, y: base))
                        block.addLine(to: CGPoint(x: cx - spineW / 2 - lipH * 0.6, y: base - lipH))
                        block.addQuadCurve(to: CGPoint(x: cx + spineW / 2 + lipH * 0.6, y: base - lipH), control: CGPoint(x: cx, y: base - lipH - size.height * 0.30))
                        block.addLine(to: CGPoint(x: cx + spineW / 2, y: base))
                        block.addLine(to: CGPoint(x: cx + spineW / 2, y: size.height))
                        block.closeSubpath()
                        ctx.fill(block, with: .color(Quire.paste))
                        ctx.stroke(block, with: .color(Quire.ink.opacity(0.8)), lineWidth: 1.4)
                        for side in [-1.0, 1.0] {
                            let bx = cx + CGFloat(side) * (spineW / 2 + 22)
                            let boardRect = CGRect(x: bx - 6, y: base - CGFloat(target / max(0.5, target)) * size.height * 0.28, width: 12, height: size.height)
                            ctx.fill(Path(boardRect), with: .color(Quire.greyboard.opacity(0.6)))
                            ctx.draw(Text("board").font(Quire.note(10)).foregroundColor(Quire.inkFaint), at: CGPoint(x: bx, y: boardRect.minY - 10))
                            ctx.draw(Text("tap").font(Quire.title(11)).foregroundColor(Quire.thread), at: CGPoint(x: cx + CGFloat(side) * spineW * 0.42, y: base - lipH - 26))
                        }
                        ctx.draw(Text("in the lying press, spine up").font(Quire.note(11)).foregroundColor(Quire.inkFaint), at: CGPoint(x: cx, y: size.height - 10))
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onEnded { v in
                        let cx = geo.size.width / 2
                        guard abs(v.location.x - cx) > geo.size.width * 0.12 else { message = "The backing taps go on the shoulders, not the middle."; return }
                        bench.backingTap()
                        Knock.crisp()
                        let l = bench.shoulderMM
                        message = l < target - 0.3 ? "Shoulder \(String(format: "%.1f", l)) mm; the board is \(String(format: "%.1f", target)). Keep going." : (l > target + 0.4 ? "Too tall: the board will sit proud." : "The shoulder matches the board.")
                    })
                }
                .frame(height: 130)
            }
        }
    }

    private var liningCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Lining", trailing: bench.s?.liningKraft == true ? "mull and kraft on" : (bench.s?.liningMull == true ? "mull on" : "bare spine"))
                GeometryReader { geo in
                    ZStack {
                        Canvas { ctx, size in
                            let spine = CGRect(x: size.width * 0.36, y: 8, width: size.width * 0.28, height: size.height - 16)
                            ctx.fill(Path(roundedRect: spine, cornerRadius: 6), with: .color(Quire.paste))
                            var leaves = Path()
                            var y = spine.minY + 3
                            while y < spine.maxY { leaves.move(to: CGPoint(x: spine.minX, y: y)); leaves.addLine(to: CGPoint(x: spine.maxX, y: y)); y += 3 }
                            ctx.stroke(leaves, with: .color(Quire.ink.opacity(0.12)), lineWidth: 0.6)
                            if bench.s?.liningMull == true {
                                let mull = spine.insetBy(dx: 6, dy: 10)
                                ctx.fill(Path(mull), with: .color(Quire.linenPale.opacity(0.9)))
                                var weave = Path()
                                var x = mull.minX
                                while x < mull.maxX { weave.move(to: CGPoint(x: x, y: mull.minY)); weave.addLine(to: CGPoint(x: x, y: mull.maxY)); x += 4 }
                                var yy = mull.minY
                                while yy < mull.maxY { weave.move(to: CGPoint(x: mull.minX, y: yy)); weave.addLine(to: CGPoint(x: mull.maxX, y: yy)); yy += 4 }
                                ctx.stroke(weave, with: .color(Quire.ink.opacity(0.18)), lineWidth: 0.6)
                            }
                            if bench.s?.liningKraft == true {
                                let kraft = spine.insetBy(dx: 10, dy: 20)
                                ctx.fill(Path(kraft), with: .color(Color(red: 0.72, green: 0.56, blue: 0.38).opacity(0.9)))
                            }
                            if bench.s?.liningMull == true {
                                let count = bench.bubbles
                                for k in 0..<count {
                                    let by = spine.minY + spine.height * (0.2 + CGFloat(k) * 0.2)
                                    let bx = spine.midX + CGFloat(k % 2 == 0 ? -14 : 12)
                                    ctx.fill(Path(ellipseIn: CGRect(x: bx - 12, y: by - 7, width: 24, height: 14)), with: .color(Color.white.opacity(0.55)))
                                    ctx.stroke(Path(ellipseIn: CGRect(x: bx - 12, y: by - 7, width: 24, height: 14)), with: .color(Quire.ink.opacity(0.35)), lineWidth: 0.8)
                                }
                            }
                            ctx.stroke(Path(roundedRect: spine, cornerRadius: 6), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1.2)
                            ctx.draw(Text("spine").font(Quire.note(11)).foregroundColor(Quire.inkFaint), at: CGPoint(x: spine.midX, y: size.height - 4))
                        }
                        liningStrip("mull", tone: Quire.linenPale, x: geo.size.width * 0.12, size: geo.size, enabled: bench.s?.liningMull != true)
                        liningStrip("kraft", tone: Color(red: 0.72, green: 0.56, blue: 0.38), x: geo.size.width * 0.88, size: geo.size, enabled: bench.s?.liningMull == true && bench.s?.liningKraft != true)
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 8).onEnded { v in
                        guard dragLining == nil, bench.s?.liningMull == true else { return }
                        if abs(v.translation.width) > 40 && abs(v.startLocation.x - geo.size.width / 2) < geo.size.width * 0.22 {
                            bench.liningSwipe()
                            Knock.light()
                            message = bench.bubbles == 0 ? "Smooth, no bubbles." : "\(bench.bubbles) bubble\(bench.bubbles == 1 ? "" : "s") left. Keep swiping from the middle out."
                        }
                    })
                }
                .frame(height: 170)
                Text(bench.s?.liningMull == true ? "Swipe across the spine to chase the bubbles out, then drag the kraft on." : "Drag the mull onto the spine, smooth it, then the kraft.")
                    .font(Quire.body(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func liningStrip(_ name: String, tone: Color, x: CGFloat, size: CGSize, enabled: Bool) -> some View {
        let dragging = dragLining == name
        return RoundedRectangle(cornerRadius: 4)
            .fill(tone)
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Quire.ink.opacity(0.6), lineWidth: 1))
            .overlay(Text(name).font(Quire.title(11)).foregroundColor(Quire.ink).rotationEffect(.degrees(-90)))
            .frame(width: size.width * 0.16, height: size.height - 30)
            .position(x: x, y: size.height / 2)
            .offset(dragging ? liningOffset : .zero)
            .opacity(enabled ? 1 : 0.25)
            .gesture(DragGesture(minimumDistance: 4)
                .onChanged { v in guard enabled else { return }; dragLining = name; liningOffset = v.translation }
                .onEnded { v in
                    defer { dragLining = nil; liningOffset = .zero }
                    guard enabled else { return }
                    let endX = x + v.translation.width
                    if abs(endX - size.width / 2) < size.width * 0.2 {
                        bench.layLining(mull: name == "mull")
                        Knock.firm()
                        message = name == "mull" ? "The mull is on. Smooth it from the middle out." : "Kraft on over the mull."
                    } else {
                        message = "Drop it on the spine."
                    }
                })
    }

    private var headbandCard: some View {
        let a = bench.s?.headbandA ?? 0, b = bench.s?.headbandB ?? 1
        let taps = bench.s?.headbandTaps ?? 0
        return SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Headbands", trailing: "\(taps) beads")
                HStack(spacing: 6) {
                    ForEach(0..<silkTones.count, id: \.self) { i in
                        Button(action: {
                            Knock.light()
                            if i == a { return }
                            if i == b { bench.chooseHeadband(a, b) } else { bench.chooseHeadband(i, a) }
                        }) {
                            Circle().fill(silkTones[i]).frame(width: 24, height: 24)
                                .overlay(Circle().stroke(Quire.ink.opacity(i == a || i == b ? 0.9 : 0.25), lineWidth: i == a || i == b ? 2 : 1))
                        }.buttonStyle(.plain)
                    }
                }
                Text("Silks: \(silkNames[a]) and \(silkNames[b]). Tap the head and the tail in a steady rhythm; each tap winds one bead.")
                    .font(Quire.body(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 10) {
                    ForEach(["head", "tail"], id: \.self) { end in
                        Button(action: {
                            let now = Date()
                            let interval = lastHeadTap.map { now.timeIntervalSince($0) }
                            lastHeadTap = now
                            bench.headbandTap(interval: interval != nil && interval! < 3 ? interval : nil)
                            Knock.light()
                            let reg = Rhythm.regularity(bench.s?.headbandIntervals ?? [])
                            message = (bench.s?.headbandTaps ?? 0) < 4 ? "Keep the rhythm." : (reg > 0.7 ? "An even bead." : "The beads are uneven; keep a steady beat.")
                        }) {
                            VStack(spacing: 6) {
                                HStack(spacing: 2) {
                                    ForEach(0..<max(1, min(12, taps / 2 + (end == "head" ? taps % 2 : 0))), id: \.self) { k in
                                        Capsule().fill(k % 2 == 0 ? silkTones[a] : silkTones[b]).frame(width: 9, height: 14)
                                            .overlay(Capsule().stroke(Quire.ink.opacity(0.4), lineWidth: 0.6))
                                    }
                                }
                                .frame(height: 16)
                                Text(end).font(Quire.title(12)).foregroundColor(Quire.ink)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Quire.paste.opacity(0.6)))
                        }.buttonStyle(.plain)
                    }
                }
                if let ints = bench.s?.headbandIntervals, ints.count >= 2 {
                    MeterBar(label: "Rhythm", value: Rhythm.regularity(ints), tone: Quire.brass)
                }
            }
        }
    }

    private var endpaperCard: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: "Endpapers", trailing: (bench.s?.endpaperStroke ?? -1) >= 0 ? "tipped on" : "to tip on")
                GeometryReader { geo in
                    Canvas { ctx, size in
                        let sheet = CGRect(x: size.width * 0.2, y: 10, width: size.width * 0.6, height: size.height - 20)
                        ctx.fill(Path(sheet), with: .color(Quire.card))
                        let band = CGRect(x: sheet.minX, y: sheet.minY, width: 22, height: sheet.height)
                        ctx.fill(Path(band), with: .color(Quire.paste.opacity(0.9)))
                        ctx.stroke(Path(band), with: .color(Quire.thread.opacity(0.7)), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        ctx.stroke(Path(sheet), with: .color(Quire.ink.opacity(0.7)), lineWidth: 1)
                        ctx.draw(Text("paste a line 5 mm wide along the spine edge, top to bottom").font(Quire.note(11)).foregroundColor(Quire.inkFaint), at: CGPoint(x: sheet.midX + 14, y: sheet.midY))
                        if let acc = bench.s?.endpaperStroke, acc >= 0 {
                            ctx.fill(Path(band.insetBy(dx: 4, dy: 0)), with: .color(Quire.brass.opacity(0.4)))
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 10).onEnded { v in
                        let band = CGRect(x: geo.size.width * 0.2, y: 10, width: 22, height: geo.size.height - 20)
                        let startIn = abs(v.startLocation.x - band.midX) < 18
                        let endIn = abs(v.location.x - band.midX) < 18
                        let coverage = min(1, abs(v.translation.height) / (band.height * 0.85))
                        let accuracy = (startIn ? 0.5 : 0.2) + (endIn ? 0.5 : 0.2)
                        let value = accuracy * Double(coverage)
                        bench.endpaper(value)
                        Knock.light()
                        message = value > 0.75 ? "A clean line of paste; the endpaper is tipped on." : "The paste wandered off the edge or stopped short."
                    })
                }
                .frame(height: 120)
            }
        }
    }
}
