import Foundation

/// "Bütçeli Draft" modu için tek bir içerik paketi (örn. "Film Draftı").
struct DraftTemplate: Codable, Identifiable, Hashable {
    let id: String
    let mode: String
    let title: String
    let coverImage: String
    let budget: Int
    let rosterSize: Int
    let pool: [DraftPoolItem]
}

/// Draft havuzundaki tek bir seçilebilir item.
/// `cost` MVP'de elle küratörlü bir tam sayı — otomatik/piyasa-verisine-dayalı
/// fiyatlandırma v2 kapsamında (bkz. teknik prompt Bölüm 8).
struct DraftPoolItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let cost: Int
    let image: String
}
