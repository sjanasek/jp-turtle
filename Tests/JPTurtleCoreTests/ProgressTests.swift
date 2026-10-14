import XCTest
@testable import JPTurtleCore

final class ProgressTests: XCTestCase {
    private let cal = Calendar(identifier: .gregorian)

    private func day(_ offset: Int) -> Date {
        cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: Date()))!.addingTimeInterval(12 * 3600)
    }

    func testStreakExtendsOnConsecutiveDays() {
        var p = Progress()
        XCTAssertEqual(p.registerStudy(now: day(0), calendar: cal), .restarted(gapDays: 0))
        XCTAssertEqual(p.streak, 1)
        XCTAssertEqual(p.registerStudy(now: day(0), calendar: cal), .alreadyToday)
        XCTAssertEqual(p.registerStudy(now: day(1), calendar: cal), .extended)
        XCTAssertEqual(p.streak, 2)
    }

    func testShieldSavesOneMissedDay() {
        var p = Progress()
        p.shields = 1
        _ = p.registerStudy(now: day(0), calendar: cal)
        XCTAssertEqual(p.registerStudy(now: day(2), calendar: cal), .shieldUsed)
        XCTAssertEqual(p.streak, 2)
        XCTAssertEqual(p.shields, 0)
    }

    func testLongGapRestartsWithComebackBonus() {
        var p = Progress()
        _ = p.registerStudy(now: day(0), calendar: cal)
        _ = p.registerStudy(now: day(1), calendar: cal)
        XCTAssertEqual(p.registerStudy(now: day(6), calendar: cal), .restarted(gapDays: 5))
        XCTAssertEqual(p.streak, 1)
        XCTAssertEqual(p.comebackBonusRemaining, 10)
        XCTAssertEqual(p.bestStreak, 2)
    }

    func testShieldEarnedEveryFiveDays() {
        var p = Progress()
        p.shields = 0
        for i in 0..<5 { _ = p.registerStudy(now: day(i), calendar: cal) }
        XCTAssertEqual(p.shields, 1)
    }

    func testDayRollResetsCounters() {
        var p = Progress()
        p.rollDay(now: day(0), calendar: cal)
        p.reviewsToday = 7
        p.completedQuestsToday = [.warmup]
        p.rollDay(now: day(0), calendar: cal)
        XCTAssertEqual(p.reviewsToday, 7)
        p.rollDay(now: day(1), calendar: cal)
        XCTAssertEqual(p.reviewsToday, 0)
        XCTAssertTrue(p.completedQuestsToday.isEmpty)
    }

    func testQuestsAwardXPOnce() {
        var p = Progress()
        p.reviewsToday = 10
        let first = p.checkQuests().map(\.kind)
        XCTAssertTrue(first.contains(.reviews))
        XCTAssertTrue(first.contains(.warmup))
        let xp = p.xp
        XCTAssertTrue(p.checkQuests().isEmpty)
        XCTAssertEqual(p.xp, xp)
    }

    func testStageThresholds() {
        XCTAssertEqual(TurtleStage.stage(forXP: 0), .egg)
        XCTAssertEqual(TurtleStage.stage(forXP: 99), .egg)
        XCTAssertEqual(TurtleStage.stage(forXP: 100), .hatchling)
        XCTAssertEqual(TurtleStage.stage(forXP: 10_000), .sensei)
    }

    func testDecodingOldSaveUsesDefaults() throws {
        // Speicherstand ohne die neuen Gamification-Felder.
        let json = #"{"xp": 42, "streak": 3}"#
        let p = try JSONDecoder().decode(Progress.self, from: Data(json.utf8))
        XCTAssertEqual(p.xp, 42)
        XCTAssertEqual(p.streak, 3)
        XCTAssertEqual(p.shields, 1)
        XCTAssertEqual(p.hearts, 0)
        XCTAssertTrue(p.stickers.isEmpty)
    }

    func testFriendshipLevels() {
        XCTAssertEqual(FriendshipLevel.level(forHearts: 0), .stranger)
        XCTAssertEqual(FriendshipLevel.level(forHearts: 5), .acquaintance)
        XCTAssertEqual(FriendshipLevel.level(forHearts: 200), .soulmate)
    }
}

final class PronunciationTests: XCTestCase {
    func testRomajiFadesOnlyWhenMastered() {
        var card = CardState(wordID: "w0001")
        XCTAssertTrue(RomajiMode.fading.shouldShow(for: nil))
        XCTAssertTrue(RomajiMode.fading.shouldShow(for: card))
        for _ in 0..<5 { card = Scheduler.review(card, grade: .good) }
        XCTAssertTrue(card.isMastered)
        XCTAssertFalse(RomajiMode.fading.shouldShow(for: card))
        XCTAssertTrue(RomajiMode.always.shouldShow(for: card))
        XCTAssertFalse(RomajiMode.off.shouldShow(for: nil))
    }

    func testSpokenTextUsesKanaNotKanji() {
        let word = Vocabulary.all.first { $0.kanji == "水" }!
        XCTAssertEqual(SpokenText.text(for: word), "みず")
        let kanjiTarget = WritingTarget.kanji(in: word).first!
        XCTAssertEqual(SpokenText.text(for: kanjiTarget), "みず")
        let kanaTarget = WritingTarget.kana(KanaTable.hiragana[0])
        XCTAssertEqual(SpokenText.text(for: kanaTarget), "あ")
    }

    func testNewSettingsDefaultForOldSaves() throws {
        let p = try JSONDecoder().decode(Progress.self, from: Data(#"{"xp": 5}"#.utf8))
        XCTAssertEqual(p.romajiMode, .fading)
        XCTAssertTrue(p.autoSpeak)
    }
}
