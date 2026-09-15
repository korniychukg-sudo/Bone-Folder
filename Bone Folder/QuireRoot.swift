import SwiftUI

struct QuireRoot: View {
    @EnvironmentObject var bindery: Bindery
    @State private var tab = 0
    @State private var lastTab = 0
    @State private var restored = false

    var body: some View {
        ZStack {
            Quire.page.ignoresSafeArea()
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0:
                        NavigationView { TodayView().environmentObject(bindery) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { BenchView().environmentObject(bindery) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { RegisterView().environmentObject(bindery) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { ShelfView().environmentObject(bindery) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { BookTabView().environmentObject(bindery) }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .id(tab)
                .transition(.asymmetric(
                    insertion: .move(edge: tab > lastTab ? .trailing : .leading)
                        .combined(with: .opacity),
                    removal: .opacity))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                bar
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            guard !restored else { return }
            restored = true
            let saved = bindery.ledger.lastTab ?? 0
            if saved != tab && saved >= 0 && saved < 5 { tab = saved; lastTab = saved }
        }
        .onChange(of: tab) { value in bindery.rememberTab(value) }
        .onReceive(bindery.$wantedTab) { wanted in
            guard let wanted = wanted else { return }
            lastTab = tab
            withAnimation(.easeInOut(duration: 0.22)) { tab = wanted }
            bindery.wantedTab = nil
        }
    }

    private var bar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Today")
            tabButton(1, "Bench")
            tabButton(2, "Register")
            tabButton(3, "Shelf")
            tabButton(4, "Book")
        }
        .padding(.top, 7)
        .padding(.bottom, 3)
        .background(
            Quire.card
                .overlay(Rectangle().fill(Quire.ink.opacity(0.10)).frame(height: 0.7), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, _ label: String) -> some View {
        let active = tab == index
        let tone = active ? Quire.ink : Quire.inkFaint
        return Button(action: {
            Knock.light()
            lastTab = tab
            withAnimation(.easeInOut(duration: 0.22)) { tab = index }
        }) {
            VStack(spacing: 3) {
                Group {
                    switch index {
                    case 0: TodayMark(size: 22, color: tone)
                    case 1: BenchMark(size: 22, color: tone)
                    case 2: RegisterMark(size: 22, color: tone)
                    case 3: ShelfMark(size: 22, color: tone)
                    default: BookMark(size: 22, color: tone)
                    }
                }
                Text(label).font(Quire.body(9.5)).foregroundColor(tone)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct QuireIntro: View {
    var onDone: () -> Void
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("Bone Folder",
         "A bindery is a bench under a tall window, a press, a paste pot and a needle. Everything a book is, from the fold to the shelf, is made there by hand, and every stage can be felt under the finger: the crease, the awl, the pull of the thread, the taps of the hammer.",
         "ob_0"),
        ("The sheet knows its order",
         "Pages are printed on the sheet out of order, some upside down. Fold it the right way and they come out one to sixteen; fold it wrong and page nine stands on its head on the front. The grain must run with the spine, or the fold cracks.",
         "ob_1"),
        ("A stitch is a grammar",
         "Every structure is a sequence of stations and links: the pamphlet, the Coptic chain, the kettle stitch on tapes, the French link, the Japanese four-hole. You drag the needle from station to station and the thread follows; the engine checks each move, and each pull must land in the window.",
         "ob_2"),
        ("Then the press, in real hours",
         "The block is rounded with a hammer, lined, given headbands, boarded and covered, and cased in. Then it goes into the press and stays there on the clock. What you keep is a shelf of books you can pull out and open, the sewing seen from inside, the record pencilled on the back.",
         "ob_3")
    ]

    var body: some View {
        ZStack {
            Quire.page.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    if page > 0 {
                        BackChevron { withAnimation { page -= 1 } }
                    }
                    Spacer()
                    Button(action: { Knock.light(); onDone() }) {
                        Text("Skip").font(Quire.body(13.5)).foregroundColor(Quire.inkFaint)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, Quire.gutter)
                .padding(.top, 14)
                Spacer(minLength: 0)
                ScrollView {
                    Column {
                        SheetCard(padding: 9) {
                            PlateBox(name: pages[page].2, height: Quire.isPad ? 320 : 218)
                        }
                        VStack(alignment: .leading, spacing: 9) {
                            Text(pages[page].0).font(Quire.title(24)).foregroundColor(Quire.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(pages[page].1).font(Quire.body(14.5))
                                .foregroundColor(Quire.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, Quire.gutter)
                    .id(page)
                    .transition(.opacity)
                }
                Spacer(minLength: 0)
                HStack(spacing: 6) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Circle().fill(i == page ? Quire.ink : Quire.ink.opacity(0.20))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 13)
                SealButton(title: page == pages.count - 1 ? "Into the bindery" : "Next", tone: Quire.walnut) {
                    if page == pages.count - 1 { onDone() } else { withAnimation { page += 1 } }
                }
                .padding(.horizontal, Quire.gutter)
                .padding(.bottom, 20)
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var bindery: Bindery
    var onClose: () -> Void
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Quire.page.ignoresSafeArea()
            VStack(spacing: 0) {
                SheetHead(title: "About the bindery", subtitle: "Bone Folder 1.0") { onClose() }
                ScrollView {
                    Column {
                        SheetCard {
                            VStack(alignment: .leading, spacing: 9) {
                                HeadRule(text: "What this is")
                                Text("A bindery bench in your hands. Thirteen sewing and folding structures with their real stitch grammars, four impositions whose page order is derived from the folds you make, sixty materials, thirty historical bindings, eighteen tools and forty titles. The block is folded, punched, sewn, rounded, lined, boarded, covered and pressed by hand gestures, and the press runs on the real clock.")
                                    .font(Quire.body(13.5)).foregroundColor(Quire.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("The critique reads every stage: fold accuracy and grain, station accuracy, stitch faults, tension in the window, the rounding profile, bubbles under the lining, the squares, the corners and the patience in the press, and gives the book a word from a working copy to a master binding.")
                                    .font(Quire.body(13.5)).foregroundColor(Quire.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        SheetCard {
                            VStack(alignment: .leading, spacing: 9) {
                                HeadRule(text: "Your standing")
                                HStack(spacing: 9) {
                                    CountTile(value: "\(bindery.ledger.points)", label: "points")
                                    CountTile(value: "\(bindery.booksMade)", label: "books bound")
                                    CountTile(value: "\(bindery.ledger.bestStreak)", label: "best streak")
                                }
                                Text("Everything is stored on this device only. There is no account, no network and nothing leaves the bindery.")
                                    .font(Quire.body(12.5)).foregroundColor(Quire.inkFaint)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        SheetCard {
                            VStack(alignment: .leading, spacing: 9) {
                                HeadRule(text: "Start again")
                                Text("Empties the shelf and the bench, clears the streak, the badges and the examination, and returns you to Apprentice.")
                                    .font(Quire.body(12.5)).foregroundColor(Quire.inkSoft)
                                    .fixedSize(horizontal: false, vertical: true)
                                if confirmReset {
                                    NoticeBar(text: "This cannot be undone. Empty the bindery?", tone: Quire.thread,
                                              action: ("Empty it", { bindery.resetAll(); confirmReset = false; onClose() }))
                                    SealButton(title: "Keep everything", tone: Quire.inkSoft, filled: false) { confirmReset = false }
                                } else {
                                    SealButton(title: "Reset progress", tone: Quire.thread, filled: false) { confirmReset = true }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Quire.gutter)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}
