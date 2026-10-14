import Foundation

/// Entwicklungsstufen von Kame, der Lern-Schildkröte. Jede Stufe wird ab
/// einer bestimmten XP-Zahl erreicht.
public enum TurtleStage: Int, Codable, CaseIterable, Comparable, Sendable {
    case egg = 0, hatchling, juvenile, wanderer, elder, sensei

    public static func < (lhs: TurtleStage, rhs: TurtleStage) -> Bool { lhs.rawValue < rhs.rawValue }

    public var minXP: Int {
        switch self {
        case .egg: return 0
        case .hatchling: return 100
        case .juvenile: return 400
        case .wanderer: return 1_000
        case .elder: return 2_500
        case .sensei: return 6_000
        }
    }

    public var title: String {
        switch self {
        case .egg: return "Ei"
        case .hatchling: return "Schlüpfling"
        case .juvenile: return "Jungtier"
        case .wanderer: return "Wanderer"
        case .elder: return "Weise Kame"
        case .sensei: return "Kame-Sensei"
        }
    }

    public var japanese: String {
        switch self {
        case .egg: return "たまご"
        case .hatchling: return "こがめ"
        case .juvenile: return "わかがめ"
        case .wanderer: return "たびがめ"
        case .elder: return "ろうがめ"
        case .sensei: return "かめせんせい"
        }
    }

    public var flavor: String {
        switch self {
        case .egg: return "Noch ganz still. Jede richtige Antwort wärmt das Ei."
        case .hatchling: return "Geschlüpft! Kame kennt jetzt die ersten Wörter."
        case .juvenile: return "Kame paddelt los. Der Panzer bekommt erste Muster."
        case .wanderer: return "Kame reist durch Japan – Bahnhof, Markt, Berge."
        case .elder: return "Kame kennt viele Wörter und erzählt Geschichten."
        case .sensei: return "Kame unterrichtet jetzt selbst. Du bist N5-fit!"
        }
    }

    public static func stage(forXP xp: Int) -> TurtleStage {
        allCases.last { xp >= $0.minXP } ?? .egg
    }

    public var next: TurtleStage? { TurtleStage(rawValue: rawValue + 1) }
}

/// Tägliche Aufgaben. Werden einmal pro Tag zurückgesetzt. Bewusst klein,
/// damit auch ein Zwei-Minuten-Tag "geschafft" sein kann.
public struct DailyQuest: Identifiable, Hashable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case warmup, reviews, newWords, kanaRound, writing, widgetAnswers, perfectStreak
    }

    public let kind: Kind
    public let title: String
    public let target: Int
    public let rewardXP: Int
    public let symbol: String

    public var id: Kind { kind }

    public static let all: [DailyQuest] = [
        DailyQuest(kind: .warmup, title: "Aufwärmen: 3 Karten", target: 3, rewardXP: 10, symbol: "cup.and.saucer"),
        DailyQuest(kind: .reviews, title: "10 Karten wiederholen", target: 10, rewardXP: 25, symbol: "rectangle.stack"),
        DailyQuest(kind: .newWords, title: "3 neue Wörter lernen", target: 3, rewardXP: 20, symbol: "sparkles"),
        DailyQuest(kind: .writing, title: "5 Zeichen schreiben", target: 5, rewardXP: 25, symbol: "pencil.and.scribble"),
        DailyQuest(kind: .kanaRound, title: "Eine Runde im Kana-Dojo", target: 1, rewardXP: 15, symbol: "character.ja"),
        DailyQuest(kind: .widgetAnswers, title: "2 Widget-Fragen beantworten", target: 2, rewardXP: 15, symbol: "lock.iphone"),
        DailyQuest(kind: .perfectStreak, title: "5 richtige Antworten in Folge", target: 5, rewardXP: 20, symbol: "flame"),
    ]
}

/// Alles, was den Spielfortschritt ausmacht. Wird als JSON gespeichert.
/// Neue Felder immer mit Default-Wert anlegen, damit alte Speicherstände
/// weiter dekodierbar bleiben (siehe `init(from:)`).
public struct Progress: Codable, Equatable, Sendable {
    public var xp: Int = 0
    public var streak: Int = 0
    public var bestStreak: Int = 0
    /// Tag (yyyy-MM-dd, lokale Zeitzone) der letzten Lernaktivität.
    public var lastStudyDay: String?
    public var totalReviews: Int = 0
    public var correctReviews: Int = 0
    /// Trefferzähler pro Kana-ID (3 = gemeistert).
    public var kanaCorrectCounts: [String: Int] = [:]
    public var dailyGoal: Int = 10

    // Gamification
    /// Streak-Schutzschilde: fangen einen verpassten Tag ab.
    public var shields: Int = 1
    /// Herzen = Freundschaft mit Hana.
    public var hearts: Int = 0
    /// Gesammelte Sticker-IDs (siehe `Sticker`).
    public var stickers: [String] = []
    /// Freigeschaltete Achievement-IDs.
    public var achievements: [String] = []
    /// Tag, an dem die Tageskiste zuletzt geöffnet wurde.
    public var chestOpenedDay: String?
    /// Verbleibende Antworten mit doppelten XP (Comeback-Bonus).
    public var comebackBonusRemaining: Int = 0
    /// Anzahl Tage, die vor dem letzten Lernen pausiert wurden (für Hanas Begrüßung).
    public var lastGapDays: Int = 0

    // Schreiben
    public var totalWritings: Int = 0
    public var perfectWritings: Int = 0
    /// Bester Schreib-Score (0-100) pro Zeichen.
    public var writingBest: [String: Int] = [:]

    // Tageszähler
    public var today: String?
    public var reviewsToday: Int = 0
    public var newWordsToday: Int = 0
    public var kanaRoundsToday: Int = 0
    public var writingsToday: Int = 0
    public var widgetAnswersToday: Int = 0
    public var currentCorrectRun: Int = 0
    public var bestCorrectRunToday: Int = 0
    public var completedQuestsToday: [DailyQuest.Kind] = []

    public init() {}

    // Tolerantes Decoding: fehlende Keys bekommen ihre Defaults.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func get<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? c.decodeIfPresent(T.self, forKey: key)) ?? fallback
        }
        xp = get(.xp, 0)
        streak = get(.streak, 0)
        bestStreak = get(.bestStreak, 0)
        lastStudyDay = try c.decodeIfPresent(String.self, forKey: .lastStudyDay)
        totalReviews = get(.totalReviews, 0)
        correctReviews = get(.correctReviews, 0)
        kanaCorrectCounts = get(.kanaCorrectCounts, [:])
        dailyGoal = get(.dailyGoal, 10)
        shields = get(.shields, 1)
        hearts = get(.hearts, 0)
        stickers = get(.stickers, [])
        achievements = get(.achievements, [])
        chestOpenedDay = try c.decodeIfPresent(String.self, forKey: .chestOpenedDay)
        comebackBonusRemaining = get(.comebackBonusRemaining, 0)
        lastGapDays = get(.lastGapDays, 0)
        totalWritings = get(.totalWritings, 0)
        perfectWritings = get(.perfectWritings, 0)
        writingBest = get(.writingBest, [:])
        today = try c.decodeIfPresent(String.self, forKey: .today)
        reviewsToday = get(.reviewsToday, 0)
        newWordsToday = get(.newWordsToday, 0)
        kanaRoundsToday = get(.kanaRoundsToday, 0)
        writingsToday = get(.writingsToday, 0)
        widgetAnswersToday = get(.widgetAnswersToday, 0)
        currentCorrectRun = get(.currentCorrectRun, 0)
        bestCorrectRunToday = get(.bestCorrectRunToday, 0)
        completedQuestsToday = get(.completedQuestsToday, [])
    }

    // MARK: Abgeleitete Werte

    public var stage: TurtleStage { TurtleStage.stage(forXP: xp) }

    /// Fortschritt 0...1 innerhalb der aktuellen Stufe.
    public var stageProgress: Double {
        let current = stage
        guard let next = current.next else { return 1 }
        let span = Double(next.minXP - current.minXP)
        return min(1, max(0, Double(xp - current.minXP) / span))
    }

    public var accuracy: Double {
        totalReviews == 0 ? 0 : Double(correctReviews) / Double(totalReviews)
    }

    public var friendship: FriendshipLevel { FriendshipLevel.level(forHearts: hearts) }

    public var dailyGoalReached: Bool { reviewsToday + writingsToday >= dailyGoal }

    public func chestAvailable(now: Date, calendar: Calendar = .current) -> Bool {
        dailyGoalReached && chestOpenedDay != Progress.dayKey(now, calendar: calendar)
    }

    public func kanaMastered(_ script: Kana.Script) -> Int {
        KanaTable.all(script, includeVoiced: false)
            .filter { (kanaCorrectCounts[$0.id] ?? 0) >= 3 }
            .count
    }

    public func questProgress(_ quest: DailyQuest) -> Int {
        switch quest.kind {
        case .warmup: return reviewsToday + writingsToday
        case .reviews: return reviewsToday
        case .newWords: return newWordsToday
        case .kanaRound: return kanaRoundsToday
        case .writing: return writingsToday
        case .widgetAnswers: return widgetAnswersToday
        case .perfectStreak: return bestCorrectRunToday
        }
    }

    public func isQuestDone(_ quest: DailyQuest) -> Bool {
        completedQuestsToday.contains(quest.kind)
    }

    // MARK: Mutationen

    /// Setzt Tageszähler zurück, wenn ein neuer Tag begonnen hat.
    public mutating func rollDay(now: Date, calendar: Calendar = .current) {
        let day = Progress.dayKey(now, calendar: calendar)
        guard today != day else { return }
        today = day
        reviewsToday = 0
        newWordsToday = 0
        kanaRoundsToday = 0
        writingsToday = 0
        widgetAnswersToday = 0
        currentCorrectRun = 0
        bestCorrectRunToday = 0
        completedQuestsToday = []
    }

    /// Was beim Verlängern der Serie passiert ist.
    public enum StreakEvent: Equatable, Sendable {
        case alreadyToday
        case extended
        case shieldUsed
        case restarted(gapDays: Int)
    }

    /// Aktualisiert die Lernserie für heute. Ein verpasster Tag wird durch
    /// einen Schild abgefangen; nach längerer Pause gibt es statt Strafe
    /// einen Comeback-Bonus (doppelte XP für die nächsten Antworten).
    @discardableResult
    public mutating func registerStudy(now: Date, calendar: Calendar = .current) -> StreakEvent {
        rollDay(now: now, calendar: calendar)
        let day = Progress.dayKey(now, calendar: calendar)
        if lastStudyDay == day { return .alreadyToday }

        var gap = Int.max
        if let last = lastStudyDay, let lastDate = Progress.date(fromDayKey: last, calendar: calendar) {
            gap = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: now)).day ?? Int.max
        }

        let event: StreakEvent
        if gap == 1 {
            streak += 1
            event = .extended
        } else if gap == 2 && shields > 0 {
            shields -= 1
            streak += 1
            event = .shieldUsed
        } else {
            let hadStreak = lastStudyDay != nil
            streak = 1
            if hadStreak && gap >= 3 {
                comebackBonusRemaining = 10
            }
            event = .restarted(gapDays: hadStreak ? min(gap, 999) : 0)
        }
        lastGapDays = gap == Int.max ? 0 : gap
        bestStreak = max(bestStreak, streak)
        lastStudyDay = day

        // Alle 5 Serientage gibt es einen Schild (max. 3).
        if streak % 5 == 0 { shields = min(3, shields + 1) }
        return event
    }

    /// Prüft, ob die Serie noch lebt (gelernt gestern oder heute, oder Schild vorhanden).
    public func streakIsAlive(now: Date, calendar: Calendar = .current) -> Bool {
        guard let last = lastStudyDay,
              let lastDate = Progress.date(fromDayKey: last, calendar: calendar) else { return false }
        let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastDate), to: calendar.startOfDay(for: now)).day ?? 99
        return diff <= 1 || (diff == 2 && shields > 0)
    }

    /// Schließt alle Quests ab, deren Ziel erreicht ist, und gibt die neu
    /// abgeschlossenen zurück (XP wird dabei gutgeschrieben).
    public mutating func checkQuests() -> [DailyQuest] {
        var newlyDone: [DailyQuest] = []
        for quest in DailyQuest.all where !isQuestDone(quest) && questProgress(quest) >= quest.target {
            completedQuestsToday.append(quest.kind)
            xp += quest.rewardXP
            newlyDone.append(quest)
        }
        return newlyDone
    }

    public static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    public static func date(fromDayKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var c = DateComponents()
        c.year = parts[0]; c.month = parts[1]; c.day = parts[2]
        return calendar.date(from: c)
    }
}
