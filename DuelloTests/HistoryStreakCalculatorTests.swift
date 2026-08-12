import Testing
import Foundation
@testable import Duello

@Suite("HistoryStreakCalculator")
struct HistoryStreakCalculatorTests {
    private let calendar = Calendar(identifier: .gregorian)

    private func date(daysAgo: Int, from reference: Date) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: reference)!
    }

    @Test("Hiç kayıt yoksa seri 0'dır")
    func noRecordsMeansZeroStreak() {
        let streak = HistoryStreakCalculator.streak(playDates: [], referenceDate: Date(), calendar: calendar)
        #expect(streak == 0)
    }

    @Test("Sadece bugün oynanmışsa seri 1'dir")
    func onlyTodayMeansStreakOfOne() {
        let today = Date()
        let streak = HistoryStreakCalculator.streak(playDates: [today], referenceDate: today, calendar: calendar)
        #expect(streak == 1)
    }

    @Test("Bugün, dün ve önceki gün art arda oynanmışsa seri 3'tür")
    func threeConsecutiveDaysMeansStreakOfThree() {
        let today = Date()
        let dates = [date(daysAgo: 0, from: today), date(daysAgo: 1, from: today), date(daysAgo: 2, from: today)]
        let streak = HistoryStreakCalculator.streak(playDates: dates, referenceDate: today, calendar: calendar)
        #expect(streak == 3)
    }

    @Test("Aradaki bir gün atlanmışsa seri o günde durur")
    func gapInDaysBreaksStreak() {
        let today = Date()
        // Bugün + dün oynanmış ama 2 gün önce atlanmış, 3 gün önce tekrar oynanmış.
        let dates = [date(daysAgo: 0, from: today), date(daysAgo: 1, from: today), date(daysAgo: 3, from: today)]
        let streak = HistoryStreakCalculator.streak(playDates: dates, referenceDate: today, calendar: calendar)
        #expect(streak == 2)
    }

    @Test("Bugün hiç oynanmamışsa (en son dün oynanmış olsa bile) seri 0'dır")
    func noPlayTodayMeansZeroStreakEvenIfPlayedYesterday() {
        let today = Date()
        let dates = [date(daysAgo: 1, from: today), date(daysAgo: 2, from: today)]
        let streak = HistoryStreakCalculator.streak(playDates: dates, referenceDate: today, calendar: calendar)
        #expect(streak == 0)
    }

    @Test("Aynı gün içinde birden çok kayıt seriyi birden fazla saymaz")
    func multipleRecordsSameDayCountOnce() {
        let today = Date()
        let laterToday = calendar.date(byAdding: .hour, value: 3, to: today)!
        let streak = HistoryStreakCalculator.streak(playDates: [today, laterToday], referenceDate: today, calendar: calendar)
        #expect(streak == 1)
    }
}
