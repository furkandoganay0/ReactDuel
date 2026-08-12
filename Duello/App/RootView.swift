import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var session = RecordingSessionStore()
    @State private var path: [AppRoute] = []

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                NavigationStack(path: $path) {
                    HomeView(path: $path)
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                }
                .environmentObject(session)
            } else {
                OnboardingView()
            }
        }
        .environment(\.locale, appState.language.localeOverride ?? .autoupdatingCurrent)
        .preferredColorScheme(appState.appearance.colorScheme)
        .tint(.indigo)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .categorySelection(let mode):
            CategorySelectionView(mode: mode, path: $path)

        case .predictionRecording(let template, let recordingEnabled, let playerCount):
            PredictionRecordingView(template: template, recordingEnabled: recordingEnabled, playerCount: playerCount, path: $path)

        case .predictionResult(let template, let scoreByPlayer):
            PredictionResultView(template: template, scoreByPlayer: scoreByPlayer, path: $path)

        case .draftRecording(let template):
            DraftRecordingView(template: template, path: $path)

        case .processing:
            ProcessingView(path: $path)

        case .preview:
            VideoPreviewView(path: $path)
        }
    }
}

#Preview {
    RootView().environmentObject(AppState())
}
