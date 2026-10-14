#if os(iOS)
import Foundation
import SwiftUI
import JPTurtleCore
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Kurze Einblendung oben im Bild (XP, Quest geschafft, Stufenaufstieg).
struct Toast: Equatable, Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let symbol: String
}

/// Beobachtbarer Zustand der App. Alle Schreibzugriffe laufen über
/// `StudyEngine`, damit App und Widget dieselben Regeln verwenden.
@MainActor
final class AppModel: ObservableObject {
    enum Tab: Hashable { case home, writing, kana, friends, more }

    let store: SharedStore
    let engine: StudyEngine

    @Published private(set) var progress: Progress
    @Published private(set) var cards: [String: CardState]
    @Published var selectedTab: Tab = .home
    /// Wird von HomeView konsumiert, um direkt eine Lernsitzung zu öffnen.
    @Published var requestedReviewWordID: String?
    @Published var requestedReview = false
    @Published var toast: Toast?
    /// Hanas aktueller Spruch auf der Startseite.
    @Published var hanaMood: HanaMood = .cheer
    @Published var hanaLine: String = ""

    private var toastTask: Task<Void, Never>?

    init(store: SharedStore = .shared) {
        self.store = store
        self.engine = StudyEngine(store: store)
        var p = store.loadProgress()
        p.rollDay(now: Date())
        self.progress = p
        self.cards = store.loadCards()
        store.save(p)
        refreshHanaGreeting()
    }

    // MARK: Lesen

    var dueCount: Int {
        cards.values.filter { !$0.isNew && $0.isDue(at: Date()) }.count
    }

    var learnedCount: Int { cards.values.filter { !$0.isNew }.count }
    var masteredCount: Int { cards.values.filter(\.isMastered).count }
    var streakAlive: Bool { progress.streakIsAlive(now: Date()) }
    var chestAvailable: Bool { progress.chestAvailable(now: Date()) }
    var studiedToday: Bool { progress.lastStudyDay == Progress.dayKey(Date()) }

    func card(for word: VocabWord) -> CardState? { cards[word.id] }

    func reload() {
        var p = store.loadProgress()
        p.rollDay(now: Date())
        progress = p
        cards = store.loadCards()
    }

    /// Hanas Begrüßung je nach Situation (Pause, Serie, Tageszeit).
    func refreshHanaGreeting() {
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        if !studiedToday {
            let cal = Calendar.current
            var gap = 0
            if let last = progress.lastStudyDay, let d = Progress.date(fromDayKey: last) {
                gap = cal.dateComponents([.day], from: cal.startOfDay(for: d), to: cal.startOfDay(for: now)).day ?? 0
            }
            if gap >= 3 {
                hanaMood = .welcomeBack
                hanaLine = HanaLines.line(for: .welcomeBack, streak: progress.streak, gapDays: gap)
            } else if hour >= 22 || hour < 5 {
                hanaMood = .sleepy
                hanaLine = HanaLines.line(for: .sleepy)
            } else {
                hanaMood = .cheer
                hanaLine = progress.lastStudyDay == nil
                    ? "Hallo, ich bin Hana! Das ist Kame. Wir lernen zusammen Japanisch – in winzigen Schritten. Drei Karten zum Start?"
                    : HanaLines.line(for: .welcomeBack, streak: progress.streak, gapDays: gap)
            }
        } else if chestAvailable {
            hanaMood = .surprised
            hanaLine = "Tagesziel geschafft! Die Kiste wartet – mach sie auf!"
        } else {
            hanaMood = .proud
            hanaLine = HanaLines.line(for: .proud)
        }
    }

    /// Stellt die nächste Lernsitzung zusammen. Ein per Deep Link gewünschtes
    /// Wort kommt an den Anfang.
    func makeSession(size: Int? = nil) -> [VocabWord] {
        var words = SessionPlanner.session(cards: cards, size: size ?? progress.dailyGoal)
        if let id = requestedReviewWordID, let w = Vocabulary.word(id: id) {
            words.removeAll { $0.id == id }
            words.insert(w, at: 0)
            requestedReviewWordID = nil
        }
        return words
    }

    // MARK: Schreiben

    @discardableResult
    func answer(_ word: VocabWord, grade: Grade, comboMultiplier: Double = 1, usedHint: Bool = false) -> ReviewOutcome {
        let outcome = engine.review(wordID: word.id, grade: grade, source: .app, comboMultiplier: comboMultiplier, usedHint: usedHint)
        reload()
        announce(outcome)
        return outcome
    }

    @discardableResult
    func finishKanaRound(_ results: [(kana: Kana, correct: Bool)]) -> ReviewOutcome {
        let outcome = engine.kanaRound(results: results)
        reload()
        announce(outcome)
        return outcome
    }

    @discardableResult
    func recordWriting(target: WritingTarget, score: InkScore, traced: Bool) -> ReviewOutcome {
        let outcome = engine.writing(target: target, score: score, traced: traced)
        reload()
        announce(outcome)
        return outcome
    }

    func openChest() -> ChestReward? {
        let reward = engine.openChest()
        reload()
        refreshHanaGreeting()
        return reward
    }

    func setDailyGoal(_ goal: Int) {
        var p = store.loadProgress()
        p.dailyGoal = max(5, min(50, goal))
        store.save(p)
        reload()
    }

    func setRomajiMode(_ mode: RomajiMode) {
        var p = store.loadProgress()
        p.romajiMode = mode
        store.save(p)
        reload()
    }

    func setAutoSpeak(_ on: Bool) {
        var p = store.loadProgress()
        p.autoSpeak = on
        store.save(p)
        reload()
    }

    func resetEverything() {
        store.wipe()
        reload()
        refreshHanaGreeting()
        refreshWidgets()
    }

    func refreshWidgets() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    // MARK: Deep Links

    func handle(url: URL) {
        guard let link = DeepLink(url: url) else { return }
        reload()
        switch link {
        case .home:
            selectedTab = .home
        case .review(let id):
            requestedReviewWordID = id
            selectedTab = .home
            requestedReview = true
        case .kana:
            selectedTab = .kana
        case .turtle:
            selectedTab = .friends
        }
    }

    // MARK: Toasts

    private func announce(_ outcome: ReviewOutcome) {
        if let stage = outcome.newStage {
            show(Toast(title: "Kame ist jetzt: \(stage.title)!", subtitle: stage.flavor, symbol: "tortoise.fill"))
        } else if let a = outcome.achievements.first.flatMap(Achievement.byID) {
            show(Toast(title: "Achievement: \(a.title)", subtitle: "\(a.detail) +\(a.rewardXP) XP", symbol: a.symbol))
        } else if let f = outcome.newFriendship {
            show(Toast(title: "Hana: \(f.title)!", subtitle: "Freigeschaltet: \(f.unlock)", symbol: "heart.fill"))
        } else if let quest = outcome.completedQuests.first,
                  let q = DailyQuest.all.first(where: { $0.kind == quest }) {
            show(Toast(title: "Quest geschafft: \(q.title)", subtitle: "+\(q.rewardXP) XP", symbol: "checkmark.seal.fill"))
        } else if outcome.streakEvent == .shieldUsed {
            show(Toast(title: "Schild eingesetzt – Serie gerettet!", subtitle: "Serie: \(progress.streak) Tage", symbol: "shield.fill"))
        } else if outcome.streakEvent == .extended {
            show(Toast(title: "Serie: \(progress.streak) Tage", subtitle: "Weiter so!", symbol: "flame.fill"))
        } else if case .restarted(let gap) = outcome.streakEvent, gap >= 3 {
            show(Toast(title: "Comeback-Bonus aktiv", subtitle: "Doppelte XP für die nächsten 10 Antworten", symbol: "arrow.uturn.backward.circle.fill"))
        }
        if outcome.streakEvent != .alreadyToday { refreshHanaGreeting() }
    }

    func show(_ toast: Toast) {
        self.toast = toast
        toastTask?.cancel()
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.8))
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }
}
#endif
