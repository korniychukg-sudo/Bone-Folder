import SwiftUI

struct DetailScaffold<Content: View>: View {
    var title: String
    var subtitle: String
    var plate: String
    @ViewBuilder var content: () -> Content
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ScrollView {
            Column {
                SheetCard(padding: 8) {
                    PlateBox(name: plate, height: Quire.isPad ? 400 : 250, corner: 4, fit: true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(Quire.title(22)).foregroundColor(Quire.ink).fixedSize(horizontal: false, vertical: true)
                    Text(subtitle).font(Quire.note(13)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                content()
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
                BackChevron(label: "Register") { presentation.wrappedValue.dismiss() }
            }
        }
    }
}

struct TextBlock: View {
    var head: String
    var text: String
    var body: some View {
        SheetCard {
            VStack(alignment: .leading, spacing: 8) {
                HeadRule(text: head)
                Text(text).font(Quire.body(13.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct BindingDetail: View {
    @EnvironmentObject var bindery: Bindery
    var binding: HistoricBinding

    var body: some View {
        DetailScaffold(title: binding.name, subtitle: "\(binding.date). \(binding.region).", plate: binding.plate) {
            TextBlock(head: "The structure", text: binding.summary)
            TextBlock(head: "History", text: binding.history)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "How it fails")
                    Text(binding.fails).font(Quire.body(13.5)).foregroundColor(Quire.thread).fixedSize(horizontal: false, vertical: true)
                }
            }
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "Facts")
                    ForEach(binding.facts, id: \.self) { f in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(Quire.brass).frame(width: 6, height: 6).padding(.top, 6)
                            Text(f).font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            if let s = binding.structure {
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "On the bench as", trailing: s.name)
                        StitchDiagramView(structure: s, signatures: s.family == .stab || s.family == .pamphlet || s == .accordion ? 1 : 3, stations: s.defaultStations)
                            .frame(height: 150)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Quire.paste.opacity(0.35)))
                        Text("Every structure in the register that can be sewn is on the bench, from the first day.").font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                    }
                }
            }
        }
        .onAppear { bindery.markBinding(binding.key) }
    }
}

struct MaterialDetail: View {
    @EnvironmentObject var bindery: Bindery
    var material: Material

    var body: some View {
        DetailScaffold(title: material.name, subtitle: "\(material.kind.name.dropLast(material.kind == .paper || material.kind == .board ? 1 : 0)). \(material.spec).", plate: material.plate) {
            TextBlock(head: "Use", text: material.use)
            TextBlock(head: "What it is", text: material.note)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "How it goes wrong")
                    Text(material.wrong).font(Quire.body(13.5)).foregroundColor(Quire.thread).fixedSize(horizontal: false, vertical: true)
                }
            }
            if material.kind == .paper {
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "On the bench")
                        HStack(spacing: 9) {
                            CountTile(value: "\(Int(material.gsm))", label: "gsm")
                            CountTile(value: material.grain == .long ? "long" : "short", label: "grain")
                            CountTile(value: String(format: "%.2f", SpineMath.caliperMM(gsm: material.gsm, texture: material.texture)), label: "mm a leaf")
                        }
                        Text(material.benchOK ? "Usable for a text block. A 128-page octavo block of it makes a spine of about \(String(format: "%.1f", SpineMath.widthMM(pages: 128, gsm: material.gsm, texture: material.texture, signatures: 8, thread: .linen25))) mm." : "Not for a text block; it is in the drawer for covers, linings, or as the wrong answer.")
                            .font(Quire.note(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            if let t = material.thread {
                SheetCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HeadRule(text: "Tension window")
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Quire.ink.opacity(0.08))
                                Capsule().fill(Quire.good.opacity(0.6))
                                    .frame(width: geo.size.width * CGFloat(t.tensionWindow.upperBound - t.tensionWindow.lowerBound))
                                    .offset(x: geo.size.width * CGFloat(t.tensionWindow.lowerBound))
                            }
                        }
                        .frame(height: 10)
                        Text("Pull from \(Int(t.tensionWindow.lowerBound * 100)) to \(Int(t.tensionWindow.upperBound * 100)) on the scale; \(String(format: "%.2f", t.diameterMM)) mm thick, it swells the spine by \(String(format: "%.2f", t.swellMM)) mm a signature.")
                            .font(Quire.note(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .onAppear { bindery.markMaterial(material.key) }
    }
}

struct ToolDetail: View {
    @EnvironmentObject var bindery: Bindery
    var tool: Tool

    var body: some View {
        DetailScaffold(title: tool.name, subtitle: tool.use, plate: tool.plate) {
            TextBlock(head: "What it is", text: tool.note)
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "How it goes wrong")
                    Text(tool.wrong).font(Quire.body(13.5)).foregroundColor(Quire.thread).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .onAppear { bindery.markTool(tool.key) }
    }
}

struct StructureDetail: View {
    @EnvironmentObject var bindery: Bindery
    var structure: Structure
    @State private var signatures = 3
    @State private var stations = 4

    var body: some View {
        let s = structure
        let rows = s.family == .stab || s.family == .pamphlet || s == .accordion ? 1 : signatures
        let path = StitchGrammar.path(s, signatures: rows, stations: stations)
        return DetailScaffold(title: s.name, subtitle: structureLine(s), plate: "st_" + s.rawValue) {
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "The grammar, drawn live", trailing: "\(path.count) passes")
                    StitchDiagramView(structure: s, signatures: rows, stations: stations)
                        .frame(height: s.family == .stab ? 260 : 190)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Quire.paste.opacity(0.35)))
                    if s.family != .stab && s.family != .pamphlet && s != .accordion {
                        HStack {
                            Text("Signatures").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                            ChoiceRow(items: [3, 4, 5, 6], label: { "\($0)" }, selection: $signatures)
                        }
                    }
                    if s.stationOptions.count > 1 {
                        HStack {
                            Text(s == .accordion ? "Panels" : "Stations").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                            ChoiceRow(items: s.stationOptions, label: { "\($0)" }, selection: $stations)
                        }
                    }
                }
            }
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "Pass by pass")
                    ForEach(Array(path.prefix(40).enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(i + 1)").font(Quire.title(11)).foregroundColor(Quire.inkFaint).frame(width: 22, alignment: .trailing)
                            Text(StitchGrammar.instruction(s, step: step, previous: i > 0 ? path[i - 1] : nil, stations: stations, rows: rows))
                                .font(Quire.body(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    if path.count > 40 { Text("and \(path.count - 40) more passes.").font(Quire.note(12)).foregroundColor(Quire.inkFaint) }
                }
            }
            if let b = Register.bindings.first(where: { $0.structure == s }) {
                TextBlock(head: "In history", text: "\(b.name), \(b.date.lowercased()): \(b.history)")
            }
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "Stages on the bench")
                    Text(s.stages.map { $0.name }.joined(separator: ", ") + ". Covered with \(s.coverWord); \(Clock.durationWords(Press.hours(for: s) * 3600)) in the press.")
                        .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .onAppear {
            stations = s.defaultStations
            bindery.markStructure(s.rawValue)
        }
    }

    private func structureLine(_ s: Structure) -> String {
        switch s.family {
        case .pamphlet: return "One signature sewn through the fold with one thread."
        case .chain: return "A chain stitch linking each signature to the one below, no supports."
        case .supported: return "A running stitch over tapes with a kettle at each end."
        case .longStitch: return "Sewn straight through a limp cover."
        case .stab: return "Stab-sewn through the side of a stack of leaves."
        case .belgian: return "The cover sewn first, then the block sewn to it from inside."
        case .fold: return "No thread: a folded strip with boards."
        }
    }
}

struct TitleDetail: View {
    @EnvironmentObject var bindery: Bindery
    var title: BookTitle

    var body: some View {
        let books = bindery.ledger.books.filter { $0.titleKey == title.key }
        return DetailScaffold(title: title.title, subtitle: "For \(title.client): \(title.wants).", plate: title.plate) {
            TextBlock(head: "The label", text: "\(title.label.name). \(labelNote(title.label))")
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "On your shelf", trailing: "\(books.count)")
                    if books.isEmpty {
                        Text("Not bound yet. Choose this title on the bench and it will be stamped on the spine.").font(Quire.body(13)).foregroundColor(Quire.inkSoft)
                    } else {
                        ForEach(books) { b in
                            HStack(spacing: 10) {
                                SpineThumb(book: b, height: 60)
                                Text("\(b.kind.name), \(b.score), \(b.word.lowercased())").font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                            }
                        }
                    }
                }
            }
        }
    }

    private func labelNote(_ l: LabelStyle) -> String {
        switch l {
        case .paperLabel: return "A printed paper label pasted to the spine or the front board, ruled with a double border."
        case .giltCloth: return "Gold leaf stamped into the cloth with a heated brass tool through gold foil."
        case .blindStamp: return "The tool impressed without gold, the letters sunk into the leather and left dark."
        case .handLettered: return "Written by hand in ink on a paper label, with a flourish under the title."
        }
    }
}
