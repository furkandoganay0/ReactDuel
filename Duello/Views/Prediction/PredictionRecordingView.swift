import SwiftUI
import UIKit

/// Tahmin Et modu kayıt ekranı — teknik prompt Bölüm 7.3.
/// Kayıt otomatik başlar (kısa bir 3-2-1 hazırlık sonrası), kategori bitince
/// otomatik durur ve işleme ekranına geçilir. `recordingEnabled == false` ise
/// kamera hiç açılmaz, video kaydedilmez — kullanıcı sadece skor görür
/// (kayıt/paylaşım isteyenler için değil, hızlıca oynamak isteyenler için).
struct PredictionRecordingView: View {
    let template: PredictionTemplate
    let recordingEnabled: Bool
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @Environment(\.locale) private var locale

    @StateObject private var cameraController = CameraController()
    @State private var predictionState: PredictionState
    @State private var lifecycle: RecordingLifecycle = .preparingCamera
    @State private var recBlinkVisible = true

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    enum RecordingLifecycle: Equatable {
        case preparingCamera
        case countdown(Int)
        case recording
        case done
    }

    init(template: PredictionTemplate, recordingEnabled: Bool, path: Binding<[AppRoute]>) {
        self.template = template
        self.recordingEnabled = recordingEnabled
        self._path = path
        self._predictionState = State(initialValue: PredictionTimerStateMachine.initialState(for: template))
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

            PredictionOverlayView(
                phase: predictionState.phase,
                question: currentQuestion,
                choices: predictionState.shuffledChoices,
                questionNumber: predictionState.questionIndex + 1,
                totalQuestions: template.questions.count,
                secondsRemaining: predictionState.secondsRemaining,
                selectedAnswerIndex: predictionState.selectedAnswerIndex,
                onSelect: selectAnswer
            )

            if recordingEnabled, lifecycle == .recording {
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
        }
        .navigationBarBackButtonHidden(lifecycle != .preparingCamera)
        .toolbar(lifecycle == .preparingCamera ? .visible : .hidden, for: .navigationBar)
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
        path.append(.predictionRecording(template, recordingEnabled: false))
    }

    private func handleTick() {
        switch lifecycle {
        case .countdown(let n):
            if n <= 1 {
                startRecording()
            } else {
                lifecycle = .countdown(n - 1)
            }
        case .recording:
            recBlinkVisible.toggle()
            advancePrediction()
        case .preparingCamera, .done:
            break
        }
    }

    private func startRecording() {
        lifecycle = .recording
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        if recordingEnabled {
            cameraController.recorder.startRecording()
        }
        logCurrentPhaseIfNeeded()
    }

    private func selectAnswer(_ index: Int) {
        guard lifecycle == .recording,
              predictionState.phase == .prompt,
              predictionState.selectedAnswerIndex == nil
        else { return }
        let isCorrect = predictionState.shuffledChoices.indices.contains(index)
            && currentQuestion.map { predictionState.shuffledChoices[index] == $0.answer } == true
        predictionState = PredictionTimerStateMachine.select(answerIndex: index, state: predictionState, template: template)
        UINotificationFeedbackGenerator().notificationOccurred(isCorrect ? .success : .error)
        logCurrentPhaseIfNeeded()
    }

    private func advancePrediction() {
        let previousPhase = predictionState.phase
        let previousIndex = predictionState.questionIndex
        predictionState = PredictionTimerStateMachine.tick(state: predictionState, template: template)

        if predictionState.phase == .finished {
            finishRecording()
            return
        }
        if predictionState.phase != previousPhase || predictionState.questionIndex != previousIndex {
            logCurrentPhaseIfNeeded()
        }
    }

    private func logCurrentPhaseIfNeeded() {
        guard recordingEnabled, let question = currentQuestion else { return }
        switch predictionState.phase {
        case .prompt:
            cameraController.recorder.logOverlayEvent(.showPrompt(text: question.prompt))
        case .reveal:
            cameraController.recorder.logOverlayEvent(.showAnswer(text: revealText(for: question)))
        case .finished:
            break
        }
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
        guard recordingEnabled else {
            path.append(.predictionResult(template: template, score: predictionState.score))
            return
        }
        cameraController.recorder.stopRecording()
        // AVCaptureFileOutput delegate'i lastRecordedURL'i asenkron set ediyor —
        // kısa bir gecikmeyle bekleyip session'a aktarıyoruz.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            session.reset()
            session.rawVideoURL = cameraController.recorder.lastRecordedURL
            session.overlayEvents = cameraController.recorder.overlayEvents
            path.append(.processing)
        }
    }
}
