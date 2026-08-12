import SwiftUI
import AVKit
import UIKit

/// Önizleme ekranı — render edilmiş videoyu oynatır, "Paylaş" / "Kaydet" / "Tekrar Çek".
/// `Paylaş` sistem paylaşım sayfasını açar; `Kaydet` direkt Fotoğraflar'a yazar
/// (paylaşım sayfasına hiç girmeden hızlı kısayol).
struct VideoPreviewView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @State private var player: AVPlayer?
    @State private var isShowingShareSheet = false
    @State private var saveState: SaveState = .idle

    enum SaveState: Equatable {
        case idle, saving, saved, failed
    }

    var body: some View {
        VStack(spacing: 0) {
            if let player {
                VideoPlayer(player: player)
                    .ignoresSafeArea(edges: .top)
                    .onAppear { player.play() }
            } else {
                Color.black.ignoresSafeArea(edges: .top)
            }

            VStack(spacing: 12) {
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

                HStack(spacing: 16) {
                    Button {
                        saveToPhotos()
                    } label: {
                        saveButtonLabel
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.primary.opacity(0.08))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(saveState == .saving)

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

    @ViewBuilder
    private var saveButtonLabel: some View {
        switch saveState {
        case .idle:
            Label("Kaydet", systemImage: "square.and.arrow.down")
        case .saving:
            Label { Text("Kaydediliyor…") } icon: { ProgressView().controlSize(.small) }
        case .saved:
            Label("Kaydedildi", systemImage: "checkmark.circle.fill")
        case .failed:
            Label("Tekrar Dene", systemImage: "exclamationmark.triangle.fill")
        }
    }

    private func saveToPhotos() {
        guard let url = session.exportedVideoURL, saveState != .saving else { return }
        saveState = .saving
        PhotoLibrarySaver.save(videoURL: url) { result in
            switch result {
            case .success:
                saveState = .saved
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .failure:
                saveState = .failed
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }
}
