import Foundation

/// Oynanan tek bir oturumun kaydı — skor/sonuç her zaman tutulur, video ise
/// SADECE kullanıcı `SaveDecisionView`'da açıkça "Kaydet" derse (`savedVideoFileName`
/// doluysa). MVP'de gerçek bir backend yok — playbook'un genel prensibiyle
/// tutarlı: JSON dosyası olarak Application Support'ta saklanıyor.
struct PlaySessionRecord: Codable, Identifiable, Equatable {
    let id: UUID
    let date: Date
    let mode: GameMode
    let packTitle: String
    let resultSummary: String
    var savedVideoFileName: String?
}

/// Hem "Geçmiş" galerisinin (kaydedilen videolar) hem skor geçmişi/serinin
/// tek gerçek kaynağı. Önceden hiçbiri yoktu — her oturum bitince video
/// otomatik export edilip kullanıcı ekrandan çıkınca kaybolup gidiyordu,
/// skor/seri hiç tutulmuyordu.
final class PlayHistoryStore: ObservableObject {
    @Published private(set) var records: [PlaySessionRecord] = []

    /// Kaydedilmesi onaylanan videoların KALICI olarak durduğu klasör —
    /// `VideoExporter`'ın çıktısı olan geçici (tmp) dosyanın aksine, sistem
    /// tarafından silinme riski yok.
    let videosDirectory: URL

    private let historyFileURL: URL

    /// `baseDirectory` sadece testler için — verilmezse gerçek Application Support
    /// kullanılır. Testler burayı geçici bir klasöre yönlendirip diskten okuma/yazmayı
    /// da (streak hesaplamasının aksine) gerçekten doğrulayabiliyor.
    init(baseDirectory: URL? = nil) {
        let supportDir = baseDirectory
            ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDir = supportDir.appendingPathComponent("Duello", isDirectory: true)
        videosDirectory = appDir.appendingPathComponent("Videos", isDirectory: true)
        historyFileURL = appDir.appendingPathComponent("history.json")

        try? FileManager.default.createDirectory(at: videosDirectory, withIntermediateDirectories: true)
        records = Self.load(from: historyFileURL)
    }

    @discardableResult
    func addRecord(mode: GameMode, packTitle: String, resultSummary: String) -> PlaySessionRecord {
        let record = PlaySessionRecord(
            id: UUID(), date: Date(), mode: mode, packTitle: packTitle, resultSummary: resultSummary, savedVideoFileName: nil
        )
        records.insert(record, at: 0)
        persist()
        return record
    }

    func attachSavedVideo(to recordID: UUID, fileName: String) {
        guard let index = records.firstIndex(where: { $0.id == recordID }) else { return }
        records[index].savedVideoFileName = fileName
        persist()
    }

    func deleteRecord(_ record: PlaySessionRecord) {
        if let fileName = record.savedVideoFileName {
            try? FileManager.default.removeItem(at: videosDirectory.appendingPathComponent(fileName))
        }
        records.removeAll { $0.id == record.id }
        persist()
    }

    /// Bugün dahil, kesintisiz kaç gündür oynandığı — Ana Ekran'daki seri rozeti için.
    var currentStreak: Int {
        HistoryStreakCalculator.streak(playDates: records.map(\.date), referenceDate: Date())
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: historyFileURL, options: .atomic)
    }

    private static func load(from url: URL) -> [PlaySessionRecord] {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([PlaySessionRecord].self, from: data)
        else { return [] }
        return decoded
    }
}
