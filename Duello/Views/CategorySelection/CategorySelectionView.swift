import SwiftUI

/// Yatay kart listesi — teknik prompt Bölüm 7, "Kategori Seçimi".
struct CategorySelectionView: View {
    let mode: GameMode
    @Binding var path: [AppRoute]
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var userContentStore: UserContentStore
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
            }
            // Draft da dahil her modda gösterilir — önceden sadece Tahmin Et/Bu mu O mu'da
            // vardı, Draft'ta kamera her zaman zorunluydu; kamera açılamazsa (izin reddi,
            // kamerasız cihaz) Draft modu tamamen oynanamaz hâle geliyordu.
            recordingToggle

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                createPackCard

                switch mode {
                case .prediction:
                    ForEach(userContentStore.predictionPacks + appState.catalog.predictionPacks) { pack in
                        Button {
                            let selectedPack = trimmedPredictionPack(pack, limit: itemCountLimit)
                            path.append(.predictionRecording(selectedPack, recordingEnabled: recordingEnabled, playerCount: playerCount))
                        } label: {
                            CategoryCard(
                                imageName: pack.coverImage,
                                title: pack.title,
                                subtitle: L10n.questionCount(pack.questions.count, locale: locale),
                                isUserPack: UserContentStore.isUserPack(id: pack.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .modifier(UserPackDeleteContextMenu(isUserPack: UserContentStore.isUserPack(id: pack.id)) {
                            userContentStore.deletePredictionPack(pack)
                        })
                    }
                case .draft:
                    ForEach(userContentStore.draftPacks + appState.catalog.draftPacks) { pack in
                        Button {
                            path.append(.draftRecording(pack, recordingEnabled: recordingEnabled))
                        } label: {
                            CategoryCard(
                                imageName: pack.coverImage,
                                title: pack.title,
                                subtitle: L10n.draftSubtitle(budget: pack.budget, optionCount: pack.pool.count, locale: locale),
                                isUserPack: UserContentStore.isUserPack(id: pack.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .modifier(UserPackDeleteContextMenu(isUserPack: UserContentStore.isUserPack(id: pack.id)) {
                            userContentStore.deleteDraftPack(pack)
                        })
                    }
                case .thisOrThat:
                    ForEach(userContentStore.thisOrThatPacks + appState.catalog.thisOrThatPacks) { pack in
                        Button {
                            let selectedPack = trimmedThisOrThatPack(pack, limit: itemCountLimit)
                            path.append(.thisOrThatRecording(selectedPack, recordingEnabled: recordingEnabled, playerCount: playerCount))
                        } label: {
                            CategoryCard(
                                imageName: pack.coverImage,
                                title: pack.title,
                                subtitle: L10n.roundCount(pack.rounds.count, locale: locale),
                                isUserPack: UserContentStore.isUserPack(id: pack.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .modifier(UserPackDeleteContextMenu(isUserPack: UserContentStore.isUserPack(id: pack.id)) {
                            userContentStore.deleteThisOrThatPack(pack)
                        })
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

    /// Kullanıcının kendi paketini yazabildiği ekrana giden kart — her mod
    /// kendi "Yeni ... Paketi" ekranına gider (bkz. `AppRoute`).
    private var createPackCard: some View {
        Button {
            switch mode {
            case .prediction: path.append(.createPredictionPack)
            case .draft: path.append(.createDraftPack)
            case .thisOrThat: path.append(.createThisOrThatPack)
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [6]))
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.accentColor)
                }
                .aspectRatio(1, contentMode: .fit)

                Text("Paket Oluştur")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Kendi sorularını yaz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct CategoryCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    var isUserPack: Bool = false

    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                PlaceholderCoverView(imageName: imageName, label: title)
                    .aspectRatio(1, contentMode: .fit)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)

                if isUserPack {
                    Image(systemName: "person.fill")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                        .padding(6)
                        // Kişi ikonu tek başına VoiceOver'a bağlamsız "Person" olarak
                        // okunuyordu — bunun yerine tüm kart için birleşik, anlamlı bir
                        // etiket kuruyoruz (aşağıdaki accessibilityLabel).
                        .accessibilityHidden(true)
                }
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(2)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.categoryCardAccessibilityLabel(title: title, subtitle: subtitle, isUserPack: isUserPack, locale: locale))
    }
}

/// Sadece kullanıcının kendi yazdığı paketlere (bundled paketlere değil) uzun
/// basınca "Sil" seçeneği sunan context menu — `HistoryView`'daki swipe-to-delete
/// ile aynı ruhta (onay istemeden direkt siler), ama `LazyVGrid` kartları
/// `List` satırı olmadığı için `swipeActions` yerine `contextMenu` kullanıyor.
private struct UserPackDeleteContextMenu: ViewModifier {
    let isUserPack: Bool
    let onDelete: () -> Void

    func body(content: Content) -> some View {
        if isUserPack {
            content.contextMenu {
                Button(role: .destructive, action: onDelete) {
                    Label("Sil", systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
}

#Preview {
    NavigationStack {
        CategorySelectionView(mode: .draft, path: .constant([]))
            .environmentObject(AppState())
            .environmentObject(UserContentStore())
    }
}
