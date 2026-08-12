import Foundation

enum PredictionPhase: Equatable {
    case prompt
    case reveal
    case finished
}

struct PredictionState: Equatable {
    var questionIndex: Int
    var phase: PredictionPhase
    var secondsRemaining: Int
    /// Aktif sorunun, dokunmalı buton olarak gösterilecek karıştırılmış şıkları.
    var shuffledChoices: [String] = []
    /// Kullanıcının seçtiği şıkkın `shuffledChoices` içindeki index'i. `nil` ise
    /// süre dolana kadar cevaplanmadı demektir.
    var selectedAnswerIndex: Int?
    /// Oyuncu başına doğru bilinen soru sayısı. Tek kişilik oturumda tek elemanlı
    /// (`[skor]`); iki kişilikte `[oyuncu1Skoru, oyuncu2Skoru]`.
    var scoreByPlayer: [Int] = [0]
}

/// Tahmin Et modunun soru → geri sayım → reveal → sıradaki soru akışı.
/// Tamamen saf: `Timer`/Combine'a hiç dokunmaz. View katmanı her saniye
/// `tick(state:template:)` çağırır, dönen yeni state'i gösterir. Bu ayrım
/// sayesinde tüm geçişler kamera/kayıt hiç başlamadan Swift Testing ile
/// doğrulanabiliyor (playbook Bölüm 2 — saf mantığı ayır).
///
/// Çoklu oyuncu (`playerCount == 2`): sorular oyuncular arasında sırayla
/// paylaşılır — `currentPlayerIndex(questionIndex:playerCount:)` bunu
/// `questionIndex`'ten türetir, ayrı bir "sıradaki oyuncu" state'i tutmaya
/// gerek yok.
enum PredictionTimerStateMachine {
    static func initialState(
        for template: PredictionTemplate,
        playerCount: Int = 1,
        shuffle: ([String]) -> [String] = { $0.shuffled() }
    ) -> PredictionState {
        let scores = Array(repeating: 0, count: max(playerCount, 1))
        guard let first = template.questions.first else {
            return PredictionState(questionIndex: 0, phase: .finished, secondsRemaining: 0, scoreByPlayer: scores)
        }
        return PredictionState(
            questionIndex: 0,
            phase: .prompt,
            secondsRemaining: first.timerSeconds,
            shuffledChoices: shuffle(first.choices),
            scoreByPlayer: scores
        )
    }

    /// Verilen soru index'inde sırası gelen oyuncunun (0 tabanlı) index'i.
    /// Tek kişilik oturumda her zaman 0.
    static func currentPlayerIndex(questionIndex: Int, playerCount: Int) -> Int {
        guard playerCount > 1 else { return 0 }
        return questionIndex % playerCount
    }

    /// Bir saniye ilerlet. `revealDurationSeconds`: cevabın ekranda kalma süresi.
    static func tick(
        state: PredictionState,
        template: PredictionTemplate,
        revealDurationSeconds: Int = 3,
        shuffle: ([String]) -> [String] = { $0.shuffled() }
    ) -> PredictionState {
        switch state.phase {
        case .finished:
            return state

        case .prompt:
            if state.secondsRemaining > 1 {
                var next = state
                next.secondsRemaining -= 1
                return next
            }
            // Süre bitti, kullanıcı cevaplamadı — selectedAnswerIndex nil kalır.
            var next = state
            next.phase = .reveal
            next.secondsRemaining = revealDurationSeconds
            return next

        case .reveal:
            if state.secondsRemaining > 1 {
                var next = state
                next.secondsRemaining -= 1
                return next
            }
            let nextIndex = state.questionIndex + 1
            guard nextIndex < template.questions.count else {
                return PredictionState(
                    questionIndex: nextIndex,
                    phase: .finished,
                    secondsRemaining: 0,
                    shuffledChoices: [],
                    selectedAnswerIndex: nil,
                    scoreByPlayer: state.scoreByPlayer
                )
            }
            let nextQuestion = template.questions[nextIndex]
            return PredictionState(
                questionIndex: nextIndex,
                phase: .prompt,
                secondsRemaining: nextQuestion.timerSeconds,
                shuffledChoices: shuffle(nextQuestion.choices),
                selectedAnswerIndex: nil,
                scoreByPlayer: state.scoreByPlayer
            )
        }
    }

    /// Kullanıcı bir şıkka dokunduğunda çağrılır — anında reveal fazına geçer
    /// (süre dolmasını beklemez), doğruysa o anki sorunun sahibi oyuncunun skorunu artırır.
    static func select(
        answerIndex: Int,
        state: PredictionState,
        template: PredictionTemplate,
        playerCount: Int = 1,
        revealDurationSeconds: Int = 3
    ) -> PredictionState {
        guard state.phase == .prompt,
              state.selectedAnswerIndex == nil,
              state.questionIndex < template.questions.count,
              state.shuffledChoices.indices.contains(answerIndex)
        else { return state }

        let question = template.questions[state.questionIndex]
        let isCorrect = state.shuffledChoices[answerIndex] == question.answer

        var next = state
        next.phase = .reveal
        next.secondsRemaining = revealDurationSeconds
        next.selectedAnswerIndex = answerIndex
        if isCorrect {
            let playerIndex = currentPlayerIndex(questionIndex: state.questionIndex, playerCount: playerCount)
            if next.scoreByPlayer.indices.contains(playerIndex) {
                next.scoreByPlayer[playerIndex] += 1
            }
        }
        return next
    }

    /// Kaydın tamamı için toplam saniye — kayıt süresi tahmini/UI'da ilerleme çubuğu için.
    static func totalDurationSeconds(for template: PredictionTemplate, revealDurationSeconds: Int = 3) -> Int {
        template.questions.reduce(0) { $0 + $1.timerSeconds + revealDurationSeconds }
    }
}
