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
        #if DEBUG
        .onAppear(perform: applyScreenshotRouteIfNeeded)
        #endif
    }

    #if DEBUG
    /// App Store ekran görüntüsü üretimi için: `simctl launch --env SCREENSHOT_ROUTE=...`
    /// ile başlatılırsa, hiç dokunmadan doğrudan istenen ekrana atlar (bkz.
    /// `fastlane snapshot`'ın kullandığı desenin aynısı — otomasyon aracı kullanıcının
    /// faresine/klavyesine hiç dokunmadan ekran görüntüsü alabilsin diye). Normal
    /// kullanımda bu ortam değişkeni hiç set edilmediği için tamamen etkisiz;
    /// sadece DEBUG build'de derlenir, Release'e hiç girmez.
    private func applyScreenshotRouteIfNeeded() {
        guard let route = ProcessInfo.processInfo.environment["SCREENSHOT_ROUTE"] else { return }
        appState.hasCompletedOnboarding = true

        switch route {
        case "home":
            path = []
        case "categoryPrediction":
            path = [.categorySelection(.prediction)]
        case "categoryDraft":
            path = [.categorySelection(.draft)]
        case "categoryThisOrThat":
            path = [.categorySelection(.thisOrThat)]
        case "predictionGameplay":
            if let pack = appState.catalog.predictionPacks.first {
                path = [.categorySelection(.prediction), .predictionRecording(pack, recordingEnabled: false, playerCount: 2)]
            }
        case "draftGameplay":
            if let pack = appState.catalog.draftPacks.first {
                path = [.categorySelection(.draft), .draftRecording(pack, recordingEnabled: false)]
            }
        case "thisOrThatGameplay":
            if let pack = appState.catalog.thisOrThatPacks.first {
                path = [.categorySelection(.thisOrThat), .thisOrThatRecording(pack, recordingEnabled: false, playerCount: 2)]
            }
        case "history":
            path = [.history]
        default:
            break
        }
    }
    #endif

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
