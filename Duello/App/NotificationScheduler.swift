import Foundation
import UserNotifications

/// Seri hatırlatma bildirimlerini yöneten yardımcı — tamamen cihaz-içi, sunucu
/// yok. `AppState.streakRemindersEnabled` açıksa, her oturum bitiminde (bkz.
/// `PlayHistoryStore.addRecord`) bir sonraki hatırlatmayı "yarın aynı saat"e
/// erteler; kullanıcı o gün zaten oynadığı için bugün tekrar rahatsız edilmez.
/// Bildirim izni için Info.plist'te ayrı bir açıklama string'i GEREKMİYOR —
/// kamera/mikrofon'un aksine bu tamamen sistemin kendi genel izin diyaloğu.
enum NotificationScheduler {
    static let enabledKey = "duello.streakRemindersEnabled"
    private static let reminderIdentifier = "duello.streakReminder"
    private static let reminderHour = 20 // 20:00 — çoğu kullanıcı için akşam, günün sonuna yakın

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    /// Kullanıcı Ayarlar'daki anahtarı açtığında çağrılır. İzin daha önce
    /// reddedildiyse sistem diyaloğu tekrar çıkmaz (iOS kısıtı) — `completion`
    /// bunu `false` ile bildirir, çağıran taraf gerekirse Ayarlar'a yönlendirebilir.
    static func enable(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            DispatchQueue.main.async {
                UserDefaults.standard.set(granted, forKey: enabledKey)
                if granted {
                    scheduleReminderForTomorrow()
                }
                completion(granted)
            }
        }
    }

    static func disable() {
        UserDefaults.standard.set(false, forKey: enabledKey)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])
    }

    /// Bir oturum tamamlandığında çağrılır — açıksa hatırlatmayı yarına öteler.
    /// Kapalıysa hiçbir şey yapmaz (izin zaten yoktur).
    static func rescheduleIfEnabled() {
        guard isEnabled else { return }
        scheduleReminderForTomorrow()
    }

    private static func scheduleReminderForTomorrow() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier])

        let content = UNMutableNotificationContent()
        // Sistem bildirimi cihazın dil ayarına göre gösterilir — kamera/mikrofon
        // izin metinleriyle aynı gerekçe (bkz. `en.lproj`/`tr.lproj/InfoPlist.strings`),
        // bu yüzden burada da uygulama içi dil seçicisi değil `Locale.current` kullanılıyor.
        let locale = Locale.current
        content.title = L10n.streakReminderTitle(locale: locale)
        content.body = L10n.streakReminderBody(locale: locale)
        content.sound = .default

        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) else { return }
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = reminderHour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: reminderIdentifier, content: content, trigger: trigger)
        center.add(request)
    }
}
