import SwiftUI

/// "Video hazırlanıyor…" ekranı — Bölüm 9, adım 4: render sırasında kullanıcıya
/// gösterilen yükleniyor ekranı. Ağır iş (`VideoExporter.export`) burada,
/// kayıt bittikten SONRA tetikleniyor (Bölüm 10 non-fonksiyonel gereksinim).
/// Buraya SADECE kullanıcı `SaveDecisionView`'da "Videoyu Kaydet" dediyse gelinir.
struct ProcessingView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var playHistoryStore: PlayHistoryStore
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            if let errorMessage = session.exportErrorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text("Video hazırlanamadı")
                    .font(.title3.bold())
                Text(L10n.exportErrorMessage(locale: locale))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Text(errorMessage)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Tekrar Dene") {
                    session.exportedVideoURL = nil
                    session.startExportIfNeeded(watermarkText: appState.resolvedWatermarkText, watermarkLogoData: appState.watermarkLogoData)
                }
                .buttonStyle(.borderedProminent)
            } else {
                ProgressView(value: session.exportProgress)
                    .frame(width: 220)
                    .tint(.indigo)
                Text("Video hazırlanıyor…")
                    .font(.headline)
                Text("\(Int(session.exportProgress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: session.exportProgress)
            }

            Spacer()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            session.startExportIfNeeded(watermarkText: appState.resolvedWatermarkText)
        }
        .onChange(of: session.exportedVideoURL) { url in
            guard let url else { return }
            saveToGalleryIfNeeded(exportedURL: url)
            if !path.isEmpty { path.removeLast() }
            path.append(.preview)
        }
    }

    /// Export'un çıktısı `tmp/` altında — sistem tarafından her an silinebilir,
    /// o yüzden `PlayHistoryStore`'un kalıcı Videos klasörüne bir KOPYA bırakıyoruz
    /// ve geçmiş kaydına iliştiriyoruz. `session.exportedVideoURL` kasıtlı olarak
    /// DEĞİŞTİRİLMİYOR — hâlâ tmp'yi gösteriyor, bu oturumdaki önizleme/paylaşım
    /// zaten ondan çalışıyor; galeri ayrı, kalıcı bir kopyadan besleniyor.
    private func saveToGalleryIfNeeded(exportedURL: URL) {
        guard let recordID = session.pendingHistoryRecordID else { return }
        session.pendingHistoryRecordID = nil

        let fileName = "\(recordID.uuidString).mp4"
        let destination = playHistoryStore.videosDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.copyItem(at: exportedURL, to: destination)

            // Thumbnail üretimi kozmetik — başarısız olsa bile (bozuk kare, decode
            // hatası vb.) video kaydı yine de tamamlanmalı, `HistoryView` o zaman
            // sadece genel mod ikonuna düşer.
            let thumbnailFileName = "\(recordID.uuidString).jpg"
            let thumbnailDestination = playHistoryStore.videosDirectory.appendingPathComponent(thumbnailFileName)
            let didGenerateThumbnail = VideoThumbnailGenerator.generateThumbnail(from: destination, to: thumbnailDestination)

            playHistoryStore.attachSavedVideo(
                to: recordID, fileName: fileName, thumbnailFileName: didGenerateThumbnail ? thumbnailFileName : nil
            )
        } catch {
            // Kopyalama başarısız olursa bu oturumdaki önizleme/paylaşım yine de
            // çalışır (tmp dosyası duruyor) — sadece galeriye düşmez.
        }
    }
}
