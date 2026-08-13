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

/// Tüm case'ler zaten tam yerelleştirilmiş metin taşır — export zamanı (`OverlayCompositionBuilder`)
/// hiçbir `Locale`/environment erişimi olmadığı için formatlama (örn. "Kalan bütçe: %d")
/// burada DEĞİL, event kaydedilirken (view katmanında, `L10n` ile) yapılmalı.
///
/// `playerIndex` (0/1, `nil` = tek kişilik/nötr) hemen hemen her case'te var —
/// videoya yakılan kartların, canlı ekranda gördüğün oyuncu renkleriyle
/// (Oyuncu 1 = indigo, Oyuncu 2 = turuncu) BİREBİR eşleşmesi için. Önceden
/// video her zaman nötr siyah kartlarla gidiyordu, canlı arayüzdeki renk
/// kodlaması hiç videoya yansımıyordu.
enum OverlayEventKind: Equatable {
    /// Kaydın en başında, gerçek oyun içeriği başlamadan önce ~1-2 saniyeliğine
    /// gösterilen "hook" kartı (paket adı) — kısa video izleyicisinin ilk
    /// saniyede neyi izlediğini anlaması için.
    case showIntro(text: String)
    case showPrompt(text: String, playerIndex: Int?)
    /// Tahmin Et'te promptla AYNI anda loglanır — canlı ekrandaki dokunmalı
    /// şık butonlarının videodaki karşılığı (video izleyicisi düğmelere
    /// dokunamaz ama en azından şıkların ne olduğunu görebilir).
    case showChoices(text: String, playerIndex: Int?)
    case showAnswer(text: String, playerIndex: Int?)
    case showTurn(text: String, playerIndex: Int?)
    case showPick(text: String, playerIndex: Int?)
    case showResult(text: String, playerIndex: Int?)
    case hideAll
}
