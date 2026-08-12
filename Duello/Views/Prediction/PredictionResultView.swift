import SwiftUI

/// `recordingEnabled == false` ile oynanan Tahmin Et oturumlarının sonuç
/// ekranı — kayıt/işleme/paylaşım akışı hiç devreye girmediği için
/// `ProcessingView`/`VideoPreviewView` yerine doğrudan skoru gösterir.
/// `scoreByPlayer` tek elemanlıysa (tek kişilik oturum) basit bir özet,
/// iki elemanlıysa (iki kişilik oturum) kazananı da içeren bir karşılaştırma gösterir.
struct PredictionResultView: View {
    let template: PredictionTemplate
    let scoreByPlayer: [Int]
    @Binding var path: [AppRoute]

    @Environment(\.locale) private var locale
    @State private var didAppear = false

    private var total: Int { template.questions.count }
    private var isMultiplayer: Bool { scoreByPlayer.count > 1 }
    private var playerCount: Int { max(scoreByPlayer.count, 1) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(scoreEmoji)
                .font(.system(size: 64))
                .scaleEffect(didAppear ? 1 : 0.4)
                .opacity(didAppear ? 1 : 0)

            if isMultiplayer {
                Text(L10n.predictionWinnerText(scoreByPlayer: scoreByPlayer, locale: locale))
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                HStack(spacing: 16) {
                    ForEach(scoreByPlayer.indices, id: \.self) { index in
                        scoreColumn(playerIndex: index)
                    }
                }
                .padding(.horizontal, 24)
            } else {
                Text(L10n.scoreSummary(score: scoreByPlayer.first ?? 0, total: total, locale: locale))
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(L10n.scoreFeedback(score: scoreByPlayer.first ?? 0, total: total, locale: locale))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    path.removeLast()
                    path.append(.predictionRecording(template, recordingEnabled: false, playerCount: playerCount))
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

    private func scoreColumn(playerIndex: Int) -> some View {
        let score = scoreByPlayer[playerIndex]
        let isWinner = scoreByPlayer.count > 1 && scoreByPlayer[0] != scoreByPlayer[1] && score == scoreByPlayer.max()
        let color: Color = playerIndex == 0 ? .indigo : .orange

        return VStack(spacing: 6) {
            Text(L10n.playerName(playerIndex, locale: locale))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(score)/\(total)")
                .font(.title2.bold())
                .foregroundStyle(isWinner ? color : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(isWinner ? color.opacity(0.12) : Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(isWinner ? color.opacity(0.5) : .clear, lineWidth: 2)
        )
    }

    private var scoreEmoji: String {
        guard total > 0 else { return "🎯" }
        if isMultiplayer {
            return scoreByPlayer[0] == scoreByPlayer[1] ? "🤝" : "🏆"
        }
        return Double(scoreByPlayer.first ?? 0) / Double(total) == 1.0 ? "🏆" : "🎯"
    }
}

#Preview {
    NavigationStack {
        PredictionResultView(
            template: PredictionTemplate(
                id: "t", mode: "prediction", title: "Test", coverImage: "c",
                questions: []
            ),
            scoreByPlayer: [3, 2],
            path: .constant([])
        )
    }
}
