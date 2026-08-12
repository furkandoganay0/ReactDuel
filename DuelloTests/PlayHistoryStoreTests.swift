import Testing
import Foundation
@testable import Duello

@Suite("PlayHistoryStore")
struct PlayHistoryStoreTests {
    /// Her test kendi geçici klasöründe çalışır — gerçek Application Support'a
    /// hiç dokunulmaz, testler arası sızıntı olmaz.
    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Yeni oluşturulan store boş başlar")
    func newStoreStartsEmpty() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        #expect(store.records.isEmpty)
    }

    @Test("addRecord en yeni kaydı listenin başına ekler")
    func addRecordInsertsAtFront() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        store.addRecord(mode: .prediction, packTitle: "İlk", resultSummary: "3/5")
        store.addRecord(mode: .draft, packTitle: "İkinci", resultSummary: "Oyuncu 1 Kazandı!")
        #expect(store.records.map(\.packTitle) == ["İkinci", "İlk"])
    }

    @Test("Yeni bir kayıt varsayılan olarak video içermez")
    func newRecordHasNoVideoByDefault() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let record = store.addRecord(mode: .prediction, packTitle: "Test", resultSummary: "3/5")
        #expect(record.savedVideoFileName == nil)
    }

    @Test("attachSavedVideo doğru kayda video dosya adını iliştirir")
    func attachSavedVideoUpdatesCorrectRecord() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let record = store.addRecord(mode: .prediction, packTitle: "Test", resultSummary: "3/5")
        store.attachSavedVideo(to: record.id, fileName: "abc.mp4")
        #expect(store.records.first?.savedVideoFileName == "abc.mp4")
    }

    @Test("deleteRecord kaydı listeden çıkarır")
    func deleteRecordRemovesFromList() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let record = store.addRecord(mode: .prediction, packTitle: "Test", resultSummary: "3/5")
        store.deleteRecord(record)
        #expect(store.records.isEmpty)
    }

    @Test("Kayıtlar diske yazılıp aynı klasörden yeniden yüklendiğinde korunur")
    func recordsPersistAcrossStoreInstances() {
        let directory = makeTempDirectory()
        let firstStore = PlayHistoryStore(baseDirectory: directory)
        firstStore.addRecord(mode: .draft, packTitle: "Kalıcı Test", resultSummary: "Berabere!")

        let secondStore = PlayHistoryStore(baseDirectory: directory)
        #expect(secondStore.records.map(\.packTitle) == ["Kalıcı Test"])
    }
}
