import SwiftUI
import UIKit

/// Bütçeli Draft modu kayıt ekranı — teknik prompt Bölüm 7.4-7.5.
/// Kayıt, kamera hazır olduğunda otomatik başlar; her iki roster da dolduğunda
/// sonuç birkaç saniye gösterilir (hâlâ kayıttayken), sonra kayıt durur.
struct DraftRecordingView: View {
    let template: DraftTemplate
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @Environment(\.locale) private var locale

    @StateObject private var cameraController = CameraController()
    @State private var draftState: DraftState
    @State private var lifecycle: Lifecycle = .preparingCamera
    @State private var pendingPick: DraftPoolItem?

    private let resultDisplaySeconds = 4
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum Lifecycle: Equatable {
        case preparingCamera
        case countdown(Int)
        case picking
        case showingResult(secondsLeft: Int)
        case done
    }

    init(template: DraftTemplate, path: Binding<[AppRoute]>) {
        self.template = template
        self._path = path
        self._draftState = State(initialValue: DraftStateMachine.initialState(template: template))
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
        }
        .navigationBarBackButtonHidden(lifecycle != .preparingCamera)
        .toolbar(lifecycle == .preparingCamera ? .visible : .hidden, for: .navigationBar)
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

    private var topTurnBar: some View {
        VStack {
            HStack {
                Text(L10n.playerLabel(draftState.currentPlayer, locale: locale))
                    .font(.headline)
                Spacer()
                Text(L10n.remainingBudgetLabel(
                    draftState.remainingBudget(for: draftState.currentPlayer, template: template),
                    locale: locale
                ))
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .padding(14)
            .background(Color.black.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.top, 12)
            Spacer()
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
        case .showingResult(let secondsLeft):
            if secondsLeft <= 1 {
                finishRecording()
            } else {
                lifecycle = .showingResult(secondsLeft: secondsLeft - 1)
            }
        case .picking, .preparingCamera, .done:
            break
        }
    }

    private func startRecording() {
        lifecycle = .picking
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        cameraController.recorder.startRecording()
        cameraController.recorder.logOverlayEvent(
            .showTurn(playerLabel: L10n.playerLabel(draftState.currentPlayer, locale: locale), budgetRemaining: template.budget)
        )
    }

    private func confirmPick(_ item: DraftPoolItem) {
        let playerBeforePick = draftState.currentPlayer
        draftState = DraftStateMachine.pick(item, state: draftState, template: template)
        pendingPick = nil

        cameraController.recorder.logOverlayEvent(
            .showPick(playerLabel: L10n.playerLabel(playerBeforePick, locale: locale), itemName: item.name)
        )

        if draftState.isFinished {
            let result = DraftScoreCalculator.winner(rosterA: draftState.rosterA, rosterB: draftState.rosterB)
            cameraController.recorder.logOverlayEvent(.showResult(winnerLabel: L10n.resultLabel(result, locale: locale)))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            lifecycle = .showingResult(secondsLeft: resultDisplaySeconds)
        } else {
            cameraController.recorder.logOverlayEvent(
                .showTurn(
                    playerLabel: L10n.playerLabel(draftState.currentPlayer, locale: locale),
                    budgetRemaining: draftState.remainingBudget(for: draftState.currentPlayer, template: template)
                )
            )
        }
    }

    private func finishRecording() {
        lifecycle = .done
        cameraController.recorder.stopRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            session.reset()
            session.rawVideoURL = cameraController.recorder.lastRecordedURL
            session.overlayEvents = cameraController.recorder.overlayEvents
            path.append(.processing)
        }
    }
}
