import AVFoundation

/// Tahmin Et ve Bütçeli Draft kayıt ekranlarının ortak kullandığı, `CameraSession`
/// ve `VideoRecorder`'ı tek yerde kablolayan orkestratör.
final class CameraController: ObservableObject {
    let cameraSession = CameraSession()
    let recorder = VideoRecorder()

    @Published private(set) var isReady = false
    /// `CameraSession` konfigürasyonu başarısız olduğunda set edilir. `cameraSession`
    /// kendisi `@Published` DEĞİL (bkz. CameraSession yorumu) — bu yüzden View'ların
    /// gözlemleyebilmesi için hatayı buraya, gerçekten `@Published` olan bir alana
    /// kopyalıyoruz. Önceki haliyle bu hiç okunmuyordu: konfigürasyon başarısız olsa
    /// bile `isReady` koşulsuz `true` set ediliyor, kayıt ekranı sanki kamera hazırmış
    /// gibi devam ediyordu (sessiz, videosuz bir "kayıt" ile sonuçlanan bir bug).
    @Published private(set) var configurationError: CameraSession.CameraConfigurationError?

    func prepare() {
        configurationError = nil
        cameraSession.configureIfNeeded { [weak self] in
            guard let self else { return }
            guard self.cameraSession.isConfigured else {
                self.configurationError = self.cameraSession.configurationError ?? .cannotAddVideoInput
                return
            }
            self.recorder.attachIfNeeded(to: self.cameraSession.session)
            self.isReady = true
            self.cameraSession.start()
        }
    }

    func teardown() {
        if recorder.isRecording {
            recorder.stopRecording()
        }
        cameraSession.stop()
    }
}
