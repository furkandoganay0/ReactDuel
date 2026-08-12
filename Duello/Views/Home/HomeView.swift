import SwiftUI
import UIKit

/// Ana Ekran — tek ekran, derin gezinme yok (teknik prompt Bölüm 7).
struct HomeView: View {
    @Binding var path: [AppRoute]
    @EnvironmentObject private var playHistoryStore: PlayHistoryStore
    @Environment(\.locale) private var locale
    @State private var isShowingSettings = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.white, Color.indigo.gradient)
                .padding(.top, 20)

            Text("Duello")
                .font(.system(size: 40, weight: .black, design: .rounded))

            Text("Modunu seç, tepkini kaydet")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if playHistoryStore.currentStreak > 0 {
                streakBadge
            }

            Spacer()

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

            Spacer()
        }
        .padding(.horizontal, 20)
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
