import SwiftUI
import UIKit

/// MVP'de gerçek fotoğraf/afiş asset'i yok (teknik prompt Bölüm 14 — açık soru,
/// placeholder ile ilerleniyor; ayrıca playbook Bölüm 7'nin "hassas/telifli
/// görsel kullanma" uyarısıyla da uyumlu: gerçek kişi/film görseli lisans
/// gerektirir). Bu view, `imageName`'e karşılık gelen bir asset bundle'da VARSA
/// onu gösterir; yoksa isimden deterministik bir renk üretip baş harflerle
/// yerini tutar — böylece v2'de gerçek görseller eklendiğinde kod değişmeden
/// otomatik geçiş olur.
struct PlaceholderCoverView: View {
    let imageName: String
    let label: String
    var cornerRadius: CGFloat = 16

    var body: some View {
        Group {
            if let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: Self.gradientColors(for: imageName),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text(Self.initials(for: label))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private static func initials(for text: String) -> String {
        let words = text.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private static func gradientColors(for seed: String) -> [Color] {
        let palette: [[Color]] = [
            [.indigo, .purple],
            [.orange, .red],
            [.teal, .blue],
            [.pink, .purple],
            [.green, .teal],
            [.blue, .indigo]
        ]
        let hash = abs(seed.hashValue)
        return palette[hash % palette.count]
    }
}

#Preview {
    PlaceholderCoverView(imageName: "does_not_exist", label: "Erling Haaland")
        .frame(width: 160, height: 160)
}
