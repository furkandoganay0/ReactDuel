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
        .tint(appState.accentColorChoice.color)
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .categorySelection(let mode):
            CategorySelectionView(mode: mode, path: $path)

        case .createPredictionPack:
            CreatePredictionPackView(path: $path)

        case .createDraftPack:
            CreateDraftPackView(path: $path)

        case .createThisOrThatPack:
            CreateThisOrThatPackView(path: $path)

        case .predictionRecording(let template, let recordingEnabled, let playerCount):
            // `.id` şart: `switchToNoRecordingMode` aynı yığın derinliğinde
            // `path.removeLast()` + `path.append(...)` yapıp `recordingEnabled`i
            // değiştiriyor — bu id olmadan SwiftUI view'ı "aynı" sanıp
            // `@StateObject cameraController`ı (ve dolayısıyla eski `configurationError`'ı)
            // koruyordu, "Kayıtsız Devam Et" kamera hata kartını hiç kapatmıyordu.
            PredictionRecordingView(template: template, recordingEnabled: recordingEnabled, playerCount: playerCount, path: $path)
                .id("prediction-\(template.id)-\(recordingEnabled)-\(playerCount)")

        case .predictionResult(let template, let scoreByPlayer):
            PredictionResultView(template: template, scoreByPlayer: scoreByPlayer, path: $path)

        case .draftRecording(let template, let recordingEnabled):
            // Aynı gerekçe: bkz. `.predictionRecording` üstündeki yorum.
            DraftRecordingView(template: template, recordingEnabled: recordingEnabled, path: $path)
                .id("draft-\(template.id)-\(recordingEnabled)")

        case .draftResult(let template, let rosterA, let rosterB, let result):
            DraftFinalResultView(template: template, rosterA: rosterA, rosterB: rosterB, result: result, path: $path)

        case .thisOrThatRecording(let template, let recordingEnabled, let playerCount):
            // Aynı gerekçe: bkz. `.predictionRecording` üstündeki yorum.
            ThisOrThatRecordingView(template: template, recordingEnabled: recordingEnabled, playerCount: playerCount, path: $path)
                .id("thisOrThat-\(template.id)-\(recordingEnabled)-\(playerCount)")

        case .thisOrThatResult(let template, let pickedLabels, let playerCount):
            ThisOrThatFinalResultView(template: template, pickedLabels: pickedLabels, playerCount: playerCount, path: $path)

        case .saveDecision:
            SaveDecisionView(path: $path)

        case .processing:
            ProcessingView(path: $path)

        case .preview:
            VideoPreviewView(path: $path)

        case .history:
            HistoryView(path: $path)
        }
    }
}

#Preview {
    RootView().environmentObject(AppState())
}
