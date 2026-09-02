import SwiftUI
import UIKit

/// "Bu mu O mu" modu kayıt ekranı — `PredictionRecordingView` ile aynı yaşam
/// döngüsü deseni (hazırlık → 3-2-1 → hook kartı → oynanış → sonuç → kaydetme
/// kararı). `recordingEnabled == false` ise kamera hiç açılmaz. `playerCount == 2`
/// ise round'lar oyuncular arasında sırayla paylaşılır.
struct ThisOrThatRecordingView: View {
    let template: ThisOrThatTemplate
    let recordingEnabled: Bool
    let playerCount: Int
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @EnvironmentObject private var playHistoryStore: PlayHistoryStore
    @Environment(\.locale) private var locale

    @StateObject private var cameraController = CameraController()
    @State private var state: ThisOrThatState
    @State private var lifecycle: RecordingLifecycle = .preparingCamera
    @State private var recBlinkVisible = true

    private let resultDisplaySeconds = 4
    private let introDisplaySeconds = 2
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum RecordingLifecycle: Equatable {
        case preparingCamera
        case countdown(Int)
        case showingIntro(secondsLeft: Int)
        case playing
        case showingResult(secondsLeft: Int)
        case done
    }

    init(template: ThisOrThatTemplate, recordingEnabled: Bool, playerCount: Int, path: Binding<[AppRoute]>) {
        self.template = template
        self.recordingEnabled = recordingEnabled
        self.playerCount = playerCount
        self._path = path
        self._state = State(initialValue: ThisOrThatStateMachine.initialState(for: template))
    }

    var body: some View {
        ZStack {
            if recordingEnabled {
                CameraPreviewView(session: cameraController.cameraSession.session)
                    .ignoresSafeArea()
            } else {
                LinearGradient(colors: [.black, .purple], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }

            if case .showingResult = lifecycle {
                ThisOrThatSessionResultView(pickedLabels: state.pickedLabels)
            } else if case .showingIntro = lifecycle {
                introCard
            } else if lifecycle != .preparingCamera {
                // Kamera hazır olmadan (ör. izin reddi) bu katmanı hiç çizme —
                // aksi halde `CameraErrorView` ile aynı anda üst üste biniyordu.
                ThisOrThatOverlayView(
                    phase: state.phase,
                    round: currentRound,
                    secondsRemaining: state.secondsRemaining,
                    selectedOption: state.selectedOption,
                    playerCount: playerCount,
                    currentPlayerIndex: currentPlayerIndex,
                    onSelect: select
                )
            }

            if hasActiveRecording {
                recIndicator
            }

            if case .countdown(let n) = lifecycle {
                Color.black.opacity(0.5).ignoresSafeArea()
                Text("\(n)")
                    .font(.system(size: 96, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            if lifecycle == .preparingCamera {
                if let configurationError = cameraController.configurationError {
                    CameraErrorView(
                        error: configurationError,
                        onRetry: { cameraController.prepare() },
                        onContinueWithoutRecording: recordingEnabled ? switchToNoRecordingMode : nil
                    )
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
        .onAppear {
            if recordingEnabled {
                cameraController.prepare()
            } else {
                lifecycle = .countdown(3)
            }
        }
        .onChange(of: cameraController.isReady) { ready in
            if ready, lifecycle == .preparingCamera {
                lifecycle = .countdown(3)
            }
        }
        .onReceive(ticker) { _ in handleTick() }
        .onDisappear {
            if recordingEnabled {
                cameraController.teardown()
            }
        }
    }

    private var isShowingResult: Bool {
        if case .showingResult = lifecycle { return true }
        return false
    }

    private var isShowingIntro: Bool {
        if case .showingIntro = lifecycle { return true }
        return false
    }

    private var hasActiveRecording: Bool {
        recordingEnabled && (lifecycle == .playing || isShowingResult || isShowingIntro)
    }

    private var currentPlayerIndex: Int {
        ThisOrThatStateMachine.currentPlayerIndex(roundIndex: state.roundIndex, playerCount: playerCount)
    }

    /// `nil` tek kişilik oturumda — bkz. `PredictionRecordingView.videoPlayerIndex`.
    private var videoPlayerIndex: Int? {
        playerCount > 1 ? currentPlayerIndex : nil
    }

    private var currentRound: ThisOrThatRound? {
        guard state.roundIndex < template.rounds.count else { return nil }
        return template.rounds[state.roundIndex]
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
        .background(Color.purple.gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 24)
        .transition(.scale.combined(with: .opacity))
    }

    private var recIndicator: some View {
        VStack {
            HStack {
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(Color.red).frame(width: 10, height: 10)
                    Text("REC")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .clipShape(Capsule())
                .opacity(recBlinkVisible ? 1 : 0.35)
                .animation(.easeInOut(duration: 0.5), value: recBlinkVisible)
                .padding(.trailing, 16)
                .padding(.top, 12)
            }
            Spacer()
        }
    }

    private func switchToNoRecordingMode() {
        path.removeLast()
        path.append(.thisOrThatRecording(template, recordingEnabled: false, playerCount: playerCount))
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
            recBlinkVisible.toggle()
            if secondsLeft <= 1 {
                lifecycle = .playing
                logCurrentPhaseIfNeeded()
            } else {
                lifecycle = .showingIntro(secondsLeft: secondsLeft - 1)
            }
        case .playing:
            recBlinkVisible.toggle()
            advance()
        case .showingResult(let secondsLeft):
            recBlinkVisible.toggle()
            if secondsLeft <= 1 {
                finishRecording()
            } else {
                lifecycle = .showingResult(secondsLeft: secondsLeft - 1)
            }
        case .preparingCamera, .done:
            break
        }
    }

    private func startRecording() {
        lifecycle = .showingIntro(secondsLeft: introDisplaySeconds)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if recordingEnabled {
            cameraController.recorder.startRecording()
            cameraController.recorder.logOverlayEvent(.showIntro(text: template.title))
        }
    }

    private func select(optionIsA: Bool) {
        guard lifecycle == .playing, state.phase == .choosing, state.selectedOption == nil else { return }
        state = ThisOrThatStateMachine.select(optionIsA: optionIsA, state: state, template: template)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        logCurrentPhaseIfNeeded()
    }

    private func advance() {
        let previousPhase = state.phase
        let previousIndex = state.roundIndex
        state = ThisOrThatStateMachine.tick(state: state, template: template)

        if state.phase == .finished {
            showResultThenFinish()
            return
        }
        if state.phase != previousPhase || state.roundIndex != previousIndex {
            logCurrentPhaseIfNeeded()
        }
    }

    private func showResultThenFinish() {
        if recordingEnabled {
            let summary = state.pickedLabels.isEmpty
                ? L10n.thisOrThatEmptyResultSummary(locale: locale)
                : state.pickedLabels.joined(separator: " • ")
            cameraController.recorder.logOverlayEvent(.showResult(text: summary, playerIndex: nil))
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        lifecycle = .showingResult(secondsLeft: resultDisplaySeconds)
    }

    /// Canlı ekrandaki VS düzenini (iki büyük seçenek + aralarında "VS") ve
    /// tur ilerlemesini videoya da yakar — önceden video tek satırlık
    /// "A  •  B" metnine sıkıştırıyordu, VS hissi kayboluyordu.
    private func logCurrentPhaseIfNeeded() {
        guard recordingEnabled, let round = currentRound else { return }
        switch state.phase {
        case .choosing:
            let progress = L10n.roundProgress(current: state.roundIndex + 1, total: template.rounds.count, locale: locale)
            let text = "\(progress)\n\n\(round.optionA)\n\nVS\n\n\(round.optionB)"
            cameraController.recorder.logOverlayEvent(.showPrompt(text: text, playerIndex: videoPlayerIndex))
        case .revealed:
            let text = state.selectedOption.map { $0 ? round.optionA : round.optionB } ?? L10n.thisOrThatTimeoutLabel(locale: locale)
            cameraController.recorder.logOverlayEvent(.showAnswer(text: text, playerIndex: videoPlayerIndex))
        case .finished:
            break
        }
    }

    private func finishRecording() {
        lifecycle = .done
        let summary = state.pickedLabels.isEmpty
            ? L10n.thisOrThatEmptyResultSummary(locale: locale)
            : state.pickedLabels.joined(separator: " • ")

        guard recordingEnabled else {
            playHistoryStore.addRecord(mode: .thisOrThat, packTitle: template.title, resultSummary: summary, playerCount: playerCount)
            path.append(.thisOrThatResult(template: template, pickedLabels: state.pickedLabels, playerCount: playerCount))
            return
        }
        cameraController.recorder.stopRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            session.reset()
            session.rawVideoURL = cameraController.recorder.lastRecordedURL
            session.overlayEvents = cameraController.recorder.overlayEvents
            let record = playHistoryStore.addRecord(
                mode: .thisOrThat, packTitle: template.title, resultSummary: summary, playerCount: playerCount
            )
            session.pendingHistoryRecordID = record.id
            path.append(.saveDecision)
        }
    }
}
