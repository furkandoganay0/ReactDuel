import Foundation

/// Sadece `Bundle(for:)` çağrısı için var olan, dışarıya hiç sızmayan bir işaretçi.
/// `Bundle.main`, DuelloTests hedefinde (host app olmadan çalıştırılırsa) test
/// runner'ın bundle'ını döner, Duello.app'inkini DEĞİL — bu yüzden içerik
/// yüklerken `.main` yerine "bu sınıfın derlendiği bundle" kullanılıyor. Bu,
/// hem gerçek uygulamada hem testlerde (DuelloTests → Duello hedefine
/// `dependencies` ile bağlı, aynı proje içinde host app olarak XcodeGen
/// tarafından otomatik kablolanır) doğru bundle'ı verir. Yine de ilk gerçek
/// Xcode açılışında DuelloTests hedefinin "Host Application"ının Duello
/// olduğunu doğrula (bkz. NOTES.md).
private final class DuelloBundleMarker {}

extension Bundle {
    static var duelloModule: Bundle { Bundle(for: DuelloBundleMarker.self) }
}

/// Bundle'daki bir `content_<dil>.json` dosyasının tamamı.
struct ContentCatalog: Codable {
    let predictionPacks: [PredictionTemplate]
    let draftPacks: [DraftTemplate]
    let thisOrThatPacks: [ThisOrThatTemplate]

    static let empty = ContentCatalog(predictionPacks: [], draftPacks: [], thisOrThatPacks: [])
}

/// Bundled, dile göre ayrılmış içerik JSON'larını yükler.
///
/// Bu, playbook Bölüm 2'deki "iki katmanlı yerelleştirme" prensibinin veri
/// tarafı: statik arayüz metni String Catalog'da, soru/ipucu/kategori içeriği
/// burada — çünkü içerik statik UI metni değil, veri.
enum ContentLoader {
    /// Desteklenen dil kodları — yeni bir dil eklerken hem burayı hem
    /// `content_<kod>.json` dosyasını eklemek gerekir.
    static let supportedLanguageCodes = ["tr", "en"]

    /// `Locale.preferredLanguages` destekleniyorsa onu, yoksa İngilizce'yi döndürür.
    static func preferredSupportedLanguageCode() -> String {
        for preferred in Locale.preferredLanguages {
            let code = Locale(identifier: preferred).language.languageCode?.identifier ?? ""
            if supportedLanguageCodes.contains(code) {
                return code
            }
        }
        return "en"
    }

    static func loadCatalog(languageCode: String? = nil, bundle: Bundle = .duelloModule) -> ContentCatalog {
        let code = languageCode ?? preferredSupportedLanguageCode()
        let fileName = "content_\(code)"

        let url = bundle.url(forResource: fileName, withExtension: "json", subdirectory: "Content")
            ?? bundle.url(forResource: fileName, withExtension: "json")

        guard let url else {
            assertionFailure("İçerik dosyası bulunamadı: \(fileName).json — bundle'a eklendiğinden emin ol.")
            return .empty
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(ContentCatalog.self, from: data)
        } catch {
            assertionFailure("İçerik decode hatası (\(fileName).json): \(error)")
            return .empty
        }
    }
}
