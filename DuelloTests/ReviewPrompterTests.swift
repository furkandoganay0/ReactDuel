import Testing
@testable import Duello

@Suite("ReviewPrompter")
struct ReviewPrompterTests {
    @Test("İlk eşiğe henüz ulaşılmadıysa nil döner")
    func belowFirstMilestoneReturnsNil() {
        #expect(ReviewPrompter.newlyReachedMilestone(sessionCount: 2, lastMilestone: 0) == nil)
    }

    @Test("İlk eşiğe tam ulaşınca o eşiği döner")
    func reachingFirstMilestoneReturnsIt() {
        #expect(ReviewPrompter.newlyReachedMilestone(sessionCount: 3, lastMilestone: 0) == 3)
    }

    @Test("Aynı eşik daha önce tetiklendiyse bir daha dönmez")
    func sameMilestoneNotRepeated() {
        #expect(ReviewPrompter.newlyReachedMilestone(sessionCount: 5, lastMilestone: 3) == nil)
    }

    @Test("Birden fazla eşik atlanmışsa (ör. uygulama uzun süre açılmadıysa) bir sonraki eşik döner")
    func skippingAheadReturnsNextMilestone() {
        #expect(ReviewPrompter.newlyReachedMilestone(sessionCount: 30, lastMilestone: 3) == 10)
    }

    @Test("Tüm eşikler geçildiyse nil döner")
    func pastAllMilestonesReturnsNil() {
        #expect(ReviewPrompter.newlyReachedMilestone(sessionCount: 100, lastMilestone: 50) == nil)
    }
}
