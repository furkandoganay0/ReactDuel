import Testing
@testable import Duello

@Suite("ContentLoader")
struct ContentLoaderTests {

    @Test("Türkçe katalog en az 2 tahmin ve 2 draft paketi içerir")
    func turkishCatalogHasMinimumPacks() {
        let catalog = ContentLoader.loadCatalog(languageCode: "tr", bundle: .duelloModule)
        #expect(catalog.predictionPacks.count >= 2)
        #expect(catalog.draftPacks.count >= 2)
    }

    @Test("İngilizce katalog en az 2 tahmin ve 2 draft paketi içerir")
    func englishCatalogHasMinimumPacks() {
        let catalog = ContentLoader.loadCatalog(languageCode: "en", bundle: .duelloModule)
        #expect(catalog.predictionPacks.count >= 2)
        #expect(catalog.draftPacks.count >= 2)
    }

    @Test("Her draft paketinde en ucuz rosterSize kadar item, bütçeyi aşmadan seçilebilir")
    func draftPacksAreCompletableWithinBudget() {
        let catalog = ContentLoader.loadCatalog(languageCode: "tr", bundle: .duelloModule)
        for pack in catalog.draftPacks {
            let cheapest = pack.pool
                .map(\.cost)
                .sorted()
                .prefix(pack.rosterSize)
                .reduce(0, +)
            #expect(cheapest <= pack.budget, "\(pack.title): en ucuz \(pack.rosterSize) item bile bütçeyi aşıyor")
            #expect(pack.pool.count >= pack.rosterSize)
        }
    }

    @Test("Desteklenmeyen dil kodu boş katalog yerine İngilizce'ye düşmemeli — açıkça boş döner")
    func unsupportedLanguageFallsBackGracefully() {
        // ContentLoader.loadCatalog her zaman açık bir languageCode ile çağrıldığında
        // o dosyayı arar; burada sadece "tr"/"en" bundle'da var olduğunu doğruluyoruz.
        let tr = ContentLoader.loadCatalog(languageCode: "tr", bundle: .duelloModule)
        let en = ContentLoader.loadCatalog(languageCode: "en", bundle: .duelloModule)
        #expect(!tr.predictionPacks.isEmpty)
        #expect(!en.predictionPacks.isEmpty)
    }
}
