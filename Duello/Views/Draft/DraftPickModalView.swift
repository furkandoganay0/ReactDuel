import SwiftUI

/// Bir item'a dokunulduğunda açılan onay kartı.
///
/// Teknik prompt Bölüm 7.4, kamerayı köşeye küçük bir PIP olarak taşımayı
/// öneriyor ("seçim anındaki tepki de kayda girsin diye"). Burada daha basit
/// ve daha az riskli bir yaklaşım tercih edildi: kamera HER ZAMAN tam ekran
/// kalır, bu kart sadece ekranın alt yarısını kaplayan yarı saydam bir katman —
/// aynı ürün amacına (dokunuş anındaki tepkinin kadrajda kalması) ulaşıyor,
/// ama preview layer'ı köşeye taşıyıp geri getiren ek animasyon durumu
/// gerektirmiyor. Gerçek cihazda daha iyi hissettirirse köşe-PIP'e geçmek v1.1
/// cilası olarak bırakıldı.
struct DraftPickModalView: View {
    let item: DraftPoolItem
    let remainingBudgetAfterPick: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 40, height: 5)
                    .padding(.top, 10)

                PlaceholderCoverView(imageName: item.image, label: item.name)
                    .frame(width: 96, height: 96)

                Text(item.name)
                    .font(.title3.bold())
                    .foregroundStyle(.white)

                Text(L10n.pickCostLabel(cost: item.cost, remainingBudgetAfterPick: remainingBudgetAfterPick, locale: locale))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))

                HStack(spacing: 12) {
                    Button(role: .cancel, action: onCancel) {
                        Text("Vazgeç")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.15))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button(action: onConfirm) {
                        Text("Seç")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(.black.opacity(0.88))
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ZStack {
        Color.gray
        DraftPickModalView(
            item: DraftPoolItem(id: "1", name: "Lionel Messi", cost: 9, image: "messi"),
            remainingBudgetAfterPick: 11,
            onConfirm: {},
            onCancel: {}
        )
    }
}
