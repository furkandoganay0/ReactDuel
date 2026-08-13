import SwiftUI

/// Dokunulunca hafifçe küçülen, "canlı" hissettiren buton stili — kayıt
/// ekranlarındaki dokunmalı şık/seçenek butonları için ortak (bkz.
/// `PredictionOverlayView`, `ThisOrThatOverlayView`).
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
