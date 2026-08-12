import Photos

/// Videoyu doğrudan Fotoğraflar kütüphanesine kaydeden ince bir sarmalayıcı —
/// paylaşım sayfasına gitmeden hızlı "Kaydet" kısayolu için (`VideoPreviewView`,
/// `HistoryView`). Onboarding'de zaten `.addOnly` foto kütüphanesi izni isteniyor
/// (bkz. `PermissionsRequester`) — burada yine de tek daha istek atıyoruz, çünkü
/// kullanıcı ilk seferinde reddedip sonradan Ayarlar'dan izin vermiş olabilir.
enum PhotoLibrarySaver {
    enum SaveError: Error {
        case notAuthorized
        case underlying(Error)
    }

    static func save(videoURL: URL, completion: @escaping (Result<Void, SaveError>) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(.failure(.notAuthorized)) }
                return
            }
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            } completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(()))
                    } else {
                        completion(.failure(.underlying(error ?? NSError(domain: "PhotoLibrarySaver", code: -1))))
                    }
                }
            }
        }
    }
}
