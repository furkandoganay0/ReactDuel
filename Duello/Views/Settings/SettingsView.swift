import SwiftUI
import PhotosUI
import UIKit

/// Dil ve görünüm (açık/koyu) tercihlerinin yönetildiği ayarlar sayfası —
/// Ana Ekran'dan dişli ikonuyla açılan bir sheet.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLogoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $appState.language) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.titleKey).tag(language)
                        }
                    } label: {
                        Label("Dil", systemImage: "globe")
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Dil")
                } footer: {
                    Text("\"Sistem\" seçiliyse cihazının dili kullanılır.")
                }

                Section {
                    Picker(selection: $appState.appearance) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Label {
                                Text(appearance.titleKey)
                            } icon: {
                                Image(systemName: appearance.systemImage)
                            }
                            .tag(appearance)
                        }
                    } label: {
                        Label("Görünüm", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Görünüm")
                }

                Section {
                    HStack(spacing: 14) {
                        ForEach(AppAccentColor.allCases) { choice in
                            Button {
                                appState.accentColorChoice = choice
                            } label: {
                                Circle()
                                    .fill(choice.color.gradient)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(.primary, lineWidth: appState.accentColorChoice == choice ? 2 : 0)
                                            .padding(-3)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(Text(choice.rawValue))
                            .accessibilityAddTraits(appState.accentColorChoice == choice ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Marka Rengi")
                } footer: {
                    Text("Uygulama genelindeki vurgu rengi — kendi marka rengini seç.")
                }

                Section {
                    TextField("@kullaniciadi", text: $appState.creatorHandle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack(spacing: 12) {
                        watermarkLogoPreview

                        PhotosPicker(selection: $selectedLogoItem, matching: .images) {
                            Text(appState.watermarkLogoData == nil ? "Logo Ekle" : "Logoyu Değiştir")
                        }

                        Spacer()

                        if appState.watermarkLogoData != nil {
                            Button(role: .destructive) {
                                appState.watermarkLogoData = nil
                                selectedLogoItem = nil
                            } label: {
                                Text("Kaldır")
                            }
                        }
                    }
                } header: {
                    Text("Video Filigranı")
                } footer: {
                    Text("Paylaştığın videonun köşesinde kendi rumuzun (ve istersen logon/profil fotoğrafın) görünsün. Boş bırakırsan ReactDuel markası kullanılır.")
                }

                Section {
                    Toggle(isOn: $appState.soundEffectsEnabled) {
                        Label("Doğru/Yanlış Sesi", systemImage: "speaker.wave.2.fill")
                    }
                } footer: {
                    Text("Tahmin Et modunda cevap sonrası kısa bir ses efekti çalar.")
                }
            }
            .navigationTitle(Text("Ayarlar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Tamam")
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onChange(of: selectedLogoItem) { newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self),
                      let image = UIImage(data: data),
                      let resized = image.resizedForWatermark(),
                      let jpegData = resized.jpegData(compressionQuality: 0.85)
                else { return }
                await MainActor.run {
                    appState.watermarkLogoData = jpegData
                }
            }
        }
    }

    @ViewBuilder
    private var watermarkLogoPreview: some View {
        if let data = appState.watermarkLogoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                )
        }
    }
}

private extension UIImage {
    /// Su damgası için gereken küçük boyuta (`UserDefaults`'a sığacak kadar
    /// hafif) indirger — kullanıcının seçtiği fotoğraf kamera çözünürlüğünde
    /// olabilir, oysa videoda birkaç piksellik bir daire olarak görünecek.
    func resizedForWatermark(maxDimension: CGFloat = 200) -> UIImage? {
        let scale = min(1, maxDimension / max(size.width, size.height))
        guard scale < 1 else { return self }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

#Preview {
    SettingsView().environmentObject(AppState())
}
