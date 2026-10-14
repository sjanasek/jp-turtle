#if os(iOS)
import AppIntents
import WidgetKit
import JPTurtleCore

/// Antwort im Homescreen-Quiz. Läuft im Widget-Prozess; die Logik liegt in
/// JPTurtleCore (WidgetQuiz), damit App und Widget identisch rechnen.
struct AnswerQuizIntent: AppIntent {
    static var title: LocalizedStringResource = "Antwort wählen"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Antwort-Index")
    var index: Int

    init() {}

    init(index: Int) {
        self.index = index
    }

    func perform() async throws -> some IntentResult {
        WidgetQuiz.answer(index: index)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Nächste Vokabel anfordern.
struct NextWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Nächstes Wort"
    static var isDiscoverable: Bool = false

    init() {}

    func perform() async throws -> some IntentResult {
        WidgetQuiz.next()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Sperrbildschirm: Bedeutung aufdecken.
struct RevealWordIntent: AppIntent {
    static var title: LocalizedStringResource = "Bedeutung aufdecken"
    static var isDiscoverable: Bool = false

    init() {}

    func perform() async throws -> some IntentResult {
        WidgetQuiz.reveal()
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Sperrbildschirm: Selbsteinschätzung nach dem Aufdecken.
struct SelfGradeIntent: AppIntent {
    static var title: LocalizedStringResource = "Gewusst?"
    static var isDiscoverable: Bool = false

    @Parameter(title: "Gewusst")
    var knew: Bool

    init() {}

    init(knew: Bool) {
        self.knew = knew
    }

    func perform() async throws -> some IntentResult {
        WidgetQuiz.selfGrade(knew: knew)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
#endif
