import Foundation

/// Zustand des Widget-Quiz (Sperrbildschirm + Homescreen). Wird im
/// SharedStore abgelegt; die App-Intents des Widgets verändern ihn.
public struct WidgetQuizState: Codable, Equatable, Sendable {
    public var wordID: String
    public var choiceIDs: [String]
    public var correctIndex: Int
    public var answeredIndex: Int?
    public var revealed: Bool
    public var createdAt: Date
    /// Kleiner Zähler nur fürs Widget ("3 richtig heute").
    public var correctToday: Int
    public var day: String

    public var word: VocabWord? { Vocabulary.word(id: wordID) }
    public var choices: [VocabWord] { choiceIDs.compactMap(Vocabulary.word(id:)) }
    public var isAnswered: Bool { answeredIndex != nil }
    public var answeredCorrectly: Bool? {
        guard let a = answeredIndex else { return nil }
        return a == correctIndex
    }
}

/// Regeln für das Widget-Quiz. Komplett ohne WidgetKit, damit es testbar bleibt.
public enum WidgetQuiz {
    /// Nach einer Antwort bleibt das Ergebnis so lange sichtbar.
    public static let resultLifetime: TimeInterval = 15 * 60
    /// Unbeantwortete Fragen wechseln spätestens nach dieser Zeit.
    public static let questionLifetime: TimeInterval = 4 * 60 * 60

    /// Liefert den aktuellen Zustand und erzeugt bei Bedarf eine neue Frage.
    @discardableResult
    public static func current(store: SharedStore = .shared, now: Date = Date()) -> WidgetQuizState {
        if let state = store.loadWidgetState(), !isExpired(state, now: now) {
            return state
        }
        return fresh(store: store, now: now)
    }

    public static func isExpired(_ state: WidgetQuizState, now: Date) -> Bool {
        let age = now.timeIntervalSince(state.createdAt)
        if state.isAnswered { return age > resultLifetime }
        return age > questionLifetime
    }

    /// Erzeugt eine neue Frage: bevorzugt fällige Karten, sonst ein
    /// tagesabhängig zufälliges Wort (alle Widgets zeigen dasselbe).
    @discardableResult
    public static func fresh(store: SharedStore = .shared, now: Date = Date()) -> WidgetQuizState {
        let previous = store.loadWidgetState()
        let cards = store.loadCards()
        var rng = SeededGenerator(day: now, salt: UInt64(now.timeIntervalSince1970 / 600))

        let due = SessionPlanner.dueWords(cards: cards, now: now, limit: 10)
            .filter { $0.id != previous?.wordID }
        let word: VocabWord
        if let pick = due.randomElement(using: &rng) {
            word = pick
        } else {
            let unseen = SessionPlanner.newWords(cards: cards, limit: 20, pool: World.openWords(cards: cards))
                .filter { $0.id != previous?.wordID }
            word = unseen.randomElement(using: &rng)
                ?? Vocabulary.all.randomElement(using: &rng)
                ?? Vocabulary.all[0]
        }

        let q = QuizFactory.question(for: word, mode: .wordToMeaning, choiceCount: 3, using: &rng)
        let today = Progress.dayKey(now)
        let state = WidgetQuizState(
            wordID: word.id,
            choiceIDs: q.choices.map(\.id),
            correctIndex: q.correctIndex,
            answeredIndex: nil,
            revealed: false,
            createdAt: now,
            correctToday: previous?.day == today ? (previous?.correctToday ?? 0) : 0,
            day: today
        )
        store.save(state)
        return state
    }

    /// Antwort aus dem Homescreen-Widget verbuchen.
    @discardableResult
    public static func answer(index: Int, store: SharedStore = .shared, now: Date = Date()) -> WidgetQuizState {
        var state = current(store: store, now: now)
        guard !state.isAnswered, state.choiceIDs.indices.contains(index) else { return state }
        state.answeredIndex = index
        state.revealed = true
        state.createdAt = now
        let correct = index == state.correctIndex
        if correct { state.correctToday += 1 }
        store.save(state)
        StudyEngine(store: store).review(wordID: state.wordID, grade: correct ? .good : .again, source: .widget, now: now)
        return state
    }

    /// Sperrbildschirm: Bedeutung aufdecken (keine Bewertung).
    @discardableResult
    public static func reveal(store: SharedStore = .shared, now: Date = Date()) -> WidgetQuizState {
        var state = current(store: store, now: now)
        state.revealed = true
        store.save(state)
        return state
    }

    /// Sperrbildschirm: "Gewusst" / "Nicht gewusst" nach dem Aufdecken.
    @discardableResult
    public static func selfGrade(knew: Bool, store: SharedStore = .shared, now: Date = Date()) -> WidgetQuizState {
        var state = current(store: store, now: now)
        guard !state.isAnswered else { return state }
        state.answeredIndex = knew ? state.correctIndex : -1
        state.revealed = true
        state.createdAt = now
        if knew { state.correctToday += 1 }
        store.save(state)
        StudyEngine(store: store).review(wordID: state.wordID, grade: knew ? .good : .again, source: .widget, now: now)
        return state
    }

    /// Nächste Frage erzwingen.
    @discardableResult
    public static func next(store: SharedStore = .shared, now: Date = Date()) -> WidgetQuizState {
        fresh(store: store, now: now)
    }
}
