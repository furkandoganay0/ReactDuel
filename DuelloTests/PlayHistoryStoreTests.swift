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
        store.addRecord(mode: .prediction, packTitle: "İlk", resultSummary: "3/5", playerCount: 1)
        store.addRecord(mode: .draft, packTitle: "İkinci", resultSummary: "Oyuncu 1 Kazandı!", playerCount: 2)
        #expect(store.records.map(\.packTitle) == ["İkinci", "İlk"])
    }

    @Test("Yeni bir kayıt varsayılan olarak video içermez")
    func newRecordHasNoVideoByDefault() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let record = store.addRecord(mode: .prediction, packTitle: "Test", resultSummary: "3/5", playerCount: 1)
        #expect(record.savedVideoFileName == nil)
    }

    @Test("addRecord verilen oyuncu sayısını kayda yazar")
    func addRecordStoresPlayerCount() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let solo = store.addRecord(mode: .prediction, packTitle: "Solo", resultSummary: "3/5", playerCount: 1)
        let duo = store.addRecord(mode: .thisOrThat, packTitle: "Duo", resultSummary: "Bitti", playerCount: 2)
        #expect(solo.playerCount == 1)
        #expect(duo.playerCount == 2)
    }

    @Test("attachSavedVideo doğru kayda video dosya adını iliştirir")
    func attachSavedVideoUpdatesCorrectRecord() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let record = store.addRecord(mode: .prediction, packTitle: "Test", resultSummary: "3/5", playerCount: 1)
        store.attachSavedVideo(to: record.id, fileName: "abc.mp4")
        #expect(store.records.first?.savedVideoFileName == "abc.mp4")
    }

    @Test("deleteRecord kaydı listeden çıkarır")
    func deleteRecordRemovesFromList() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let record = store.addRecord(mode: .prediction, packTitle: "Test", resultSummary: "3/5", playerCount: 1)
        store.deleteRecord(record)
        #expect(store.records.isEmpty)
    }

    @Test("Kayıtlar diske yazılıp aynı klasörden yeniden yüklendiğinde korunur")
    func recordsPersistAcrossStoreInstances() {
        let directory = makeTempDirectory()
        let firstStore = PlayHistoryStore(baseDirectory: directory)
        firstStore.addRecord(mode: .draft, packTitle: "Kalıcı Test", resultSummary: "Berabere!", playerCount: 2)

        let secondStore = PlayHistoryStore(baseDirectory: directory)
        #expect(secondStore.records.map(\.packTitle) == ["Kalıcı Test"])
        #expect(secondStore.records.first?.playerCount == 2)
    }

    @Test("playerCount alanı olmayan eski (diskteki) kayıtlar, moda göre makul bir varsayılanla yüklenir")
    func legacyRecordsWithoutPlayerCountDecodeWithSensibleDefault() throws {
        let directory = makeTempDirectory()
        let appDir = directory.appendingPathComponent("Duello", isDirectory: true)
        try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        // `playerCount` alanı olmadan, eski bir sürümün yazmış olabileceği JSON'u simüle eder.
        let legacyJSON = """
        [
          {
            "id": "\(UUID().uuidString)",
            "date": 700000000.0,
            "mode": "prediction",
            "packTitle": "Eski Kayıt",
            "resultSummary": "4/5"
          },
          {
            "id": "\(UUID().uuidString)",
            "date": 700000001.0,
            "mode": "draft",
            "packTitle": "Eski Draft",
            "resultSummary": "Oyuncu 2 Kazandı!"
          }
        ]
        """
        try legacyJSON.data(using: .utf8)!.write(to: appDir.appendingPathComponent("history.json"))

        let store = PlayHistoryStore(baseDirectory: directory)
        #expect(store.records.count == 2)
        #expect(store.records.first(where: { $0.packTitle == "Eski Kayıt" })?.playerCount == 1)
        #expect(store.records.first(where: { $0.packTitle == "Eski Draft" })?.playerCount == 2)
    }

    @Test("thumbnailFileName alanı olmayan eski kayıtlar nil ile yüklenir")
    func legacyRecordsWithoutThumbnailDecodeAsNil() throws {
        let directory = makeTempDirectory()
        let appDir = directory.appendingPathComponent("Duello", isDirectory: true)
        try FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)

        let legacyJSON = """
        [
          {
            "id": "\(UUID().uuidString)",
            "date": 700000000.0,
            "mode": "prediction",
            "packTitle": "Eski Kayıt",
            "resultSummary": "4/5",
            "playerCount": 1
          }
        ]
        """
        try legacyJSON.data(using: .utf8)!.write(to: appDir.appendingPathComponent("history.json"))

        let store = PlayHistoryStore(baseDirectory: directory)
        #expect(store.records.first?.thumbnailFileName == nil)
    }

    @Test("attachSavedVideo thumbnail dosya adını da iliştirir")
    func attachSavedVideoUpdatesThumbnail() {
        let store = PlayHistoryStore(baseDirectory: makeTempDirectory())
        let record = store.addRecord(mode: .prediction, packTitle: "Test", resultSummary: "3/5", playerCount: 1)
        store.attachSavedVideo(to: record.id, fileName: "abc.mp4", thumbnailFileName: "abc.jpg")
        #expect(store.records.first?.savedVideoFileName == "abc.mp4")
        #expect(store.records.first?.thumbnailFileName == "abc.jpg")
    }
}
