import Foundation
import CoreGraphics

let args = CommandLine.arguments
let outDir = args.count > 1 ? args[1] : "Art"
let job = args.count > 2 ? args[2] : "all"
let scratch = args.count > 3 ? args[3] : outDir

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
try? FileManager.default.createDirectory(atPath: scratch, withIntermediateDirectories: true)

func wants(_ name: String) -> Bool { job == "all" || job == name }

let started = Date()
var made = 0

func note(_ text: String) {
    let elapsed = Int(Date().timeIntervalSince(started))
    print("[\(elapsed)s] \(text)")
}

if job == "icon" {
    drawIcon(outDir, scratch)
    note("icon written to \(outDir)")
    exit(0)
}

sheetScale = 1.45

if job == "probe" {
    var tiles: [(String, CGImage)] = []
    for key in ["copticCodex", "publishersCloth", "fukuroToji", "orihon", "girdleBook", "perfectBinding"] {
        let b = Register.binding(key)
        if let img = drawBindingPlate(b, dir: outDir) { tiles.append((b.name, img)) }
        note("probe \(key)")
    }
    contactSheet(scratch, "contact_probe", tiles: tiles, columns: 3, tile: 400)
    exit(0)
}

if wants("bindings") {
    var tiles: [(String, CGImage)] = []
    for b in Register.bindings {
        if let img = drawBindingPlate(b, dir: outDir) { tiles.append((b.name, img)) }
        made += 1
        note("binding \(b.key)")
    }
    contactSheet(scratch, "contact_bindings", tiles: tiles, columns: 6, tile: 300)
}

if wants("materials") {
    var tiles: [(String, CGImage)] = []
    for m in Materials.all {
        if let img = drawMaterialPlate(m, dir: outDir) { tiles.append((m.name, img)) }
        made += 1
        note("material \(m.key)")
    }
    contactSheet(scratch, "contact_materials", tiles: tiles, columns: 8, tile: 240)
}

if wants("tools") {
    var tiles: [(String, CGImage)] = []
    for t in Register.tools {
        if let img = drawToolPlate(t, dir: outDir) { tiles.append((t.name, img)) }
        made += 1
        note("tool \(t.key)")
    }
    contactSheet(scratch, "contact_tools", tiles: tiles, columns: 6, tile: 300)
}

if wants("structures") {
    var tiles: [(String, CGImage)] = []
    for s in Structure.allCases {
        if let img = drawStructurePlate(s, dir: outDir) { tiles.append((s.name, img)) }
        made += 1
        note("structure \(s.rawValue)")
    }
    contactSheet(scratch, "contact_structures", tiles: tiles, columns: 5, tile: 320)
}

if wants("labels") {
    var tiles: [(String, CGImage)] = []
    for t in Register.titles {
        if let img = drawLabelPlate(t, dir: outDir) { tiles.append((t.title, img)) }
        made += 1
        note("label \(t.key)")
    }
    contactSheet(scratch, "contact_labels", tiles: tiles, columns: 8, tile: 220)
}

if wants("lessons") {
    var tiles: [(String, CGImage)] = []
    for index in 0..<12 {
        if let img = drawLessonPlate(index, dir: outDir) { tiles.append(("Lesson \(index + 1)", img)) }
        made += 1
        note("lesson \(index + 1)")
    }
    contactSheet(scratch, "contact_lessons", tiles: tiles, columns: 4, tile: 320)
}

if wants("hours") {
    var tiles: [(String, CGImage)] = []
    for index in 0..<7 {
        if let img = drawHourPlate(index, dir: outDir) { tiles.append(("Hour \(index)", img)) }
        made += 1
        note("hour \(index)")
    }
    for index in 0..<4 {
        if let img = drawOnboardPlate(index, dir: outDir) { tiles.append(("Onboarding \(index + 1)", img)) }
        made += 1
        note("onboarding \(index)")
    }
    for (index, key) in decorKeys.enumerated() {
        if let img = drawDecorPlate(index, dir: outDir) { tiles.append((key, img)) }
        made += 1
        note("decor \(key)")
    }
    contactSheet(scratch, "contact_hours", tiles: tiles, columns: 4, tile: 320)
}

note("wrote \(made) plates into \(outDir)")
