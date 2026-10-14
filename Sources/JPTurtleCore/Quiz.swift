import Foundation

/// Eine Multiple-Choice-Frage.
public struct QuizQuestion: Hashable, Sendable {
    public enum Mode: String, Codable, Sendable {
        /// Japanisch zeigen, deutsche Bedeutung wählen.
        case wordToMeaning
        /// Deutsche Bedeutung zeigen, japanisches Wort wählen.
        case meaningToWord
    }

    public let word: VocabWord
    public let mode: Mode
    public let choices: [VocabWord]
    public let correctIndex: Int

    public var prompt: String {
        mode == .wordToMeaning ? word.display : word.meaning
    }

    public func label(for choice: VocabWord) -> String {
        mode == .wordToMeaning ? choice.meaning : choice.display
    }

    public func isCorrect(_ index: Int) -> Bool { index == correctIndex }
}

public enum QuizFactory {
    /// Baut eine Frage mit `choiceCount` Antwortmöglichkeiten. Ablenker kommen
    /// bevorzugt aus derselben Kategorie, damit es nicht zu leicht wird.
    public static func question<G: RandomNumberGenerator>(
        for word: VocabWord,
        pool: [VocabWord] = Vocabulary.all,
        mode: QuizQuestion.Mode = .wordToMeaning,
        choiceCount: Int = 4,
        using rng: inout G
    ) -> QuizQuestion {
        let others = pool.filter { $0.id != word.id && $0.meaning != word.meaning && $0.display != word.display }
        var sameCategory = others.filter { $0.category == word.category }.shuffled(using: &rng)
        var rest = others.filter { $0.category != word.category }.shuffled(using: &rng)

        var distractors: [VocabWord] = []
        var usedLabels: Set<String> = [word.meaning, word.display]
        func take(_ candidate: VocabWord) {
            let label = mode == .wordToMeaning ? candidate.meaning : candidate.display
            guard usedLabels.insert(label).inserted else { return }
            distractors.append(candidate)
        }
        while distractors.count < choiceCount - 1 {
            if !sameCategory.isEmpty, (distractors.count < 2 || rest.isEmpty) {
                take(sameCategory.removeFirst())
            } else if !rest.isEmpty {
                take(rest.removeFirst())
            } else if !sameCategory.isEmpty {
                take(sameCategory.removeFirst())
            } else {
                break
            }
        }

        var choices = distractors
        let correctIndex = Int.random(in: 0...choices.count, using: &rng)
        choices.insert(word, at: correctIndex)
        return QuizQuestion(word: word, mode: mode, choices: choices, correctIndex: correctIndex)
    }

    public static func question(
        for word: VocabWord,
        pool: [VocabWord] = Vocabulary.all,
        mode: QuizQuestion.Mode = .wordToMeaning,
        choiceCount: Int = 4
    ) -> QuizQuestion {
        var rng = SystemRandomNumberGenerator()
        return question(for: word, pool: pool, mode: mode, choiceCount: choiceCount, using: &rng)
    }

    /// Kana-Frage: Zeichen zeigen, Romaji wählen.
    public static func kanaQuestion<G: RandomNumberGenerator>(
        for kana: Kana,
        pool: [Kana],
        choiceCount: Int = 4,
        using rng: inout G
    ) -> (kana: Kana, choices: [Kana], correctIndex: Int) {
        var sameRow = pool.filter { $0.id != kana.id && $0.row == kana.row }.shuffled(using: &rng)
        var others = pool.filter { $0.id != kana.id && $0.row != kana.row }.shuffled(using: &rng)
        var distractors: [Kana] = []
        while distractors.count < choiceCount - 1 {
            if !sameRow.isEmpty, distractors.count < 2 || others.isEmpty {
                distractors.append(sameRow.removeFirst())
            } else if !others.isEmpty {
                distractors.append(others.removeFirst())
            } else {
                break
            }
        }
        var choices = distractors
        let idx = Int.random(in: 0...choices.count, using: &rng)
        choices.insert(kana, at: idx)
        return (kana, choices, idx)
    }
}

/// Stellt die Lernreihenfolge zusammen: fällige Karten zuerst, dann neue Wörter.
public enum SessionPlanner {
    public static func dueWords(
        cards: [String: CardState],
        now: Date = Date(),
        limit: Int = .max
    ) -> [VocabWord] {
        cards.values
            .filter { !$0.isNew && $0.isDue(at: now) }
            .sorted { $0.due < $1.due }
            .prefix(limit)
            .compactMap { Vocabulary.word(id: $0.wordID) }
    }

    /// Noch nie gelernte Wörter, nach Level (N5 zuerst) und Einbauordnung.
    public static func newWords(
        cards: [String: CardState],
        limit: Int,
        pool: [VocabWord] = Vocabulary.all
    ) -> [VocabWord] {
        Array(pool
            .filter { cards[$0.id] == nil || cards[$0.id]?.isNew == true }
            .sorted { lhs, rhs in
                // Höheres JLPT-Level (= leichter) zuerst, innerhalb des Levels nach Einbauordnung.
                if lhs.level != rhs.level { return lhs.level > rhs.level }
                return lhs.id < rhs.id
            }
            .prefix(limit))
    }

    /// Fertige Sitzung: erst fällig, dann neu, auf `size` begrenzt.
    public static func session(
        cards: [String: CardState],
        size: Int,
        newWordShare: Int = 3,
        pool: [VocabWord] = Vocabulary.all,
        now: Date = Date()
    ) -> [VocabWord] {
        var result = dueWords(cards: cards, now: now, limit: size)
        let newLimit = max(0, min(newWordShare, size - result.count))
        result += newWords(cards: cards, limit: newLimit, pool: pool)
        if result.isEmpty {
            // Nichts fällig und alles bekannt: zufällige Auffrischung.
            result = Array(pool.shuffled().prefix(size))
        }
        return result
    }

    /// Sitzung für ein Gebiet: erst Wörter, die noch nicht zum Item wurden (fällige,
    /// dann angefangene, dann neue), danach – wenn das Gebiet fertig ist – zur Auffrischung alle.
    public static func regionSession(
        region: WorldRegion,
        cards: [String: CardState],
        size: Int = 5,
        now: Date = Date()
    ) -> [VocabWord] {
        let words = region.words
        let locked = words.filter { !World.isUnlocked($0, cards: cards) }
        let pool = locked.isEmpty ? words : locked
        let due = pool.filter { cards[$0.id].map { !$0.isNew && $0.isDue(at: now) } ?? false }
        let dueIDs = Set(due.map(\.id))
        let started = pool
            .filter { !dueIDs.contains($0.id) && cards[$0.id] != nil }
            .sorted { World.correctCount($0, cards: cards) > World.correctCount($1, cards: cards) }
        let fresh = pool.filter { cards[$0.id] == nil }
        return Array((due + started + fresh).prefix(size))
    }
}
