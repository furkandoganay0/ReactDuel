import SwiftUI

/// Draft bitince gösterilen sonuç overlay'i — kayıt HALEN devam ederken
/// ekranda kalır (teknik prompt Bölüm 7.5: "bu da videonun son 3-4 saniyesi
/// olarak kayda dahil"). Ayrı bir ekran/route DEĞİL, `DraftRecordingView`
/// içinde bir overlay.
struct DraftResultView: View {
    let template: DraftTemplate
    let rosterA: [DraftPoolItem]
    let rosterB: [DraftPoolItem]
    let result: DraftResult

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(spacing: 20) {
            Text(L10n.resultTextWithEmoji(result, locale: locale))
                .font(.title.bold())
                .foregroundStyle(.white)
                .padding(.top, 40)
                .transition(.scale.combined(with: .opacity))

            HStack(alignment: .top, spacing: 16) {
                rosterColumn(
                    label: L10n.playerShortLabel(.playerA, locale: locale),
                    roster: rosterA,
                    isWinner: result == .winner(.playerA)
                )
                rosterColumn(
                    label: L10n.playerShortLabel(.playerB, locale: locale),
                    roster: rosterB,
                    isWinner: result == .winner(.playerB)
                )
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.55).ignoresSafeArea())
    }

    private func rosterColumn(label: String, roster: [DraftPoolItem], isWinner: Bool) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.white)
            Text(L10n.totalCostLabel(DraftScoreCalculator.totalCost(of: roster), locale: locale))
                .font(.subheadline.bold())
                .foregroundStyle(isWinner ? .yellow : .white.opacity(0.85))
            ForEach(roster) { item in
                Text(item.name)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(isWinner ? Color.orange.opacity(0.25) : Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isWinner ? Color.yellow.opacity(0.6) : .clear, lineWidth: 2)
        )
    }
}

#Preview {
    DraftResultView(
        template: DraftTemplate(id: "t", mode: "draft", title: "Test", coverImage: "c", budget: 20, rosterSize: 2,
                                 pool: []),
        rosterA: [DraftPoolItem(id: "1", name: "Messi", cost: 9, image: "messi")],
        rosterB: [DraftPoolItem(id: "2", name: "Ronaldo", cost: 9, image: "ronaldo")],
        result: .tie
    )
}
