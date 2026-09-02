import SwiftUI

/// Uygulamanın vurgu rengi (butonlar, `RootView`'ın `.tint`i) — bkz. `AppAppearance`/
/// `AppLanguage` ile aynı desen. İçerik üreticinin kendi marka rengini seçebilmesi
/// için: önceden bu sabit `.indigo`'ydu, her kullanıcı/marka aynı rengi taşıyordu.
enum AppAccentColor: String, CaseIterable, Identifiable, Codable {
    case indigo
    case orange
    case pink
    case teal
    case green
    case red

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .indigo: return .indigo
        case .orange: return .orange
        case .pink: return .pink
        case .teal: return .teal
        case .green: return .green
        case .red: return .red
        }
    }
}
