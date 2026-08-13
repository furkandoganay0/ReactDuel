import Foundation

/// "Bu mu O mu" modu için tek bir içerik paketi. `PredictionTemplate`'in aksine
/// doğru/yanlış yok — tercih/reaksiyon odaklı, hızlı ikili seçim formatı
/// (içerik üreticileri için: "would-you-rather" tarzı, düşünmeden tepki verilen
/// kısa video formatı).
struct ThisOrThatTemplate: Codable, Identifiable, Hashable {
    let id: String
    let mode: String
    let title: String
    let coverImage: String
    let rounds: [ThisOrThatRound]
}

struct ThisOrThatRound: Codable, Identifiable, Hashable {
    let id: String
    let optionA: String
    let optionB: String
    let timerSeconds: Int
}
