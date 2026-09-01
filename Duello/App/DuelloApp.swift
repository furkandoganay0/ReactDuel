import SwiftUI

@main
struct DuelloApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var playHistoryStore = PlayHistoryStore()
    @StateObject private var userContentStore = UserContentStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(playHistoryStore)
                .environmentObject(userContentStore)
        }
    }
}
