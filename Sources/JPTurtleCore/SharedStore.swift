import Foundation

/// Gemeinsamer Speicher für App und Widget.
///
/// Wenn die App Group (siehe `appGroupID`) in den Entitlements vorhanden ist,
/// landen alle Daten in deren UserDefaults-Suite und App + Widget sehen
/// denselben Stand. Fehlt die App Group (z. B. kostenlose Apple-ID mit xtool,
/// Stand Oktober 2026), fällt der Store auf die normalen UserDefaults des
/// jeweiligen Prozesses zurück. Dann hat das Widget seinen eigenen, kleinen
/// Fortschritt – funktioniert, aber die XP aus dem Widget kommen nicht in
/// der App an. `isSharedWithWidget` sagt dir, welcher Fall gerade gilt.
public final class SharedStore: @unchecked Sendable {
    /// Muss mit Support/JPTurtle.entitlements übereinstimmen.
    public static let appGroupID = "group.com.sjanasek.jpturtle"

    public static let shared = SharedStore()

    public let defaults: UserDefaults
    public let isSharedWithWidget: Bool

    private let queue = DispatchQueue(label: "jpturtle.store")
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private enum Key {
        static let progress = "jpturtle.progress.v1"
        static let cards = "jpturtle.cards.v1"
        static let widget = "jpturtle.widget.v1"
        static let seenWords = "jpturtle.seen.v1"
    }

    /// Standard-Initialisierer: App Group wenn möglich, sonst `.standard`.
    public convenience init() {
        var shared: UserDefaults?
        #if canImport(Darwin)
        if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedStore.appGroupID) != nil,
           let suite = UserDefaults(suiteName: SharedStore.appGroupID) {
            shared = suite
        }
        #endif
        if let shared {
            self.init(defaults: shared, isShared: true)
        } else {
            self.init(defaults: .standard, isShared: false)
        }
    }

    /// Für Tests oder eigene Suites.
    public init(defaults: UserDefaults, isShared: Bool) {
        self.defaults = defaults
        self.isSharedWithWidget = isShared
    }

    // MARK: Progress

    public func loadProgress() -> Progress {
        load(Progress.self, key: Key.progress) ?? Progress()
    }

    public func save(_ progress: Progress) {
        save(progress, key: Key.progress)
    }

    // MARK: SRS-Karten

    public func loadCards() -> [String: CardState] {
        load([String: CardState].self, key: Key.cards) ?? [:]
    }

    public func save(_ cards: [String: CardState]) {
        save(cards, key: Key.cards)
    }

    // MARK: Widget

    public func loadWidgetState() -> WidgetQuizState? {
        load(WidgetQuizState.self, key: Key.widget)
    }

    public func save(_ state: WidgetQuizState?) {
        if let state {
            save(state, key: Key.widget)
        } else {
            defaults.removeObject(forKey: Key.widget)
        }
    }

    /// Setzt alles zurück (Einstellungen → "Von vorn beginnen").
    public func wipe() {
        queue.sync {
            [Key.progress, Key.cards, Key.widget, Key.seenWords].forEach(defaults.removeObject(forKey:))
        }
    }

    // MARK: Helpers

    private func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        queue.sync {
            guard let data = defaults.data(forKey: key) else { return nil }
            return try? decoder.decode(T.self, from: data)
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        queue.sync {
            guard let data = try? encoder.encode(value) else { return }
            defaults.set(data, forKey: key)
        }
    }
}
