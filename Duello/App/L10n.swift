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

    static func roundCount(_ count: Int, locale: Locale) -> String {
        isTurkish(locale) ? "\(count) tur" : "\(count) round\(count == 1 ? "" : "s")"
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

    /// Seçim süresi dolduğunda otomatik yapılan pick için videoya yakılan metin —
    /// manuel seçimden ayırt edilsin diye ayrı, "süre doldu" vurgulu bir ifade.
    static func autoPickLabel(playerName: String, itemName: String, locale: Locale) -> String {
        isTurkish(locale) ? "⏱️ Süre doldu — \(playerName): \(itemName)" : "⏱️ Time's up — \(playerName): \(itemName)"
    }

    static func questionProgress(current: Int, total: Int, locale: Locale) -> String {
        isTurkish(locale) ? "Soru \(current)/\(total)" : "Question \(current)/\(total)"
    }

    /// Tahmin Et modunda `playerIndex` 0/1 içindir (sadece tek/iki kişilik oturum
    /// destekleniyor) — `Draft`'ın `DraftPlayer` enum'ından kasıtlı olarak ayrı,
    /// çünkü bu mod ayrı bir ekran/state machine'de yaşıyor.
    static func playerName(_ playerIndex: Int, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch playerIndex {
        case 0: return turkish ? "Oyuncu 1" : "Player 1"
        default: return turkish ? "Oyuncu 2" : "Player 2"
        }
    }

    static func playerTurnLabel(_ playerIndex: Int, locale: Locale) -> String {
        let turkish = isTurkish(locale)
        switch playerIndex {
        case 0: return turkish ? "Oyuncu 1'in Sırası" : "Player 1's Turn"
        default: return turkish ? "Oyuncu 2'nin Sırası" : "Player 2's Turn"
        }
    }

    /// İki kişilik bir Tahmin Et oturumunun sonunda kazananı/beraberliği anons eder.
    /// `scoreByPlayer.count < 2` ise (tek kişilik oturum) boş string döner.
    static func predictionWinnerText(scoreByPlayer: [Int], locale: Locale) -> String {
        guard scoreByPlayer.count >= 2 else { return "" }
        let turkish = isTurkish(locale)
        if scoreByPlayer[0] == scoreByPlayer[1] {
            return turkish ? "🤝 Berabere!" : "🤝 It's a Tie!"
        }
        let winnerIndex = scoreByPlayer[0] > scoreByPlayer[1] ? 0 : 1
        let name = playerName(winnerIndex, locale: locale)
        return turkish ? "🏆 \(name) Kazandı!" : "🏆 \(name) Won!"
    }

    /// Videoya yakılan bitiş kartı için tek/iki kişilik oturuma göre skor özeti.
    static func predictionResultOverlayText(scoreByPlayer: [Int], total: Int, locale: Locale) -> String {
        guard scoreByPlayer.count >= 2 else {
            return scoreSummary(score: scoreByPlayer.first ?? 0, total: total, locale: locale)
        }
        let turkish = isTurkish(locale)
        let scoresLine = turkish
            ? "Oyuncu 1: \(scoreByPlayer[0])/\(total) • Oyuncu 2: \(scoreByPlayer[1])/\(total)"
            : "Player 1: \(scoreByPlayer[0])/\(total) • Player 2: \(scoreByPlayer[1])/\(total)"
        return "\(scoresLine)\n\(predictionWinnerText(scoreByPlayer: scoreByPlayer, locale: locale))"
    }

    /// `PlayHistoryStore` kaydı için tek satırlık özet — video kartındaki
    /// (`predictionResultOverlayText`) satır sonu burada YOK, geçmiş listesinde tek satır olarak görünsün diye.
    static func predictionHistorySummary(scoreByPlayer: [Int], total: Int, locale: Locale) -> String {
        guard scoreByPlayer.count >= 2 else {
            return scoreSummary(score: scoreByPlayer.first ?? 0, total: total, locale: locale)
        }
        let turkish = isTurkish(locale)
        let scoresLine = turkish
            ? "Oyuncu 1: \(scoreByPlayer[0])/\(total) • Oyuncu 2: \(scoreByPlayer[1])/\(total)"
            : "Player 1: \(scoreByPlayer[0])/\(total) • Player 2: \(scoreByPlayer[1])/\(total)"
        return "\(scoresLine) — \(predictionWinnerText(scoreByPlayer: scoreByPlayer, locale: locale))"
    }

    static func thisOrThatTimeoutLabel(locale: Locale) -> String {
        isTurkish(locale) ? "⏱️ Süre doldu" : "⏱️ Time's up"
    }

    static func thisOrThatEmptyResultSummary(locale: Locale) -> String {
        isTurkish(locale) ? "Kimse seçim yapmadı" : "No picks were made"
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

    static func streakLabel(days: Int, locale: Locale) -> String {
        isTurkish(locale) ? "\(days) gündür oynuyorsun!" : "\(days)-day streak!"
    }

    static func exportErrorMessage(locale: Locale) -> String {
        isTurkish(locale)
            ? "Video işlenirken bir sorun oluştu. Lütfen tekrar dene."
            : "Something went wrong while preparing the video. Please try again."
    }
}
