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

    /// Paylaşılan videonun köşesindeki filigrana yazılacak, kullanıcının kendi
    /// rumuzu — boşsa varsayılan "⚡ Duello" markası kullanılır (bkz.
    /// `OverlayCompositionBuilder.makeWatermarkLayer`). İçerik üreticilerin
    /// kendi videolarını kendi hesaplarıyla imzalayabilmesi için.
    @Published var creatorHandle: String {
        didSet { UserDefaults.standard.set(creatorHandle, forKey: Self.creatorHandleKey) }
    }

    /// Tahmin Et modunda doğru/yanlış cevap için kısa ses efekti çalınsın mı —
    /// bazı kullanıcılar sessiz/sadece titreşimli tercih edebilir.
    @Published var soundEffectsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEffectsEnabled, forKey: Self.soundEffectsEnabledKey) }
    }

    @Published private(set) var catalog: ContentCatalog

    /// Export'a geçilecek gerçek filigran metni — boş/whitespace-only bir rumuz
    /// varsayılan markaya düşer, doluysa baştaki "@" garanti edilir (kullanıcı
    /// "@" eklemeyi unutsa bile).
    var resolvedWatermarkText: String {
        let trimmed = creatorHandle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "⚡ Duello" }
        return trimmed.hasPrefix("@") ? trimmed : "@\(trimmed)"
    }

    private static let onboardingKey = "duello.hasCompletedOnboarding"
    private static let languageKey = "duello.language"
    private static let appearanceKey = "duello.appearance"
    private static let creatorHandleKey = "duello.creatorHandle"
    private static let soundEffectsEnabledKey = "duello.soundEffectsEnabled"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)

        let storedLanguage = UserDefaults.standard.string(forKey: Self.languageKey)
            .flatMap(AppLanguage.init(rawValue:)) ?? .system
        language = storedLanguage

        appearance = UserDefaults.standard.string(forKey: Self.appearanceKey)
            .flatMap(AppAppearance.init(rawValue:)) ?? .system

        creatorHandle = UserDefaults.standard.string(forKey: Self.creatorHandleKey) ?? ""

        // `bool(forKey:)` hiç set edilmemişse `false` döner — varsayılan AÇIK
        // olması gerektiği için burada `object(forKey:)` ile "hiç set edilmemiş mi"
        // ayrımını yapıyoruz.
        soundEffectsEnabled = (UserDefaults.standard.object(forKey: Self.soundEffectsEnabledKey) as? Bool) ?? true

        catalog = ContentLoader.loadCatalog(languageCode: storedLanguage.contentLanguageCode)
    }
}
