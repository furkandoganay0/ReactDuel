import Foundation

/// Kullanıcının uygulama içinden kendi yazdığı paketler — bundled `content_<dil>.json`'un
/// aksine tek dilli (kullanıcı ne yazdıysa o) ve cihazda JSON dosyası olarak saklanır,
/// `PlayHistoryStore` ile aynı kalıcılık deseni (bkz. o dosyadaki yorumlar).
/// Paket id'leri "user-" öneki taşır — `CategorySelectionView` bununla bundled/kullanıcı
/// paketlerini ayırt edip sadece kullanıcı paketlerine silme seçeneği sunuyor.
private struct UserContent: Codable {
    var predictionPacks: [PredictionTemplate] = []
    var draftPacks: [DraftTemplate] = []
    var thisOrThatPacks: [ThisOrThatTemplate] = []
}

final class UserContentStore: ObservableObject {
    @Published private(set) var predictionPacks: [PredictionTemplate] = []
    @Published private(set) var draftPacks: [DraftTemplate] = []
    @Published private(set) var thisOrThatPacks: [ThisOrThatTemplate] = []

    private let fileURL: URL

    static let userPackIDPrefix = "user-"

    static func isUserPack(id: String) -> Bool {
        id.hasPrefix(userPackIDPrefix)
    }

    /// `baseDirectory` sadece testler için — bkz. `PlayHistoryStore.init`.
    init(baseDirectory: URL? = nil) {
        let supportDir = baseDirectory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDir = supportDir.appendingPathComponent("Duello", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        fileURL = appDir.appendingPathComponent("userContent.json")

        let loaded = Self.load(from: fileURL)
        predictionPacks = loaded.predictionPacks
        draftPacks = loaded.draftPacks
        thisOrThatPacks = loaded.thisOrThatPacks
    }

    @discardableResult
    func addPredictionPack(title: String, questions: [PredictionQuestion]) -> PredictionTemplate {
        let id = Self.userPackIDPrefix + UUID().uuidString
        let pack = PredictionTemplate(id: id, mode: "prediction", title: title, coverImage: id, questions: questions)
        predictionPacks.insert(pack, at: 0)
        persist()
        return pack
    }

    @discardableResult
    func addDraftPack(title: String, budget: Int, rosterSize: Int, pool: [DraftPoolItem]) -> DraftTemplate {
        let id = Self.userPackIDPrefix + UUID().uuidString
        let pack = DraftTemplate(id: id, mode: "draft", title: title, coverImage: id, budget: budget, rosterSize: rosterSize, pool: pool)
        draftPacks.insert(pack, at: 0)
        persist()
        return pack
    }

    @discardableResult
    func addThisOrThatPack(title: String, rounds: [ThisOrThatRound]) -> ThisOrThatTemplate {
        let id = Self.userPackIDPrefix + UUID().uuidString
        let pack = ThisOrThatTemplate(id: id, mode: "thisOrThat", title: title, coverImage: id, rounds: rounds)
        thisOrThatPacks.insert(pack, at: 0)
        persist()
        return pack
    }

    /// Var olan bir kullanıcı paketini YERİNDE günceller — id/coverImage aynı
    /// kalır (listede yer değiştirmez, `PlaceholderCoverView`'ın rengi bozulmaz).
    /// Önceden özel paketler sadece sil+yeniden-yaz ile değiştirilebiliyordu.
    func updatePredictionPack(id: String, title: String, questions: [PredictionQuestion]) {
        guard let index = predictionPacks.firstIndex(where: { $0.id == id }) else { return }
        predictionPacks[index] = PredictionTemplate(id: id, mode: "prediction", title: title, coverImage: id, questions: questions)
        persist()
    }

    func updateDraftPack(id: String, title: String, budget: Int, rosterSize: Int, pool: [DraftPoolItem]) {
        guard let index = draftPacks.firstIndex(where: { $0.id == id }) else { return }
        draftPacks[index] = DraftTemplate(id: id, mode: "draft", title: title, coverImage: id, budget: budget, rosterSize: rosterSize, pool: pool)
        persist()
    }

    func updateThisOrThatPack(id: String, title: String, rounds: [ThisOrThatRound]) {
        guard let index = thisOrThatPacks.firstIndex(where: { $0.id == id }) else { return }
        thisOrThatPacks[index] = ThisOrThatTemplate(id: id, mode: "thisOrThat", title: title, coverImage: id, rounds: rounds)
        persist()
    }

    func deletePredictionPack(_ pack: PredictionTemplate) {
        predictionPacks.removeAll { $0.id == pack.id }
        persist()
    }

    func deleteDraftPack(_ pack: DraftTemplate) {
        draftPacks.removeAll { $0.id == pack.id }
        persist()
    }

    func deleteThisOrThatPack(_ pack: ThisOrThatTemplate) {
        thisOrThatPacks.removeAll { $0.id == pack.id }
        persist()
    }

    private func persist() {
        let content = UserContent(predictionPacks: predictionPacks, draftPacks: draftPacks, thisOrThatPacks: thisOrThatPacks)
        guard let data = try? JSONEncoder().encode(content) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private static func load(from url: URL) -> UserContent {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(UserContent.self, from: data)
        else { return UserContent() }
        return decoded
    }
}
