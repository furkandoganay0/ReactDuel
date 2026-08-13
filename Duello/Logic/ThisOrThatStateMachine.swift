import Foundation

enum ThisOrThatPhase: Equatable {
    case choosing
    case revealed
    case finished
}

struct ThisOrThatState: Equatable {
    var roundIndex: Int
    var phase: ThisOrThatPhase
    var secondsRemaining: Int
    /// `true` = A seçildi, `false` = B seçildi, `nil` = süre doldu, hiç seçilmedi.
    var selectedOption: Bool?
    /// Fiilen seçilen (süre dolup atlanmayan) her round'un metni, sırayla —
    /// bitişte "işte senin tercihlerin" özet şeridi için (bkz. `ThisOrThatSessionResultView`).
    /// Round'lar arasında konu değiştiği için (Pizza/Burger, Deniz/Dağ, ...) basit bir
    /// A/B sayacı anlamsız olurdu — gerçek seçilen metinleri saklamak daha anlamlı.
    var pickedLabels: [String] = []
}

/// "Bu mu O mu" modunun round → geri sayım → reveal → sıradaki round akışı.
/// `PredictionTimerStateMachine` ile aynı desen (tamamen saf, `Timer`'a hiç
/// dokunmaz) — tek fark, doğru/yanlış olmaması: her seçim eşit derecede
/// "doğru", sadece hangi seçeneğin seçildiği kaydediliyor.
enum ThisOrThatStateMachine {
    static func initialState(
        for template: ThisOrThatTemplate
    ) -> ThisOrThatState {
        guard let first = template.rounds.first else {
            return ThisOrThatState(roundIndex: 0, phase: .finished, secondsRemaining: 0)
        }
        return ThisOrThatState(roundIndex: 0, phase: .choosing, secondsRemaining: first.timerSeconds)
    }

    /// Verilen round index'inde sırası gelen oyuncunun (0 tabanlı) index'i —
    /// `PredictionTimerStateMachine.currentPlayerIndex` ile birebir aynı mantık.
    static func currentPlayerIndex(roundIndex: Int, playerCount: Int) -> Int {
        guard playerCount > 1 else { return 0 }
        return roundIndex % playerCount
    }

    static func tick(
        state: ThisOrThatState,
        template: ThisOrThatTemplate,
        revealDurationSeconds: Int = 2
    ) -> ThisOrThatState {
        switch state.phase {
        case .finished:
            return state

        case .choosing:
            if state.secondsRemaining > 1 {
                var next = state
                next.secondsRemaining -= 1
                return next
            }
            var next = state
            next.phase = .revealed
            next.secondsRemaining = revealDurationSeconds
            return next

        case .revealed:
            if state.secondsRemaining > 1 {
                var next = state
                next.secondsRemaining -= 1
                return next
            }
            let nextIndex = state.roundIndex + 1
            guard nextIndex < template.rounds.count else {
                return ThisOrThatState(
                    roundIndex: nextIndex, phase: .finished, secondsRemaining: 0,
                    selectedOption: nil, pickedLabels: state.pickedLabels
                )
            }
            let nextRound = template.rounds[nextIndex]
            return ThisOrThatState(
                roundIndex: nextIndex, phase: .choosing, secondsRemaining: nextRound.timerSeconds,
                selectedOption: nil, pickedLabels: state.pickedLabels
            )
        }
    }

    /// Kullanıcı A ya da B'ye dokunduğunda çağrılır — anında reveal fazına geçer.
    static func select(
        optionIsA: Bool,
        state: ThisOrThatState,
        template: ThisOrThatTemplate,
        revealDurationSeconds: Int = 2
    ) -> ThisOrThatState {
        guard state.phase == .choosing,
              state.selectedOption == nil,
              state.roundIndex < template.rounds.count
        else { return state }

        let round = template.rounds[state.roundIndex]
        var next = state
        next.phase = .revealed
        next.secondsRemaining = revealDurationSeconds
        next.selectedOption = optionIsA
        next.pickedLabels.append(optionIsA ? round.optionA : round.optionB)
        return next
    }

    static func totalDurationSeconds(for template: ThisOrThatTemplate, revealDurationSeconds: Int = 2) -> Int {
        template.rounds.reduce(0) { $0 + $1.timerSeconds + revealDurationSeconds }
    }
}
