import SwiftUI

/// `recordingEnabled == false` ile oynanan "Bu mu O mu" oturumlarının sonuç
/// ekranı — bkz. `PredictionResultView`/`DraftFinalResultView` üstündeki
/// gerekçe. Aynı "sıkışma" bugu burada da vardı: kayıtsız oturum bitince
/// `ThisOrThatSessionResultView` 4 saniye görünüp direkt Ana Sayfa'ya atıyordu.
struct ThisOrThatFinalResultView: View {
    let template: ThisOrThatTemplate
    let pickedLabels: [String]
    let playerCount: Int
    @Binding var path: [AppRoute]

    var body: some View {
        VStack(spacing: 0) {
            ThisOrThatSessionResultView(pickedLabels: pickedLabels)
            actionButtons
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                path.removeLast()
                path.append(.thisOrThatRecording(template, recordingEnabled: false, playerCount: playerCount))
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
                    .background(Color.white.opacity(0.12))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 12)
        .background(Color.black)
    }
}

#Preview {
    NavigationStack {
        ThisOrThatFinalResultView(
            template: ThisOrThatTemplate(id: "t", mode: "thisOrThat", title: "Test", coverImage: "c", rounds: []),
            pickedLabels: ["Pizza", "Dağ", "Kahve"],
            playerCount: 1,
            path: .constant([])
        )
    }
}
