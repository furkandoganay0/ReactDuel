import AVFoundation

/// `AVCaptureMovieFileOutput` ile ham (overlay'siz) video kaydını yönetir ve
/// kayıt sırasında oluşan overlay olaylarını zaman damgasıyla loglar.
///
/// Event log toplama bilinçli olarak hafif: sadece bir struct append
/// (`logOverlayEvent`), hiçbir ağır iş (composition/export) burada yapılmaz —
/// bu, Bölüm 10'daki "ana thread bloklanmamalı" gereksinimi için kritik.
/// Ağır iş `VideoExporter`'a, kayıt bittikten SONRA devrediliyor.
final class VideoRecorder: NSObject, ObservableObject {
    let movieOutput = AVCaptureMovieFileOutput()

    @Published private(set) var isRecording = false
    @Published private(set) var lastRecordedURL: URL?
    @Published private(set) var recordingError: Error?

    private(set) var overlayEvents: [OverlayEvent] = []
    private var recordingStartDate: Date?

    /// Session'a bir kez eklenir (kamera konfigüre edildikten hemen sonra).
    @discardableResult
    func attachIfNeeded(to session: AVCaptureSession) -> Bool {
        guard session.canAddOutput(movieOutput) else { return false }
        session.addOutput(movieOutput)
        if let connection = movieOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }
        return true
    }

    func startRecording() {
        overlayEvents.removeAll()
        recordingStartDate = Date()
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mov")
        movieOutput.startRecording(to: tempURL, recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        movieOutput.stopRecording()
    }

    /// Kayıt başlangıcına göre saniye cinsinden bir overlay olayı kaydeder.
    /// `recordingStartDate` set değilse (kayıt henüz başlamadıysa) sessizce yok sayar.
    func logOverlayEvent(_ kind: OverlayEventKind) {
        guard let start = recordingStartDate else { return }
        let elapsed = Date().timeIntervalSince(start)
        overlayEvents.append(OverlayEvent(timestamp: elapsed, kind: kind))
    }
}

extension VideoRecorder: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isRecording = false
            if let error {
                self.recordingError = error
            } else {
                self.lastRecordedURL = outputFileURL
            }
        }
    }
}
