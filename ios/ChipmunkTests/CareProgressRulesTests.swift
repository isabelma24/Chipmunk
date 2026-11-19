import XCTest
#if canImport(Chipmunk)
@testable import Chipmunk
#else
@testable import CareProgressRules
#endif

final class CareProgressRulesTests: XCTestCase {
    func testDecayHalvesAndNeverFallsBelowFifteen() {
        XCTAssertEqual(CareProgressRules.normalizeNeed(0), 15)
        XCTAssertEqual(CareProgressRules.normalizeNeed(55), 55)
        XCTAssertEqual(CareProgressRules.decay(100, days: 1), 50)
        XCTAssertEqual(CareProgressRules.decay(100, days: 2), 25)
        XCTAssertEqual(CareProgressRules.decay(55, days: 1), 27)
        XCTAssertEqual(CareProgressRules.decay(15, days: 1), 15)
        XCTAssertEqual(CareProgressRules.decay(100, days: 30), 15)
    }

    func testDailyCareStartsAtTwentyAndReachesOneHundredOnlyWhenNeedsAreFull() {
        let starting = Array(repeating: 55, count: 5)
        XCTAssertEqual(CareProgressRules.dailyCare(starting: starting, current: starting), 20)
        XCTAssertEqual(CareProgressRules.dailyCare(starting: starting, current: [100, 100, 100, 100, 99]), 99)
        XCTAssertEqual(CareProgressRules.dailyCare(starting: starting, current: Array(repeating: 100, count: 5)), 100)
    }

    func testLessonAndActivityCareRefillsLowestNeedAndClampsAtOneHundred() {
        let afterLesson = CareProgressRules.applying(15, to: [55, 55, 55, 55, 55])
        XCTAssertEqual(afterLesson.applied, 15)
        XCTAssertEqual(afterLesson.needs.reduce(0, +), 290)
        XCTAssertEqual(afterLesson.needs.max(), 70)

        let afterActivity = CareProgressRules.applying(5, to: [55, 55, 55, 55, 55])
        XCTAssertEqual(afterActivity.applied, 5)
        XCTAssertEqual(afterActivity.needs.max(), 60)

        let nearFull = CareProgressRules.applying(15, to: [100, 100, 100, 100, 95])
        XCTAssertEqual(nearFull.applied, 5)
        XCTAssertEqual(nearFull.needs, Array(repeating: 100, count: 5))
    }

    func testBadgeRequiresStudyAndCareAboveEighty() {
        XCTAssertFalse(CareProgressRules.qualifiesForBadge(studied: false, dailyCare: 100))
        XCTAssertFalse(CareProgressRules.qualifiesForBadge(studied: true, dailyCare: 80))
        XCTAssertTrue(CareProgressRules.qualifiesForBadge(studied: true, dailyCare: 81))
    }

    func testAgeGrowsOneYearPerTenCompletedLessonsAndCapsAtOneHundred() {
        XCTAssertEqual(CareProgressRules.age(completedLessonCount: 0), 16)
        XCTAssertEqual(CareProgressRules.age(completedLessonCount: 9), 16)
        XCTAssertEqual(CareProgressRules.age(completedLessonCount: 10), 17)
        XCTAssertEqual(CareProgressRules.age(completedLessonCount: 840), 100)
        XCTAssertEqual(CareProgressRules.age(completedLessonCount: 10_000), 100)
    }
}
