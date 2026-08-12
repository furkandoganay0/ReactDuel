import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var permissions = PermissionsRequester()
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            Text("Duello'ya Hoş Geldin")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Tepkini kaydet, otomatik kurgulanmış bir video ile paylaş. Hiçbir video ya da veri, sen paylaşmadan cihazından çıkmaz.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            VStack(alignment: .leading, spacing: 14) {
                PermissionRow(title: "Kamera", status: permissions.cameraStatus)
                PermissionRow(title: "Mikrofon", status: permissions.microphoneStatus)
                PermissionRow(title: "Fotoğraflar", status: permissions.photoLibraryStatus)
            }
            .padding(.horizontal, 32)

            Button {
                Task {
                    isRequesting = true
                    await permissions.requestAll()
                    isRequesting = false
                    appState.hasCompletedOnboarding = true
                }
            } label: {
                Text(isRequesting ? "İzinler isteniyor…" : "İzinleri Ver ve Başla")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isRequesting)
            .padding(.horizontal, 32)
            .padding(.bottom, 24)
        }
        .onAppear { permissions.refreshStatuses() }
    }
}

private struct PermissionRow: View {
    let title: LocalizedStringKey
    let status: PermissionStatus

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            switch status {
            case .granted:
                Label("Verildi", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .denied:
                Label("Reddedildi", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)
            case .notDetermined:
                Label("Bekleniyor", systemImage: "circle.dashed")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }
}

#Preview {
    OnboardingView().environmentObject(AppState())
}
