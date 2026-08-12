import SwiftUI

/// Kullanıcının uygulama içi dil tercihi. `.system` cihazın dilini takip eder
/// (önceki davranışla birebir aynı); `.tr`/`.en` sistemi geçersiz kılar —
/// hem statik UI metinlerini (`Localizable.xcstrings` + `.environment(\.locale)`)
/// hem de içerik JSON'unu (`ContentLoader`) etkiler.
enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case system
    case tr
    case en

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .system: return "Sistem"
        case .tr: return "Türkçe"
        case .en: return "English"
        }
    }

    /// `nil` ise environment'ta locale hiç override edilmez — sistem dili geçerli olur.
    var localeOverride: Locale? {
        switch self {
        case .system: return nil
        case .tr: return Locale(identifier: "tr")
        case .en: return Locale(identifier: "en")
        }
    }

    /// `ContentLoader` için içerik JSON'unun hangi dilde yükleneceği.
    var contentLanguageCode: String {
        switch self {
        case .system: return ContentLoader.preferredSupportedLanguageCode()
        case .tr: return "tr"
        case .en: return "en"
        }
    }

    /// `L10n` gibi manuel (String Catalog kullanmayan) yerelleştirme yardımcıları
    /// için "tr" mi "en" mi olduğunu döner — `.system`'de gerçek sistem diline bakar.
    var resolvedIsTurkish: Bool {
        switch self {
        case .system: return ContentLoader.preferredSupportedLanguageCode() == "tr"
        case .tr: return true
        case .en: return false
        }
    }
}
