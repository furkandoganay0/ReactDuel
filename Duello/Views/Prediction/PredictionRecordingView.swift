import SwiftUI
import UIKit

/// Tahmin Et modu kayıt ekranı — teknik prompt Bölüm 7.3.
/// Kayıt otomatik başlar (kısa bir 3-2-1 hazırlık sonrası), kategori bitince
/// birkaç saniye sonuç gösterilir (hâlâ kayıttayken) ve işleme ekranına
/// geçilir. `recordingEnabled == false` ise kamera hiç açılmaz, video
/// kaydedilmez — kullanıcı sadece skor görür. `playerCount == 2` ise sorular
/// oyuncular arasında sırayla paylaşılır (bkz. `PredictionTimerStateMachine`).
struct PredictionRecordingView: View {
    let template: PredictionTemplate
    let recordingEnabled: Bool
    let playerCount: Int
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @EnvironmentObject private var playHistoryStore: PlayHistoryStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.locale) private var locale

    @StateObject private var cameraController = CameraController()
    @State private var predictionState: PredictionState
    @State private var lifecycle: RecordingLifecycle = .preparingCamera
    @State private var recBlinkVisible = true

    private let resultDisplaySeconds = 4
    private let introDisplaySeconds = 2
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum RecordingLifecycle: Equatable {
        case preparingCamera
        case countdown(Int)
        case showingIntro(secondsLeft: Int)
        case recording
        case showingResult(secondsLeft: Int)
        case done
    }

    init(template: PredictionTemplate, recordingEnabled: Bool, playerCount: Int, path: Binding<[AppRoute]>) {
        self.template = template
        self.recordingEnabled = recordingEnabled
        self.playerCount = playerCount
        self._path = path
        self._predictionState = State(initialValue: PredictionTimerStateMachine.initialState(for: template, playerCount: playerCount))
    }

    var body: some View {
        ZStack {
            if recordingEnabled {
                CameraPreviewView(session: cameraController.cameraSession.session)
                    .ignoresSafeArea()
            } else {
                LinearGradient(colors: [.black, .indigo], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }

            if case .showingResult = lifecycle {
                PredictionSessionResultView(scoreByPlayer: predictionState.scoreByPlayer, total: template.questions.count)
            } else if case .showingIntro = lifecycle {
                introCard
            } else {
                PredictionOverlayView(
                    phase: predictionState.phase,
                    question: currentQuestion,
                    choices: predictionState.shuffledChoices,
                    questionNumber: predictionState.questionIndex + 1,
                    totalQuestions: template.questions.count,
                    secondsRemaining: predictionState.secondsRemaining,
                    selectedAnswerIndex: predictionState.selectedAnswerIndex,
                    playerCount: playerCount,
                    currentPlayerIndex: currentPlayerIndex,
                    onSelect: selectAnswer
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
        .onReceive(ticker) { _ in
            handleTick()
        }
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
        recordingEnabled && (lifecycle == .recording || isShowingResult || isShowingIntro)
    }

    private var currentPlayerIndex: Int {
        PredictionTimerStateMachine.currentPlayerIndex(questionIndex: predictionState.questionIndex, playerCount: playerCount)
    }

    /// `nil` tek kişilik oturumda — videoya yakılan kartlar `PlayerPalette`'te
    /// nötr siyaha düşer, canlıdaki nötr (renksiz) akışla eşleşsin diye.
    private var videoPlayerIndex: Int? {
        playerCount > 1 ? currentPlayerIndex : nil
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
        .background(Color.indigo.gradient)
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

    private var currentQuestion: PredictionQuestion? {
        guard predictionState.questionIndex < template.questions.count else { return nil }
        return template.questions[predictionState.questionIndex]
    }

    /// Kamera açılamadığında (izin reddi vb.) sunulan çıkış yolu — aynı soru
    /// paketiyle, kamerasız/kayıtsız akışa geçer (bkz. `recordingEnabled == false`).
    private func switchToNoRecordingMode() {
        path.removeLast()
        path.append(.predictionRecording(template, recordingEnabled: false, playerCount: playerCount))
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
                lifecycle = .recording
                logCurrentPhaseIfNeeded()
            } else {
                lifecycle = .showingIntro(secondsLeft: secondsLeft - 1)
            }
        case .recording:
            recBlinkVisible.toggle()
            advancePrediction()
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

    /// Kayıt gerçekten başlar (kamera zaten çalışıyor); önce kısa bir "hook"
    /// kartı gösterilir (bkz. `introCard`), asıl soru akışı ondan sonra başlar.
    private func startRecording() {
        lifecycle = .showingIntro(secondsLeft: introDisplaySeconds)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if recordingEnabled {
            cameraController.recorder.startRecording()
            cameraController.recorder.logOverlayEvent(.showIntro(text: template.title))
        }
    }

    private func selectAnswer(_ index: Int) {
        guard lifecycle == .recording,
              predictionState.phase == .prompt,
              predictionState.selectedAnswerIndex == nil
        else { return }
        let isCorrect = predictionState.shuffledChoices.indices.contains(index)
            && currentQuestion.map { predictionState.shuffledChoices[index] == $0.answer } == true
        predictionState = PredictionTimerStateMachine.select(
            answerIndex: index, state: predictionState, template: template, playerCount: playerCount
        )
        UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)
        if appState.soundEffectsEnabled {
            isCorrect ? SoundEffectPlayer.playCorrect() : SoundEffectPlayer.playWrong()
        }
        logCurrentPhaseIfNeeded()
    }

    private func advancePrediction() {
        let previousPhase = predictionState.phase
        let previousIndex = predictionState.questionIndex
        predictionState = PredictionTimerStateMachine.tick(state: predictionState, template: template)

        if predictionState.phase == .finished {
            showResultThenFinish()
            return
        }
        if predictionState.phase != previousPhase || predictionState.questionIndex != previousIndex {
            logCurrentPhaseIfNeeded()
        }
    }

    private func showResultThenFinish() {
        if recordingEnabled {
            cameraController.recorder.logOverlayEvent(
                .showResult(
                    text: L10n.predictionResultOverlayText(
                        scoreByPlayer: predictionState.scoreByPlayer, total: template.questions.count, locale: locale
                    ),
                    playerIndex: nil
                )
            )
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        lifecycle = .showingResult(secondsLeft: resultDisplaySeconds)
    }

    /// Canlı ekranda gördüğün her şeyin (ilerleme rozeti, şık butonları, oyuncu
    /// rengi) videoya da yakılmasını sağlar — önceden video sadece soru metnini
    /// gösteriyordu, izleyici şıkların ne olduğunu hiç göremiyordu.
    private func logCurrentPhaseIfNeeded() {
        guard recordingEnabled, let question = currentQuestion else { return }
        switch predictionState.phase {
        case .prompt:
            let progress = L10n.questionProgress(
                current: predictionState.questionIndex + 1, total: template.questions.count, locale: locale
            )
            cameraController.recorder.logOverlayEvent(
                .showPrompt(text: "\(progress)\n\n\(question.prompt)", playerIndex: videoPlayerIndex)
            )
            cameraController.recorder.logOverlayEvent(
                .showChoices(text: choicesVideoText(), playerIndex: videoPlayerIndex)
            )
        case .reveal:
            cameraController.recorder.logOverlayEvent(
                .showAnswer(text: revealText(for: question), playerIndex: videoPlayerIndex)
            )
        case .finished:
            break
        }
    }

    private func choicesVideoText() -> String {
        let letters = ["A", "B", "C", "D"]
        return predictionState.shuffledChoices.enumerated()
            .map { index, choice in
                let letter = index < letters.count ? letters[index] : "•"
                return "\(letter)  \(choice)"
            }
            .joined(separator: "\n")
    }

    private func revealText(for question: PredictionQuestion) -> String {
        let selectedCorrect: Bool?
        if let selectedAnswerIndex = predictionState.selectedAnswerIndex,
           predictionState.shuffledChoices.indices.contains(selectedAnswerIndex) {
            selectedCorrect = predictionState.shuffledChoices[selectedAnswerIndex] == question.answer
        } else {
            selectedCorrect = nil
        }
        return L10n.answerFeedback(selectedCorrect: selectedCorrect, correctAnswer: question.answer, locale: locale)
    }

    private func finishRecording() {
        lifecycle = .done
        let summary = L10n.predictionHistorySummary(
            scoreByPlayer: predictionState.scoreByPlayer, total: template.questions.count, locale: locale
        )

        guard recordingEnabled else {
            playHistoryStore.addRecord(mode: .prediction, packTitle: template.title, resultSummary: summary, playerCount: playerCount)
            path.append(.predictionResult(template: template, scoreByPlayer: predictionState.scoreByPlayer))
            return
        }
        cameraController.recorder.stopRecording()
        // AVCaptureFileOutput delegate'i lastRecordedURL'i asenkron set ediyor —
        // kısa bir gecikmeyle bekleyip session'a aktarıyoruz.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            session.reset()
            session.rawVideoURL = cameraController.recorder.lastRecordedURL
            session.overlayEvents = cameraController.recorder.overlayEvents
            // Skor her zaman geçmişe eklenir; video sadece kullanıcı `SaveDecisionView`'da
            // onaylarsa (bkz. o ekran + `ProcessingView`) bu kayda iliştirilir.
            let record = playHistoryStore.addRecord(
                mode: .prediction, packTitle: template.title, resultSummary: summary, playerCount: playerCount
            )
            session.pendingHistoryRecordID = record.id
            path.append(.saveDecision)
        }
    }
}
