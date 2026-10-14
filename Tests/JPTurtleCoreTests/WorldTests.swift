import XCTest
@testable import JPTurtleCore

final class WorldTests: XCTestCase {
    private var store: SharedStore!

    override func setUp() {
        let suite = "world-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        store = SharedStore(defaults: defaults, isShared: false)
    }

    private func word(_ display: String) -> VocabWord {
        Vocabulary.all.first { $0.display == display }!
    }

    func testEveryWordBelongsToExactlyOneRegion() {
        var seen: [String: String] = [:]
        for region in World.regions {
            for item in region.items {
                XCTAssertNil(seen[item.word.id], "\(item.word.display) ist doppelt zugeordnet")
                seen[item.word.id] = region.id
            }
        }
        XCTAssertEqual(seen.count, Vocabulary.all.count)
    }

    func testPondContainsFishAndWave() {
        let pond = World.region(id: "pond")!
        let names = pond.words.map(\.display)
        XCTAssertTrue(names.contains("魚"))
        XCTAssertTrue(names.contains("波"))
        XCTAssertEqual(pond.requires, 0)
    }

    func testRegionRequirementsAreReachable() {
        var itemsBefore = 0
        for region in World.regions {
            XCTAssertLessThanOrEqual(region.requires, itemsBefore, "\(region.title) wäre nie erreichbar")
            if region.requires > 0 {
                // nicht mehr als 75 % der vorherigen Items verlangen
                XCTAssertLessThanOrEqual(Double(region.requires), Double(itemsBefore) * 0.75, region.title)
            }
            itemsBefore += region.items.count
        }
    }

    func testItemUnlocksAfterFiveCorrectAnswers() {
        let engine = StudyEngine(store: store)
        let fish = word("魚")
        let start = Date()
        var unlockedOn: Int?
        for i in 1...6 {
            let outcome = engine.review(wordID: fish.id, grade: .good, now: start.addingTimeInterval(Double(i) * 60))
            if outcome.unlockedWordIDs.contains(fish.id) { unlockedOn = i }
        }
        XCTAssertEqual(unlockedOn, World.unlockThreshold)
        XCTAssertTrue(World.isUnlocked(fish, cards: store.loadCards()))
    }

    func testEarlyPracticeCountsButDoesNotMoveSchedule() {
        let engine = StudyEngine(store: store)
        let tea = word("お茶")
        let t0 = Date()
        engine.review(wordID: tea.id, grade: .good, now: t0)
        let first = store.loadCards()[tea.id]!
        engine.review(wordID: tea.id, grade: .good, now: t0.addingTimeInterval(120))
        let second = store.loadCards()[tea.id]!
        XCTAssertEqual(second.correctCount, 2)
        XCTAssertEqual(second.intervalDays, first.intervalDays)
        XCTAssertEqual(second.due, first.due)
        XCTAssertEqual(second.repetitions, first.repetitions)
    }

    func testWrongAnswerDoesNotCountAndResetsSchedule() {
        let engine = StudyEngine(store: store)
        let id = word("魚").id
        let t0 = Date()
        engine.review(wordID: id, grade: .good, now: t0)
        engine.review(wordID: id, grade: .again, now: t0.addingTimeInterval(60))
        let card = store.loadCards()[id]!
        XCTAssertEqual(card.correctCount, 1)
        XCTAssertEqual(card.lapses, 1)
    }

    func testCompletingPondGivesBonusOnlyOnce() {
        let engine = StudyEngine(store: store)
        let pond = World.region(id: "pond")!
        var completedHits = 0
        var xpAtCompletion = 0
        var t = Date()
        for item in pond.items {
            for _ in 0..<World.unlockThreshold {
                t = t.addingTimeInterval(60)
                let outcome = engine.review(wordID: item.word.id, grade: .good, now: t)
                if outcome.completedRegionIDs.contains("pond") {
                    completedHits += 1
                    xpAtCompletion = outcome.xpGained
                }
            }
        }
        XCTAssertEqual(completedHits, 1)
        XCTAssertGreaterThanOrEqual(xpAtCompletion, World.regionBonusXP)
        let progress = store.loadProgress()
        XCTAssertEqual(progress.completedRegions, ["pond"])
        XCTAssertTrue(progress.achievements.contains("region-first"))
        XCTAssertTrue(progress.achievements.contains("item-first"))
        // weiteres Üben löst keinen zweiten Bonus aus
        t = t.addingTimeInterval(60)
        let again = engine.review(wordID: pond.items[0].word.id, grade: .good, now: t)
        XCTAssertTrue(again.completedRegionIDs.isEmpty)
    }

    func testFogLiftsWhenEnoughItemsUnlocked() {
        var cards: [String: CardState] = [:]
        let tea = World.region(id: "teahouse")!
        XCTAssertFalse(World.isOpen(tea, cards: cards))
        for item in World.region(id: "pond")!.items.prefix(tea.requires) {
            var c = CardState(wordID: item.word.id)
            c.correctCount = World.unlockThreshold
            cards[item.word.id] = c
        }
        XCTAssertTrue(World.isOpen(tea, cards: cards))
        XCTAssertTrue(World.openWords(cards: cards).contains { $0.display == "お茶" })
        XCTAssertFalse(World.openWords(cards: [:]).contains { $0.display == "お茶" })
    }

    func testOpenedRegionIsReportedWhenThresholdCrossed() {
        let engine = StudyEngine(store: store)
        let tea = World.region(id: "teahouse")!
        var t = Date()
        var opened = false
        for item in World.region(id: "pond")!.items.prefix(tea.requires) {
            for _ in 0..<World.unlockThreshold {
                t = t.addingTimeInterval(60)
                if engine.review(wordID: item.word.id, grade: .good, now: t).openedRegionIDs.contains("teahouse") { opened = true }
            }
        }
        XCTAssertTrue(opened)
    }

    func testGoodWritingCountsDoubleForItsWord() {
        let engine = StudyEngine(store: store)
        let water = word("水")
        let target = WritingTarget.kanji(in: water).first!
        XCTAssertEqual(target.wordID, water.id)
        let good = InkScore(coverage: 0.8, precision: 0.8, placement: 0.8, strokeDelta: 0, total: 80)
        engine.writing(target: target, score: good, traced: true)
        XCTAssertEqual(store.loadCards()[water.id]?.correctCount, World.writingBonus)
        let weak = InkScore(coverage: 0.2, precision: 0.2, placement: 0.2, strokeDelta: 0, total: 20)
        engine.writing(target: target, score: weak, traced: true)
        XCTAssertEqual(store.loadCards()[water.id]?.correctCount, World.writingBonus)
    }

    func testStampNeedsAllKanjiWrittenWell() {
        let school = word("学校")
        XCTAssertFalse(World.isStamped(school, writingBest: ["kanji-学": 90]))
        XCTAssertTrue(World.isStamped(school, writingBest: ["kanji-学": 90, "kanji-校": 70]))
        XCTAssertFalse(World.isStamped(word("こんにちは"), writingBest: [:]))
    }

    func testRegionSessionPrefersUnfinishedWords() {
        var cards: [String: CardState] = [:]
        let pond = World.region(id: "pond")!
        for item in pond.items.prefix(3) {
            var c = CardState(wordID: item.word.id)
            c.correctCount = World.unlockThreshold
            c.lastReview = Date()
            c.due = Date().addingTimeInterval(86_400)
            cards[item.word.id] = c
        }
        let session = SessionPlanner.regionSession(region: pond, cards: cards, size: 5)
        XCTAssertEqual(session.count, 5)
        let unlocked = Set(pond.items.prefix(3).map(\.word.id))
        XCTAssertTrue(session.allSatisfy { !unlocked.contains($0.id) })
    }

    func testCardDecodingToleratesMissingCorrectCount() throws {
        let json = #"{"wordID":"w0001","intervalDays":1,"ease":2.5,"repetitions":1,"lapses":0,"due":"2026-10-14T10:00:00Z"}"#
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let card = try decoder.decode(CardState.self, from: Data(json.utf8))
        XCTAssertEqual(card.correctCount, 0)
        XCTAssertEqual(card.repetitions, 1)
    }
}
