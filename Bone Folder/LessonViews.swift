import SwiftUI

struct LessonView: View {
    @EnvironmentObject var bindery: Bindery
    var lesson: Lesson
    @Environment(\.presentationMode) private var presentation

    var body: some View {
        ScrollView {
            Column {
                SheetCard(padding: 8) {
                    PlateBox(name: lesson.plate, height: Quire.isPad ? 400 : 250, corner: 4, fit: true)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lesson \(lesson.index + 1)").font(Quire.title(11)).tracking(1.5).foregroundColor(Quire.inkFaint)
                    Text(lesson.title).font(Quire.title(24)).foregroundColor(Quire.ink).fixedSize(horizontal: false, vertical: true)
                    Text(lesson.summary).font(Quire.note(13.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                SheetCard {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(lesson.paragraphs.enumerated()), id: \.offset) { i, para in
                            Text(para).font(Quire.body(Quire.isPad ? 16 : 14.5)).foregroundColor(Quire.inkSoft)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                if lesson.index + 1 < Lessons.all.count {
                    NavigationLink(destination: LessonView(lesson: Lessons.all[lesson.index + 1]).environmentObject(bindery)) {
                        HStack {
                            Text("Next: \(Lessons.all[lesson.index + 1].title)").font(Quire.title(13.5)).foregroundColor(Quire.walnut)
                            Spacer()
                            ChevGlyph(size: 14, color: Quire.walnut, right: true)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 6).stroke(Quire.walnut.opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
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
        .onAppear { bindery.markLesson(lesson.index) }
    }
}

struct ExamCard: View {
    @EnvironmentObject var bindery: Bindery
    @State private var paper: [ExamQuestion] = []
    @State private var index = 0
    @State private var chosen: Int? = nil
    @State private var score = 0
    @State private var finished = false

    var body: some View {
        VStack(spacing: 10) {
            HeadRule(text: "Examination", trailing: bindery.ledger.examBest.map { "best \($0) percent" } ?? "not yet sat")
            if paper.isEmpty {
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Twelve questions from a bank of thirty two, plus two folding puzzles computed from the imposition engine, a spine to name from its plate, and a fault to diagnose. Seventy percent passes; eighty earns the badge.")
                            .font(Quire.body(13.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 9) {
                            CountTile(value: "\(bindery.ledger.examsTaken ?? 0)", label: "sat")
                            CountTile(value: "\(bindery.ledger.examBest ?? 0)", label: "best percent")
                        }
                        SealButton(title: "Sit the examination", tone: Quire.walnut) { start() }
                    }
                }
            } else if finished {
                let pct = Int((Double(score) / Double(paper.count) * 100).rounded())
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(score) of \(paper.count), \(pct) percent").font(Quire.title(22)).foregroundColor(Quire.ink)
                        Text(pct >= 80 ? "Examined and passed with the badge. The bench is yours." : (pct >= 70 ? "Passed. Eighty percent earns the badge." : "Not yet. Read the lessons again and come back."))
                            .font(Quire.body(13.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                        SealButton(title: "Sit it again", tone: Quire.walnut, filled: false) { start() }
                        SealButton(title: "Close", tone: Quire.inkSoft, filled: false) { paper = []; finished = false }
                    }
                }
            } else {
                let q = paper[index]
                SheetCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Question \(index + 1) of \(paper.count)").font(Quire.title(11)).tracking(1.2).foregroundColor(Quire.inkFaint)
                            Spacer()
                            Text("\(score) right").font(Quire.note(12)).foregroundColor(Quire.inkFaint)
                        }
                        if let plate = q.plate {
                            PlateBox(name: plate, height: Quire.isPad ? 260 : 180, corner: 4, fit: true)
                        }
                        Text(q.prompt).font(Quire.title(15)).foregroundColor(Quire.ink).fixedSize(horizontal: false, vertical: true)
                        ForEach(0..<q.choices.count, id: \.self) { i in
                            let state: Int = chosen == nil ? 0 : (i == q.answer ? 1 : (i == chosen ? 2 : 3))
                            Button(action: { guard chosen == nil else { return }; answer(i) }) {
                                HStack {
                                    Text(q.choices[i]).font(Quire.body(13.5)).foregroundColor(state == 3 ? Quire.inkFaint : Quire.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                    if state == 1 { CheckGlyph(size: 14, color: Quire.good) }
                                    if state == 2 { CrossGlyph(size: 12, color: Quire.thread) }
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity)
                                .background(RoundedRectangle(cornerRadius: 6).fill(state == 1 ? Quire.good.opacity(0.14) : (state == 2 ? Quire.thread.opacity(0.12) : Quire.ink.opacity(0.04))))
                            }
                            .buttonStyle(.plain)
                        }
                        if chosen != nil {
                            Text(q.explain).font(Quire.note(12.5)).foregroundColor(Quire.inkSoft).fixedSize(horizontal: false, vertical: true)
                            SealButton(title: index + 1 < paper.count ? "Next question" : "Finish", tone: Quire.walnut) { next() }
                        }
                    }
                }
            }
        }
    }

    private func start() {
        paper = Exam.paper(seed: UInt64(Date().timeIntervalSince1970) ^ 0x5EED)
        index = 0
        chosen = nil
        score = 0
        finished = false
    }

    private func answer(_ i: Int) {
        chosen = i
        if i == paper[index].answer { score += 1; Knock.firm() } else { Knock.light() }
    }

    private func next() {
        if index + 1 < paper.count {
            index += 1
            chosen = nil
        } else {
            finished = true
            bindery.recordExam(score: score, total: paper.count)
        }
    }
}
