import SwiftUI

/// `recordingEnabled == false` ile oynanan Draft oturumlarının sonuç ekranı —
/// bkz. `PredictionResultView` üstündeki gerekçe. Önceden kayıtsız bir Draft
/// bitince `DraftResultView` sadece 4 saniyeliğine (canlı overlay olarak)
/// görünüp ardından direkt Ana Sayfa'ya atıyordu — "Tekrar Oyna" seçeneği hiç
/// yoktu, tek kişilik/kamerasız test/oynanışta gerçek bir "sıkışma" noktasıydı.
struct DraftFinalResultView: View {
    let template: DraftTemplate
    let rosterA: [DraftPoolItem]
    let rosterB: [DraftPoolItem]
    let result: DraftResult
    @Binding var path: [AppRoute]

    var body: some View {
        VStack(spacing: 0) {
            DraftResultView(template: template, rosterA: rosterA, rosterB: rosterB, result: result)
            actionButtons
        }
        .background(Color.black.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                path.removeLast()
                path.append(.draftRecording(template, recordingEnabled: false))
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
        DraftFinalResultView(
            template: DraftTemplate(id: "t", mode: "draft", title: "Test", coverImage: "c", budget: 20, rosterSize: 2, pool: []),
            rosterA: [DraftPoolItem(id: "1", name: "Messi", cost: 9, image: "messi")],
            rosterB: [DraftPoolItem(id: "2", name: "Ronaldo", cost: 9, image: "ronaldo")],
            result: .tie,
            path: .constant([])
        )
    }
}
