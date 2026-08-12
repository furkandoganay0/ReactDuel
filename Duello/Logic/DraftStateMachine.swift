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
        if bothFull {
            newState.isFinished = true
            return newState
        }

        let otherPlayer: DraftPlayer = state.currentPlayer == .playerA ? .playerB : .playerA
        return advanceToNextActionablePlayer(otherPlayer, state: newState, template: template)
    }

    /// Bir oyuncunun havuzdaki hiçbir item'ı (kalan bütçesi yetmediği ya da
    /// rosterı zaten dolu olduğu için) alamıyor olması, önceden hiç ele
    /// alınmıyordu — sıra otomatik diğer oyuncuya geçse de o da tıkanmışsa
    /// (ya da rosterı zaten doluysa) kullanıcı hiçbir şey seçemeyen, kapatılamayan
    /// bir ekranda kalıyordu. `pick` bu kontrolü her el değişiminde uygular.
    static func canPlayerAct(_ player: DraftPlayer, state: DraftState, template: DraftTemplate) -> Bool {
        let roster = state.roster(for: player)
        guard roster.count < template.rosterSize else { return false }
        return state.availablePool.contains { candidate in
            BudgetValidator.canPick(
                candidate,
                currentRoster: roster,
                budget: template.budget,
                rosterSize: template.rosterSize
            ) == .allowed
        }
    }

    /// `player`den başlayarak hamle yapabilecek ilk oyuncuya geçer. `player` hamle
    /// yapamıyorsa diğer oyuncuya bakar; o da yapamıyorsa (kimse için ne bütçe ne
    /// roster yeri kalmamışsa) draft'ı mevcut rosterlarla bitmiş sayar.
    private static func advanceToNextActionablePlayer(
        _ player: DraftPlayer,
        state: DraftState,
        template: DraftTemplate
    ) -> DraftState {
        var newState = state
        if canPlayerAct(player, state: state, template: template) {
            newState.currentPlayer = player
            return newState
        }
        let other: DraftPlayer = player == .playerA ? .playerB : .playerA
        if canPlayerAct(other, state: state, template: template) {
            newState.currentPlayer = other
            return newState
        }
        newState.isFinished = true
        return newState
    }
}
