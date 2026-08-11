import SwiftUI

@main
struct LanguageRouletteApp: App {
    @StateObject private var contentStore = ContentStore()

    var body: some Scene {
        WindowGroup {
            ContentView(contentStore: contentStore)
                .preferredColorScheme(.light)
        }
    }
}
