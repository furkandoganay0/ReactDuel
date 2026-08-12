import Testing
@testable import Duello

@Suite("DraftScoreCalculator")
struct DraftScoreCalculatorTests {

    private func item(_ id: String, _ cost: Int) -> DraftPoolItem {
        DraftPoolItem(id: id, name: id, cost: cost, image: "placeholder")
    }

    @Test("Eşit toplam skor beraberlik döner")
    func equalScoreIsTie() {
        let a = [item("a1", 5), item("a2", 5)]
        let b = [item("b1", 4), item("b2", 6)]
        #expect(DraftScoreCalculator.winner(rosterA: a, rosterB: b) == .tie)
    }

    @Test("İki boş roster beraberliktir")
    func bothEmptyRostersAreTie() {
        #expect(DraftScoreCalculator.winner(rosterA: [], rosterB: []) == .tie)
    }

    @Test("Boş roster'a karşı dolu roster her zaman kaybeder")
    func emptyRosterLosesToNonEmpty() {
        let b = [item("b1", 1)]
        #expect(DraftScoreCalculator.winner(rosterA: [], rosterB: b) == .winner(.playerB))
    }

    @Test("Tek item'lık rosterlar doğru karşılaştırılır")
    func singleItemRosters() {
        let a = [item("a1", 7)]
        let b = [item("b1", 3)]
        #expect(DraftScoreCalculator.winner(rosterA: a, rosterB: b) == .winner(.playerA))
    }

    @Test("Bütçe tam kullanılmamış roster yine de toplam cost'a göre kazanabilir")
    func underspentRosterCanStillWin() {
        // A bütçeyi tam kullanmamış (toplam 12) ama B'den (toplam 10) yine de yüksek.
        let a = [item("a1", 6), item("a2", 6)]
        let b = [item("b1", 5), item("b2", 5)]
        #expect(DraftScoreCalculator.winner(rosterA: a, rosterB: b) == .winner(.playerA))
    }

    @Test("totalCost boş roster için 0 döner")
    func totalCostOfEmptyRosterIsZero() {
        #expect(DraftScoreCalculator.totalCost(of: []) == 0)
    }
}
