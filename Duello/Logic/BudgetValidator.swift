import Foundation

enum BudgetValidationResult: Equatable {
    case allowed
    case exceedsBudget
    case rosterFull
    case alreadyPicked
}

/// Bir draft seçiminin geçerli olup olmadığını saf şekilde değerlendirir.
/// UI katmanı bunu her pick denemesinde çağırır; sonuca göre item'ı devre dışı
/// bırakır veya hata mesajı gösterir.
enum BudgetValidator {
    static func remainingBudget(budget: Int, roster: [DraftPoolItem]) -> Int {
        budget - DraftScoreCalculator.totalCost(of: roster)
    }

    static func canPick(
        _ item: DraftPoolItem,
        currentRoster: [DraftPoolItem],
        budget: Int,
        rosterSize: Int
    ) -> BudgetValidationResult {
        if currentRoster.count >= rosterSize {
            return .rosterFull
        }
        if currentRoster.contains(where: { $0.id == item.id }) {
            return .alreadyPicked
        }
        let remaining = remainingBudget(budget: budget, roster: currentRoster)
        if item.cost > remaining {
            return .exceedsBudget
        }
        return .allowed
    }
}
