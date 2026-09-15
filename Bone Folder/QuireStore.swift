import Foundation
import SwiftUI
import Combine

struct BoundBook: Codable, Hashable, Identifiable {
    var id: String
    var titleKey: String
    var label: String
    var structure: String
    var signatures: Int
    var imposition: String
    var stations: Int
    var sheet: String
    var paperKey: String
    var thread: String
    var coverKey: String
    var boardKey: String
    var score: Int
    var word: String
    var day: Int
    var hour: Int
    var pages: Int
    var spineMM: Double
    var critique: [String]
    var tensions: [String]
    var pressHours: Double
    var forCommission: Bool
    var headbandA: Int? = nil
    var headbandB: Int? = nil
    var parts: [ScorePart]? = nil

    var title: BookTitle { Register.title(titleKey) }
    var kind: Structure { Structure(rawValue: structure) ?? .pamphlet3 }
    var labelStyle: LabelStyle { LabelStyle(rawValue: label) ?? .paperLabel }
    var paper: Material { Materials.find(paperKey) }
    var cover: Material { Materials.find(coverKey) }
    var board: Material { Materials.find(boardKey) }
    var threadKind: ThreadKind { ThreadKind(rawValue: thread) ?? .linen25 }
    var impositionKind: Imposition { Imposition(rawValue: imposition) ?? .octavo }
    var sheetSize: SheetSize { SheetSize(rawValue: sheet) ?? .a3 }

    var pencilNotes: [String] {
        var lines: [String] = []
        lines.append(title.title)
        lines.append("\(kind.name), \(signatures) \(kind.family == .stab ? "leaves" : (signatures == 1 ? "signature" : "signatures")), \(stations) stations")
        lines.append("\(impositionKind.name) on \(sheetSize.name), \(pages) pages")
        lines.append("\(paper.name), \(paper.grain.name.lowercased())")
        lines.append("\(Materials.thread(threadKind).name.lowercased()), \(cover.name.lowercased()) over \(board.name.lowercased())")
        lines.append("spine \(String(format: "%.1f", spineMM)) mm, pressed \(Clock.durationWords(pressHours * 3600))")
        lines.append("\(score), \(word.lowercased())")
        return lines
    }
}

struct Ledger: Codable {
    var books: [BoundBook] = []
    var points: Int = 0
    var streak: Int = 0
    var bestStreak: Int = 0
    var lastDay: Int = -1
    var daysDone: [Int] = []
    var seenIntro: Bool? = nil
    var bestIds: [String: String]? = nil
    var readLessons: [Int]? = nil
    var readTerms: [String]? = nil
    var readBindings: [String]? = nil
    var readMaterials: [String]? = nil
    var readTools: [String]? = nil
    var readStructures: [String]? = nil
    var examBest: Int? = nil
    var examsTaken: Int? = nil
    var badges: [String]? = nil
    var commissionsDone: [Int]? = nil
    var booksMade: Int? = nil
    var bench: BenchSnapshot? = nil
    var lastTab: Int? = nil
    var dailyRank: [String: Int]? = nil
    var fullPresses: Int? = nil
}

final class Bindery: ObservableObject {
    @Published var ledger: Ledger { didSet { save() } }
    @Published var wantedTab: Int? = nil
    let bench = BenchSession()
    private var benchLink: AnyCancellable? = nil
    private let key = "bonefolder.ledger.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Ledger.self, from: data) {
            ledger = decoded
        } else {
            ledger = Ledger()
        }
        if let snap = ledger.bench { bench.restore(snap) }
        benchLink = bench.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
            DispatchQueue.main.async { self?.snapshotBench() }
        }
    }

    private func snapshotBench() {
        let snap = bench.snapshot()
        if snap != ledger.bench { ledger.bench = snap }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(ledger) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func rememberTab(_ tab: Int) { if ledger.lastTab != tab { ledger.lastTab = tab } }

    var today: Int { Almanac.dayIndex() }

    var liveStreak: Int {
        guard ledger.lastDay == today || ledger.lastDay == today - 1 else { return 0 }
        return ledger.streak
    }

    var rankIndex: Int { Daily.rankIndex(points: ledger.points) }

    var rank: (String, String, Int, Int) {
        let i = rankIndex
        let current = Daily.ladder[i]
        let ceiling = i + 1 < Daily.ladder.count ? Daily.ladder[i + 1].0 : current.0
        return (current.1, current.2, ledger.points, ceiling)
    }

    var commission: Commission { Daily.commission(day: today, rank: ledger.dailyRank?["\(today)"] ?? rankIndex) }

    func lockDaily() {
        var ranks = ledger.dailyRank ?? [:]
        guard ranks["\(today)"] == nil else { return }
        ranks["\(today)"] = rankIndex
        if ranks.count > 60 {
            let keep = ranks.keys.compactMap { Int($0) }.sorted().suffix(60)
            ranks = ranks.filter { keep.contains(Int($0.key) ?? -1) }
        }
        ledger.dailyRank = ranks
    }

    func award(_ n: Int) { ledger.points += n }

    func workedToday() -> Bool { ledger.daysDone.contains(today) }
    func commissionDoneToday() -> Bool { (ledger.commissionsDone ?? []).contains(today) }

    func recordDay() {
        let day = today
        guard !ledger.daysDone.contains(day) else { return }
        ledger.daysDone.append(day)
        if ledger.daysDone.count > 400 { ledger.daysDone.removeFirst(ledger.daysDone.count - 400) }
        if ledger.lastDay == day - 1 { ledger.streak += 1 } else { ledger.streak = 1 }
        ledger.lastDay = day
        ledger.bestStreak = max(ledger.bestStreak, ledger.streak)
    }

    @discardableResult
    func shelve(_ book: BoundBook) -> (Bool, Int) {
        var upgraded = false
        var gained = 14 + book.score / 5
        var ids = ledger.bestIds ?? [:]
        if let existingId = ids[book.structure], let existing = ledger.books.first(where: { $0.id == existingId }) {
            if book.score > existing.score { ids[book.structure] = book.id; upgraded = true; gained += 8 }
        } else {
            ids[book.structure] = book.id
            upgraded = true
            gained += 16
        }
        ledger.bestIds = ids
        if book.score >= 90 { gained += 15 }
        if book.forCommission && !commissionDoneToday() {
            var done = ledger.commissionsDone ?? []
            done.append(today)
            ledger.commissionsDone = done
            gained += commission.reward
        }
        if book.pressHours >= Press.hours(for: book.kind) - 0.01 && book.kind.family == .supported {
            ledger.fullPresses = (ledger.fullPresses ?? 0) + 1
        }
        ledger.books.append(book)
        ledger.booksMade = (ledger.booksMade ?? 0) + 1
        trimBooks()
        award(gained)
        recordDay()
        checkBadges()
        return (upgraded, gained)
    }

    private func trimBooks() {
        let keep = Set((ledger.bestIds ?? [:]).values)
        while ledger.books.count > 48 {
            if let index = ledger.books.firstIndex(where: { !keep.contains($0.id) }) {
                ledger.books.remove(at: index)
            } else {
                ledger.books.removeFirst()
            }
        }
    }

    func best(_ structure: Structure) -> BoundBook? {
        guard let id = (ledger.bestIds ?? [:])[structure.rawValue] else { return nil }
        return ledger.books.first { $0.id == id }
    }

    func isBest(_ book: BoundBook) -> Bool { (ledger.bestIds ?? [:])[book.structure] == book.id }

    func book(_ id: String) -> BoundBook? { ledger.books.first { $0.id == id } }

    var structuresBound: Set<String> { Set(ledger.books.map { $0.structure }) }

    func markLesson(_ index: Int) {
        var read = ledger.readLessons ?? []
        if !read.contains(index) { read.append(index); award(6) }
        ledger.readLessons = read
        checkBadges()
    }

    func markTerm(_ term: String) {
        var read = ledger.readTerms ?? []
        if !read.contains(term) { read.append(term); award(1) }
        ledger.readTerms = read
        checkBadges()
    }

    private func mark(_ list: [String]?, _ key: String, points: Int) -> [String]? {
        var seen = list ?? []
        if !seen.contains(key) { seen.append(key); award(points) }
        return seen
    }

    func markBinding(_ key: String) { ledger.readBindings = mark(ledger.readBindings, key, points: 2) }
    func markMaterial(_ key: String) { ledger.readMaterials = mark(ledger.readMaterials, key, points: 1) }
    func markTool(_ key: String) { ledger.readTools = mark(ledger.readTools, key, points: 2) }
    func markStructure(_ key: String) { ledger.readStructures = mark(ledger.readStructures, key, points: 2) }

    func recordExam(score: Int, total: Int) {
        let pct = Int((Double(score) / Double(max(1, total)) * 100).rounded())
        ledger.examsTaken = (ledger.examsTaken ?? 0) + 1
        if pct > (ledger.examBest ?? 0) { ledger.examBest = pct }
        award(6 + pct / 4)
        recordDay()
        checkBadges()
    }

    var lessonsRead: Int { (ledger.readLessons ?? []).count }
    var termsRead: Int { (ledger.readTerms ?? []).count }
    var booksMade: Int { ledger.booksMade ?? 0 }
    var fineCount: Int { ledger.books.filter { $0.score >= 75 }.count }
    var masterCount: Int { ledger.books.filter { $0.score >= 90 }.count }

    func hasBadge(_ key: String) -> Bool { (ledger.badges ?? []).contains(key) }

    func checkBadges() {
        var badges = ledger.badges ?? []
        func grant(_ key: String, _ condition: Bool) {
            if condition && !badges.contains(key) { badges.append(key); ledger.points += 20 }
        }
        let bound = structuresBound
        grant("first", booksMade >= 1)
        grant("pamphlet", bound.contains("pamphlet3") || bound.contains("pamphlet5"))
        grant("chain", ledger.books.contains { ($0.kind.family == .chain) && $0.score >= 60 })
        grant("tapes", bound.contains("kettleTapes") || bound.contains("frenchLink"))
        grant("stab", ledger.books.contains { $0.kind.family == .stab })
        grant("belgian", bound.contains("secretBelgian"))
        grant("fold", bound.contains("accordion"))
        grant("master", masterCount >= 1)
        grant("fine", fineCount >= 5)
        grant("shelf", ledger.books.count >= 24)
        grant("patience", (ledger.fullPresses ?? 0) >= 1)
        grant("streak", ledger.bestStreak >= 7)
        grant("reader", lessonsRead >= Lessons.all.count)
        grant("glossary", termsRead >= Glossary.all.count)
        grant("examiner", (ledger.examBest ?? 0) >= 80)
        grant("allStructures", Structure.allCases.allSatisfy { bound.contains($0.rawValue) })
        if badges != (ledger.badges ?? []) { ledger.badges = badges }
    }

    func resetAll() {
        bench.reset()
        ledger = Ledger()
        ledger.seenIntro = true
    }
}
