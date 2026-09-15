import SwiftUI

extension Structure: Identifiable {
    public var id: String { rawValue }
}

struct RegisterView: View {
    @EnvironmentObject var bindery: Bindery
    @State private var section = 0
    @State private var drawer = 0
    @State private var openBinding: HistoricBinding? = nil
    @State private var openMaterial: Material? = nil
    @State private var openTool: Tool? = nil
    @State private var openStructure: Structure? = nil
    @State private var openTitle: BookTitle? = nil

    var body: some View {
        ScrollView {
            Column {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The register").font(Quire.title(24)).foregroundColor(Quire.ink)
                    Text("Thirty bindings from the Coptic codex to the glued paperback, sixty materials in four drawers, eighteen tools, thirteen structures drawn from their own stitch grammar, and forty titles.")
                        .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                BandPicker(titles: ["Bindings", "Materials", "Tools", "Structures", "Titles"], index: $section)
                Group {
                    switch section {
                    case 0: bindings
                    case 1: materials
                    case 2: tools
                    case 3: structures
                    default: titles
                    }
                }
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Quire.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(item: $openBinding) { b in
            NavigationView { BindingDetail(binding: b).environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(item: $openMaterial) { m in
            NavigationView { MaterialDetail(material: m).environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(item: $openTool) { t in
            NavigationView { ToolDetail(tool: t).environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(item: $openStructure) { st in
            NavigationView { StructureDetail(structure: st).environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(item: $openTitle) { t in
            NavigationView { TitleDetail(title: t).environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private var bindings: some View {
        let read = Set(bindery.ledger.readBindings ?? [])
        return VStack(spacing: 10) {
            HeadRule(text: "Historical bindings", trailing: "\(read.count) of \(Register.bindings.count) read")
            ForEach(Register.bindings) { b in
                Button(action: { Knock.light(); openBinding = b }) {
                    HStack(spacing: 12) {
                        PlateBox(name: b.plate, height: 74, corner: 4).frame(width: 110)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(b.name).font(Quire.title(14)).foregroundColor(Quire.ink)
                            Text("\(b.date), \(b.region)").font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                            Text(b.summary).font(Quire.body(12)).foregroundColor(Quire.inkSoft).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        if read.contains(b.key) { CheckGlyph(size: 14, color: Quire.good) }
                        ChevGlyph(size: 13, color: Quire.inkFaint, right: true)
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(0.12), lineWidth: 0.8)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var materials: some View {
        let kinds: [MaterialKind] = [.paper, .cloth, .leather, .thread, .board]
        let read = Set(bindery.ledger.readMaterials ?? [])
        return VStack(spacing: 10) {
            BandPicker(titles: ["Paper", "Cloth", "Leather", "Thread", "Board"], index: $drawer)
            let kind = kinds[min(drawer, kinds.count - 1)]
            HeadRule(text: kind.name, trailing: "\(Materials.of(kind).filter { read.contains($0.key) }.count) of \(Materials.of(kind).count) read")
            let columns = Quire.isPad ? 3 : 2
            let items = Materials.of(kind)
            ForEach(0..<((items.count + columns - 1) / columns), id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<columns, id: \.self) { col in
                        let i = row * columns + col
                        if i < items.count {
                            let m = items[i]
                            Button(action: { Knock.light(); openMaterial = m }) {
                                VStack(alignment: .leading, spacing: 5) {
                                    PlateBox(name: m.plate, height: 84, corner: 4)
                                    Text(m.name).font(Quire.title(12.5)).foregroundColor(Quire.ink).lineLimit(1)
                                    Text(m.spec).font(Quire.note(11)).foregroundColor(Quire.inkFaint).lineLimit(1)
                                }
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(read.contains(m.key) ? 0.3 : 0.12), lineWidth: 0.8)))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private var tools: some View {
        let read = Set(bindery.ledger.readTools ?? [])
        return VStack(spacing: 10) {
            HeadRule(text: "Tools of the bench", trailing: "\(read.count) of \(Register.tools.count) read")
            ForEach(Register.tools) { t in
                Button(action: { Knock.light(); openTool = t }) {
                    HStack(spacing: 12) {
                        PlateBox(name: t.plate, height: 70, corner: 4).frame(width: 104)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(t.name).font(Quire.title(14)).foregroundColor(Quire.ink)
                            Text(t.use).font(Quire.body(12)).foregroundColor(Quire.inkSoft).lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        if read.contains(t.key) { CheckGlyph(size: 14, color: Quire.good) }
                        ChevGlyph(size: 13, color: Quire.inkFaint, right: true)
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(0.12), lineWidth: 0.8)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var structures: some View {
        let read = Set(bindery.ledger.readStructures ?? [])
        return VStack(spacing: 10) {
            HeadRule(text: "Sewing and folding structures", trailing: "\(read.count) of \(Structure.allCases.count) read")
            ForEach(Structure.allCases, id: \.self) { s in
                Button(action: { Knock.light(); openStructure = s }) {
                    HStack(spacing: 12) {
                        PlateBox(name: "st_" + s.rawValue, height: 74, corner: 4).frame(width: 110)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.name).font(Quire.title(14)).foregroundColor(Quire.ink)
                            Text("\(s.family == .stab ? "one stack" : "\(s.signatureRange.lowerBound) to \(s.signatureRange.upperBound) signatures"), \(s.stationOptions.map { "\($0)" }.joined(separator: " or ")) \(s == .accordion ? "panels" : "stations"), \(s.needles == 2 ? "two needles" : "one needle")")
                                .font(Quire.note(12)).foregroundColor(Quire.inkFaint).lineLimit(2)
                            if let best = bindery.best(s) {
                                Text("Best on the shelf: \(best.score), \(best.word.lowercased())").font(Quire.body(12)).foregroundColor(Quire.inkSoft)
                            } else {
                                Text("Not yet bound.").font(Quire.body(12)).foregroundColor(Quire.inkSoft)
                            }
                        }
                        Spacer(minLength: 0)
                        ChevGlyph(size: 13, color: Quire.inkFaint, right: true)
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(0.12), lineWidth: 0.8)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var titles: some View {
        let columns = Quire.isPad ? 3 : 2
        let items = Register.titles
        return VStack(spacing: 10) {
            HeadRule(text: "Forty titles", trailing: "labels stamped by hand")
            ForEach(0..<((items.count + columns - 1) / columns), id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(0..<columns, id: \.self) { col in
                        let i = row * columns + col
                        if i < items.count {
                            let t = items[i]
                            Button(action: { Knock.light(); openTitle = t }) {
                                VStack(alignment: .leading, spacing: 5) {
                                    PlateBox(name: t.plate, height: 72, corner: 4)
                                    Text(t.title).font(Quire.title(12.5)).foregroundColor(Quire.ink).lineLimit(1)
                                    Text("for \(t.client)").font(Quire.note(11)).foregroundColor(Quire.inkFaint).lineLimit(1)
                                }
                                .padding(8)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(0.12), lineWidth: 0.8)))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
}
