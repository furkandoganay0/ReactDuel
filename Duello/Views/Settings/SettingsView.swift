import SwiftUI

/// Dil ve görünüm (açık/koyu) tercihlerinin yönetildiği ayarlar sayfası —
/// Ana Ekran'dan dişli ikonuyla açılan bir sheet.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

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
                    TextField("@kullaniciadi", text: $appState.creatorHandle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Video Filigranı")
                } footer: {
                    Text("Paylaştığın videonun köşesinde kendi rumuzun görünsün. Boş bırakırsan Duello markası kullanılır.")
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
    }
}

#Preview {
    SettingsView().environmentObject(AppState())
}
