import Foundation

/// Bewertung einer Antwort – orientiert sich an SM-2 / Anki.
public enum Grade: Int, Codable, CaseIterable, Sendable {
    case again = 0
    case hard = 1
    case good = 2
    case easy = 3

    public var title: String {
        switch self {
        case .again: return "Nochmal"
        case .hard: return "Schwer"
        case .good: return "Gut"
        case .easy: return "Leicht"
        }
    }

    public var isCorrect: Bool { self != .again }
}

/// Lernzustand einer Vokabel-Karte.
public struct CardState: Codable, Hashable, Sendable {
    public let wordID: String
    /// Intervall in Tagen bis zur nächsten Wiederholung.
    public var intervalDays: Double
    /// Leichtigkeitsfaktor (SM-2, Start 2.5, nie unter 1.3).
    public var ease: Double
    /// Anzahl aufeinanderfolgender korrekter Antworten.
    public var repetitions: Int
    /// Anzahl Fehlversuche insgesamt.
    public var lapses: Int
    public var due: Date
    public var lastReview: Date?
    /// Richtige Antworten insgesamt (auch Schreib-Bonus). Ab `World.unlockThreshold` zieht das Wort als Item in Kames Welt ein.
    public var correctCount: Int = 0

    public init(wordID: String, now: Date = Date()) {
        self.wordID = wordID
        self.intervalDays = 0
        self.ease = 2.5
        self.repetitions = 0
        self.lapses = 0
        self.due = now
        self.lastReview = nil
    }

    // Tolerantes Decoding: fehlende Keys (ältere Speicherstände) bekommen Defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        wordID = try c.decode(String.self, forKey: .wordID)
        intervalDays = (try? c.decode(Double.self, forKey: .intervalDays)) ?? 0
        ease = (try? c.decode(Double.self, forKey: .ease)) ?? 2.5
        repetitions = (try? c.decode(Int.self, forKey: .repetitions)) ?? 0
        lapses = (try? c.decode(Int.self, forKey: .lapses)) ?? 0
        due = (try? c.decode(Date.self, forKey: .due)) ?? Date()
        lastReview = try? c.decodeIfPresent(Date.self, forKey: .lastReview)
        correctCount = (try? c.decode(Int.self, forKey: .correctCount)) ?? 0
    }

    public var isNew: Bool { lastReview == nil }

    /// "Gemeistert" = mindestens 3 richtige Wiederholungen in Folge und Intervall ≥ 7 Tage.
    public var isMastered: Bool { repetitions >= 3 && intervalDays >= 7 }

    public func isDue(at now: Date) -> Bool { due <= now }
}

/// Vereinfachter SM-2-Scheduler. Bewusst klein gehalten und deterministisch,
/// damit er sich gut testen lässt.
public enum Scheduler {
    public static func review(_ card: CardState, grade: Grade, now: Date = Date()) -> CardState {
        var c = card
        c.lastReview = now

        switch grade {
        case .again:
            c.repetitions = 0
            c.lapses += 1
            c.ease = max(1.3, c.ease - 0.2)
            // In 10 Minuten nochmal.
            c.intervalDays = 0
            c.due = now.addingTimeInterval(10 * 60)
            return c

        case .hard:
            c.ease = max(1.3, c.ease - 0.15)
        case .good:
            break
        case .easy:
            c.ease += 0.15
        }

        c.repetitions += 1
        c.correctCount += 1
        let next: Double
        switch c.repetitions {
        case 1: next = 1
        case 2: next = 3
        default:
            let factor = grade == .hard ? 1.2 : (grade == .easy ? c.ease * 1.3 : c.ease)
            next = max(c.intervalDays * factor, c.intervalDays + 1)
        }
        c.intervalDays = (next * 10).rounded() / 10
        c.due = now.addingTimeInterval(c.intervalDays * 86_400)
        return c
    }
}
