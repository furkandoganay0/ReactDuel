import Testing
@testable import Duello

@Suite("BudgetValidator")
struct BudgetValidatorTests {

    private func item(_ id: String, _ cost: Int) -> DraftPoolItem {
        DraftPoolItem(id: id, name: id, cost: cost, image: "placeholder")
    }

    @Test("Boş roster'a, bütçe dahilindeki bir item eklenebilir")
    func allowsPickWithinBudgetOnEmptyRoster() {
        let result = BudgetValidator.canPick(item("x", 5), currentRoster: [], budget: 20, rosterSize: 5)
        #expect(result == .allowed)
    }

    @Test("Kalan bütçeyi aşan item reddedilir")
    func rejectsPickExceedingRemainingBudget() {
        let roster = [item("a", 18)]
        let result = BudgetValidator.canPick(item("x", 5), currentRoster: roster, budget: 20, rosterSize: 5)
        #expect(result == .exceedsBudget)
    }

    @Test("Roster zaten rosterSize'a ulaştıysa yeni pick reddedilir")
    func rejectsPickWhenRosterFull() {
        let roster = [item("a", 1), item("b", 1)]
        let result = BudgetValidator.canPick(item("x", 1), currentRoster: roster, budget: 20, rosterSize: 2)
        #expect(result == .rosterFull)
    }

    @Test("Aynı item iki kez seçilemez")
    func rejectsDuplicatePick() {
        let existing = item("dup", 3)
        let roster = [existing]
        let result = BudgetValidator.canPick(existing, currentRoster: roster, budget: 20, rosterSize: 5)
        #expect(result == .alreadyPicked)
    }

    @Test("Kalan bütçeye tam eşit maliyetli item kabul edilir (sınır durumu)")
    func allowsPickExactlyMatchingRemainingBudget() {
        let roster = [item("a", 15)]
        let result = BudgetValidator.canPick(item("x", 5), currentRoster: roster, budget: 20, rosterSize: 5)
        #expect(result == .allowed)
    }

    @Test("remainingBudget bütçe tam kullanılmamış roster için doğru hesaplanır")
    func remainingBudgetForUnderspentRoster() {
        let roster = [item("a", 3), item("b", 4)]
        #expect(BudgetValidator.remainingBudget(budget: 20, roster: roster) == 13)
    }

    @Test("remainingBudget boş roster için tam bütçeyi döner")
    func remainingBudgetForEmptyRoster() {
        #expect(BudgetValidator.remainingBudget(budget: 20, roster: []) == 20)
    }
}
