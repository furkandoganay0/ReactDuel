import Testing
@testable import Duello

@Suite("DraftStateMachine")
struct DraftStateMachineTests {

    private func item(_ id: String, _ cost: Int) -> DraftPoolItem {
        DraftPoolItem(id: id, name: id, cost: cost, image: "placeholder")
    }

    private func makeTemplate(budget: Int = 10, rosterSize: Int = 2) -> DraftTemplate {
        DraftTemplate(
            id: "t1",
            mode: "draft",
            title: "Test Draft",
            coverImage: "cover",
            budget: budget,
            rosterSize: rosterSize,
            pool: [item("p1", 4), item("p2", 5), item("p3", 6), item("p4", 3)]
        )
    }

    @Test("Başlangıç durumu playerA ile başlar, rosterlar boş")
    func initialStateStartsWithPlayerA() {
        let t = makeTemplate()
        let state = DraftStateMachine.initialState(template: t)
        #expect(state.currentPlayer == .playerA)
        #expect(state.rosterA.isEmpty)
        #expect(state.rosterB.isEmpty)
        #expect(state.isFinished == false)
    }

    @Test("Geçerli bir pick sırayı diğer oyuncuya devreder")
    func validPickPassesTurnToOtherPlayer() {
        let t = makeTemplate()
        var state = DraftStateMachine.initialState(template: t)
        state = DraftStateMachine.pick(item("p1", 4), state: state, template: t)
        #expect(state.rosterA.map(\.id) == ["p1"])
        #expect(state.currentPlayer == .playerB)
    }

    @Test("Bütçeyi aşan pick durumu değiştirmez")
    func invalidPickIsNoOp() {
        let t = makeTemplate(budget: 3, rosterSize: 2)
        let state = DraftStateMachine.initialState(template: t)
        let next = DraftStateMachine.pick(item("p3", 6), state: state, template: t)
        #expect(next == state)
    }

    @Test("Her iki roster da rosterSize'a ulaşınca draft biter")
    func draftFinishesWhenBothRostersFull() {
        let t = makeTemplate(budget: 20, rosterSize: 1)
        var state = DraftStateMachine.initialState(template: t)
        state = DraftStateMachine.pick(item("p1", 4), state: state, template: t) // A picks
        #expect(state.isFinished == false)
        state = DraftStateMachine.pick(item("p2", 5), state: state, template: t) // B picks
        #expect(state.isFinished == true)
    }

    @Test("Pick edilen item kullanılabilir havuzdan çıkar")
    func pickedItemLeavesAvailablePool() {
        let t = makeTemplate()
        var state = DraftStateMachine.initialState(template: t)
        state = DraftStateMachine.pick(item("p1", 4), state: state, template: t)
        #expect(!state.availablePool.contains(where: { $0.id == "p1" }))
    }
}
