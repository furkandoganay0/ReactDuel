import Foundation

/// "Tahmin Et" modu için tek bir içerik paketi (örn. "Futbolcuyu Tahmin Et").
/// Bundled JSON'dan (`content_tr.json` / `content_en.json`) decode edilir —
/// bkz. `ContentLoader`. Bu, veri/içerik olduğu için String Catalog'a değil,
/// dile göre ayrı JSON dosyalarına gider (playbook Bölüm 2, dual-track localization).
struct PredictionTemplate: Codable, Identifiable, Hashable {
    let id: String
    let mode: String
    let title: String
    let coverImage: String
    let questions: [PredictionQuestion]
}

struct PredictionQuestion: Codable, Identifiable, Hashable {
    let id: String
    let prompt: String
    let answer: String
    let answerImage: String
    let timerSeconds: Int
    /// Doğru cevap dahil, ekranda dokunmalı buton olarak gösterilecek şıklar.
    /// Sırası önemli değil — runtime'da `PredictionTimerStateMachine` karıştırıyor.
    let choices: [String]
}
