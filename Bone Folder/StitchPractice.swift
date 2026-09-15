import SwiftUI

struct StitchPractice: View {
    @EnvironmentObject var bindery: Bindery
    @StateObject private var session = BenchSession()
    @State private var structure: Structure = .pamphlet3
    @State private var signatures = 3
    @State private var thread: ThreadKind = .linen25
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ScrollView {
            Column {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice: the stitch").font(Quire.title(22)).foregroundColor(Quire.ink)
                    Text("Any structure, a block already folded and punched, and no score against you. Drag the needle station to station and pull each row into the window.")
                        .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                ChoiceRow(items: Structure.allCases.filter { $0 != .accordion }, label: { $0.shortName }, selection: $structure)
                    .onChange(of: structure) { _ in restart() }
                HStack {
                    if structure.family != .stab && structure.family != .pamphlet {
                        Text("Signatures").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                        ChoiceRow(items: [3, 4, 5, 6], label: { "\($0)" }, selection: $signatures)
                            .onChange(of: signatures) { _ in restart() }
                    }
                }
                Text("Thread").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft).frame(maxWidth: .infinity, alignment: .leading)
                ChoiceRow(items: ThreadKind.allCases, label: { $0.name }, selection: $thread)
                    .onChange(of: thread) { _ in restart() }
                if session.active {
                    SewStage(session: session)
                        .frame(minHeight: Quire.isPad ? 640 : 520)
                }
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "Tally", trailing: session.sewingDone ? "sewn" : "sewing")
                        HStack(spacing: 9) {
                            CountTile(value: "\(session.s?.stitchIndex ?? 0)/\(session.path.count)", label: "passes")
                            CountTile(value: "\(session.s?.stitchFaults ?? 0)", label: "skipped", tone: (session.s?.stitchFaults ?? 0) > 0 ? Quire.thread : Quire.ink)
                            CountTile(value: "\(session.tensionResults.filter { $0 == .good }.count)/\(session.tensionResults.count)", label: "pulls in window")
                        }
                        SealButton(title: "Start again", tone: Quire.walnut, filled: false) { restart() }
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
        .onAppear { if !session.active { restart() } }
    }

    private func restart() {
        let sigs = structure.family == .stab ? 24 : (structure.family == .pamphlet ? 1 : signatures)
        session.start(structure: structure, title: Register.titles[0], label: .paperLabel, signatures: sigs, stations: structure.defaultStations,
                      imposition: structure.defaultImposition, sheet: .a3, paper: Materials.find("bookWove"), thread: thread,
                      cover: Materials.find("starchCotton"), board: Materials.find("grey2"), commission: nil)
        let sewIndex = structure.stages.firstIndex(of: .sew) ?? 0
        for _ in 0..<sewIndex { session.advance() }
    }
}
