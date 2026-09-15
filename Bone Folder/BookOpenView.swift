import SwiftUI

struct BookOpenView: View {
    @EnvironmentObject var bindery: Bindery
    var book: BoundBook
    var onClose: () -> Void
    @State private var page = 0
    @State private var flip: Double = 0

    private let pageCount = 6

    var body: some View {
        ZStack {
            Quire.walnutDark.ignoresSafeArea()
            PlateFill(name: "dc_benchTop").ignoresSafeArea().opacity(0.8)
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(book.title.title).font(Quire.title(18)).foregroundColor(Quire.card)
                        Text("\(book.kind.name), \(book.score), \(book.word.lowercased())").font(Quire.note(12)).foregroundColor(Quire.linenPale)
                    }
                    Spacer()
                    Button(action: { Knock.light(); onClose() }) {
                        CrossGlyph(size: 16, color: Quire.card).padding(9).background(Circle().fill(Color.white.opacity(0.15)))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, Quire.gutter)
                .padding(.top, 14)
                Spacer(minLength: 8)
                GeometryReader { geo in
                    let w = min(geo.size.width - 24, Quire.isPad ? 620 : 420)
                    let h = min(geo.size.height - 10, w * 1.25)
                    ZStack {
                        pageFace(page, size: CGSize(width: w, height: h))
                            .frame(width: w, height: h)
                            .rotation3DEffect(.degrees(flip), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.6)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .gesture(DragGesture(minimumDistance: 20).onEnded { v in
                        if v.translation.width < -40 { turn(1) } else if v.translation.width > 40 { turn(-1) }
                    })
                }
                HStack(spacing: 14) {
                    Button(action: { turn(-1) }) { ChevGlyph(size: 20, color: page > 0 ? Quire.card : Quire.card.opacity(0.3)) }.buttonStyle(.plain).disabled(page == 0)
                    Text(pageName(page)).font(Quire.note(12.5)).foregroundColor(Quire.linenPale).frame(minWidth: 160)
                    Button(action: { turn(1) }) { ChevGlyph(size: 20, color: page < pageCount - 1 ? Quire.card : Quire.card.opacity(0.3), right: true) }.buttonStyle(.plain).disabled(page == pageCount - 1)
                }
                .padding(.vertical, 12)
                SealButton(title: "Close the book", tone: Quire.card, filled: false) { onClose() }
                    .padding(.horizontal, Quire.gutter)
                    .padding(.bottom, 16)
            }
        }
    }

    private func turn(_ dir: Int) {
        let next = page + dir
        guard next >= 0, next < pageCount else { return }
        Knock.light()
        withAnimation(.easeIn(duration: 0.16)) { flip = dir > 0 ? -70 : 20 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            page = next
            flip = dir > 0 ? 40 : -50
            withAnimation(.easeOut(duration: 0.22)) { flip = 0 }
        }
    }

    private func pageName(_ p: Int) -> String {
        switch p {
        case 0: return "the front board"
        case 1: return "endpaper and pastedown"
        case 2: return "the sewing, seen from inside"
        case 3: return "headbands and the title page"
        case 4: return "a page"
        default: return "the pencilled record"
        }
    }

    @ViewBuilder
    private func pageFace(_ p: Int, size: CGSize) -> some View {
        switch p {
        case 0: coverFace(size)
        case 1: endpaperFace(size)
        case 2: sewingFace(size)
        case 3: titleFace(size)
        case 4: textFace(size)
        default: recordFace(size)
        }
    }

    private func coverFace(_ size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.tint(book.cover.tone))
            if book.kind.exposedSpine {
                HStack(spacing: 0) {
                    VStack(spacing: 4) {
                        ForEach(0..<max(1, min(12, book.signatures)), id: \.self) { _ in
                            Rectangle().fill(Quire.paste).frame(height: 6)
                        }
                    }
                    .frame(width: 22)
                    Spacer()
                }
            }
            VStack {
                Spacer()
                PlateBox(name: book.title.plate, height: size.height * 0.24, corner: 3)
                    .frame(width: size.width * 0.7)
                Spacer().frame(height: size.height * 0.16)
            }
            RoundedRectangle(cornerRadius: 4).stroke(Quire.ink.opacity(0.6), lineWidth: 1)
            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.14), Color.clear, Color.black.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing).cornerRadius(4)
        }
        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 6, y: 8)
    }

    private func endpaperFace(_ size: CGSize) -> some View {
        ZStack {
            PlateFill(name: book.coverKey == "pastePaper" ? "dc_endPaste" : "dc_endMarbled").cornerRadius(4)
            HStack(spacing: 0) {
                Rectangle().fill(Color.black.opacity(0.25)).frame(width: 12)
                Spacer()
            }
            VStack {
                Spacer()
                Text("the pastedown, \(Materials.find(book.coverKey == "pastePaper" ? "pastePaper" : "marbled").name.lowercased()), grain with the spine")
                    .font(Quire.note(12)).foregroundColor(Quire.ink.opacity(0.85))
                    .padding(6).background(Quire.card.opacity(0.8)).cornerRadius(3)
                    .padding(.bottom, 12)
            }
            RoundedRectangle(cornerRadius: 4).stroke(Quire.ink.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 8, x: 4, y: 6)
    }

    private func sewingFace(_ size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Quire.paste)
            VStack(spacing: 8) {
                Text("the inside of the spine").font(Quire.note(12)).foregroundColor(Quire.inkFaint).padding(.top, 10)
                if book.kind == .accordion {
                    StitchDiagramView(structure: .accordion, signatures: 1, stations: book.stations)
                } else {
                    StitchDiagramView(structure: book.kind, signatures: book.kind.family == .stab ? 1 : min(book.signatures, 12), stations: book.stations, thread: book.threadKind, coverTone: Color.tint(book.cover.tone))
                }
                HStack(spacing: 4) {
                    ForEach(Array(book.tensions.enumerated()), id: \.offset) { _, t in
                        Circle().fill(t == "good" ? Quire.good : (t == "loose" ? Quire.brass : Quire.thread)).frame(width: 8, height: 8)
                    }
                    Text(book.tensions.isEmpty ? "no thread" : "the pulls").font(Quire.note(11)).foregroundColor(Quire.inkFaint)
                }
                .padding(.bottom, 10)
            }
            RoundedRectangle(cornerRadius: 4).stroke(Quire.ink.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 8, x: 4, y: 6)
    }

    private func titleFace(_ size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.tint(book.paper.tone))
            VStack(spacing: 10) {
                if book.kind.family == .supported {
                    HStack(spacing: 2) {
                        ForEach(0..<14, id: \.self) { k in
                            Capsule().fill(k % 2 == 0 ? silkTones[book.headbandA ?? 0] : silkTones[book.headbandB ?? 1]).frame(width: 9, height: 12)
                        }
                    }
                    .padding(.top, 6)
                    Text("headbands in \(silkNames[book.headbandA ?? 0]) and \(silkNames[book.headbandB ?? 1]) silk").font(Quire.note(11)).foregroundColor(Quire.inkFaint)
                }
                Spacer()
                Text(book.title.title.uppercased()).font(Quire.title(22)).tracking(2).foregroundColor(Quire.ink).multilineTextAlignment(.center)
                Rectangle().fill(Quire.ink.opacity(0.5)).frame(width: 80, height: 1)
                Text("bound by hand in \(book.kind.name.lowercased())").font(Quire.note(13)).foregroundColor(Quire.inkSoft)
                Text("for \(book.title.client)").font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                Spacer()
                Text("Bone Folder Bindery").font(Quire.title(11)).tracking(1.5).foregroundColor(Quire.inkFaint).padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            RoundedRectangle(cornerRadius: 4).stroke(Quire.ink.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 8, x: 4, y: 6)
    }

    private func textFace(_ size: CGSize) -> some View {
        let lesson = Lessons.all[Int(seedOf(book.id) % UInt64(Lessons.all.count))]
        return ZStack {
            RoundedRectangle(cornerRadius: 4).fill(Color.tint(book.paper.tone))
            VStack(alignment: .leading, spacing: 8) {
                Text(lesson.title).font(Quire.title(15)).foregroundColor(Quire.ink)
                ForEach(lesson.paragraphs.prefix(2), id: \.self) { para in
                    Text(para).font(Quire.body(11.5)).foregroundColor(Quire.inkSoft).lineLimit(8)
                }
                Spacer()
                HStack { Spacer(); Text("\(book.pages / 2 + 1)").font(Quire.body(11)).foregroundColor(Quire.inkFaint) }
            }
            .padding(20)
            RoundedRectangle(cornerRadius: 4).stroke(Quire.ink.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 8, x: 4, y: 6)
    }

    private func recordFace(_ size: CGSize) -> some View {
        ZStack {
            PlateFill(name: book.coverKey == "pastePaper" ? "dc_endPaste" : "dc_endMarbled").cornerRadius(4).opacity(0.35)
            RoundedRectangle(cornerRadius: 4).fill(Color.tint(book.paper.tone).opacity(0.7))
            VStack(alignment: .leading, spacing: 6) {
                Text("pencilled on the back pastedown").font(Quire.note(11)).foregroundColor(Quire.inkFaint)
                ForEach(Array(book.pencilNotes.enumerated()), id: \.offset) { _, line in
                    Text(line).font(Quire.note(13)).foregroundColor(Quire.inkSoft).rotationEffect(.degrees(-1.2)).fixedSize(horizontal: false, vertical: true)
                }
                Divider()
                ForEach(Array(book.critique.prefix(4).enumerated()), id: \.offset) { _, line in
                    Text(line).font(Quire.note(11.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                if let parts = book.parts {
                    Divider()
                    ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                        HStack {
                            Text(part.name).font(Quire.body(11)).foregroundColor(Quire.inkSoft)
                            Spacer()
                            Text("\(Int(part.value * 100))").font(Quire.title(11)).foregroundColor(Quire.ink)
                        }
                    }
                }
                Spacer()
                HStack {
                    if bindery.isBest(book) { StampTag(text: "best of its kind", tone: Quire.brass) }
                    Spacer()
                    Text("day \(book.day), \(book.hour):00").font(Quire.note(11)).foregroundColor(Quire.inkFaint)
                }
            }
            .padding(18)
            RoundedRectangle(cornerRadius: 4).stroke(Quire.ink.opacity(0.5), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.45), radius: 8, x: 4, y: 6)
    }
}
