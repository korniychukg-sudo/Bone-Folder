import SwiftUI

struct BookTabView: View {
    @EnvironmentObject var bindery: Bindery
    @State private var section = 0
    @State private var openLesson: Lesson? = nil
    @State private var openFold = false
    @State private var openStitch = false

    var body: some View {
        ScrollView {
            Column {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The book").font(Quire.title(24)).foregroundColor(Quire.ink)
                    Text("Twelve lessons from the grain to the publisher's case, a glossary of the bench, an examination and the badges you have earned.")
                        .font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                BandPicker(titles: ["Lessons", "Glossary", "Examination", "Badges"], index: $section)
                Group {
                    switch section {
                    case 0: lessons
                    case 1: glossary
                    case 2: ExamCard().environmentObject(bindery)
                    default: badges
                    }
                }
            }
            .padding(.horizontal, Quire.gutter)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(Quire.page.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(item: $openLesson) { lesson in
            NavigationView { LessonView(lesson: lesson).environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(isPresented: $openFold) {
            NavigationView { FoldPractice().environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
        .fullScreenCover(isPresented: $openStitch) {
            NavigationView { StitchPractice().environmentObject(bindery) }.navigationViewStyle(StackNavigationViewStyle())
        }
    }

    private var lessons: some View {
        let read = Set(bindery.ledger.readLessons ?? [])
        return VStack(spacing: 10) {
            Button(action: { Knock.light(); openFold = true }) {
                HStack(spacing: 12) {
                    PlateBox(name: "ls_1", height: 74, corner: 4).frame(width: 110)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Practice: the folding puzzle").font(Quire.title(14)).foregroundColor(Quire.ink)
                        Text("Fold a printed sheet in any of the four impositions until the pages come out in order. No bench, no score against you.")
                            .font(Quire.body(12)).foregroundColor(Quire.inkSoft).lineLimit(3)
                    }
                    Spacer(minLength: 0)
                    ChevGlyph(size: 13, color: Quire.inkFaint, right: true)
                }
                .padding(9)
                .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.walnut.opacity(0.35), lineWidth: 0.9)))
            }
            .buttonStyle(.plain)
            Button(action: { Knock.light(); openStitch = true }) {
                HStack(spacing: 12) {
                    PlateBox(name: "ls_5", height: 74, corner: 4).frame(width: 110)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Practice: the stitch").font(Quire.title(14)).foregroundColor(Quire.ink)
                        Text("Sew any of the twelve stitches on a block already folded and punched: the needle, the links and the tension pulls, with nothing at stake.")
                            .font(Quire.body(12)).foregroundColor(Quire.inkSoft).lineLimit(3)
                    }
                    Spacer(minLength: 0)
                    ChevGlyph(size: 13, color: Quire.inkFaint, right: true)
                }
                .padding(9)
                .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.walnut.opacity(0.35), lineWidth: 0.9)))
            }
            .buttonStyle(.plain)
            HeadRule(text: "Lessons", trailing: "\(read.count) of \(Lessons.all.count) read")
            ForEach(Lessons.all) { lesson in
                Button(action: { Knock.light(); openLesson = lesson }) {
                    HStack(spacing: 12) {
                        PlateBox(name: lesson.plate, height: 74, corner: 4).frame(width: 110)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(lesson.index + 1). \(lesson.title)").font(Quire.title(14)).foregroundColor(Quire.ink)
                            Text(lesson.summary).font(Quire.body(12)).foregroundColor(Quire.inkSoft).lineLimit(2)
                            Text("\(lesson.words) words").font(Quire.note(11)).foregroundColor(Quire.inkFaint)
                        }
                        Spacer(minLength: 0)
                        if read.contains(lesson.index) { CheckGlyph(size: 14, color: Quire.good) }
                        ChevGlyph(size: 13, color: Quire.inkFaint, right: true)
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(0.12), lineWidth: 0.8)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var glossary: some View {
        let read = Set(bindery.ledger.readTerms ?? [])
        return VStack(spacing: 8) {
            HeadRule(text: "Glossary", trailing: "\(read.count) of \(Glossary.all.count) read")
            ForEach(Glossary.all) { term in
                GlossaryRow(term: term, read: read.contains(term.term)) { bindery.markTerm(term.term) }
            }
        }
    }

    private var badges: some View {
        VStack(spacing: 10) {
            HeadRule(text: "Badges", trailing: "\((bindery.ledger.badges ?? []).count) of \(Daily.badges.count)")
            ForEach(Daily.badges, id: \.0) { badge in
                let has = bindery.hasBadge(badge.0)
                HStack(spacing: 12) {
                    RibbonGlyph(size: 30, color: has ? Quire.brass : Quire.inkFaint.opacity(0.4))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(badge.1).font(Quire.title(14)).foregroundColor(has ? Quire.ink : Quire.inkFaint)
                        Text(badge.2).font(Quire.body(12)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                    if has { StampTag(text: "earned", tone: Quire.brass) }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 7).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 7).stroke(Quire.ink.opacity(has ? 0.25 : 0.10), lineWidth: 0.8)))
            }
            SheetCard {
                VStack(alignment: .leading, spacing: 8) {
                    HeadRule(text: "Ranks")
                    ForEach(Array(Daily.ladder.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(step.0)").font(Quire.title(12)).foregroundColor(i <= bindery.rankIndex ? Quire.brass : Quire.inkFaint).frame(width: 44, alignment: .trailing)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.1).font(Quire.title(13)).foregroundColor(i <= bindery.rankIndex ? Quire.ink : Quire.inkFaint)
                                Text(step.2).font(Quire.note(11.5)).foregroundColor(Quire.inkFaint).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct GlossaryRow: View {
    var term: GlossaryTerm
    var read: Bool
    var onOpen: () -> Void
    @State private var open = false

    var body: some View {
        Button(action: { Knock.light(); withAnimation(.easeOut(duration: 0.2)) { open.toggle() }; if open { onOpen() } }) {
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(term.term).font(Quire.title(14)).foregroundColor(Quire.ink)
                    Spacer()
                    if read { CheckGlyph(size: 13, color: Quire.good) }
                    ChevGlyph(size: 12, color: Quire.inkFaint, right: !open)
                        .rotationEffect(.degrees(open ? 90 : 0))
                }
                if open {
                    Text(term.meaning).font(Quire.body(13)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 6).fill(Quire.card).overlay(RoundedRectangle(cornerRadius: 6).stroke(Quire.ink.opacity(0.10), lineWidth: 0.8)))
        }
        .buttonStyle(.plain)
    }
}
