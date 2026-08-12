import Foundation

/// `PlayHistoryStore.currentStreak`'in saf, test edilebilir çekirdeği —
/// playbook Bölüm 2 prensibiyle tutarlı: "şimdi" (`referenceDate`) dışarıdan
/// verildiği için gerçek tarihe/saate hiç bağlı olmadan test edilebiliyor.
enum HistoryStreakCalculator {
    /// `referenceDate`in günü dahil, geriye doğru kesintisiz kaç gün
    /// `playDates` içinde en az bir tarih var.
    static func streak(playDates: [Date], referenceDate: Date, calendar: Calendar = .current) -> Int {
        guard !playDates.isEmpty else { return 0 }
        let playedDays = Set(playDates.map { calendar.startOfDay(for: $0) })

        var streak = 0
        var cursor = calendar.startOfDay(for: referenceDate)
        while playedDays.contains(cursor) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previousDay
        }
        return streak
    }
}
