import AVFoundation
import UIKit

/// Kaydedilen bir videonun küçük bir önizleme karesini (JPEG) üretir — `HistoryView`
/// listesindeki genel mod ikonu yerine gerçek bir görsel gösterebilmek için.
/// Video zaten dikey (9:16) olduğundan tam kareyi olduğu gibi alıyoruz, sadece
/// dosya boyutunu küçük tutmak için piksel boyutunu sınırlıyoruz.
enum VideoThumbnailGenerator {
    /// `videoURL`'in ilk saniyesinden bir kare çıkarıp `outputURL`'e JPEG olarak yazar.
    /// Başarısız olursa (bozuk video, decode hatası vb.) sessizce `false` döner —
    /// galeri kaydı yine de devam etmeli, thumbnail sadece kozmetik bir ekleme.
    static func generateThumbnail(from videoURL: URL, to outputURL: URL, maxDimension: CGFloat = 480) -> Bool {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxDimension, height: maxDimension)

        let time = CMTime(seconds: 0.1, preferredTimescale: 600)
        guard let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) else { return false }

        let uiImage = UIImage(cgImage: cgImage)
        guard let jpegData = uiImage.jpegData(compressionQuality: 0.7) else { return false }

        do {
            try jpegData.write(to: outputURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
