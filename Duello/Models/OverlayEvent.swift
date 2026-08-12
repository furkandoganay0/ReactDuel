import Foundation

/// Kayıt sırasında oluşan, kayıt başlangıcına göre zaman damgalı bir overlay olayı.
///
/// Ham video (Bölüm 9) overlay'siz kaydedilir; bu event log post-processing
/// aşamasında bir `CALayer` hiyerarşisine dönüştürülüp videoya "yakılır"
/// (bkz. `OverlayCompositionBuilder`, `VideoExporter`).
struct OverlayEvent: Equatable {
    let timestamp: TimeInterval
    let kind: OverlayEventKind
}

enum OverlayEventKind: Equatable {
    case showPrompt(text: String)
    case showAnswer(text: String)
    case showTurn(playerLabel: String, budgetRemaining: Int)
    case showPick(playerLabel: String, itemName: String)
    case showResult(winnerLabel: String)
    case hideAll
}
