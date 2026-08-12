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

    @Test("Rosterı zaten dolu olan oyuncuya sıra geçmez, atlanıp diğer oyuncuda kalır")
    func skipsPlayerWithFullRoster() {
        let t = makeTemplate(budget: 30, rosterSize: 3)
        let state = DraftState(
            rosterA: [item("a1", 4), item("a2", 3), item("a3", 5)], // A dolu: 3/3
            rosterB: [item("b1", 5)], // B: 1/3, yeri var
            currentPlayer: .playerB,
            availablePool: [item("p3", 6), item("p5", 2)],
            isFinished: false
        )
        let next = DraftStateMachine.pick(item("p3", 6), state: state, template: t)
        // B'nin picki'nden sonra sıra normalde A'ya geçerdi ama A'nın rosterı dolu —
        // A atlanır, sıra B'de kalmaya devam eder.
        #expect(next.currentPlayer == .playerB)
        #expect(next.isFinished == false)
    }

    @Test("Kalan havuzdaki hiçbir item kimseye yetmiyorsa draft mevcut rosterlarla biter")
    func draftFinishesWhenNoOneCanAffordRemainingItems() {
        let t = DraftTemplate(
            id: "t-budget-stuck", mode: "draft", title: "Test", coverImage: "cover",
            budget: 5, rosterSize: 1,
            pool: [item("cheap", 5), item("pricey1", 6), item("pricey2", 7)]
        )
        var state = DraftStateMachine.initialState(template: t)
        // A tek uygun fiyatlı item'ı alır ve rosterı dolar (rosterSize: 1); kalan iki
        // item de hem B'nin tam bütçesini (5) hem de zaten dolu olan A'yı aşıyor —
        // önceden bu durum hiç ele alınmıyordu, kullanıcı hiçbir şey seçemeyen ve
        // kapatılamayan bir ekranda kalıyordu.
        state = DraftStateMachine.pick(item("cheap", 5), state: state, template: t)
        #expect(state.isFinished == true)
        #expect(state.rosterA.map(\.id) == ["cheap"])
        #expect(state.rosterB.isEmpty)
    }

    @Test("canPlayerAct: rosterı dolu oyuncu için false döner")
    func canPlayerActFalseWhenRosterFull() {
        let t = makeTemplate(budget: 30, rosterSize: 1)
        let state = DraftState(
            rosterA: [item("a1", 4)],
            rosterB: [],
            currentPlayer: .playerA,
            availablePool: [item("p2", 5)],
            isFinished: false
        )
        #expect(DraftStateMachine.canPlayerAct(.playerA, state: state, template: t) == false)
        #expect(DraftStateMachine.canPlayerAct(.playerB, state: state, template: t) == true)
    }
}
