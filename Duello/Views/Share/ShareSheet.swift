import SwiftUI
import UIKit

/// `UIActivityViewController`'ı SwiftUI'a sarmalayan sistem paylaşım sayfası.
/// TikTok/Instagram/YouTube'a özel bir entegrasyon YOK — teknik prompt Bölüm 5:
/// `LSApplicationQueriesSchemes` gerektiren "yüklü mü kontrol et" akışı MVP
/// kapsamında yok, sistem paylaşım sayfası bu uygulamaları zaten listeler.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
