import SwiftUI

struct BenchView: View {
    @EnvironmentObject var bindery: Bindery
    @State private var showAbandon = false
    @State private var celebration: (BoundBook, Bool, Int)? = nil
    @State private var showVerdict = false

    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ZStack {
            Quire.page.ignoresSafeArea()
            if bench.active {
                work
            } else {
                BenchSetupView()
            }
            if let c = celebration {
                Celebration(title: "Shelved", line: "\(c.0.title.title): \(c.0.score), \(c.1 ? "the best of its kind on the shelf" : "not the best of its kind yet"). \(c.2) points.", word: c.0.word) {
                    celebration = nil
                    bindery.wantedTab = 3
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showVerdict) {
            VerdictSheet(onShelve: { shelve() }, onClose: { showVerdict = false }).environmentObject(bindery)
        }
    }

    private var work: some View {
        VStack(spacing: 0) {
            header
            StageRail(stages: bench.stages, current: bench.stageIndex) { index in bench.goTo(index) }
                .padding(.horizontal, Quire.gutter)
                .padding(.vertical, 8)
            Group {
                switch bench.stage {
                case .sheet: SheetStage()
                case .fold: FoldStage()
                case .punch: PunchStage()
                case .sew: SewStage(session: bench)
                case .spine: SpineStage()
                case .boards: BoardsStage()
                case .cover: CoverStage()
                case .press: PressStage(onDone: { showVerdict = true })
                }
            }
            .id(bench.stageIndex)
            .transition(.opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(bench.title.title).font(Quire.title(17)).foregroundColor(Quire.ink).lineLimit(1)
                Text("\(bench.structure.name), \(bench.structure.family == .stab ? "\(bench.s?.signatures ?? 0) leaves" : "\(bench.s?.signatures ?? 0) signature\((bench.s?.signatures ?? 0) == 1 ? "" : "s")"), \(bench.paper.name.lowercased())")
                    .font(Quire.note(12)).foregroundColor(Quire.inkFaint).lineLimit(1)
            }
            Spacer()
            if bench.s?.forCommission == true { StampTag(text: "commission", tone: Quire.brass) }
            Button(action: { Knock.light(); showAbandon = true }) {
                CrossGlyph(size: 14, color: Quire.inkSoft).padding(8).background(Circle().fill(Quire.ink.opacity(0.07)))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Quire.gutter)
        .padding(.top, 12)
        .actionSheet(isPresented: $showAbandon) {
            ActionSheet(title: Text("Leave this book?"), message: Text("The work stays on the bench until you take it up again, or you can throw it away."),
                        buttons: [.destructive(Text("Throw it away")) { bench.reset() }, .cancel(Text("Keep it on the bench"))])
        }
    }

    private var footer: some View {
        VStack(spacing: 6) {
            if bench.stage != .press {
                if bench.stageComplete {
                    SealButton(title: bench.stageIndex + 1 < bench.stages.count ? "On to \(bench.stages[bench.stageIndex + 1].name.lowercased())" : "Finish", tone: Quire.walnut) {
                        withAnimation(.easeInOut(duration: 0.25)) { bench.advance() }
                    }
                } else {
                    Text(stageHint).font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.vertical, 6)
                }
            }
        }
        .padding(.horizontal, Quire.gutter)
        .padding(.bottom, 8)
    }

    private var stageHint: String {
        switch bench.stage {
        case .sheet: return "The sheet is laid."
        case .fold: return bench.structure == .accordion ? "Fold every panel in rhythm." : "Fold the sheet down to one leaf, and crease every fold with the folder."
        case .punch: return "Tap every station mark with the awl."
        case .sew: return "Sew every station and pull each row into the window."
        case .spine: return "Round, back, line, headband and tip the endpapers."
        case .boards: return "Cut both boards on the line."
        case .cover: return "Paste, turn in, make the corners" + (bench.structure.family == .supported ? ", case in and nip." : ".")
        case .press: return ""
        }
    }

    private func shelve() {
        guard let book = bench.finish() else { return }
        let (upgraded, gained) = bindery.shelve(book)
        showVerdict = false
        Knock.hard()
        celebration = (book, upgraded, gained)
    }
}

struct StageRail: View {
    var stages: [Stage]
    var current: Int
    var onPick: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.offset) { i, stage in
                let done = i < current
                let active = i == current
                Button(action: { if i <= current { Knock.light(); onPick(i) } }) {
                    VStack(spacing: 3) {
                        ZStack {
                            Circle().fill(active ? Quire.walnut : (done ? Quire.brass : Quire.ink.opacity(0.08))).frame(width: 18, height: 18)
                            if done { CheckGlyph(size: 12, color: Quire.card) }
                            if active { Circle().fill(Quire.card).frame(width: 6, height: 6) }
                        }
                        Text(stage.name).font(Quire.title(9)).foregroundColor(active ? Quire.ink : (done ? Quire.inkSoft : Quire.inkFaint))
                            .lineLimit(1).minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                if i < stages.count - 1 {
                    Rectangle().fill(i < current ? Quire.brass : Quire.ink.opacity(0.12)).frame(height: 1.2).frame(maxWidth: 14).offset(y: -8)
                }
            }
        }
    }
}

struct BenchSetupView: View {
    @EnvironmentObject var bindery: Bindery
    @State private var structure: Structure = .pamphlet3
    @State private var titleKey: String = Register.titles[0].key
    @State private var label: LabelStyle = .paperLabel
    @State private var signatures: Int = 1
    @State private var stations: Int = 3
    @State private var imposition: Imposition = .quarto
    @State private var sheet: SheetSize = .a3
    @State private var paperKey: String = "bookWove"
    @State private var thread: ThreadKind = .linen25
    @State private var coverKey: String = "starchCotton"
    @State private var boardKey: String = "grey2"

    private var bench: BenchSession { bindery.bench }

    var body: some View {
        ScrollView {
            Column {
                commissionCard
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "Structure")
                        ChoiceRow(items: Structure.allCases, label: { $0.shortName }, selection: $structure)
                        Text(Register.bindings.first { $0.structure == structure }?.summary ?? structure.coverWord)
                            .font(Quire.note(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        StitchDiagramView(structure: structure, signatures: structure.family == .chain || structure.family == .supported || structure == .longStitch || structure == .secretBelgian ? 3 : 1, stations: structure.defaultStations, thread: thread)
                            .frame(height: 150)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Quire.paste.opacity(0.35)))
                    }
                }
                .onChange(of: structure) { s in
                    signatures = min(max(signatures, s.signatureRange.lowerBound), s.signatureRange.upperBound)
                    if s.family == .stab { signatures = 24 }
                    if !s.stationOptions.contains(stations) { stations = s.defaultStations }
                    if !s.allowedImpositions.contains(imposition) { imposition = s.defaultImposition }
                }
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "The block")
                        if structure.family == .stab {
                            stepper("Leaves", value: $signatures, range: structure.leavesRange, step: 4)
                        } else if structure == .accordion {
                            Text("Panels").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                            ChoiceRow(items: structure.stationOptions, label: { "\($0)" }, selection: $stations)
                        } else {
                            stepper("Signatures", value: $signatures, range: structure.signatureRange, step: 1)
                        }
                        if structure != .accordion {
                            Text(structure.family == .stab ? "Holes" : "Stations").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                            ChoiceRow(items: structure.stationOptions, label: { "\($0)" }, selection: $stations)
                        }
                        Text("Imposition").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        ChoiceRow(items: structure.allowedImpositions, label: { "\($0.name) (\($0.pages))" }, selection: $imposition)
                        Text("Sheet").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        ChoiceRow(items: SheetSize.allCases, label: { $0.name }, selection: $sheet)
                        Text(imposition.note).font(Quire.note(12)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                    }
                }
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "Materials")
                        Text("Paper").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        ChoiceRow(items: Materials.benchPapers.map { $0.key }, label: { Materials.find($0).name }, selection: $paperKey)
                        HStack(spacing: 8) {
                            Text(Materials.find(paperKey).spec).font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                            if Materials.find(paperKey).grain != imposition.correctGrain {
                                StampTag(text: "grain across the spine", tone: Quire.thread)
                            } else {
                                StampTag(text: "grain with the spine", tone: Quire.good)
                            }
                        }
                        Text("Thread").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        ChoiceRow(items: ThreadKind.allCases, label: { $0.name }, selection: $thread)
                        Text("Covering").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        ChoiceRow(items: Materials.benchCovers.map { $0.key }, label: { Materials.find($0).name }, selection: $coverKey)
                        if structure.family != .pamphlet && structure.family != .stab {
                            Text("Boards").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                            ChoiceRow(items: Materials.benchBoards.map { $0.key }, label: { Materials.find($0).name }, selection: $boardKey)
                        }
                    }
                }
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HeadRule(text: "Title and label")
                        ChoiceRow(items: Register.titles.map { $0.key }, label: { Register.title($0).title }, selection: $titleKey)
                        ChoiceRow(items: LabelStyle.allCases, label: { $0.name }, selection: $label)
                        PlateBox(name: Register.title(titleKey).plate, height: 110, corner: 4)
                    }
                }
                SealButton(title: "Lay the sheet", tone: Quire.walnut) {
                    bench.start(structure: structure, title: Register.title(titleKey), label: label, signatures: signatures, stations: stations,
                                imposition: imposition, sheet: sheet, paper: Materials.find(paperKey), thread: thread,
                                cover: Materials.find(coverKey), board: Materials.find(boardKey), commission: bindery.commission)
                }
                .rising(2)
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .onAppear {
            let c = bindery.commission
            if titleKey == Register.titles[0].key && bindery.ledger.books.isEmpty { applyCommission(c) }
        }
    }

    private var commissionCard: some View {
        let c = bindery.commission
        let done = bindery.commissionDoneToday()
        return SheetCard {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    HeadRule(text: "Commission of the day")
                    if done { StampTag(text: "delivered", tone: Quire.good) }
                }
                Text(c.line).font(Quire.note(13.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                HStack {
                    CountTile(value: "\(c.target)", label: "target")
                    CountTile(value: "\(c.reward)", label: "reward")
                    SealButton(title: "Take it up", tone: Quire.brass, filled: false) {
                        applyCommission(c)
                        bindery.lockDaily()
                        bench.startFromCommission(c)
                    }
                }
            }
        }
        .rising(0)
    }

    private func applyCommission(_ c: Commission) {
        structure = c.structure
        titleKey = c.titleKey
        label = c.title.label
        signatures = c.signatures
        stations = c.stations
        imposition = c.imposition
        sheet = c.sheet
        paperKey = c.paperKey
        thread = c.thread
        coverKey = c.coverKey
        boardKey = c.boardKey
    }

    private func stepper(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack {
            Text(label).font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
            Spacer()
            Button(action: { Knock.light(); value.wrappedValue = max(range.lowerBound, value.wrappedValue - step) }) {
                Text("-").font(Quire.title(18)).foregroundColor(Quire.ink).frame(width: 34, height: 30).background(RoundedRectangle(cornerRadius: 5).fill(Quire.ink.opacity(0.07)))
            }.buttonStyle(.plain)
            Text("\(value.wrappedValue)").font(Quire.title(16)).foregroundColor(Quire.ink).frame(width: 40)
            Button(action: { Knock.light(); value.wrappedValue = min(range.upperBound, value.wrappedValue + step) }) {
                Text("+").font(Quire.title(18)).foregroundColor(Quire.ink).frame(width: 34, height: 30).background(RoundedRectangle(cornerRadius: 5).fill(Quire.ink.opacity(0.07)))
            }.buttonStyle(.plain)
        }
    }
}

struct VerdictSheet: View {
    @EnvironmentObject var bindery: Bindery
    var onShelve: () -> Void
    var onClose: () -> Void

    var body: some View {
        let v = bindery.bench.verdict
        ZStack {
            Quire.page.ignoresSafeArea()
            VStack(spacing: 0) {
                SheetHead(title: "The critique", subtitle: bindery.bench.title.title) { onClose() }
                ScrollView {
                    Column {
                        SheetCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("\(v.score)").font(Quire.title(40)).foregroundColor(Quire.ink)
                                    Text(v.word).font(Quire.title(18)).foregroundColor(Quire.walnut)
                                }
                                ForEach(Array(v.parts.enumerated()), id: \.offset) { _, part in
                                    MeterBar(label: part.name, value: part.value, tone: part.value >= 0.75 ? Quire.good : (part.value >= 0.45 ? Quire.brass : Quire.thread), caption: part.note)
                                }
                            }
                        }
                        SheetCard {
                            VStack(alignment: .leading, spacing: 8) {
                                HeadRule(text: "In the binder's words")
                                ForEach(Array(v.critique.enumerated()), id: \.offset) { _, line in
                                    Text(line).font(Quire.body(13.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        SealButton(title: "Shelve it", tone: Quire.walnut) { onShelve() }
                    }
                    .padding(.horizontal, Quire.gutter)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}
