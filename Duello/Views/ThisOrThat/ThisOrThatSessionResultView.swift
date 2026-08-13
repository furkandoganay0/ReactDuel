import SwiftUI

/// "Bu mu O mu" oturumu bitince gösterilen özet — kayıt HALEN devam ederken
/// ekranda kalır (bkz. `DraftResultView`/`PredictionSessionResultView`, aynı desen).
/// Doğru/yanlış olmadığı için skor yerine "işte senin tercihlerin" şeridi gösteriyor.
struct ThisOrThatSessionResultView: View {
    let pickedLabels: [String]

    var body: some View {
        VStack(spacing: 20) {
            Text("🎉")
                .font(.system(size: 56))
                .padding(.top, 56)

            Text("Bitti!")
                .font(.title.bold())
                .foregroundStyle(.white)

            if !pickedLabels.isEmpty {
                Text("Tercihlerin:")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))

                pickedChipsFlow
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.55).ignoresSafeArea())
    }

    private var pickedChipsFlow: some View {
        // `LazyVGrid` ile basit bir sarma (wrap) düzeni — `pickedLabels` sayısı
        // paket başına küçük (tipik 8) olduğu için performans kaygısı yok.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 8) {
            ForEach(Array(pickedLabels.enumerated()), id: \.offset) { _, label in
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    ThisOrThatSessionResultView(pickedLabels: ["Pizza", "Dağ", "Kahve", "Kış", "Kedi"])
}
