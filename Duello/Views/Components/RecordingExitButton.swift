import SwiftUI

/// Kayıt ekranlarının (Tahmin Et / Draft) sol üstünde gösterilen, her zaman
/// erişilebilir çıkış butonu. Önceden geri tuşu sadece kamera hazırlanırken
/// görünürdü — kayıt başladıktan sonra kullanıcının çıkış yolu yoktu. Aktif
/// bir kayıt varken dokunulursa onay ister (video kaybolacağı için), henüz
/// kayıt başlamadıysa direkt çıkar.
struct RecordingExitButton: View {
    let hasActiveRecording: Bool
    let onExit: () -> Void

    @State private var isShowingConfirmation = false

    var body: some View {
        VStack {
            HStack {
                Button {
                    if hasActiveRecording {
                        isShowingConfirmation = true
                    } else {
                        onExit()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
                .padding(.leading, 16)
                .padding(.top, 12)

                Spacer()
            }
            Spacer()
        }
        .confirmationDialog(
            Text("Kaydı bırakmak istediğine emin misin?"),
            isPresented: $isShowingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Kaydı Bırak", role: .destructive, action: onExit)
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Şu ana kadar kaydettiğin video kaybolacak.")
        }
    }
}
