import XCTest
@testable import JPTurtleCore

final class EngineTests: XCTestCase {
    private var store: SharedStore!

    override func setUp() {
        let suite = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        store = SharedStore(defaults: defaults, isShared: false)
    }

    func testReviewAwardsXPAndQuestAndAchievement() {
        let engine = StudyEngine(store: store)
        let outcome = engine.review(wordID: "w0001", grade: .good)
        XCTAssertGreaterThan(outcome.xpGained, 0)
        XCTAssertTrue(outcome.achievements.contains("first-word"))
        XCTAssertEqual(store.loadProgress().totalReviews, 1)
        XCTAssertEqual(store.loadCards()["w0001"]?.repetitions, 1)
    }

    func testComboMultiplierAndHint() {
        let engine = StudyEngine(store: store)
        let now = Date()
        // Erste Aktionen des Tages lösen Serie, Quests und Achievements aus –
        // die sollen den Vergleich nicht verfälschen.
        for id in ["w0020", "w0021", "w0022", "w0023", "w0024", "w0025"] {
            _ = engine.review(wordID: id, grade: .good, now: now)
        }
        let plain = engine.review(wordID: "w0002", grade: .good, now: now).xpGained
        let combo = engine.review(wordID: "w0003", grade: .good, comboMultiplier: 2, now: now).xpGained
        let hinted = engine.review(wordID: "w0004", grade: .good, usedHint: true, now: now).xpGained
        XCTAssertGreaterThan(combo, plain)
        XCTAssertLessThan(hinted, plain)
    }

    func testComebackBonusDoublesXP() {
        var p = Progress()
        p.comebackBonusRemaining = 1
        p.lastStudyDay = Progress.dayKey(Date())
        store.save(p)
        let engine = StudyEngine(store: store)
        let bonus = engine.review(wordID: "w0010", grade: .good)
        XCTAssertTrue(bonus.comebackBonusApplied)
        let normal = engine.review(wordID: "w0011", grade: .good)
        XCTAssertFalse(normal.comebackBonusApplied)
        XCTAssertGreaterThan(bonus.xpGained, normal.xpGained)
    }

    func testWidgetAnswerFlowsIntoProgress() {
        let now = Date()
        let state = WidgetQuiz.fresh(store: store, now: now)
        XCTAssertEqual(state.choiceIDs.count, 3)
        let answered = WidgetQuiz.answer(index: state.correctIndex, store: store, now: now)
        XCTAssertEqual(answered.answeredCorrectly, true)
        XCTAssertEqual(answered.correctToday, 1)
        let p = store.loadProgress()
        XCTAssertEqual(p.widgetAnswersToday, 1)
        XCTAssertTrue(p.achievements.contains("widget-first"))
        // Zweite Antwort auf dieselbe Frage wird ignoriert.
        let again = WidgetQuiz.answer(index: 0, store: store, now: now)
        XCTAssertEqual(again, answered)
    }

    func testWidgetQuestionExpires() {
        let now = Date()
        let state = WidgetQuiz.fresh(store: store, now: now)
        XCTAssertFalse(WidgetQuiz.isExpired(state, now: now.addingTimeInterval(60)))
        XCTAssertTrue(WidgetQuiz.isExpired(state, now: now.addingTimeInterval(WidgetQuiz.questionLifetime + 1)))
        let answered = WidgetQuiz.selfGrade(knew: true, store: store, now: now)
        XCTAssertTrue(WidgetQuiz.isExpired(answered, now: now.addingTimeInterval(WidgetQuiz.resultLifetime + 1)))
        let next = WidgetQuiz.current(store: store, now: now.addingTimeInterval(WidgetQuiz.resultLifetime + 1))
        XCTAssertNotEqual(next.wordID, answered.wordID)
    }

    func testChestOnlyOncePerDay() {
        var p = Progress()
        p.rollDay(now: Date())
        p.reviewsToday = p.dailyGoal
        store.save(p)
        let engine = StudyEngine(store: store)
        XCTAssertNotNil(engine.openChest())
        XCTAssertNil(engine.openChest())
    }

    func testWritingRecordsBestScore() {
        let engine = StudyEngine(store: store)
        let target = WritingTarget.kana(KanaTable.hiragana[0])
        let good = InkScore(coverage: 0.9, precision: 0.9, placement: 0.9, strokeDelta: 0, total: 90)
        let weak = InkScore(coverage: 0.3, precision: 0.3, placement: 0.3, strokeDelta: 1, total: 30)
        let o1 = engine.writing(target: target, score: good, traced: true)
        XCTAssertTrue(o1.achievements.contains("write-first"))
        _ = engine.writing(target: target, score: weak, traced: false)
        let p = store.loadProgress()
        XCTAssertEqual(p.writingBest[target.id], 90)
        XCTAssertEqual(p.totalWritings, 2)
        XCTAssertEqual(p.perfectWritings, 1)
    }
}
