import SwiftUI

/// Tahmin Et oturumu bitince gösterilen sonuç overlay'i — kayıt HALEN devam
/// ederken ekranda kalır (bkz. `DraftResultView`, aynı desen: son birkaç
/// saniye de kayda dahil olsun diye ayrı bir ekran/route değil, kayıt view'ı
/// içinde bir overlay).
struct PredictionSessionResultView: View {
    let scoreByPlayer: [Int]
    let total: Int

    @Environment(\.locale) private var locale

    private var isMultiplayer: Bool { scoreByPlayer.count > 1 }

    var body: some View {
        VStack(spacing: 20) {
            if isMultiplayer {
                Text(L10n.predictionWinnerText(scoreByPlayer: scoreByPlayer, locale: locale))
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 48)
                    .transition(.scale.combined(with: .opacity))

                HStack(spacing: 16) {
                    ForEach(scoreByPlayer.indices, id: \.self) { index in
                        scoreColumn(playerIndex: index)
                    }
                }
                .padding(.horizontal, 16)
            } else {
                Text("🎯")
                    .font(.system(size: 56))
                    .padding(.top, 56)
                Text(L10n.scoreSummary(score: scoreByPlayer.first ?? 0, total: total, locale: locale))
                    .font(.title.bold())
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.55).ignoresSafeArea())
    }

    private func scoreColumn(playerIndex: Int) -> some View {
        let score = scoreByPlayer[playerIndex]
        let isWinner = scoreByPlayer[0] != scoreByPlayer[1] && score == scoreByPlayer.max()
        let color: Color = playerIndex == 0 ? .indigo : .orange

        return VStack(spacing: 8) {
            Text(L10n.playerName(playerIndex, locale: locale))
                .font(.headline)
                .foregroundStyle(.white)
            Text("\(score)/\(total)")
                .font(.title2.bold())
                .foregroundStyle(isWinner ? .yellow : .white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(isWinner ? color.opacity(0.3) : Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isWinner ? Color.yellow.opacity(0.6) : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    PredictionSessionResultView(scoreByPlayer: [3, 2], total: 5)
}
