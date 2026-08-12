import Testing
@testable import Duello

@Suite("PredictionTimerStateMachine")
struct PredictionTimerStateMachineTests {

    private func question(_ id: String, seconds: Int, choices: [String]? = nil) -> PredictionQuestion {
        PredictionQuestion(
            id: id,
            prompt: "p-\(id)",
            answer: "a-\(id)",
            answerImage: "img",
            timerSeconds: seconds,
            choices: choices ?? ["a-\(id)", "b-\(id)", "c-\(id)", "d-\(id)"]
        )
    }

    /// Testlerde karıştırma olmadan deterministik sıra için kullanılır.
    private func identityShuffle(_ choices: [String]) -> [String] { choices }

    private func template(_ questions: [PredictionQuestion]) -> PredictionTemplate {
        PredictionTemplate(id: "t1", mode: "prediction", title: "Test", coverImage: "cover", questions: questions)
    }

    @Test("Başlangıç durumu ilk sorunun timerSeconds'ıyla prompt fazında başlar")
    func initialStateStartsAtFirstQuestion() {
        let t = template([question("q1", seconds: 6), question("q2", seconds: 4)])
        let state = PredictionTimerStateMachine.initialState(for: t)
        #expect(state.questionIndex == 0)
        #expect(state.phase == .prompt)
        #expect(state.secondsRemaining == 6)
    }

    @Test("Sorusu olmayan şablon direkt finished döner")
    func emptyTemplateFinishesImmediately() {
        let t = template([])
        let state = PredictionTimerStateMachine.initialState(for: t)
        #expect(state.phase == .finished)
    }

    @Test("Prompt fazında her tick süreyi bir azaltır")
    func tickDecrementsPromptCountdown() {
        let t = template([question("q1", seconds: 3)])
        var state = PredictionTimerStateMachine.initialState(for: t)
        state = PredictionTimerStateMachine.tick(state: state, template: t)
        #expect(state.phase == .prompt)
        #expect(state.secondsRemaining == 2)
    }

    @Test("Prompt süresi bitince reveal fazına geçer")
    func promptTransitionsToRevealWhenTimeRunsOut() {
        let t = template([question("q1", seconds: 1)])
        var state = PredictionTimerStateMachine.initialState(for: t)
        state = PredictionTimerStateMachine.tick(state: state, template: t, revealDurationSeconds: 3)
        #expect(state.phase == .reveal)
        #expect(state.questionIndex == 0)
        #expect(state.secondsRemaining == 3)
    }

    @Test("Reveal bitince sıradaki soruya geçer")
    func revealTransitionsToNextQuestion() {
        let t = template([question("q1", seconds: 1), question("q2", seconds: 5)])
        var state = PredictionState(questionIndex: 0, phase: .reveal, secondsRemaining: 1)
        state = PredictionTimerStateMachine.tick(state: state, template: t)
        #expect(state.phase == .prompt)
        #expect(state.questionIndex == 1)
        #expect(state.secondsRemaining == 5)
    }

    @Test("Son sorunun reveal'ı bitince finished'e geçer")
    func lastQuestionRevealFinishes() {
        let t = template([question("q1", seconds: 1)])
        var state = PredictionState(questionIndex: 0, phase: .reveal, secondsRemaining: 1)
        state = PredictionTimerStateMachine.tick(state: state, template: t)
        #expect(state.phase == .finished)
    }

    @Test("finished durumunda tick çağırmak durumu değiştirmez (idempotent)")
    func finishedStateIsStable() {
        let t = template([question("q1", seconds: 1)])
        let finished = PredictionState(questionIndex: 1, phase: .finished, secondsRemaining: 0)
        let next = PredictionTimerStateMachine.tick(state: finished, template: t)
        #expect(next == finished)
    }

    @Test("totalDurationSeconds tüm soruların prompt+reveal sürelerini toplar")
    func totalDurationSumsAllQuestions() {
        let t = template([question("q1", seconds: 6), question("q2", seconds: 4)])
        let total = PredictionTimerStateMachine.totalDurationSeconds(for: t, revealDurationSeconds: 3)
        #expect(total == (6 + 3) + (4 + 3))
    }

    @Test("initialState şıkları verilen shuffle fonksiyonuyla karıştırır")
    func initialStateUsesProvidedShuffle() {
        let t = template([question("q1", seconds: 6, choices: ["a", "b", "c", "d"])])
        let state = PredictionTimerStateMachine.initialState(for: t, shuffle: identityShuffle)
        #expect(state.shuffledChoices == ["a", "b", "c", "d"])
    }

    @Test("Doğru şıkka dokunmak anında reveal'a geçer ve skoru artırır")
    func selectCorrectAnswerAdvancesToRevealAndScores() {
        let q = question("q1", seconds: 6, choices: ["a-q1", "wrong1", "wrong2", "wrong3"])
        let t = template([q])
        let state = PredictionTimerStateMachine.initialState(for: t, shuffle: identityShuffle)
        let next = PredictionTimerStateMachine.select(answerIndex: 0, state: state, template: t, revealDurationSeconds: 3)
        #expect(next.phase == .reveal)
        #expect(next.selectedAnswerIndex == 0)
        #expect(next.secondsRemaining == 3)
        #expect(next.score == 1)
    }

    @Test("Yanlış şıkka dokunmak reveal'a geçer ama skoru artırmaz")
    func selectWrongAnswerDoesNotScore() {
        let q = question("q1", seconds: 6, choices: ["a-q1", "wrong1", "wrong2", "wrong3"])
        let t = template([q])
        let state = PredictionTimerStateMachine.initialState(for: t, shuffle: identityShuffle)
        let next = PredictionTimerStateMachine.select(answerIndex: 1, state: state, template: t)
        #expect(next.phase == .reveal)
        #expect(next.selectedAnswerIndex == 1)
        #expect(next.score == 0)
    }

    @Test("reveal fazındayken select çağırmak state'i değiştirmez")
    func selectIgnoredOutsidePromptPhase() {
        let q = question("q1", seconds: 1, choices: ["a-q1", "wrong1", "wrong2", "wrong3"])
        let t = template([q])
        let reveal = PredictionState(questionIndex: 0, phase: .reveal, secondsRemaining: 3, shuffledChoices: q.choices)
        let next = PredictionTimerStateMachine.select(answerIndex: 0, state: reveal, template: t)
        #expect(next == reveal)
    }

    @Test("Süre dolunca cevaplanmamış olarak reveal'a geçer, skor artmaz")
    func timeoutRevealsWithoutSelection() {
        let q = question("q1", seconds: 1, choices: ["a-q1", "wrong1", "wrong2", "wrong3"])
        let t = template([q])
        var state = PredictionTimerStateMachine.initialState(for: t, shuffle: identityShuffle)
        state = PredictionTimerStateMachine.tick(state: state, template: t, revealDurationSeconds: 3)
        #expect(state.phase == .reveal)
        #expect(state.selectedAnswerIndex == nil)
        #expect(state.score == 0)
    }

    @Test("Skor sorular arasında ve finished'e geçerken korunur")
    func scorePersistsAcrossQuestionsAndIntoFinished() {
        let q1 = question("q1", seconds: 1, choices: ["a-q1", "x", "y", "z"])
        let q2 = question("q2", seconds: 1, choices: ["a-q2", "x", "y", "z"])
        let t = template([q1, q2])
        var state = PredictionTimerStateMachine.initialState(for: t, shuffle: identityShuffle)
        state = PredictionTimerStateMachine.select(answerIndex: 0, state: state, template: t, revealDurationSeconds: 1)
        #expect(state.score == 1)
        state = PredictionTimerStateMachine.tick(state: state, template: t, revealDurationSeconds: 1, shuffle: identityShuffle)
        #expect(state.phase == .prompt)
        #expect(state.questionIndex == 1)
        #expect(state.score == 1)
        state = PredictionTimerStateMachine.tick(state: state, template: t, revealDurationSeconds: 1)
        state = PredictionTimerStateMachine.tick(state: state, template: t, revealDurationSeconds: 1)
        #expect(state.phase == .finished)
        #expect(state.score == 1)
    }
}
