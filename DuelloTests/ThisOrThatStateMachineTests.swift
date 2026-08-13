import Testing
@testable import Duello

@Suite("ThisOrThatStateMachine")
struct ThisOrThatStateMachineTests {

    private func round(_ id: String, seconds: Int) -> ThisOrThatRound {
        ThisOrThatRound(id: id, optionA: "A-\(id)", optionB: "B-\(id)", timerSeconds: seconds)
    }

    private func template(_ rounds: [ThisOrThatRound]) -> ThisOrThatTemplate {
        ThisOrThatTemplate(id: "t1", mode: "thisOrThat", title: "Test", coverImage: "cover", rounds: rounds)
    }

    @Test("Başlangıç durumu ilk round'un timerSeconds'ıyla choosing fazında başlar")
    func initialStateStartsAtFirstRound() {
        let t = template([round("r1", seconds: 5), round("r2", seconds: 4)])
        let state = ThisOrThatStateMachine.initialState(for: t)
        #expect(state.roundIndex == 0)
        #expect(state.phase == .choosing)
        #expect(state.secondsRemaining == 5)
        #expect(state.pickedLabels.isEmpty)
    }

    @Test("Round'u olmayan şablon direkt finished döner")
    func emptyTemplateFinishesImmediately() {
        let state = ThisOrThatStateMachine.initialState(for: template([]))
        #expect(state.phase == .finished)
    }

    @Test("choosing fazında her tick süreyi bir azaltır")
    func tickDecrementsChoosingCountdown() {
        let t = template([round("r1", seconds: 3)])
        var state = ThisOrThatStateMachine.initialState(for: t)
        state = ThisOrThatStateMachine.tick(state: state, template: t)
        #expect(state.phase == .choosing)
        #expect(state.secondsRemaining == 2)
    }

    @Test("Süre bitince cevapsız revealed fazına geçer, pickedLabels'a bir şey eklenmez")
    func timeoutRevealsWithoutSelection() {
        let t = template([round("r1", seconds: 1)])
        var state = ThisOrThatStateMachine.initialState(for: t)
        state = ThisOrThatStateMachine.tick(state: state, template: t, revealDurationSeconds: 2)
        #expect(state.phase == .revealed)
        #expect(state.selectedOption == nil)
        #expect(state.pickedLabels.isEmpty)
    }

    @Test("A seçmek anında revealed'a geçer ve A'nın metnini pickedLabels'a ekler")
    func selectingAAdvancesAndRecordsLabel() {
        let t = template([round("r1", seconds: 5)])
        let state = ThisOrThatStateMachine.initialState(for: t)
        let next = ThisOrThatStateMachine.select(optionIsA: true, state: state, template: t, revealDurationSeconds: 2)
        #expect(next.phase == .revealed)
        #expect(next.selectedOption == true)
        #expect(next.pickedLabels == ["A-r1"])
        #expect(next.secondsRemaining == 2)
    }

    @Test("B seçmek B'nin metnini pickedLabels'a ekler")
    func selectingBRecordsLabel() {
        let t = template([round("r1", seconds: 5)])
        let state = ThisOrThatStateMachine.initialState(for: t)
        let next = ThisOrThatStateMachine.select(optionIsA: false, state: state, template: t)
        #expect(next.selectedOption == false)
        #expect(next.pickedLabels == ["B-r1"])
    }

    @Test("revealed fazındayken select çağırmak state'i değiştirmez")
    func selectIgnoredOutsideChoosingPhase() {
        let t = template([round("r1", seconds: 5)])
        let revealed = ThisOrThatState(roundIndex: 0, phase: .revealed, secondsRemaining: 2)
        let next = ThisOrThatStateMachine.select(optionIsA: true, state: revealed, template: t)
        #expect(next == revealed)
    }

    @Test("Reveal bitince sıradaki round'a geçer, pickedLabels korunur")
    func revealTransitionsToNextRoundPreservingLabels() {
        let t = template([round("r1", seconds: 1), round("r2", seconds: 4)])
        let state = ThisOrThatState(roundIndex: 0, phase: .revealed, secondsRemaining: 1, selectedOption: true, pickedLabels: ["A-r1"])
        let next = ThisOrThatStateMachine.tick(state: state, template: t)
        #expect(next.phase == .choosing)
        #expect(next.roundIndex == 1)
        #expect(next.secondsRemaining == 4)
        #expect(next.selectedOption == nil)
        #expect(next.pickedLabels == ["A-r1"])
    }

    @Test("Son round'un reveal'ı bitince finished'e geçer, pickedLabels korunur")
    func lastRoundRevealFinishesPreservingLabels() {
        let t = template([round("r1", seconds: 1)])
        let state = ThisOrThatState(roundIndex: 0, phase: .revealed, secondsRemaining: 1, selectedOption: false, pickedLabels: ["B-r1"])
        let next = ThisOrThatStateMachine.tick(state: state, template: t)
        #expect(next.phase == .finished)
        #expect(next.pickedLabels == ["B-r1"])
    }

    @Test("finished durumunda tick çağırmak durumu değiştirmez (idempotent)")
    func finishedStateIsStable() {
        let t = template([round("r1", seconds: 1)])
        let finished = ThisOrThatState(roundIndex: 1, phase: .finished, secondsRemaining: 0)
        let next = ThisOrThatStateMachine.tick(state: finished, template: t)
        #expect(next == finished)
    }

    @Test("currentPlayerIndex tek kişilik oturumda her zaman 0 döner")
    func currentPlayerIndexAlwaysZeroForSolo() {
        #expect(ThisOrThatStateMachine.currentPlayerIndex(roundIndex: 0, playerCount: 1) == 0)
        #expect(ThisOrThatStateMachine.currentPlayerIndex(roundIndex: 4, playerCount: 1) == 0)
    }

    @Test("currentPlayerIndex iki kişilik oturumda round'a göre sırayla değişir")
    func currentPlayerIndexAlternatesForTwoPlayers() {
        #expect(ThisOrThatStateMachine.currentPlayerIndex(roundIndex: 0, playerCount: 2) == 0)
        #expect(ThisOrThatStateMachine.currentPlayerIndex(roundIndex: 1, playerCount: 2) == 1)
        #expect(ThisOrThatStateMachine.currentPlayerIndex(roundIndex: 2, playerCount: 2) == 0)
    }

    @Test("totalDurationSeconds tüm round'ların choosing+reveal sürelerini toplar")
    func totalDurationSumsAllRounds() {
        let t = template([round("r1", seconds: 5), round("r2", seconds: 4)])
        let total = ThisOrThatStateMachine.totalDurationSeconds(for: t, revealDurationSeconds: 2)
        #expect(total == (5 + 2) + (4 + 2))
    }
}
