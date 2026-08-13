import SwiftUI
import UIKit

/// Bütçeli Draft modu kayıt ekranı — teknik prompt Bölüm 7.4-7.5.
/// Kayıt, kamera hazır olduğunda otomatik başlar; her iki roster da dolduğunda
/// sonuç birkaç saniye gösterilir (hâlâ kayıttayken), sonra kayıt durur.
struct DraftRecordingView: View {
    let template: DraftTemplate
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @EnvironmentObject private var playHistoryStore: PlayHistoryStore
    @Environment(\.locale) private var locale

    @StateObject private var cameraController = CameraController()
    @State private var draftState: DraftState
    @State private var lifecycle: Lifecycle = .preparingCamera
    @State private var pendingPick: DraftPoolItem?
    @State private var pickSecondsRemaining: Int

    private let resultDisplaySeconds = 4
    private let introDisplaySeconds = 2
    private let pickTimerSeconds = 8
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum Lifecycle: Equatable {
        case preparingCamera
        case countdown(Int)
        case showingIntro(secondsLeft: Int)
        case picking
        case showingResult(secondsLeft: Int)
        case done
    }

    init(template: DraftTemplate, path: Binding<[AppRoute]>) {
        self.template = template
        self._path = path
        self._draftState = State(initialValue: DraftStateMachine.initialState(template: template))
        self._pickSecondsRemaining = State(initialValue: 8)
    }

    var body: some View {
        ZStack {
            CameraPreviewView(session: cameraController.cameraSession.session)
                .ignoresSafeArea()

            if lifecycle == .picking || isPickModalShown {
                topTurnBar
            }

            if case .showingResult = lifecycle {
                DraftResultView(
                    template: template,
                    rosterA: draftState.rosterA,
                    rosterB: draftState.rosterB,
                    result: DraftScoreCalculator.winner(rosterA: draftState.rosterA, rosterB: draftState.rosterB)
                )
            } else if case .showingIntro = lifecycle {
                introCard
            } else if lifecycle == .picking {
                bottomPoolPicker
            }

            if let pendingPick {
                DraftPickModalView(
                    item: pendingPick,
                    remainingBudgetAfterPick: draftState.remainingBudget(for: draftState.currentPlayer, template: template) - pendingPick.cost,
                    onConfirm: { confirmPick(pendingPick) },
                    onCancel: { self.pendingPick = nil }
                )
            }

            if case .countdown(let n) = lifecycle {
                Color.black.opacity(0.5).ignoresSafeArea()
                Text("\(n)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            if lifecycle == .preparingCamera {
                if let configurationError = cameraController.configurationError {
                    CameraErrorView(error: configurationError, onRetry: { cameraController.prepare() })
                } else {
                    ProgressView("Kamera hazırlanıyor…")
                        .tint(.white)
                        .foregroundStyle(.white)
                }
            }

            RecordingExitButton(hasActiveRecording: hasActiveRecording) {
                path.removeLast()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { cameraController.prepare() }
        .onChange(of: cameraController.isReady) { ready in
            if ready, lifecycle == .preparingCamera {
                lifecycle = .countdown(3)
            }
        }
        .onReceive(ticker) { _ in handleTick() }
        .onDisappear { cameraController.teardown() }
    }

    private var isPickModalShown: Bool { pendingPick != nil }

    private var hasActiveRecording: Bool {
        switch lifecycle {
        case .picking, .showingResult, .showingIntro: return true
        case .preparingCamera, .countdown, .done: return false
        }
    }

    private var currentRoster: [DraftPoolItem] {
        draftState.roster(for: draftState.currentPlayer)
    }

    private var introCard: some View {
        VStack(spacing: 12) {
            Text("🔥")
                .font(.system(size: 44))
            Text(template.title)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(Color.orange.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }

    private var topTurnBar: some View {
        VStack {
            VStack(spacing: 10) {
                HStack {
                    pickCountdownBadge
                    Text(L10n.playerLabel(draftState.currentPlayer, locale: locale))
                        .font(.headline)
                    Spacer()
                    Text(L10n.rosterProgressLabel(
                        picked: currentRoster.count, rosterSize: template.rosterSize, locale: locale
                    ))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                    Text(L10n.remainingBudgetLabel(
                        draftState.remainingBudget(for: draftState.currentPlayer, template: template),
                        locale: locale
                    ))
                        .font(.headline)
                }
                .foregroundStyle(.white)

                if !currentRoster.isEmpty {
                    rosterChipRow
                        .transition(.opacity)
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .animation(.easeInOut(duration: 0.2), value: currentRoster.count)
            Spacer()
        }
    }

    /// Bu turda seçim yapmak için kalan süre — süre dolarsa otomatik (rastgele
    /// uygun) bir seçim yapılır (bkz. `autoPickForTimeout`). Tempo/gerginlik
    /// için: önceden seçim süresi sınırsızdı, "ölü an" riski vardı.
    private var pickCountdownBadge: some View {
        Text("\(pickSecondsRemaining)")
            .font(.subheadline.weight(.black))
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(Circle().fill(pickSecondsRemaining <= 3 ? Color.red : Color.white.opacity(0.2)))
            .animation(.easeInOut(duration: 0.2), value: pickSecondsRemaining <= 3)
    }

    /// Şu ana kadar seçilen item'ları canlı gösteren şerit — önceden bütçeyle
    /// seçim yaparken kendi rosterını görebilmenin tek yolu kaydın sonunu
    /// beklemekti (`DraftResultView`). Artık her seçim anında burada birikiyor.
    private var rosterChipRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(currentRoster) { item in
                    HStack(spacing: 6) {
                        PlaceholderCoverView(imageName: item.image, label: item.name)
                            .frame(width: 26, height: 26)
                        Text(item.name)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var bottomPoolPicker: some View {
        VStack {
            Spacer()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(draftState.availablePool) { item in
                        poolItemCard(item)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 150)
            .background(Color.black.opacity(0.35))
            .padding(.bottom, 16)
        }
    }

    private func poolItemCard(_ item: DraftPoolItem) -> some View {
        let validation = BudgetValidator.canPick(
            item,
            currentRoster: draftState.roster(for: draftState.currentPlayer),
            budget: template.budget,
            rosterSize: template.rosterSize
        )
        let isAffordable = validation == .allowed

        return Button {
            guard isAffordable else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            pendingPick = item
        } label: {
            VStack(spacing: 6) {
                PlaceholderCoverView(imageName: item.image, label: item.name)
                    .frame(width: 80, height: 80)
                Text(item.name)
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text("\(item.cost)")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(width: 90)
            .opacity(isAffordable ? 1 : 0.35)
        }
        .disabled(!isAffordable)
    }

    private func handleTick() {
        switch lifecycle {
        case .countdown(let n):
            if n <= 1 {
                startRecording()
            } else {
                lifecycle = .countdown(n - 1)
            }
        case .showingIntro(let secondsLeft):
            if secondsLeft <= 1 {
                lifecycle = .picking
                cameraController.recorder.logOverlayEvent(
                    .showTurn(text: turnOverlayText(for: draftState.currentPlayer, budgetRemaining: template.budget), playerIndex: nil)
                )
            } else {
                lifecycle = .showingIntro(secondsLeft: secondsLeft - 1)
            }
        case .picking:
            guard pendingPick == nil else { return } // onay modalı açıkken saat durur
            if pickSecondsRemaining <= 1 {
                autoPickForTimeout()
            } else {
                pickSecondsRemaining -= 1
            }
        case .showingResult(let secondsLeft):
            if secondsLeft <= 1 {
                finishRecording()
            } else {
                lifecycle = .showingResult(secondsLeft: secondsLeft - 1)
            }
        case .preparingCamera, .done:
            break
        }
    }

    /// Kayıt gerçekten başlar (kamera zaten çalışıyor); önce kısa bir "hook"
    /// kartı gösterilir (bkz. `introCard`), asıl seçim turu ondan sonra başlar.
    private func startRecording() {
        lifecycle = .showingIntro(secondsLeft: introDisplaySeconds)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        cameraController.recorder.startRecording()
        cameraController.recorder.logOverlayEvent(.showIntro(text: template.title))
    }

    /// Seçim süresi dolunca çağrılır: sırası gelen oyuncu için uygun (bütçeye
    /// giren, roster'a sığan) item'lardan rastgele birini otomatik seçer —
    /// oyunun akışı hiç durmasın diye. `advanceToNextActionablePlayer`
    /// (`DraftStateMachine`) garanti eder ki sırası gelen oyuncu her zaman en
    /// az bir uygun item bulabilir, o yüzden liste normalde boş olmaz.
    private func autoPickForTimeout() {
        let affordable = draftState.availablePool.filter {
            BudgetValidator.canPick(
                $0,
                currentRoster: draftState.roster(for: draftState.currentPlayer),
                budget: template.budget,
                rosterSize: template.rosterSize
            ) == .allowed
        }
        guard let randomItem = affordable.randomElement() else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        confirmPick(randomItem, isAutoPick: true)
    }

    private func confirmPick(_ item: DraftPoolItem, isAutoPick: Bool = false) {
        let playerBeforePick = draftState.currentPlayer
        draftState = DraftStateMachine.pick(item, state: draftState, template: template)
        pendingPick = nil
        pickSecondsRemaining = pickTimerSeconds

        let playerLabel = L10n.playerLabel(playerBeforePick, locale: locale)
        let pickText = isAutoPick ? L10n.autoPickLabel(playerName: playerLabel, itemName: item.name, locale: locale)
            : "\(playerLabel): \(item.name) (\(item.cost))"
        cameraController.recorder.logOverlayEvent(.showPick(text: pickText, playerIndex: nil))

        if draftState.isFinished {
            let result = DraftScoreCalculator.winner(rosterA: draftState.rosterA, rosterB: draftState.rosterB)
            // Canlı ekranda kayıt bitince görünen `DraftResultView` her iki rosterı
            // da (isim + toplam maliyet) karşılaştırmalı gösteriyor — video da aynısını
            // yakmalı, önceden sadece kazananın adı yazıyordu.
            let summary = L10n.draftResultVideoSummary(
                resultText: L10n.resultLabel(result, locale: locale),
                rosterA: draftState.rosterA.map(\.name), costA: DraftScoreCalculator.totalCost(of: draftState.rosterA),
                rosterB: draftState.rosterB.map(\.name), costB: DraftScoreCalculator.totalCost(of: draftState.rosterB),
                locale: locale
            )
            cameraController.recorder.logOverlayEvent(.showResult(text: summary, playerIndex: nil))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            lifecycle = .showingResult(secondsLeft: resultDisplaySeconds)
        } else {
            cameraController.recorder.logOverlayEvent(
                .showTurn(
                    text: turnOverlayText(
                        for: draftState.currentPlayer,
                        budgetRemaining: draftState.remainingBudget(for: draftState.currentPlayer, template: template)
                    ),
                    playerIndex: nil
                )
            )
        }
    }

    private func turnOverlayText(for player: DraftPlayer, budgetRemaining: Int) -> String {
        "\(L10n.playerLabel(player, locale: locale)) • \(L10n.remainingBudgetLabel(budgetRemaining, locale: locale))"
    }

    private func finishRecording() {
        lifecycle = .done
        cameraController.recorder.stopRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            session.reset()
            session.rawVideoURL = cameraController.recorder.lastRecordedURL
            session.overlayEvents = cameraController.recorder.overlayEvents

            let result = DraftScoreCalculator.winner(rosterA: draftState.rosterA, rosterB: draftState.rosterB)
            let record = playHistoryStore.addRecord(
                mode: .draft, packTitle: template.title, resultSummary: L10n.resultLabel(result, locale: locale)
            )
            session.pendingHistoryRecordID = record.id
            path.append(.saveDecision)
        }
    }
}
