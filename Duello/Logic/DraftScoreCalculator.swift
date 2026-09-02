import Foundation

enum DraftPlayer: String, Codable, Hashable {
    case playerA
    case playerB
}

enum DraftResult: Hashable {
    case winner(DraftPlayer)
    case tie
}

/// Saf, View/SwiftData'dan bağımsız skor mantığı — playbook Bölüm 2
/// ("Saf, test edilebilir mantığı ayır") prensibiyle `StreakCalculator` deseninin
/// aynısı. Swift Testing ile doğrudan test edilir, kamera/UI hiç devreye girmez.
enum DraftScoreCalculator {
    static func totalCost(of roster: [DraftPoolItem]) -> Int {
        roster.reduce(0) { $0 + $1.cost }
    }

    /// v1 kuralı bilinçli olarak basit: toplam cost'u yüksek olan roster kazanır.
    /// Bu, "en pahalı ismi mi topladın yoksa bütçeyi en akıllı mı kullandın" tartışmasını
    /// kışkırtır — paylaşım/yorum tetiklemesi ürün açısından istenen bir yan etki.
    static func winner(rosterA: [DraftPoolItem], rosterB: [DraftPoolItem]) -> DraftResult {
        let scoreA = totalCost(of: rosterA)
        let scoreB = totalCost(of: rosterB)
        if scoreA == scoreB { return .tie }
        return scoreA > scoreB ? .winner(.playerA) : .winner(.playerB)
    }
}
