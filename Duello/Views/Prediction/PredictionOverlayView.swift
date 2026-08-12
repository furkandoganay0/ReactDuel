import SwiftUI

/// Kayıt sırasında kullanıcının GÖRDÜĞÜ canlı SwiftUI overlay'i. Bu, final videoya
/// yakılan `OverlayCompositionBuilder`'ın CALayer overlay'inden AYRI bir katman —
/// ikisi de aynı event log'dan (prompt/answer) besleniyor ama biri canlı önizleme
/// (bu dosya), diğeri post-processing burn-in (Bölüm 9). Görsel dilin tutarlı
/// olması için renk/yerleşim seçimleri kasıtlı olarak `OverlayCompositionBuilder`
/// ile benzer tutuldu.
struct PredictionOverlayView: View {
    let phase: PredictionPhase
    let question: PredictionQuestion?
    let choices: [String]
    let questionNumber: Int
    let totalQuestions: Int
    let secondsRemaining: Int
    let selectedAnswerIndex: Int?
    let onSelect: (Int) -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 14) {
            progressBadge

            if let question, phase == .prompt {
                promptCard(question: question)
                choiceGrid
            } else if let question, phase == .reveal {
                answerCard(question: question)
            }
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)
        .animation(.easeInOut(duration: 0.2), value: phase)
    }

    private var progressBadge: some View {
        Text(L10n.questionProgress(current: min(questionNumber, totalQuestions), total: totalQuestions, locale: locale))
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.6))
            .clipShape(Capsule())
    }

    private func promptCard(question: PredictionQuestion) -> some View {
        VStack(spacing: 10) {
            Text(question.prompt)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("\(secondsRemaining)")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText(countsDown: true))
                .animation(.easeInOut(duration: 0.25), value: secondsRemaining)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.opacity)
    }

    private var choiceGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                Button {
                    onSelect(index)
                } label: {
                    Text(choice)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .padding(.horizontal, 10)
                        .background(Color.blue.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(PressableButtonStyle())
                .disabled(selectedAnswerIndex != nil)
            }
        }
        .transition(.opacity)
    }

    private func answerCard(question: PredictionQuestion) -> some View {
        VStack(spacing: 6) {
            Text(L10n.feedbackTitle(selectedCorrect: selectedCorrect, locale: locale))
                .font(.title3.weight(.bold))
            Text(question.answer)
                .font(.system(size: 26, weight: .bold))
        }
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(20)
        .frame(maxWidth: .infinity)
        .background((selectedCorrect == true ? Color.green : Color.red).opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .transition(.scale.combined(with: .opacity))
    }

    /// `nil` — süre doldu, hiç cevaplanmadı. `true`/`false` — seçilen şıkkın doğruluğu.
    private var selectedCorrect: Bool? {
        guard let selectedAnswerIndex, choices.indices.contains(selectedAnswerIndex), let question else {
            return nil
        }
        return choices[selectedAnswerIndex] == question.answer
    }
}

/// Dokunulunca hafifçe küçülen, "canlı" hissettiren buton stili — şık butonları için.
private struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    ZStack {
        Color.black
        PredictionOverlayView(
            phase: .prompt,
            question: PredictionQuestion(
                id: "q1", prompt: "Test sorusu", answer: "Cevap", answerImage: "x", timerSeconds: 6,
                choices: ["Cevap", "Yanlış 1", "Yanlış 2", "Yanlış 3"]
            ),
            choices: ["Cevap", "Yanlış 1", "Yanlış 2", "Yanlış 3"],
            questionNumber: 2,
            totalQuestions: 5,
            secondsRemaining: 4,
            selectedAnswerIndex: nil,
            onSelect: { _ in }
        )
    }
}
