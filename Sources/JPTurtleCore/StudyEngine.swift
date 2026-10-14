import Foundation

/// Ergebnis einer verbuchten Aktion – damit die UI XP-Animationen,
/// Stufenaufstiege, Quests, Achievements und Hanas Reaktion zeigen kann.
public struct ReviewOutcome: Equatable, Sendable {
    public var xpGained: Int
    public var streakEvent: Progress.StreakEvent
    public var newStage: TurtleStage?
    public var completedQuests: [DailyQuest.Kind]
    public var achievements: [String]
    public var heartsGained: Int
    public var newFriendship: FriendshipLevel?
    public var comebackBonusApplied: Bool
    public var card: CardState?
    /// Wörter, die durch diese Aktion zu Items in Kames Welt wurden.
    public var unlockedWordIDs: [String] = []
    /// Gebiete, über denen der Nebel gewichen ist.
    public var openedRegionIDs: [String] = []
    /// Gebiete, die jetzt vollständig sind.
    public var completedRegionIDs: [String] = []

    public var streakExtended: Bool {
        switch streakEvent {
        case .extended, .shieldUsed: return true
        case .restarted(let gap): return gap == 0
        case .alreadyToday: return false
        }
    }

    /// Passende Stimmung für Hana.
    public var hanaMood: HanaMood {
        if newStage != nil || !achievements.isEmpty || !completedRegionIDs.isEmpty { return .surprised }
        if !unlockedWordIDs.isEmpty || !openedRegionIDs.isEmpty { return .proud }
        if newFriendship != nil || !completedQuests.isEmpty { return .proud }
        if case .restarted(let gap) = streakEvent, gap >= 3 { return .welcomeBack }
        return .happy
    }
}

/// Zentrale Schreib-API auf den SharedStore. App und Widget benutzen dieselbe
/// Logik, damit Fortschritt egal von wo konsistent verbucht wird.
public struct StudyEngine: Sendable {
    public enum Source: Sendable { case app, widget }

    public let store: SharedStore

    public init(store: SharedStore = .shared) {
        self.store = store
    }

    // MARK: Vokabeln

    /// Verbucht eine Antwort auf eine Vokabel. `comboMultiplier` kommt aus der
    /// Sitzung (Combo-Anzeige), `usedHint` halbiert die XP der Antwort.
    @discardableResult
    public func review(
        wordID: String,
        grade: Grade,
        source: Source = .app,
        comboMultiplier: Double = 1,
        usedHint: Bool = false,
        now: Date = Date()
    ) -> ReviewOutcome {
        var cards = store.loadCards()
        var progress = store.loadProgress()
        let before = progress.stage

        let cardsBefore = cards
        let old = cards[wordID] ?? CardState(wordID: wordID, now: now)
        let wasNew = old.isNew
        let card: CardState
        if !wasNew, !old.isDue(at: now), grade.isCorrect {
            // Frühes Üben (z. B. Gebietssitzung): zählt fürs Freischalten, verschiebt aber den
            // Wiederholungstermin nicht. So bleibt die Spaced Repetition ehrlich.
            var early = old
            early.correctCount += 1
            card = early
        } else {
            card = Scheduler.review(old, grade: grade, now: now)
        }
        cards[wordID] = card

        let streakEvent = progress.registerStudy(now: now)
        progress.totalReviews += 1
        progress.reviewsToday += 1
        if wasNew { progress.newWordsToday += 1 }
        if source == .widget { progress.widgetAnswersToday += 1 }

        var base = 0
        if grade.isCorrect {
            progress.correctReviews += 1
            progress.currentCorrectRun += 1
            progress.bestCorrectRunToday = max(progress.bestCorrectRunToday, progress.currentCorrectRun)
            base += grade == .easy ? 12 : (grade == .hard ? 6 : 10)
            if wasNew { base += 5 }
            if usedHint { base = max(2, base / 2) }
        } else {
            progress.currentCorrectRun = 0
            base += 2
        }
        base = Int((Double(base) * max(1, comboMultiplier)).rounded())

        var xp = base
        var comeback = false
        if progress.comebackBonusRemaining > 0 {
            progress.comebackBonusRemaining -= 1
            xp += base
            comeback = true
        }
        xp += streakBonus(for: streakEvent, streak: progress.streak)
        progress.xp += xp

        let world = World.change(before: cardsBefore, after: cards, completed: &progress.completedRegions)
        return finish(&progress, cards: cards, baseXP: xp, streakEvent: streakEvent, before: before, card: card, saveCards: true, comeback: comeback, viaWidget: source == .widget, hearts: heartsFor(streakEvent), world: world)
    }

    // MARK: Kana-Dojo

    @discardableResult
    public func kanaRound(results: [(kana: Kana, correct: Bool)], now: Date = Date()) -> ReviewOutcome {
        var progress = store.loadProgress()
        let before = progress.stage
        let streakEvent = progress.registerStudy(now: now)

        var xp = 0
        for r in results where r.correct {
            progress.kanaCorrectCounts[r.kana.id, default: 0] += 1
            xp += 3
        }
        if !results.isEmpty, results.allSatisfy(\.correct) { xp += 10 }
        progress.kanaRoundsToday += 1
        xp += streakBonus(for: streakEvent, streak: progress.streak)
        progress.xp += xp

        return finish(&progress, cards: store.loadCards(), baseXP: xp, streakEvent: streakEvent, before: before, card: nil, saveCards: false, comeback: false, viaWidget: false, hearts: heartsFor(streakEvent) + 1, world: .none)
    }

    // MARK: Schreiben

    /// Verbucht ein geschriebenes Zeichen.
    @discardableResult
    public func writing(target: WritingTarget, score: InkScore, traced: Bool, now: Date = Date()) -> ReviewOutcome {
        var progress = store.loadProgress()
        let before = progress.stage
        let streakEvent = progress.registerStudy(now: now)

        var cards = store.loadCards()
        let cardsBefore = cards
        var cardsChanged = false
        if score.total >= World.stampScore, let wordID = target.wordID {
            // Gutes Schreiben zählt für das Wort doppelt: Items per Schreiben freischalten.
            var card = cards[wordID] ?? CardState(wordID: wordID, now: now)
            card.correctCount += World.writingBonus
            cards[wordID] = card
            cardsChanged = true
        }

        progress.totalWritings += 1
        progress.writingsToday += 1
        if score.isPerfect { progress.perfectWritings += 1 }
        let best = progress.writingBest[target.id] ?? 0
        progress.writingBest[target.id] = max(best, score.total)

        // Freies Schreiben (ohne Vorlage) ist mehr wert als Nachspuren.
        var xp = traced ? score.verdict.xp : score.verdict.xp + 5
        if score.total > best, best > 0 { xp += 3 }   // persönliche Bestleistung
        if progress.comebackBonusRemaining > 0 {
            progress.comebackBonusRemaining -= 1
            xp *= 2
        }
        xp += streakBonus(for: streakEvent, streak: progress.streak)
        progress.xp += xp

        let world = World.change(before: cardsBefore, after: cards, completed: &progress.completedRegions)
        return finish(&progress, cards: cards, baseXP: xp, streakEvent: streakEvent, before: before, card: nil, saveCards: cardsChanged, comeback: false, viaWidget: false, hearts: heartsFor(streakEvent) + (score.isPerfect ? 1 : 0), world: world)
    }

    // MARK: Tageskiste

    /// Öffnet die Tageskiste, falls verfügbar. Gibt die Belohnung zurück.
    public func openChest(now: Date = Date()) -> ChestReward? {
        var progress = store.loadProgress()
        progress.rollDay(now: now)
        guard progress.chestAvailable(now: now) else { return nil }
        var rng = SystemRandomNumberGenerator()
        let reward = Chest.roll(owned: progress.stickers, shields: progress.shields, using: &rng)
        apply(reward, to: &progress)
        progress.chestOpenedDay = Progress.dayKey(now)
        _ = Achievement.evaluate(progress: &progress, cards: store.loadCards())
        store.save(progress)
        return reward
    }

    public func apply(_ reward: ChestReward, to progress: inout Progress) {
        switch reward {
        case .xp(let n): progress.xp += n
        case .shield: progress.shields = min(3, progress.shields + 1)
        case .sticker(let s): if !progress.stickers.contains(s.id) { progress.stickers.append(s.id) }
        case .hearts(let n): progress.hearts += n
        }
    }

    // MARK: Abfragen

    public func dueCount(now: Date = Date()) -> Int {
        store.loadCards().values.filter { !$0.isNew && $0.isDue(at: now) }.count
    }

    public func masteredCounts() -> [WordCategory: Int] {
        let cards = store.loadCards()
        var counts: [WordCategory: Int] = [:]
        for card in cards.values where card.isMastered {
            if let w = Vocabulary.word(id: card.wordID) {
                counts[w.category, default: 0] += 1
            }
        }
        return counts
    }

    // MARK: Intern

    private func streakBonus(for event: Progress.StreakEvent, streak: Int) -> Int {
        switch event {
        case .extended, .shieldUsed: return 5 * min(streak, 10)
        case .restarted: return 5
        case .alreadyToday: return 0
        }
    }

    private func heartsFor(_ event: Progress.StreakEvent) -> Int {
        // Erste Aktivität des Tages bringt Herzen – kommt man zurück, extra viele.
        switch event {
        case .alreadyToday: return 0
        case .extended, .shieldUsed: return 2
        case .restarted(let gap): return gap >= 3 ? 3 : 1
        }
    }

    private func finish(
        _ progress: inout Progress,
        cards: [String: CardState],
        baseXP: Int,
        streakEvent: Progress.StreakEvent,
        before: TurtleStage,
        card: CardState?,
        saveCards: Bool,
        comeback: Bool,
        viaWidget: Bool,
        hearts: Int,
        world: World.Change
    ) -> ReviewOutcome {
        var xp = baseXP
        let friendshipBefore = progress.friendship
        progress.hearts += hearts + world.hearts
        progress.xp += world.xp
        xp += world.xp

        let quests = progress.checkQuests()
        xp += quests.reduce(0) { $0 + $1.rewardXP }

        let unlocked = Achievement.evaluate(progress: &progress, cards: cards, streakEvent: streakEvent, viaWidget: viaWidget)
        xp += unlocked.reduce(0) { $0 + $1.rewardXP }

        if saveCards { store.save(cards) }
        store.save(progress)

        let after = progress.stage
        let friendshipAfter = progress.friendship
        return ReviewOutcome(
            xpGained: xp,
            streakEvent: streakEvent,
            newStage: after > before ? after : nil,
            completedQuests: quests.map(\.kind),
            achievements: unlocked.map(\.id),
            heartsGained: hearts,
            newFriendship: friendshipAfter > friendshipBefore ? friendshipAfter : nil,
            comebackBonusApplied: comeback,
            card: card,
            unlockedWordIDs: world.unlockedWordIDs,
            openedRegionIDs: world.openedRegionIDs,
            completedRegionIDs: world.completedRegionIDs
        )
    }
}
