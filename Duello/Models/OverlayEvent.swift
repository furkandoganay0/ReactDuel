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
enum OverlayEventKind: Equatable {
    /// Kaydın en başında, gerçek oyun içeriği başlamadan önce ~1-2 saniyeliğine
    /// gösterilen "hook" kartı (paket adı) — kısa video izleyicisinin ilk
    /// saniyede neyi izlediğini anlaması için.
    case showIntro(text: String)
    case showPrompt(text: String)
    case showAnswer(text: String)
    case showTurn(text: String)
    case showPick(text: String)
    case showResult(text: String)
    case hideAll
}
