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

    @Test("updatePredictionPack aynı id ile içeriği yerinde değiştirir, konumu korur")
    func updatePredictionPackReplacesInPlace() {
        let store = UserContentStore(baseDirectory: makeTempDirectory())
        let question = PredictionQuestion(id: "q1", prompt: "p", answer: "a", answerImage: "", timerSeconds: 6, choices: ["a", "b", "c", "d"])
        let other = store.addPredictionPack(title: "Diğer", questions: [question])
        let pack = store.addPredictionPack(title: "Orijinal", questions: [question])

        let updatedQuestion = PredictionQuestion(id: "q1", prompt: "yeni soru", answer: "x", answerImage: "", timerSeconds: 6, choices: ["x", "y", "z", "w"])
        store.updatePredictionPack(id: pack.id, title: "Güncellenmiş", questions: [updatedQuestion])

        #expect(store.predictionPacks.map(\.title) == ["Güncellenmiş", "Diğer"])
        #expect(store.predictionPacks.first?.id == pack.id)
        #expect(store.predictionPacks.first?.questions.first?.prompt == "yeni soru")
        #expect(other.title == "Diğer")
    }

    @Test("updateDraftPack ve updateThisOrThatPack de yerinde günceller")
    func updateDraftAndThisOrThatPacksReplaceInPlace() {
        let store = UserContentStore(baseDirectory: makeTempDirectory())
        let item = DraftPoolItem(id: "p1", name: "A", cost: 5, image: "")
        let round = ThisOrThatRound(id: "r1", optionA: "A", optionB: "B", timerSeconds: 5)
        let draftPack = store.addDraftPack(title: "Draft", budget: 20, rosterSize: 5, pool: [item])
        let totPack = store.addThisOrThatPack(title: "TOT", rounds: [round])

        let newItem = DraftPoolItem(id: "p2", name: "B", cost: 8, image: "")
        store.updateDraftPack(id: draftPack.id, title: "Draft v2", budget: 25, rosterSize: 4, pool: [newItem])
        let newRound = ThisOrThatRound(id: "r2", optionA: "C", optionB: "D", timerSeconds: 5)
        store.updateThisOrThatPack(id: totPack.id, title: "TOT v2", rounds: [newRound])

        #expect(store.draftPacks.first?.id == draftPack.id)
        #expect(store.draftPacks.first?.title == "Draft v2")
        #expect(store.draftPacks.first?.budget == 25)
        #expect(store.thisOrThatPacks.first?.id == totPack.id)
        #expect(store.thisOrThatPacks.first?.title == "TOT v2")
    }
}
