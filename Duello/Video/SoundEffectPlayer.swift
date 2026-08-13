import AudioToolbox

/// Tahmin Et modunda doğru/yanlış cevap için kısa sistem sesi çalar.
///
/// NOT: Bunlar özel olarak kaydedilmiş/lisanslı ses dosyaları DEĞİL — iOS'in
/// kendi dahili "UI sesleri" seti içinden, yaygın olarak "doğru/yanlış" hissi
/// veren iki ID (`AudioServicesPlaySystemSound`, dosya bundle etmeden çalışır).
/// Bu ID'ler Apple tarafından resmi olarak belgelenmemiş, bilinen bir developer
/// pratiği — ileride markaya özel gerçek ses efektleri eklenecekse burası
/// değiştirilecek tek yer.
enum SoundEffectPlayer {
    private static let correctSoundID: SystemSoundID = 1025
    private static let wrongSoundID: SystemSoundID = 1053

    static func playCorrect() {
        AudioServicesPlaySystemSound(correctSoundID)
    }

    static func playWrong() {
        AudioServicesPlaySystemSound(wrongSoundID)
    }
}
