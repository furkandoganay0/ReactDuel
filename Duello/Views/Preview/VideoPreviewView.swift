import SwiftUI
import AVKit

/// Önizleme ekranı — render edilmiş videoyu oynatır, "Tekrar Çek" / "Paylaş".
struct VideoPreviewView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @State private var player: AVPlayer?
    @State private var isShowingShareSheet = false

    var body: some View {
        VStack(spacing: 0) {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea(edges: .top)
                    .onAppear { player.play() }
            } else {
                Color.black.ignoresSafeArea(edges: .top)
            }

            HStack(spacing: 16) {
                Button {
                    // Basitlik ve durum-bütünlüğü için kök ekrana dönüyoruz —
                    // kayıt view'larının @State'ini "yarım kalmış" bir noktadan
                    // geri yüklemeye çalışmak yerine kategori seçiminden
                    // temiz bir başlangıç yapmak daha güvenilir.
                    session.reset()
                    path.removeAll()
                } label: {
                    Label("Tekrar Çek", systemImage: "arrow.counterclockwise")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary.opacity(0.08))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    isShowingShareSheet = true
                } label: {
                    Label("Paylaş", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let url = session.exportedVideoURL {
                player = AVPlayer(url: url)
            }
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = session.exportedVideoURL {
                ShareSheet(items: [url])
            }
        }
    }
}
