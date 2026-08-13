import SwiftUI

/// Yatay kart listesi — teknik prompt Bölüm 7, "Kategori Seçimi".
struct CategorySelectionView: View {
    let mode: GameMode
    @Binding var path: [AppRoute]
    @EnvironmentObject private var appState: AppState
    @Environment(\.locale) private var locale
    @State private var recordingEnabled = true
    @State private var playerCount = 1
    /// 0 = paketteki tüm soru/round. Kısa/hızlı içerik için (bkz. Bölüm: influencer
    /// formatı) bir paketten sadece birkaçını çekip daha kısa bir video üretmeyi sağlar.
    @State private var itemCountLimit = 0

    private var title: LocalizedStringKey {
        switch mode {
        case .prediction: return "Tahmin Et"
        case .draft: return "Bütçeli Draft"
        case .thisOrThat: return "Bu mu O mu"
        }
    }

    /// Tek/iki kişi + hızlı mod seçicileri sadece "sıra tabanlı" modlarda anlamlı —
    /// Draft'ın kendi (her zaman 2 kişilik) turn akışı zaten var.
    private var showsSharedPickers: Bool {
        mode == .prediction || mode == .thisOrThat
    }

    var body: some View {
        ScrollView {
            if showsSharedPickers {
                playerCountPicker
                itemCountPicker
                recordingToggle
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                switch mode {
                case .prediction:
                    ForEach(appState.catalog.predictionPacks) { pack in
                        Button {
                            let selectedPack = trimmedPredictionPack(pack, limit: itemCountLimit)
                            path.append(.predictionRecording(selectedPack, recordingEnabled: recordingEnabled, playerCount: playerCount))
                        } label: {
                            CategoryCard(
                                imageName: pack.coverImage,
                                title: pack.title,
                                subtitle: L10n.questionCount(pack.questions.count, locale: locale)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                case .draft:
                    ForEach(appState.catalog.draftPacks) { pack in
                        Button {
                            path.append(.draftRecording(pack))
                        } label: {
                            CategoryCard(
                                imageName: pack.coverImage,
                                title: pack.title,
                                subtitle: L10n.draftSubtitle(budget: pack.budget, optionCount: pack.pool.count, locale: locale)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                case .thisOrThat:
                    ForEach(appState.catalog.thisOrThatPacks) { pack in
                        Button {
                            let selectedPack = trimmedThisOrThatPack(pack, limit: itemCountLimit)
                            path.append(.thisOrThatRecording(selectedPack, recordingEnabled: recordingEnabled, playerCount: playerCount))
                        } label: {
                            CategoryCard(
                                imageName: pack.coverImage,
                                title: pack.title,
                                subtitle: L10n.roundCount(pack.rounds.count, locale: locale)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Sorular HER ZAMAN karıştırılır (`limit == 0`/"Tümü" dahil) — önceden
    /// tam paket oynanınca sorular hep aynı, sabit sırada geliyordu, bu da
    /// paketi birkaç kez oynayınca "hep aynı sorular" hissi veriyordu.
    /// `limit > 0` ise ayrıca karıştırılmış listenin ilk `limit` tanesi alınır.
    private func trimmedPredictionPack(_ pack: PredictionTemplate, limit: Int) -> PredictionTemplate {
        let shuffled = pack.questions.shuffled()
        let selectedQuestions = (limit > 0 && limit < shuffled.count) ? Array(shuffled.prefix(limit)) : shuffled
        return PredictionTemplate(
            id: pack.id, mode: pack.mode, title: pack.title, coverImage: pack.coverImage, questions: selectedQuestions
        )
    }

    private func trimmedThisOrThatPack(_ pack: ThisOrThatTemplate, limit: Int) -> ThisOrThatTemplate {
        let shuffled = pack.rounds.shuffled()
        let selectedRounds = (limit > 0 && limit < shuffled.count) ? Array(shuffled.prefix(limit)) : shuffled
        return ThisOrThatTemplate(
            id: pack.id, mode: pack.mode, title: pack.title, coverImage: pack.coverImage, rounds: selectedRounds
        )
    }

    private var playerCountPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kaç kişi oynayacak?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("", selection: $playerCount) {
                Text("Tek Kişi").tag(1)
                Text("İki Kişi").tag(2)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private var itemCountPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kaç soru?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Picker("", selection: $itemCountLimit) {
                Text("3 Soru").tag(3)
                Text("5 Soru").tag(5)
                Text("10 Soru").tag(10)
                Text("Tümü").tag(0)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }

    private var recordingToggle: some View {
        Toggle(isOn: $recordingEnabled) {
            Label("Videolu kaydet ve paylaş", systemImage: "video.fill")
                .font(.subheadline.weight(.semibold))
        }
        .padding(14)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

private struct CategoryCard: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PlaceholderCoverView(imageName: imageName, label: title)
                .aspectRatio(1, contentMode: .fit)
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView(mode: .draft, path: .constant([]))
            .environmentObject(AppState())
    }
}
