import SwiftUI
import AVKit

/// "Geçmiş" — oynanan tüm oturumların (skor + varsa kaydedilen video) listesi.
/// Önceden hiçbir oturumun izi kalmıyordu; kullanıcı ekrandan çıkınca video da
/// skor da kayboluyordu. Artık `PlayHistoryStore` her oturumu (video isteğe bağlı) tutuyor.
struct HistoryView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var playHistoryStore: PlayHistoryStore
    @Environment(\.locale) private var locale
    @State private var playingRecord: PlaySessionRecord?

    var body: some View {
        Group {
            if playHistoryStore.records.isEmpty {
                emptyState
            } else {
                List {
                    if playHistoryStore.currentStreak > 0 {
                        streakHeader
                    }
                    ForEach(playHistoryStore.records) { record in
                        recordRow(record)
                            .swipeActions {
                                Button(role: .destructive) {
                                    withAnimation { playHistoryStore.deleteRecord(record) }
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(Text("Geçmiş"))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $playingRecord) { record in
            if let fileName = record.savedVideoFileName {
                HistoryVideoPlayerView(url: playHistoryStore.videosDirectory.appendingPathComponent(fileName))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Henüz oynanmış bir oturum yok")
                .font(.headline)
            Text("Oynadığın oyunlar ve kaydettiğin videolar burada birikecek.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var streakHeader: some View {
        HStack(spacing: 8) {
            Text("🔥")
            Text(L10n.streakLabel(days: playHistoryStore.currentStreak, locale: locale))
                .font(.subheadline.weight(.semibold))
        }
        .listRowBackground(Color.orange.opacity(0.12))
    }

    private func recordRow(_ record: PlaySessionRecord) -> some View {
        Button {
            guard record.savedVideoFileName != nil else { return }
            playingRecord = record
        } label: {
            HStack(spacing: 12) {
                Image(systemName: record.mode == .prediction ? "questionmark.circle.fill" : "person.2.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(record.mode == .prediction ? .indigo : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.packTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(record.resultSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(record.date, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary.opacity(0.8))
                }

                Spacer()

                if record.savedVideoFileName != nil {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .disabled(record.savedVideoFileName == nil)
    }
}

/// Geçmişten bir kayda dokununca açılan basit oynatıcı — paylaşım da içeriyor.
private struct HistoryVideoPlayerView: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isShowingShareSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                } else {
                    Color.black
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
                .padding(16)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
            .onAppear { player = AVPlayer(url: url) }
            .sheet(isPresented: $isShowingShareSheet) {
                ShareSheet(items: [url])
            }
        }
    }
}

#Preview {
    NavigationStack {
        HistoryView(path: .constant([]))
            .environmentObject(PlayHistoryStore())
    }
}
