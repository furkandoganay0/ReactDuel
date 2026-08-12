import Foundation

/// Bütçeli Draft modunun tur-bazlı durumu. Saf değer tipi — kamera/kayıt
/// katmanına hiç dokunmaz, sadece View'ın gösterdiği state'i tutar.
struct DraftState: Equatable {
    var rosterA: [DraftPoolItem] = []
    var rosterB: [DraftPoolItem] = []
    var currentPlayer: DraftPlayer = .playerA
    var availablePool: [DraftPoolItem]
    var isFinished: Bool = false

    func roster(for player: DraftPlayer) -> [DraftPoolItem] {
        player == .playerA ? rosterA : rosterB
    }

    func remainingBudget(for player: DraftPlayer, template: DraftTemplate) -> Int {
        BudgetValidator.remainingBudget(budget: template.budget, roster: roster(for: player))
    }
}

enum DraftStateMachine {
    static func initialState(template: DraftTemplate) -> DraftState {
        DraftState(rosterA: [], rosterB: [], currentPlayer: .playerA, availablePool: template.pool, isFinished: false)
    }

    /// Bir pick uygular. Geçersiz bir pick (bütçe aşımı, roster dolu, zaten seçilmiş)
    /// durumu **değiştirmez** — çağıran taraf `BudgetValidator.canPick` ile önce
    /// UI'da doğrulamalı, bu fonksiyon son bir güvenlik ağı.
    static func pick(_ item: DraftPoolItem, state: DraftState, template: DraftTemplate) -> DraftState {
        let currentRoster = state.roster(for: state.currentPlayer)
        let validation = BudgetValidator.canPick(
            item,
            currentRoster: currentRoster,
            budget: template.budget,
            rosterSize: template.rosterSize
        )
        guard validation == .allowed else { return state }

        var newState = state
        var updatedRoster = currentRoster
        updatedRoster.append(item)

        switch state.currentPlayer {
        case .playerA: newState.rosterA = updatedRoster
        case .playerB: newState.rosterB = updatedRoster
        }
        newState.availablePool.removeAll { $0.id == item.id }

        let bothFull = newState.rosterA.count >= template.rosterSize && newState.rosterB.count >= template.rosterSize
        newState.isFinished = bothFull
        if !bothFull {
            newState.currentPlayer = state.currentPlayer == .playerA ? .playerB : .playerA
        }
        return newState
    }
}
