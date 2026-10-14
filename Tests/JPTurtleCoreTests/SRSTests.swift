import XCTest
@testable import JPTurtleCore

final class SRSTests: XCTestCase {
    func testAgainResetsAndSchedulesSoon() {
        let now = Date()
        var card = CardState(wordID: "w0001", now: now)
        card = Scheduler.review(card, grade: .good, now: now)
        card = Scheduler.review(card, grade: .good, now: now)
        XCTAssertEqual(card.repetitions, 2)

        let again = Scheduler.review(card, grade: .again, now: now)
        XCTAssertEqual(again.repetitions, 0)
        XCTAssertEqual(again.lapses, 1)
        XCTAssertLessThan(again.due.timeIntervalSince(now), 11 * 60)
        XCTAssertGreaterThanOrEqual(again.ease, 1.3)
    }

    func testIntervalsGrow() {
        let now = Date()
        var card = CardState(wordID: "w0001", now: now)
        var previous = 0.0
        for _ in 0..<5 {
            card = Scheduler.review(card, grade: .good, now: now)
            XCTAssertGreaterThan(card.intervalDays, previous)
            previous = card.intervalDays
        }
        XCTAssertTrue(card.isMastered)
    }

    func testEaseNeverBelowFloor() {
        var card = CardState(wordID: "x")
        for _ in 0..<20 { card = Scheduler.review(card, grade: .again) }
        XCTAssertEqual(card.ease, 1.3, accuracy: 0.0001)
    }
}
