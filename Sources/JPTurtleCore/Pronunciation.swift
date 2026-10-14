import Foundation

/// Wann die Lautschrift (Romaji) unter den Zeichen eingeblendet wird.
/// Für Anfänger standardmäßig "fading": Sie ist am Anfang immer da und
/// verschwindet pro Wort, sobald es gemeistert ist. So wird die Stütze
/// langsam abgebaut, ohne dass man sie manuell ausschalten muss.
public enum RomajiMode: String, Codable, CaseIterable, Sendable {
    case always, fading, off

    public var title: String {
        switch self {
        case .always: return "Immer anzeigen"
        case .fading: return "Ausblenden, wenn gemeistert"
        case .off: return "Nie anzeigen"
        }
    }

    public func shouldShow(for card: CardState?) -> Bool {
        switch self {
        case .always: return true
        case .off: return false
        case .fading: return !(card?.isMastered ?? false)
        }
    }
}

/// Was der Sprachausgabe übergeben wird. Immer die Kana-Lesung, nie das Kanji:
/// Die Sprachsynthese rät bei Kanji manchmal die falsche Lesung.
public enum SpokenText {
    public static func text(for word: VocabWord) -> String { word.kana }

    public static func text(for kana: Kana) -> String { kana.character }

    public static func text(for target: WritingTarget) -> String {
        target.kind == .kanji ? target.reading : target.character
    }
}
