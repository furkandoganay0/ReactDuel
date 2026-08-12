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
    /// Oturum boyunca doğru bilinen soru sayısı.
    var score: Int = 0
}

/// Tahmin Et modunun soru → geri sayım → reveal → sıradaki soru akışı.
/// Tamamen saf: `Timer`/Combine'a hiç dokunmaz. View katmanı her saniye
/// `tick(state:template:)` çağırır, dönen yeni state'i gösterir. Bu ayrım
/// sayesinde tüm geçişler kamera/kayıt hiç başlamadan Swift Testing ile
/// doğrulanabiliyor (playbook Bölüm 2 — saf mantığı ayır).
enum PredictionTimerStateMachine {
    static func initialState(
        for template: PredictionTemplate,
        shuffle: ([String]) -> [String] = { $0.shuffled() }
    ) -> PredictionState {
        guard let first = template.questions.first else {
            return PredictionState(questionIndex: 0, phase: .finished, secondsRemaining: 0)
        }
        return PredictionState(
            questionIndex: 0,
            phase: .prompt,
            secondsRemaining: first.timerSeconds,
            shuffledChoices: shuffle(first.choices)
        )
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
                    score: state.score
                )
            }
            let nextQuestion = template.questions[nextIndex]
            return PredictionState(
                questionIndex: nextIndex,
                phase: .prompt,
                secondsRemaining: nextQuestion.timerSeconds,
                shuffledChoices: shuffle(nextQuestion.choices),
                selectedAnswerIndex: nil,
                score: state.score
            )
        }
    }

    /// Kullanıcı bir şıkka dokunduğunda çağrılır — anında reveal fazına geçer
    /// (süre dolmasını beklemez), doğruysa skoru artırır.
    static func select(
        answerIndex: Int,
        state: PredictionState,
        template: PredictionTemplate,
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
        next.score = state.score + (isCorrect ? 1 : 0)
        return next
    }

    /// Kaydın tamamı için toplam saniye — kayıt süresi tahmini/UI'da ilerleme çubuğu için.
    static func totalDurationSeconds(for template: PredictionTemplate, revealDurationSeconds: Int = 3) -> Int {
        template.questions.reduce(0) { $0 + $1.timerSeconds + revealDurationSeconds }
    }
}
