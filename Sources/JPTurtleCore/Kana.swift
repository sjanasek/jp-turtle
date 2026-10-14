import Foundation

/// Ein einzelnes Kana-Zeichen für das Kana-Dojo.
public struct Kana: Codable, Identifiable, Hashable, Sendable {
    public enum Script: String, Codable, CaseIterable, Sendable {
        case hiragana, katakana

        public var title: String {
            switch self {
            case .hiragana: return "Hiragana"
            case .katakana: return "Katakana"
            }
        }
    }

    public let character: String
    public let romaji: String
    public let script: Script
    /// Reihe der Gojūon-Tabelle (z. B. "k" für か き く け こ), "dakuten" für Trübungszeichen.
    public let row: String

    public var id: String { "\(script.rawValue)-\(romaji)" }
}

/// Die Gojūon-Tabellen inklusive Dakuten/Handakuten.
public enum KanaTable {
    private static let base: [(String, String, String)] = [
        // (hiragana, katakana, romaji)
        ("あ", "ア", "a"), ("い", "イ", "i"), ("う", "ウ", "u"), ("え", "エ", "e"), ("お", "オ", "o"),
        ("か", "カ", "ka"), ("き", "キ", "ki"), ("く", "ク", "ku"), ("け", "ケ", "ke"), ("こ", "コ", "ko"),
        ("さ", "サ", "sa"), ("し", "シ", "shi"), ("す", "ス", "su"), ("せ", "セ", "se"), ("そ", "ソ", "so"),
        ("た", "タ", "ta"), ("ち", "チ", "chi"), ("つ", "ツ", "tsu"), ("て", "テ", "te"), ("と", "ト", "to"),
        ("な", "ナ", "na"), ("に", "ニ", "ni"), ("ぬ", "ヌ", "nu"), ("ね", "ネ", "ne"), ("の", "ノ", "no"),
        ("は", "ハ", "ha"), ("ひ", "ヒ", "hi"), ("ふ", "フ", "fu"), ("へ", "ヘ", "he"), ("ほ", "ホ", "ho"),
        ("ま", "マ", "ma"), ("み", "ミ", "mi"), ("む", "ム", "mu"), ("め", "メ", "me"), ("も", "モ", "mo"),
        ("や", "ヤ", "ya"), ("ゆ", "ユ", "yu"), ("よ", "ヨ", "yo"),
        ("ら", "ラ", "ra"), ("り", "リ", "ri"), ("る", "ル", "ru"), ("れ", "レ", "re"), ("ろ", "ロ", "ro"),
        ("わ", "ワ", "wa"), ("を", "ヲ", "wo"), ("ん", "ン", "n"),
    ]

    private static let voiced: [(String, String, String)] = [
        ("が", "ガ", "ga"), ("ぎ", "ギ", "gi"), ("ぐ", "グ", "gu"), ("げ", "ゲ", "ge"), ("ご", "ゴ", "go"),
        ("ざ", "ザ", "za"), ("じ", "ジ", "ji"), ("ず", "ズ", "zu"), ("ぜ", "ゼ", "ze"), ("ぞ", "ゾ", "zo"),
        ("だ", "ダ", "da"), ("ぢ", "ヂ", "dji"), ("づ", "ヅ", "dzu"), ("で", "デ", "de"), ("ど", "ド", "do"),
        ("ば", "バ", "ba"), ("び", "ビ", "bi"), ("ぶ", "ブ", "bu"), ("べ", "ベ", "be"), ("ぼ", "ボ", "bo"),
        ("ぱ", "パ", "pa"), ("ぴ", "ピ", "pi"), ("ぷ", "プ", "pu"), ("ぺ", "ペ", "pe"), ("ぽ", "ポ", "po"),
    ]

    private static func rowName(for romaji: String) -> String {
        if ["a", "i", "u", "e", "o"].contains(romaji) { return "vowel" }
        if romaji == "n" { return "n" }
        if romaji == "shi" || romaji == "chi" || romaji == "tsu" || romaji == "fu" {
            // Unregelmäßige Lesungen in ihre Reihe einsortieren.
            switch romaji {
            case "shi": return "s"
            case "chi", "tsu": return "t"
            default: return "h"
            }
        }
        return String(romaji.prefix(1))
    }

    public static let hiragana: [Kana] = base.map {
        Kana(character: $0.0, romaji: $0.2, script: .hiragana, row: rowName(for: $0.2))
    } + voiced.map {
        Kana(character: $0.0, romaji: $0.2, script: .hiragana, row: "dakuten")
    }

    public static let katakana: [Kana] = base.map {
        Kana(character: $0.1, romaji: $0.2, script: .katakana, row: rowName(for: $0.2))
    } + voiced.map {
        Kana(character: $0.1, romaji: $0.2, script: .katakana, row: "dakuten")
    }

    public static func all(_ script: Kana.Script, includeVoiced: Bool = true) -> [Kana] {
        let list = script == .hiragana ? hiragana : katakana
        return includeVoiced ? list : list.filter { $0.row != "dakuten" }
    }

    /// Nur die 46 Grundzeichen (ohne Dakuten) – das Ziel für "Kana gemeistert".
    public static func basicCount(_ script: Kana.Script) -> Int {
        all(script, includeVoiced: false).count
    }
}
