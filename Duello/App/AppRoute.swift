import Foundation

/// Ana gezinme rotası. Ağır veri (ham video URL'i, event log) `NavigationPath`
/// yerine `RecordingSessionStore` (environmentObject) üzerinden taşınıyor —
/// bu hem daha basit hem de her ekranın kendi Hashable payload'ı taşımasını
/// gerektirmiyor.
enum AppRoute: Hashable {
    case categorySelection(GameMode)
    case predictionRecording(PredictionTemplate, recordingEnabled: Bool)
    case predictionResult(template: PredictionTemplate, score: Int)
    case draftRecording(DraftTemplate)
    case processing
    case preview
}
