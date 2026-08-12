import Foundation

/// Bir kayıt oturumunun (ham video + overlay event log + export sonucu) tek
/// gerçek kaynağı. `ProcessingView` ve `PreviewView` bunu okur; kayıt
/// ekranları (`PredictionRecordingView`, `DraftRecordingView`) bunu doldurur.
final class RecordingSessionStore: ObservableObject {
    @Published var rawVideoURL: URL?
    @Published var overlayEvents: [OverlayEvent] = []
    @Published var exportedVideoURL: URL?
    @Published var exportProgress: Float = 0
    @Published var exportErrorMessage: String?

    func reset() {
        rawVideoURL = nil
        overlayEvents = []
        exportedVideoURL = nil
        exportProgress = 0
        exportErrorMessage = nil
    }

    func startExportIfNeeded(watermarkText: String = "⚡ Duello") {
        guard let rawVideoURL, exportedVideoURL == nil else { return }
        exportErrorMessage = nil
        exportProgress = 0

        VideoExporter.export(
            rawVideoURL: rawVideoURL,
            overlayEvents: overlayEvents,
            outputURL: VideoExporter.makeOutputURL(),
            watermarkText: watermarkText,
            progressHandler: { [weak self] progress in
                self?.exportProgress = progress
            },
            completion: { [weak self] result in
                switch result {
                case .success(let url):
                    self?.exportedVideoURL = url
                case .failure(let error):
                    self?.exportErrorMessage = String(describing: error)
                }
            }
        )
    }
}
