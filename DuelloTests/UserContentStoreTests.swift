import Testing
import Foundation
@testable import Duello

@Suite("UserContentStore")
struct UserContentStoreTests {
    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Yeni oluşturulan store boş başlar")
    func newStoreStartsEmpty() {
        let store = UserContentStore(baseDirectory: makeTempDirectory())
        #expect(store.predictionPacks.isEmpty)
        #expect(store.draftPacks.isEmpty)
        #expect(store.thisOrThatPacks.isEmpty)
    }

    @Test("addPredictionPack en yeni paketi listenin başına ekler ve id'ye 'user-' öneki verir")
    func addPredictionPackInsertsAtFrontWithUserPrefix() {
        let store = UserContentStore(baseDirectory: makeTempDirectory())
        let question = PredictionQuestion(id: "q1", prompt: "p", answer: "a", answerImage: "", timerSeconds: 6, choices: ["a", "b", "c", "d"])
        store.addPredictionPack(title: "İlk", questions: [question])
        let pack = store.addPredictionPack(title: "İkinci", questions: [question])

        #expect(store.predictionPacks.map(\.title) == ["İkinci", "İlk"])
        #expect(pack.id.hasPrefix(UserContentStore.userPackIDPrefix))
        #expect(UserContentStore.isUserPack(id: pack.id))
    }

    @Test("isUserPack bundled paket id'leri için false döner")
    func isUserPackFalseForBundledIDs() {
        #expect(UserContentStore.isUserPack(id: "footballer-guess-1") == false)
    }

    @Test("addDraftPack ve addThisOrThatPack de listeye ekler")
    func addDraftAndThisOrThatPacksInsert() {
        let store = UserContentStore(baseDirectory: makeTempDirectory())
        let item = DraftPoolItem(id: "p1", name: "A", cost: 5, image: "")
        let round = ThisOrThatRound(id: "r1", optionA: "A", optionB: "B", timerSeconds: 5)

        let draftPack = store.addDraftPack(title: "Draft", budget: 20, rosterSize: 5, pool: [item])
        let totPack = store.addThisOrThatPack(title: "TOT", rounds: [round])

        #expect(store.draftPacks.map(\.id) == [draftPack.id])
        #expect(store.thisOrThatPacks.map(\.id) == [totPack.id])
    }

    @Test("delete metodları ilgili paketi listeden çıkarır")
    func deleteRemovesFromList() {
        let store = UserContentStore(baseDirectory: makeTempDirectory())
        let question = PredictionQuestion(id: "q1", prompt: "p", answer: "a", answerImage: "", timerSeconds: 6, choices: ["a", "b", "c", "d"])
        let pack = store.addPredictionPack(title: "Test", questions: [question])

        store.deletePredictionPack(pack)

        #expect(store.predictionPacks.isEmpty)
    }

    @Test("Paketler diske yazılıp aynı klasörden yeniden yüklendiğinde korunur")
    func packsPersistAcrossStoreInstances() {
        let directory = makeTempDirectory()
        let question = PredictionQuestion(id: "q1", prompt: "p", answer: "a", answerImage: "", timerSeconds: 6, choices: ["a", "b", "c", "d"])

        let firstStore = UserContentStore(baseDirectory: directory)
        firstStore.addPredictionPack(title: "Kalıcı Test", questions: [question])

        let secondStore = UserContentStore(baseDirectory: directory)
        #expect(secondStore.predictionPacks.map(\.title) == ["Kalıcı Test"])
    }
}
