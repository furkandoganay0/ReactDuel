import SwiftUI

/// `recordingEnabled == false` ile oynanan Tahmin Et oturumlarının sonuç
/// ekranı — kayıt/işleme/paylaşım akışı hiç devreye girmediği için
/// `ProcessingView`/`VideoPreviewView` yerine doğrudan skoru gösterir.
struct PredictionResultView: View {
    let template: PredictionTemplate
    let score: Int
    @Binding var path: [AppRoute]

    @Environment(\.locale) private var locale
    @State private var didAppear = false

    private var total: Int { template.questions.count }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(scoreEmoji)
                .font(.system(size: 64))
                .scaleEffect(didAppear ? 1 : 0.4)
                .opacity(didAppear ? 1 : 0)

            Text(L10n.scoreSummary(score: score, total: total, locale: locale))
                .font(.title.bold())
                .multilineTextAlignment(.center)

            Text(L10n.scoreFeedback(score: score, total: total, locale: locale))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    path.removeLast()
                    path.append(.predictionRecording(template, recordingEnabled: false))
                } label: {
                    Text("Tekrar Oyna")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    path.removeAll()
                } label: {
                    Text("Ana Sayfa")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.08))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                didAppear = true
            }
        }
    }

    private var scoreEmoji: String {
        guard total > 0 else { return "🎯" }
        return Double(score) / Double(total) == 1.0 ? "🏆" : "🎯"
    }
}

#Preview {
    NavigationStack {
        PredictionResultView(
            template: PredictionTemplate(
                id: "t", mode: "prediction", title: "Test", coverImage: "c",
                questions: []
            ),
            score: 3,
            path: .constant([])
        )
    }
}
