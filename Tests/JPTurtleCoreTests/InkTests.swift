import XCTest
@testable import JPTurtleCore

final class InkTests: XCTestCase {
    /// Einfache Vorlage: horizontaler Balken.
    private func bar(width: Int = 64, height: Int = 64, y: Int, thickness: Int = 4, x0: Int = 10, x1: Int = 54) -> BitMask {
        var m = BitMask(width: width, height: height)
        for yy in y..<(y + thickness) {
            for x in x0..<x1 { m[x, yy] = 1 }
        }
        return m
    }

    func testIdenticalStrokeScoresHigh() {
        let template = bar(y: 30)
        let s = InkScorer.score(template: template, user: template, strokesDrawn: 1, expectedStrokes: 1)
        XCTAssertGreaterThanOrEqual(s.total, 95)
        XCTAssertEqual(s.verdict, .perfect)
    }

    func testSlightlyOffsetStrokeStillGood() {
        let s = InkScorer.score(template: bar(y: 30), user: bar(y: 33), strokesDrawn: 1, expectedStrokes: 1)
        XCTAssertGreaterThanOrEqual(s.total, 65)
    }

    func testFarOffStrokeScoresLow() {
        let s = InkScorer.score(template: bar(y: 10), user: bar(y: 50), strokesDrawn: 1, expectedStrokes: 1)
        XCTAssertLessThan(s.total, 45)
        XCTAssertEqual(s.verdict, .practice)
    }

    func testStrokeCountPenalty() {
        let template = bar(y: 30)
        let right = InkScorer.score(template: template, user: template, strokesDrawn: 1, expectedStrokes: 1)
        let wrong = InkScorer.score(template: template, user: template, strokesDrawn: 4, expectedStrokes: 1)
        XCTAssertGreaterThan(right.total, wrong.total)
    }

    func testEmptyInkIsZero() {
        let s = InkScorer.score(template: bar(y: 30), user: BitMask(width: 64, height: 64), strokesDrawn: 0, expectedStrokes: 1)
        XCTAssertEqual(s.total, 0)
    }

    func testDilationGrowsInk() {
        let m = bar(y: 30)
        XCTAssertGreaterThan(m.dilated(radius: 3).inkCount, m.inkCount)
        XCTAssertEqual(m.dilated(radius: 0), m)
    }
}
