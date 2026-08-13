import Foundation

/// Ana gezinme rotası. Ağır veri (ham video URL'i, event log) `NavigationPath`
/// yerine `RecordingSessionStore` (environmentObject) üzerinden taşınıyor —
/// bu hem daha basit hem de her ekranın kendi Hashable payload'ı taşımasını
/// gerektirmiyor.
enum AppRoute: Hashable {
    case categorySelection(GameMode)
    case predictionRecording(PredictionTemplate, recordingEnabled: Bool, playerCount: Int)
    case predictionResult(template: PredictionTemplate, scoreByPlayer: [Int])
    case draftRecording(DraftTemplate)
    case thisOrThatRecording(ThisOrThatTemplate, recordingEnabled: Bool, playerCount: Int)
    /// Kayıt bitti, kullanıcıya videoyu kaydedip kaydetmeyeceği soruluyor —
    /// oyun biter bitmez otomatik export ARTIK başlamıyor.
    case saveDecision
    case processing
    case preview
    case history
}
