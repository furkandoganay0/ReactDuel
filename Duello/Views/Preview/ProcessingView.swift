import SwiftUI

/// "Video hazırlanıyor…" ekranı — Bölüm 9, adım 4: render sırasında kullanıcıya
/// gösterilen yükleniyor ekranı. Ağır iş (`VideoExporter.export`) burada,
/// kayıt bittikten SONRA tetikleniyor (Bölüm 10 non-fonksiyonel gereksinim).
struct ProcessingView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var session: RecordingSessionStore
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
                    session.startExportIfNeeded()
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
            session.startExportIfNeeded()
        }
        .onChange(of: session.exportedVideoURL) { url in
            guard url != nil else { return }
            if !path.isEmpty { path.removeLast() }
            path.append(.preview)
        }
    }
}
