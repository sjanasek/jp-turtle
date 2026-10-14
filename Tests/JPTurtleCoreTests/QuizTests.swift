import XCTest
@testable import JPTurtleCore

final class QuizTests: XCTestCase {
    func testQuestionHasUniqueChoicesAndCorrectIndex() {
        var rng = SeededGenerator(seed: 1)
        for word in Vocabulary.all {
            let q = QuizFactory.question(for: word, using: &rng)
            XCTAssertEqual(q.choices.count, 4)
            XCTAssertEqual(q.choices[q.correctIndex].id, word.id)
            let meanings = q.choices.map(\.meaning)
            XCTAssertEqual(meanings.count, Set(meanings).count, "Doppelte Bedeutung bei \(word.display)")
        }
    }

    func testDeterministicWithSeed() {
        var a = SeededGenerator(seed: 99)
        var b = SeededGenerator(seed: 99)
        let w = Vocabulary.all[10]
        XCTAssertEqual(QuizFactory.question(for: w, using: &a), QuizFactory.question(for: w, using: &b))
    }

    func testKanaQuestion() {
        var rng = SeededGenerator(seed: 3)
        let pool = KanaTable.all(.hiragana)
        let q = QuizFactory.kanaQuestion(for: pool[5], pool: pool, using: &rng)
        XCTAssertEqual(q.choices.count, 4)
        XCTAssertEqual(q.choices[q.correctIndex], pool[5])
    }

    func testSessionPrefersDueCards() {
        let now = Date()
        var cards: [String: CardState] = [:]
        var due = CardState(wordID: "w0005", now: now.addingTimeInterval(-86_400 * 3))
        due = Scheduler.review(due, grade: .good, now: now.addingTimeInterval(-86_400 * 3))
        cards[due.wordID] = due
        let session = SessionPlanner.session(cards: cards, size: 5, now: now)
        XCTAssertEqual(session.first?.id, "w0005")
        XCTAssertEqual(session.count, 4) // 1 fällig + 3 neue
    }

    func testDeepLinkRoundTrip() {
        let links: [DeepLink] = [.home, .kana, .turtle, .review(wordID: "w0001"), .review(wordID: nil)]
        for l in links {
            XCTAssertEqual(DeepLink(url: l.url), l)
        }
        XCTAssertNil(DeepLink(url: URL(string: "https://example.com")!))
    }
}
