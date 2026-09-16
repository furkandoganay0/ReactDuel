import SwiftUI

/// Kullanıcının uygulama içi dil tercihi. `.system` cihazın dilini takip eder
/// (önceki davranışla birebir aynı); diğerleri sistemi geçersiz kılar — hem
/// statik UI metinlerini (`Localizable.xcstrings` + `.environment(\.locale)`)
/// hem de içerik JSON'unu (`ContentLoader`) etkiler.
///
/// `.tr`/`.en` dışındaki 6 dil (dünyada internette en çok kullanılan diller —
/// İspanyolca, Fransızca, Portekizce, Basitleştirilmiş Çince, Hintçe, Arapça)
/// v1.1'de eklendi: STATİK arayüz metni (bu dosyanın kapsadığı) tamamen bu
/// dillerde, ama SORU/İÇERİK PAKETLERİ (`ContentLoader`) ve `L10n`'un
/// runtime'da hesapladığı dinamik metinler (skor, oyuncu sırası vb.) henüz
/// sadece tr/en'de var — bu yüzden `contentLanguageCode`/`resolvedIsTurkish`
/// bu 6 dil için İngilizce'ye düşüyor (bkz. ilgili yorumlar). Trivia içeriğini
/// gerçek anlamda doğru/doğal çevirmek (ör. Çince'de bir futbolcu ipucunun
/// okunması) ayrı, kapsamlı bir iş — bu yüzden şimdilik kapsam dışı bırakıldı.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case tr
    case en
    case es
    case fr
    case pt
    case zhHans
    case hi
    case ar

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: return "Sistem"
        case .tr: return "Türkçe"
        case .en: return "English"
        case .es: return "Español"
        case .fr: return "Français"
        case .pt: return "Português"
        case .zhHans: return "中文（简体）"
        case .hi: return "हिन्दी"
        case .ar: return "العربية"
        }
    }

    /// `nil` ise environment'ta locale hiç override edilmez — sistem dili geçerli olur.
    var localeOverride: Locale? {
        switch self {
        case .system: return nil
        case .tr: return Locale(identifier: "tr")
        case .en: return Locale(identifier: "en")
        case .es: return Locale(identifier: "es")
        case .fr: return Locale(identifier: "fr")
        case .pt: return Locale(identifier: "pt")
        case .zhHans: return Locale(identifier: "zh-Hans")
        case .hi: return Locale(identifier: "hi")
        case .ar: return Locale(identifier: "ar")
        }
    }

    /// `ContentLoader` için içerik JSON'unun hangi dilde yükleneceği. Sadece
    /// tr/en gerçek içerik dosyasına sahip (bkz. `ContentLoader.supportedLanguageCodes`) —
    /// diğer 6 dilde soru paketleri İngilizce olarak yüklenir (dosya başı yorum).
    var contentLanguageCode: String {
        switch self {
        case .system: return ContentLoader.preferredSupportedLanguageCode()
        case .tr: return "tr"
        case .en, .es, .fr, .pt, .zhHans, .hi, .ar: return "en"
        }
    }

    /// `L10n` gibi manuel (String Catalog kullanmayan) yerelleştirme yardımcıları
    /// için "tr" mi "en" mi olduğunu döner — `.system`'de gerçek sistem diline bakar.
    /// Yeni 6 dilin hiçbiri henüz `L10n`'da desteklenmiyor, o yüzden İngilizce'ye düşer.
    var resolvedIsTurkish: Bool {
        switch self {
        case .system: return ContentLoader.preferredSupportedLanguageCode() == "tr"
        case .tr: return true
        case .en, .es, .fr, .pt, .zhHans, .hi, .ar: return false
        }
    }

    /// Sadece Arapça için `true` — `RootView` bunu görüp arayüzü sağdan sola
    /// çevirir (`.environment(\.layoutDirection, .rightToLeft)`). `.environment(\.locale)`
    /// override'ı TEK BAŞINA layout yönünü değiştirmez, cihazın kendi sistem
    /// dili/bölgesini takip eder — uygulama içi dil seçici sistemden bağımsız
    /// olduğu için bunu elle yapmak gerekiyor.
    var isRightToLeft: Bool {
        self == .ar
    }
}
