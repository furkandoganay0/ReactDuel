import SwiftUI
import UIKit

/// Kamera konfigürasyonu başarısız olduğunda (izin reddi, kamera meşgul, vb.)
/// "Kamera hazırlanıyor…" spinner'ı yerine gösterilen hata kartı. Önceden bu
/// durum hiç ele alınmıyordu — kullanıcı sonsuz spinner'da kalıyor ya da (asıl
/// bug) uygulama sanki kamera hazırmış gibi videosuz bir kayda devam ediyordu.
struct CameraErrorView: View {
    let error: CameraSession.CameraConfigurationError
    let onRetry: () -> Void
    var onContinueWithoutRecording: (() -> Void)?

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "video.slash.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white)

            Text(L10n.cameraErrorTitle(locale: locale))
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(L10n.cameraErrorMessage(error, locale: locale))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 10) {
                Button(action: onRetry) {
                    Text("Tekrar Dene")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Ayarlar'a Git")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                if let onContinueWithoutRecording {
                    Button(action: onContinueWithoutRecording) {
                        Text("Kayıtsız Devam Et")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        CameraErrorView(error: .cannotAddVideoInput, onRetry: {}, onContinueWithoutRecording: {})
    }
}
