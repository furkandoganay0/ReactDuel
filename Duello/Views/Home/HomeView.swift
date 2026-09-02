import SwiftUI
import UIKit

/// Ana Ekran — tek ekran, derin gezinme yok (teknik prompt Bölüm 7).
/// `ScrollView` içinde: 3 mod kartı + üst içerik küçük ekranlarda taşabiliyordu,
/// sabit `Spacer()`li merkezleme yerine doğal akışa bırakıldı.
struct HomeView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var playHistoryStore: PlayHistoryStore
    @EnvironmentObject private var appState: AppState
    @Environment(\.locale) private var locale
    @State private var isShowingSettings = false

    /// Güne göre deterministik seçilen bir paket — her gün aynı, cihazlar
    /// arasında da tutarlı (kullanıcıya özel rastgelelik değil, takvim günü
    /// bazlı). "Bugün ne oynasam" kararsızlığını azaltmak için.
    private var featuredPack: PredictionTemplate? {
        let packs = appState.catalog.predictionPacks
        guard !packs.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return packs[dayOfYear % packs.count]
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white, Color.indigo.gradient)
                    .padding(.top, 20)

                Text("ReactDuel")
                    .font(.system(size: 40, weight: .black, design: .rounded))

                Text("Modunu seç, tepkini kaydet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if playHistoryStore.currentStreak > 0 {
                    streakBadge
                }

                if let featuredPack {
                    featuredPackBanner(featuredPack)
                }

                quickPlayButton

                VStack(spacing: 16) {
                    ModeCard(
                        title: "Tahmin Et",
                        subtitle: "İpucuna bak, süre dolmadan tahmin et",
                        systemImage: "questionmark.circle.fill",
                        color: .indigo
                    ) {
                        path.append(.categorySelection(.prediction))
                    }

                    ModeCard(
                        title: "Bütçeli Draft",
                        subtitle: "Sabit bütçeyle sırayla seç, kazananı bul",
                        systemImage: "person.2.circle.fill",
                        color: .orange
                    ) {
                        path.append(.categorySelection(.draft))
                    }

                    ModeCard(
                        title: "Bu mu O mu",
                        subtitle: "Hızlı ikili seçimler, tepkini yakala",
                        systemImage: "arrow.left.arrow.right.circle.fill",
                        color: .purple
                    ) {
                        path.append(.categorySelection(.thisOrThat))
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    path.append(.history)
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Geçmiş"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Ayarlar"))
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
    }

    /// Tek dokunuşla, hiç menüde gezinmeden 3 soruluk rastgele bir pakete
    /// kayda başlar — içerik üreticinin "hızlıca bir klip daha çekeyim"
    /// anındaki sürtünmeyi (mod seç → paket seç → ayarları seç) tamamen kaldırır.
    private var quickPlayButton: some View {
        Button {
            startQuickPlay()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                Text("Hızlı Oyna")
                    .fontWeight(.bold)
                Text("· 3 soru, rastgele paket")
                    .font(.caption)
                    .opacity(0.85)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing))
            .clipShape(Capsule())
            .shadow(color: .indigo.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    private func startQuickPlay() {
        guard let pack = appState.catalog.predictionPacks.randomElement() else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        let quickPack = PredictionTemplate(
            id: pack.id, mode: pack.mode, title: pack.title, coverImage: pack.coverImage,
            questions: Array(pack.questions.shuffled().prefix(3))
        )
        path.append(.predictionRecording(quickPack, recordingEnabled: true, playerCount: 1))
    }

    private func featuredPackBanner(_ pack: PredictionTemplate) -> some View {
        Button {
            path.append(.predictionRecording(pack, recordingEnabled: true, playerCount: 1))
        } label: {
            HStack(spacing: 12) {
                PlaceholderCoverView(imageName: pack.coverImage, label: pack.title)
                    .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Günün Paketi")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.indigo)
                        .textCase(.uppercase)
                    Text(pack.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.indigo.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var streakBadge: some View {
        HStack(spacing: 6) {
            Text("🔥")
            Text(L10n.streakLabel(days: playHistoryStore.currentStreak, locale: locale))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.12))
        .clipShape(Capsule())
    }
}

private struct ModeCard: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let systemImage: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        } label: {
            HStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
                    .background(color.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: color.opacity(0.4), radius: 10, y: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.primary.opacity(0.06))
            )
            .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.12)) { isPressed = true } }
                .onEnded { _ in withAnimation(.easeOut(duration: 0.12)) { isPressed = false } }
        )
    }
}

#Preview {
    NavigationStack {
        HomeView(path: .constant([]))
    }
    .environmentObject(AppState())
    .environmentObject(PlayHistoryStore())
}
