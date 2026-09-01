import SwiftUI
import UIKit
import AVFoundation

/// `AVCaptureVideoPreviewLayer`'ı SwiftUI'a sarmalayan tam ekran canlı önizleme.
///
/// NOT: Simulator kamera akışı vermez — bu view'ın gerçekten çalıştığını
/// doğrulamak için gerçek cihazda çalıştırmak gerekir (Bölüm 13, Adım 4).
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        // Oturum henüz kare üretmiyorsa (izin reddi, konfigürasyon hatası, ya da
        // Simulator'da hiç) katman şeffaf kalır — arkasında ne varsa o görünür.
        // `CameraErrorView`'ın beyaz metni böyle bir zeminde kayboluyordu; sabit
        // siyah zemin bunu cihazdan/duruma bağımsız hale getiriyor.
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        // Session sabit — güncellenecek bir şey yok. Layout değişimlerini
        // UIView'ın kendi layoutSubviews'ı hallediyor.
    }

    final class PreviewUIView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            // swiftlint:disable:next force_cast
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
