import XCTest
@testable import JPTurtleCore

final class VocabularyTests: XCTestCase {
    func testIDsAreUnique() {
        let ids = Vocabulary.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testNoDuplicateDisplayMeaningPairs() {
        let pairs = Vocabulary.all.map { "\($0.display)|\($0.meaning)" }
        XCTAssertEqual(pairs.count, Set(pairs).count)
    }

    func testEveryCategoryHasEnoughWordsForDistractors() {
        for cat in WordCategory.allCases {
            XCTAssertGreaterThanOrEqual(Vocabulary.words(in: cat).count, 4, "\(cat)")
        }
    }

    func testKanaTablesComplete() {
        XCTAssertEqual(KanaTable.basicCount(.hiragana), 46)
        XCTAssertEqual(KanaTable.basicCount(.katakana), 46)
        XCTAssertEqual(KanaTable.hiragana.count, KanaTable.katakana.count)
        for k in KanaTable.hiragana + KanaTable.katakana {
            XCTAssertNotNil(StrokeCounts.count(for: k.character), "Strichzahl fehlt für \(k.character)")
        }
    }

    func testKanjiStrokeCountsCoverVocabulary() {
        var missing: Set<String> = []
        for w in Vocabulary.all {
            for ch in w.kanji ?? "" {
                let s = String(ch)
                // Nur echte Kanji prüfen (Kana in gemischten Wörtern überspringen).
                guard let scalar = s.unicodeScalars.first, (0x4E00...0x9FFF).contains(scalar.value) else { continue }
                if StrokeCounts.kanji[s] == nil { missing.insert(s) }
            }
        }
        XCTAssertTrue(missing.isEmpty, "Strichzahlen fehlen für: \(missing.sorted())")
    }
}
