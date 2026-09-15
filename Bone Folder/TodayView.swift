import SwiftUI

struct TodayView: View {
    @EnvironmentObject var bindery: Bindery
    @State private var now = Date()
    @State private var openSettings = false
    @State private var openLast: BoundBook? = nil
    private let clock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var hour: Double { Clock.hourNow(now) }
    private var weather: Weather { Daily.weather(day: bindery.today) }

    var body: some View {
        ScrollView {
            Column {
                sceneCard
                commissionCard
                if bindery.bench.active { benchCard }
                standingCard
                lastCard
                wordCard
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.bottom, 28)
        }
        .background(Quire.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .onReceive(clock) { _ in now = Date() }
        .onAppear { now = Date() }
        .fullScreenCover(isPresented: $openSettings) {
            SettingsView { openSettings = false }.environmentObject(bindery)
        }
        .fullScreenCover(item: $openLast) { book in
            BookOpenView(book: book) { openLast = nil }.environmentObject(bindery)
        }
    }

    private var sceneCard: some View {
        let bench = bindery.bench
        let pressing = bench.active && bench.s?.pressStart != nil && bench.s?.pressedHours == nil
        return SheetCard(padding: 0) {
            VStack(spacing: 0) {
                ZStack {
                    PlateFill(name: "hr_\(Clock.plateIndex(hour))")
                    LiveBindery(hour: hour, weather: weather, pressRemaining: pressing ? bench.pressRemaining : nil, pressTotal: bench.pressNeeded * 3600, pressBookTone: pressing ? Color.tint(bench.cover.tone) : nil)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { Knock.light(); openSettings = true }) {
                                GearlessCog(size: 16, color: Quire.card).padding(8).background(Circle().fill(Quire.ink.opacity(0.35)))
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                        }
                        Spacer()
                    }
                }
                .frame(height: Quire.isPad ? 300 : 210)
                .clipped()
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Clock.hourWords(hour)).font(Quire.title(15.5)).foregroundColor(Quire.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(sceneNote(pressing: pressing)).font(Quire.body(12)).foregroundColor(Quire.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(13)
            }
        }
        .rising(0)
    }

    private func clockWords(_ h: Double) -> String {
        let hh = Int(h), mm = Int((h - Double(hh)) * 60)
        return String(format: "%d:%02d", hh, mm)
    }

    private func sceneNote(pressing: Bool) -> String {
        var parts: [String] = []
        let month = Clock.monthNow(now)
        parts.append("The bindery at this hour, \(weather.kind.word); sun up at \(clockWords(Daily.sunrise(month: month))), down at \(clockWords(Daily.sunset(month: month))).")
        if pressing {
            parts.append("A book is in the press: \(Clock.durationWords(bindery.bench.pressRemaining)) to go.")
        } else {
            parts.append("The press is empty.")
        }
        return parts.joined(separator: " ")
    }

    private var commissionCard: some View {
        let c = bindery.commission
        let done = bindery.commissionDoneToday()
        return SheetCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack {
                    HeadRule(text: "Commission of the day")
                    if done { StampTag(text: "delivered", tone: Quire.good) }
                }
                Text(c.title.title).font(Quire.title(17)).foregroundColor(Quire.ink)
                Text(c.line).font(Quire.note(13.5)).foregroundColor(Quire.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 9) {
                    CountTile(value: c.structure.shortName, label: "structure")
                    CountTile(value: "\(c.target)", label: "target")
                    CountTile(value: "\(bindery.liveStreak)", label: "day streak", tone: Quire.brass)
                }
                HStack(spacing: 10) {
                    PlateBox(name: "st_" + c.structure.rawValue, height: 76, corner: 4).frame(width: 110)
                    Text(structureSummary(c.structure)).font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                SealButton(title: done ? "Bind another" : (bindery.bench.active ? "Back to the bench" : "Take it to the bench"), tone: done ? Quire.inkSoft : Quire.walnut, filled: !done) {
                    if !bindery.bench.active && !done {
                        bindery.lockDaily()
                        bindery.bench.startFromCommission(c)
                    }
                    bindery.wantedTab = 1
                }
            }
        }
        .rising(1)
    }

    private func structureSummary(_ s: Structure) -> String {
        Register.bindings.first { $0.structure == s }?.summary ?? s.coverWord
    }

    private var benchCard: some View {
        let bench = bindery.bench
        return SheetCard {
            VStack(alignment: .leading, spacing: 9) {
                HeadRule(text: "On the bench", trailing: bench.stage.name)
                Text("\(bench.title.title): \(bench.structure.name), at the \(bench.stage.name.lowercased()) stage.")
                    .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                if bench.s?.pressStart != nil && bench.s?.pressedHours == nil {
                    MeterBar(label: "In the press", value: 1 - bench.pressRemaining / max(1, bench.pressNeeded * 3600), tone: Quire.brass,
                             caption: bench.pressRemaining > 0 ? "\(Clock.durationWords(bench.pressRemaining)) left" : "Done. Take it out on the bench.")
                }
                SealButton(title: "Go to the bench", tone: Quire.walnut, filled: false) { bindery.wantedTab = 1 }
            }
        }
        .rising(2)
    }

    private var standingCard: some View {
        let (name, note, points, ceiling) = bindery.rank
        let progress = ceiling > points ? Double(points) / Double(max(1, ceiling)) : 1
        return SheetCard {
            VStack(alignment: .leading, spacing: 11) {
                HeadRule(text: "Standing in the bindery")
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(name).font(Quire.title(18)).foregroundColor(Quire.ink)
                        Text(note).font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    VStack(spacing: 1) {
                        Text("\(bindery.liveStreak)").font(Quire.title(22)).foregroundColor(Quire.brass)
                        Text("STREAK").font(Quire.body(8)).tracking(1).foregroundColor(Quire.inkFaint)
                    }
                }
                MeterBar(label: "Toward the next bench", value: progress, tone: Quire.brass,
                         caption: ceiling > points ? "\(ceiling - points) points to go" : "Master Binder, and nothing above it")
                HStack(spacing: 9) {
                    CountTile(value: "\(bindery.ledger.books.count)", label: "on the shelf")
                    CountTile(value: "\(bindery.structuresBound.count)/\(Structure.allCases.count)", label: "structures")
                    CountTile(value: "\(bindery.ledger.bestStreak)", label: "best streak")
                }
                NoticeBar(text: "Rank locks nothing. Every structure is on the bench from the first day; the rank only changes what the commission asks for.", tone: Quire.indigo)
            }
        }
        .rising(3)
    }

    private var lastCard: some View {
        Group {
            if let last = bindery.ledger.books.last {
                SheetCard {
                    VStack(alignment: .leading, spacing: 9) {
                        HeadRule(text: "Last onto the shelf", trailing: last.word)
                        HStack(alignment: .top, spacing: 12) {
                            SpineThumb(book: last, height: 84)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(last.title.title).font(Quire.title(14)).foregroundColor(Quire.ink)
                                Text("\(last.kind.name), \(last.pages) pages, \(last.score).").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(last.critique.first ?? "").font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        SealButton(title: "Open it", tone: Quire.walnut, filled: false) { openLast = last }
                    }
                }
                .rising(4)
            }
        }
    }

    private var wordCard: some View {
        var rng = Bobbin(Almanac.seed(bindery.today) ^ 0x1A57)
        let entry = Glossary.all[rng.int(0, Glossary.all.count - 1)]
        let tool = Register.tools[rng.int(0, Register.tools.count - 1)]
        return SheetCard {
            VStack(alignment: .leading, spacing: 9) {
                HeadRule(text: "A word from the bench")
                Text(entry.term).font(Quire.title(16)).foregroundColor(Quire.ink)
                Text(entry.meaning).font(Quire.body(13)).foregroundColor(Quire.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .top, spacing: 10) {
                    PlateBox(name: tool.plate, height: 70, corner: 4).frame(width: 100)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tool.name).font(Quire.title(13)).foregroundColor(Quire.ink)
                        Text(tool.wrong).font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .rising(5)
    }
}

struct SpineThumb: View {
    var book: BoundBook
    var height: CGFloat

    var body: some View {
        let width = max(16, min(40, CGFloat(book.spineMM) * 2.2))
        return ZStack {
            RoundedRectangle(cornerRadius: 2).fill(Color.tint(book.cover.tone))
            VStack {
                Spacer()
                RoundedRectangle(cornerRadius: 1).fill(book.labelStyle == .giltCloth ? Quire.brassPale : Quire.card).frame(width: width * 0.7, height: height * 0.22)
                Spacer().frame(height: height * 0.2)
            }
            if book.kind.exposedSpine {
                VStack(spacing: 3) {
                    ForEach(0..<min(6, book.signatures), id: \.self) { _ in
                        Rectangle().fill(Quire.paste).frame(height: 3)
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: width, height: height)
        .overlay(RoundedRectangle(cornerRadius: 2).stroke(Quire.ink.opacity(0.6), lineWidth: 0.8))
    }
}
