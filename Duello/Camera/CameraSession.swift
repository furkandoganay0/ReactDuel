import AVFoundation

/// Ön kamera + mikrofon `AVCaptureSession`'ını yönetir.
///
/// Bilinçli olarak `@MainActor` DEĞİL: session konfigürasyonu Apple'ın kendi
/// önerdiği gibi ayrı bir seri kuyrukta (`sessionQueue`) yapılıyor, sadece
/// `@Published` state güncellemeleri ana thread'e sıçratılıyor. Sınıfı
/// `@MainActor` yapmak, `sessionQueue.async` içinden actor-izole metodları
/// senkron çağırmayı derleme hatasına çevirirdi.
final class CameraSession: NSObject, ObservableObject {
    let session = AVCaptureSession()

    @Published private(set) var isConfigured = false
    @Published private(set) var isRunning = false
    @Published private(set) var configurationError: CameraConfigurationError?

    private let sessionQueue = DispatchQueue(label: "com.reactduel.app.camera.session")

    enum CameraConfigurationError: Error, Equatable {
        case noFrontCamera
        case cannotAddVideoInput
    }

    /// Konfigürasyon bitince ana thread'de çağrılır.
    func configureIfNeeded(completion: (() -> Void)? = nil) {
        guard !isConfigured else {
            completion?()
            return
        }
        sessionQueue.async { [weak self] in
            self?.configureSession()
            DispatchQueue.main.async { completion?() }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        DispatchQueue.main.async { [weak self] in self?.configurationError = nil }

        session.sessionPreset = .hd1920x1080

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            postConfigurationError(.noFrontCamera)
            return
        }

        guard let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              session.canAddInput(videoInput) else {
            postConfigurationError(.cannotAddVideoInput)
            return
        }
        session.addInput(videoInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio),
           let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
           session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }

        DispatchQueue.main.async { [weak self] in
            self?.isConfigured = true
        }
    }

    private func postConfigurationError(_ error: CameraConfigurationError) {
        DispatchQueue.main.async { [weak self] in
            self?.configurationError = error
        }
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self, self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }
}
