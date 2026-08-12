import SwiftUI

/// Kayıt bitince gösterilen ilk ekran — video ARTIK otomatik export edilmiyor.
/// Kullanıcı "Videoyu Kaydet" derse export/önizleme/paylaşım akışına girilir;
/// "Kaydetme" derse ham kayıt silinir, sadece skor geçmişe eklenmiş olarak kalır
/// (bkz. `PlayHistoryStore`, kayıt zaten oyun bitince eklendi).
struct SaveDecisionView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "video.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(.indigo)

            Text("Videoyu kaydetmek ister misin?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("Kaydetmezsen çektiğin görüntü silinir — skorun yine de geçmişine eklenmiş olur.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    path.append(.processing)
                } label: {
                    Label("Videoyu Kaydet", systemImage: "square.and.arrow.down")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    session.discardRawVideo()
                    path.removeAll()
                } label: {
                    Text("Kaydetme")
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
    }
}

#Preview {
    NavigationStack {
        SaveDecisionView(path: .constant([]))
            .environmentObject(RecordingSessionStore())
    }
}
