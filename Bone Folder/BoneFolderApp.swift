import SwiftUI

@main
struct BoneFolderApp: App {
    @StateObject private var bindery = Bindery()

    var body: some Scene {
        WindowGroup {
            Group {
                if bindery.ledger.seenIntro == true {
                    QuireRoot().environmentObject(bindery)
                } else {
                    QuireIntro { bindery.ledger.seenIntro = true }
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
