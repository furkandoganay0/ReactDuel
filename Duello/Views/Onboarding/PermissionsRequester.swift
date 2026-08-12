import AVFoundation
import Photos

enum PermissionStatus: Equatable {
    case notDetermined
    case granted
    case denied
}

/// Kamera/mikrofon/foto kütüphanesi izinlerini isteyen ince bir sarmalayıcı.
/// Sistem API'lerine doğrudan bağımlı olan tek katman — `OnboardingView`
/// bunu çağırır, sonucu `@Published` ile UI'a yansıtır.
@MainActor
final class PermissionsRequester: ObservableObject {
    @Published private(set) var cameraStatus: PermissionStatus = .notDetermined
    @Published private(set) var microphoneStatus: PermissionStatus = .notDetermined
    @Published private(set) var photoLibraryStatus: PermissionStatus = .notDetermined

    var allGranted: Bool {
        cameraStatus == .granted && microphoneStatus == .granted && photoLibraryStatus == .granted
    }

    func refreshStatuses() {
        cameraStatus = Self.map(AVCaptureDevice.authorizationStatus(for: .video))
        microphoneStatus = Self.map(AVCaptureDevice.authorizationStatus(for: .audio))
        photoLibraryStatus = Self.map(PHPhotoLibrary.authorizationStatus(for: .addOnly))
    }

    func requestAll() async {
        let cameraGranted = await AVCaptureDevice.requestAccess(for: .video)
        cameraStatus = cameraGranted ? .granted : .denied

        let micGranted = await AVCaptureDevice.requestAccess(for: .audio)
        microphoneStatus = micGranted ? .granted : .denied

        let photoStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        photoLibraryStatus = Self.map(photoStatus)
    }

    private static func map(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited: return .granted
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}
