import Foundation

/// Sayı/duruma göre değişen (interpolasyonlu) metinler için manuel yerelleştirme.
///
/// `Localizable.xcstrings` + `.environment(\.locale)`, SADECE çağrı yerinde
/// literal olan `Text("...")` için otomatik çalışır (Xcode'un LocalizedStringKey
/// mekanizması). Bu dosyadaki metinler ise runtime'da hesaplanan (skor, kalan
/// bütçe, soru sayısı, oyuncu adı vb.) string'ler — bunları String Catalog'un
/// `%lld`/`%@` format-specifier eşleştirmesine bırakmak yerine (bu eşleşmeyi
/// Xcode'un genstrings aracı olmadan elle birebir tutturmak kırılgan), doğrudan
/// dile göre metni seçen saf fonksiyonlar kullanıyoruz — hem güvenilir hem test edilebilir.
enum L10n {
    static func isTurkish(_ locale: Locale) -> Bool {
        locale.language.languageCode?.identifier == "tr"
    }

    static func questionCount(_ count: Int, locale: Locale) -> String {
        isTurkish(locale) ? "\(count) soru" : "\(count) question\(count == 1 ? "" : "s")"
    }

    static func draftSubtitle(budget: Int, optionCount: Int, locale: Locale) -> String {
        isTurkish(locale)
            ? "Bütçe: \(budget) • \(optionCount) seçenek"
            : "Budget: \(budget) • \(optionCount) options"
    }

    static func playerLabel(_ player: DraftPlayer, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch player {
        case .playerA: return turkish ? "Oyuncu 1'in sırası" : "Player 1's turn"
        case .playerB: return turkish ? "Oyuncu 2'nin sırası" : "Player 2's turn"
        }
    }

    static func playerShortLabel(_ player: DraftPlayer, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch player {
        case .playerA: return turkish ? "Oyuncu 1" : "Player 1"
        case .playerB: return turkish ? "Oyuncu 2" : "Player 2"
        }
    }

    static func resultLabel(_ result: DraftResult, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch result {
        case .winner(.playerA): return turkish ? "Oyuncu 1 Kazandı!" : "Player 1 Won!"
        case .winner(.playerB): return turkish ? "Oyuncu 2 Kazandı!" : "Player 2 Won!"
        case .tie: return turkish ? "Berabere!" : "It's a Tie!"
        }
    }

    static func resultTextWithEmoji(_ result: DraftResult, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch result {
        case .winner(.playerA): return turkish ? "🏆 Oyuncu 1 Kazandı!" : "🏆 Player 1 Won!"
        case .winner(.playerB): return turkish ? "🏆 Oyuncu 2 Kazandı!" : "🏆 Player 2 Won!"
        case .tie: return turkish ? "🤝 Berabere!" : "🤝 It's a Tie!"
        }
    }

    static func totalCostLabel(_ cost: Int, locale: Locale) -> String {
        isTurkish(locale) ? "Toplam: \(cost)" : "Total: \(cost)"
    }

    static func rosterProgressLabel(picked: Int, rosterSize: Int, locale: Locale) -> String {
        isTurkish(locale) ? "\(picked)/\(rosterSize) seçildi" : "\(picked)/\(rosterSize) picked"
    }

    static func remainingBudgetLabel(_ amount: Int, locale: Locale) -> String {
        isTurkish(locale) ? "Kalan bütçe: \(amount)" : "Remaining budget: \(amount)"
    }

    static func pickCostLabel(cost: Int, remainingBudgetAfterPick: Int, locale: Locale) -> String {
        isTurkish(locale)
            ? "Maliyet: \(cost) • Bu seçimden sonra kalan bütçe: \(remainingBudgetAfterPick)"
            : "Cost: \(cost) • Remaining budget after this pick: \(remainingBudgetAfterPick)"
    }

    static func questionProgress(current: Int, total: Int, locale: Locale) -> String {
        isTurkish(locale) ? "Soru \(current)/\(total)" : "Question \(current)/\(total)"
    }

    static func feedbackTitle(selectedCorrect: Bool?, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch selectedCorrect {
        case .none: return turkish ? "⏱️ Süre doldu" : "⏱️ Time's up"
        case .some(true): return turkish ? "✅ Doğru!" : "✅ Correct!"
        case .some(false): return turkish ? "❌ Yanlış" : "❌ Wrong"
        }
    }

    /// Videoya yakılan reveal kartı için: durum ve cevap ayrı satırlarda —
    /// tek satıra sıkıştırılmış uzun bir cümle yerine iki satırlı, daha okunur
    /// bir kart (bkz. `OverlayCompositionBuilder`).
    static func answerFeedback(selectedCorrect: Bool?, correctAnswer: String, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch selectedCorrect {
        case .none:
            return turkish ? "⏱️ Süre doldu\n\(correctAnswer)" : "⏱️ Time's up\n\(correctAnswer)"
        case .some(true):
            return turkish ? "✅ Doğru!\n\(correctAnswer)" : "✅ Correct!\n\(correctAnswer)"
        case .some(false):
            return turkish ? "❌ Yanlış\n\(correctAnswer)" : "❌ Wrong\n\(correctAnswer)"
        }
    }

    static func scoreSummary(score: Int, total: Int, locale: Locale) -> String {
        isTurkish(locale) ? "\(score)/\(total) doğru bildin!" : "You got \(score)/\(total) right!"
    }

    static func scoreFeedback(score: Int, total: Int, locale: Locale) -> String {
        guard total > 0 else { return "" }
        let turkish = isTurkish(locale)
        let ratio = Double(score) / Double(total)
        switch ratio {
        case 1.0:
            return turkish ? "Mükemmel skor!" : "Perfect score!"
        case 0.6...:
            return turkish ? "Gayet iyi!" : "Pretty good!"
        default:
            return turkish ? "Bir dahaki sefere daha iyisini yapabilirsin." : "You can do better next time."
        }
    }

    static func cameraErrorTitle(locale: Locale) -> String {
        isTurkish(locale) ? "Kamera açılamadı" : "Couldn't open camera"
    }

    /// `.cannotAddVideoInput` pratikte çoğunlukla izin reddedilmiş olmasından kaynaklanır
    /// (ya da kamera başka bir uygulama tarafından kullanılıyordur) — mesaj bunu yansıtıyor.
    static func cameraErrorMessage(_ error: CameraSession.CameraConfigurationError, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch error {
        case .noFrontCamera:
            return turkish
                ? "Cihazında ön kamera bulunamadı."
                : "This device doesn't have a front camera."
        case .cannotAddVideoInput:
            return turkish
                ? "Kameraya erişilemedi. İzin reddedilmiş olabilir ya da kamera başka bir uygulama tarafından kullanılıyor olabilir."
                : "Couldn't access the camera. Permission may have been denied, or another app is using the camera."
        }
    }

    static func exportErrorMessage(locale: Locale) -> String {
        isTurkish(locale)
            ? "Video işlenirken bir sorun oluştu. Lütfen tekrar dene."
            : "Something went wrong while preparing the video. Please try again."
    }
}
