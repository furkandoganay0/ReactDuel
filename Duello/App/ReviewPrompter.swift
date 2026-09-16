import Foundation

/// Ne zaman `requestReview()` (StoreKit) tetiklenmeli kararını veren saf mantık —
/// StoreKit'in kendisi View içermeyen bir yerden çağrılamadığı için burası sadece
/// "şimdi mi" sorusuna cevap veriyor, gerçek çağrıyı ve `UserDefaults` kalıcılığını
/// `HomeView` yapıyor (bkz. `PredictionTimerStateMachine` vb. ile aynı desen —
/// saf fonksiyon + side-effect'i çağıran tarafa bırakmak, test edilebilirlik için).
/// Önceden uygulamada hiç puan isteme akışı yoktu.
enum ReviewPrompter {
    static let lastMilestoneKey = "duello.reviewPrompt.lastMilestone"

    /// Sistem zaten kendi başına yılda ~3 gösterimle sınırlıyor — buradaki
    /// eşikler, sadece kullanıcı gerçekten birkaç kez oynamışken (ilk oturumdan
    /// hemen sonra değil) sormamızı garanti ediyor.
    static let milestones = [3, 10, 25, 50]

    /// `sessionCount` = o ana kadar oynanmış toplam oturum sayısı
    /// (`PlayHistoryStore.records.count`). `lastMilestone` = daha önce en son
    /// tetiklenen eşik (hiç tetiklenmediyse 0). Yeni bir eşiğe ilk kez
    /// ulaşıldıysa o eşiği döner; aksi halde `nil`.
    static func newlyReachedMilestone(sessionCount: Int, lastMilestone: Int) -> Int? {
        milestones.first(where: { $0 > lastMilestone && sessionCount >= $0 })
    }
}
