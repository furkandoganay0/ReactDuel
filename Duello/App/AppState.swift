import Foundation

/// Uygulama genelinde paylaşılan, kalıcılık gerektirmeyen durum. MVP'de gerçek
/// bir kullanıcı hesabı/veritabanı yok (teknik prompt Bölüm 3) — onboarding,
/// dil ve görünüm tercihi `UserDefaults`'ta tutuluyor.
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey) }
    }

    @Published var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: Self.languageKey)
            catalog = ContentLoader.loadCatalog(languageCode: language.contentLanguageCode)
        }
    }

    @Published var appearance: AppAppearance {
        didSet { UserDefaults.standard.set(appearance.rawValue, forKey: Self.appearanceKey) }
    }

    @Published private(set) var catalog: ContentCatalog

    private static let onboardingKey = "duello.hasCompletedOnboarding"
    private static let languageKey = "duello.language"
    private static let appearanceKey = "duello.appearance"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)

        let storedLanguage = UserDefaults.standard.string(forKey: Self.languageKey)
            .flatMap(AppLanguage.init(rawValue:)) ?? .system
        language = storedLanguage

        appearance = UserDefaults.standard.string(forKey: Self.appearanceKey)
            .flatMap(AppAppearance.init(rawValue:)) ?? .system

        catalog = ContentLoader.loadCatalog(languageCode: storedLanguage.contentLanguageCode)
    }
}
