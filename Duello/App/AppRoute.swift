import Foundation

/// Ana gezinme rotası. Ağır veri (ham video URL'i, event log) `NavigationPath`
/// yerine `RecordingSessionStore` (environmentObject) üzerinden taşınıyor —
/// bu hem daha basit hem de her ekranın kendi Hashable payload'ı taşımasını
/// gerektirmiyor.
enum AppRoute: Hashable {
    case categorySelection(GameMode)
    /// `editing` doluysa ekran "yeni paket" yerine mevcut paketi düzenleme
    /// modunda açılır (bkz. `CreatePredictionPackView` vb.'nin `existingPack`
    /// parametresi) — önceden özel paketler sadece sil/yeniden yaz ile
    /// değiştirilebiliyordu, küçük bir yazım hatası bile tüm paketi silip
    /// baştan yazmayı gerektiriyordu.
    case createPredictionPack(editing: PredictionTemplate?)
    case createDraftPack(editing: DraftTemplate?)
    case createThisOrThatPack(editing: ThisOrThatTemplate?)
    case predictionRecording(PredictionTemplate, recordingEnabled: Bool, playerCount: Int)
    case predictionResult(template: PredictionTemplate, scoreByPlayer: [Int])
    case draftRecording(DraftTemplate, recordingEnabled: Bool)
    case draftResult(template: DraftTemplate, rosterA: [DraftPoolItem], rosterB: [DraftPoolItem], result: DraftResult)
    case thisOrThatRecording(ThisOrThatTemplate, recordingEnabled: Bool, playerCount: Int)
    case thisOrThatResult(template: ThisOrThatTemplate, pickedLabels: [String], playerCount: Int)
    /// Kayıt bitti, kullanıcıya videoyu kaydedip kaydetmeyeceği soruluyor —
    /// oyun biter bitmez otomatik export ARTIK başlamıyor.
    case saveDecision
    case processing
    case preview
    case history
}
