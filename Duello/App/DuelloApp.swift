import SwiftUI

@main
struct DuelloApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var playHistoryStore = PlayHistoryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(playHistoryStore)
        }
    }
}
