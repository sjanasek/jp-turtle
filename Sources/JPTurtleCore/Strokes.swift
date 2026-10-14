import Foundation

/// Strichzahlen für das Schreib-Dojo. Die Zahl dient als Hinweis und fließt
/// weich in die Bewertung ein (ein Strich zu viel/zu wenig kostet wenige Punkte).
public enum StrokeCounts {
    public static let hiragana: [String: Int] = [
        "あ": 3, "い": 2, "う": 2, "え": 2, "お": 3,
        "か": 3, "き": 4, "く": 1, "け": 3, "こ": 2,
        "さ": 3, "し": 1, "す": 2, "せ": 3, "そ": 1,
        "た": 4, "ち": 2, "つ": 1, "て": 1, "と": 2,
        "な": 4, "に": 3, "ぬ": 2, "ね": 2, "の": 1,
        "は": 3, "ひ": 1, "ふ": 4, "へ": 1, "ほ": 4,
        "ま": 3, "み": 2, "む": 3, "め": 2, "も": 3,
        "や": 3, "ゆ": 2, "よ": 2,
        "ら": 2, "り": 2, "る": 1, "れ": 2, "ろ": 1,
        "わ": 2, "を": 3, "ん": 1,
        "が": 5, "ぎ": 6, "ぐ": 3, "げ": 5, "ご": 4,
        "ざ": 5, "じ": 3, "ず": 4, "ぜ": 5, "ぞ": 3,
        "だ": 6, "ぢ": 4, "づ": 3, "で": 3, "ど": 4,
        "ば": 5, "び": 3, "ぶ": 6, "べ": 3, "ぼ": 6,
        "ぱ": 4, "ぴ": 2, "ぷ": 5, "ぺ": 2, "ぽ": 5,
    ]

    public static let katakana: [String: Int] = [
        "ア": 2, "イ": 2, "ウ": 3, "エ": 3, "オ": 3,
        "カ": 2, "キ": 3, "ク": 2, "ケ": 3, "コ": 2,
        "サ": 3, "シ": 3, "ス": 2, "セ": 2, "ソ": 2,
        "タ": 3, "チ": 3, "ツ": 3, "テ": 3, "ト": 2,
        "ナ": 2, "ニ": 2, "ヌ": 2, "ネ": 4, "ノ": 1,
        "ハ": 2, "ヒ": 2, "フ": 1, "ヘ": 1, "ホ": 4,
        "マ": 2, "ミ": 3, "ム": 2, "メ": 2, "モ": 3,
        "ヤ": 2, "ユ": 2, "ヨ": 3,
        "ラ": 2, "リ": 2, "ル": 2, "レ": 1, "ロ": 3,
        "ワ": 2, "ヲ": 3, "ン": 2,
        "ガ": 4, "ギ": 5, "グ": 4, "ゲ": 5, "ゴ": 4,
        "ザ": 5, "ジ": 5, "ズ": 4, "ゼ": 4, "ゾ": 4,
        "ダ": 5, "ヂ": 5, "ヅ": 5, "デ": 5, "ド": 4,
        "バ": 4, "ビ": 4, "ブ": 3, "ベ": 3, "ボ": 6,
        "パ": 3, "ピ": 3, "プ": 2, "ペ": 2, "ポ": 5,
    ]

    /// Kanji, die im eingebauten Wortschatz vorkommen (JLPT N5/N4).
    public static let kanji: [String: Int] = [
        "一": 1, "二": 2, "三": 3, "四": 5, "五": 4, "六": 4, "七": 2, "八": 2, "九": 2, "十": 2,
        "百": 6, "千": 3, "万": 3, "日": 4, "月": 4, "年": 6, "今": 4, "時": 10, "間": 12, "分": 4,
        "午": 4, "昨": 9, "明": 8, "前": 9, "後": 9, "週": 11, "末": 5, "毎": 6, "朝": 12, "昼": 9, "夜": 8,
        "水": 4, "火": 4, "木": 4, "山": 3, "川": 3, "海": 9, "空": 8, "雨": 8, "雪": 11, "花": 7,
        "天": 4, "気": 6, "風": 9, "星": 9, "森": 12,
        "人": 2, "男": 7, "女": 3, "子": 3, "供": 8, "友": 4, "達": 12, "先": 6, "生": 5, "学": 8,
        "父": 4, "母": 5, "家": 10, "族": 11, "私": 7, "名": 6,
        "校": 10, "駅": 14, "店": 8, "会": 6, "社": 7, "病": 10, "院": 10, "銀": 14, "行": 6, "国": 8,
        "町": 7, "部": 11, "屋": 9, "道": 12, "本": 5, "公": 4, "園": 13, "図": 7, "書": 10, "館": 16,
        "食": 9, "飲": 12, "来": 7, "見": 7, "聞": 14, "話": 13, "読": 14, "買": 12, "寝": 13, "起": 10,
        "待": 9, "帰": 10, "勉": 10, "強": 11, "働": 13, "泳": 8, "遊": 12, "歩": 8, "立": 5, "座": 10,
        "使": 8, "作": 7, "教": 11,
        "大": 3, "小": 3, "新": 13, "古": 5, "高": 10, "安": 6, "暑": 12, "寒": 12, "美": 9, "味": 8,
        "楽": 13, "難": 18, "簡": 18, "単": 9, "優": 17, "忙": 6, "元": 4, "静": 14, "早": 6, "長": 8,
        "短": 12, "多": 6, "少": 4, "白": 5, "黒": 11, "赤": 7, "青": 8, "面": 9, "好": 6,
        "車": 7, "電": 13, "傘": 12, "机": 6, "椅": 12, "計": 9, "金": 8, "服": 8, "靴": 13, "鞄": 14,
        "写": 5, "真": 10, "紙": 10, "手": 4, "窓": 11, "薬": 16, "切": 4, "符": 11,
        "茶": 9, "飯": 12, "魚": 11, "肉": 6, "野": 11, "菜": 11, "果": 8, "物": 8, "卵": 7, "牛": 4,
        "乳": 8, "酒": 10, "塩": 13, "砂": 9, "糖": 16,
        "犬": 4, "猫": 11, "鳥": 11, "馬": 10, "亀": 11,
        "目": 5, "口": 3, "耳": 6, "足": 7, "頭": 16, "体": 7, "顔": 18,
        "何": 7, "誰": 15, "緒": 14,
    ]

    public static func count(for character: String) -> Int? {
        hiragana[character] ?? katakana[character] ?? kanji[character]
    }
}

/// Ein Schreib-Übungsziel: ein einzelnes Zeichen plus Kontext.
public struct WritingTarget: Identifiable, Hashable, Sendable {
    public enum Kind: String, Sendable { case hiragana, katakana, kanji }

    public let character: String
    public let kind: Kind
    /// Aussprache/Lesung (Romaji bei Kana, Kana-Lesung bei Kanji).
    public let reading: String
    /// Bedeutung (bei Kanji das Wort, aus dem es stammt).
    public let meaning: String?
    public let strokes: Int?

    public var id: String { "\(kind.rawValue)-\(character)" }

    public init(character: String, kind: Kind, reading: String, meaning: String?, strokes: Int?) {
        self.character = character
        self.kind = kind
        self.reading = reading
        self.meaning = meaning
        self.strokes = strokes
    }

    public static func kana(_ k: Kana) -> WritingTarget {
        WritingTarget(
            character: k.character,
            kind: k.script == .hiragana ? .hiragana : .katakana,
            reading: k.romaji,
            meaning: nil,
            strokes: StrokeCounts.count(for: k.character)
        )
    }

    /// Alle Kanji aus einem Vokabel (ein Ziel pro Zeichen).
    public static func kanji(in word: VocabWord) -> [WritingTarget] {
        guard let kanji = word.kanji else { return [] }
        return kanji.compactMap { ch in
            let s = String(ch)
            guard StrokeCounts.kanji[s] != nil else { return nil }
            return WritingTarget(
                character: s,
                kind: .kanji,
                reading: word.kana,
                meaning: "\(word.display) = \(word.meaning)",
                strokes: StrokeCounts.kanji[s]
            )
        }
    }

    /// Alle Kanji-Ziele aus dem Wortschatz, dedupliziert nach Zeichen.
    public static func allKanjiTargets(from words: [VocabWord] = Vocabulary.all) -> [WritingTarget] {
        var seen = Set<String>()
        var out: [WritingTarget] = []
        for w in words {
            for t in kanji(in: w) where !seen.contains(t.character) {
                seen.insert(t.character)
                out.append(t)
            }
        }
        return out
    }
}
