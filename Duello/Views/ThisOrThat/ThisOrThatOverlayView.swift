import SwiftUI

/// "Bu mu O mu" modunun canlı kayıt overlay'i — `PredictionOverlayView` ile
/// aynı görsel dil (oyuncu rengi/rozeti, pop animasyonu), ama doğru/yanlış
/// yerine sadece iki büyük seçenek butonu var.
struct ThisOrThatOverlayView: View {
    let phase: ThisOrThatPhase
    let round: ThisOrThatRound?
    let secondsRemaining: Int
    let selectedOption: Bool?
    let playerCount: Int
    let currentPlayerIndex: Int
    let onSelect: (Bool) -> Void

    @Environment(\.locale) private var locale

    private var isMultiplayer: Bool { playerCount > 1 }

    private var currentPlayerColor: Color {
        currentPlayerIndex == 0 ? .indigo : .orange
    }

    var body: some View {
        VStack(spacing: 16) {
            if isMultiplayer {
                HStack {
                    Spacer()
                    turnBanner
                }
            }

            Spacer()

            if let round, phase == .choosing {
                optionButtons(round: round)
            } else if let round, phase == .revealed {
                revealCard(round: round)
            }

            Spacer()

            if phase == .choosing {
                Text("\(secondsRemaining)")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.easeInOut(duration: 0.25), value: secondsRemaining)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 50)
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.2), value: phase)
    }

    private var turnBanner: some View {
        HStack(spacing: 6) {
            Text("\(currentPlayerIndex + 1)")
                .font(.caption.weight(.black))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(.white.opacity(0.28)))
            Text(L10n.playerTurnLabel(currentPlayerIndex, locale: locale))
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(currentPlayerColor.gradient)
        .clipShape(Capsule())
        .shadow(color: currentPlayerColor.opacity(0.5), radius: 8, y: 3)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private func optionButtons(round: ThisOrThatRound) -> some View {
        VStack(spacing: 14) {
            optionButton(text: round.optionA, isA: true)
            Text("VS")
                .font(.headline.weight(.black))
                .foregroundStyle(.white.opacity(0.55))
            optionButton(text: round.optionB, isA: false)
        }
        .transition(.opacity)
    }

    private func optionButton(text: String, isA: Bool) -> some View {
        Button {
            onSelect(isA)
        } label: {
            Text(text)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 92)
                .padding(.horizontal, 16)
                .background((isMultiplayer ? currentPlayerColor : (isA ? Color.blue : Color.pink)).opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(selectedOption != nil)
    }

    private func revealCard(round: ThisOrThatRound) -> some View {
        Group {
            if let selectedOption {
                Text(selectedOption ? round.optionA : round.optionB)
            } else {
                Text("⏱️ Süre doldu")
            }
        }
        .font(.system(size: 34, weight: .black))
        .foregroundStyle(.white)
        .multilineTextAlignment(.center)
        .padding(28)
        .frame(maxWidth: .infinity)
        .background((isMultiplayer ? currentPlayerColor : Color.purple).gradient)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .transition(.scale.combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.black
        ThisOrThatOverlayView(
            phase: .choosing,
            round: ThisOrThatRound(id: "r1", optionA: "Pizza", optionB: "Burger", timerSeconds: 5),
            secondsRemaining: 3,
            selectedOption: nil,
            playerCount: 2,
            currentPlayerIndex: 0,
            onSelect: { _ in }
        )
    }
}
