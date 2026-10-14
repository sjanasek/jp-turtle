import Foundation

/// Ein Item in Kames Welt. Jedes Wort des Wortschatzes ist genau ein Item.
public struct WorldItem: Identifiable, Hashable, Sendable {
    public let word: VocabWord
    /// SF-Symbol als Bild für das freigeschaltete Item.
    public let symbol: String

    public var id: String { word.id }
}

/// Ein Gebiet in Kames Welt (Teich, Teehaus, Berg ...). Jedes Gebiet hat
/// Themenwörter; wer sie lernt, füllt das Gebiet mit Leben.
public struct WorldRegion: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let japanese: String
    /// Lesung des japanischen Namens (für die Sprachausgabe).
    public let reading: String
    public let tagline: String
    public let symbol: String
    /// Wie viele Items in der ganzen Welt freigeschaltet sein müssen, damit der Nebel
    /// über dem Gebiet weicht.
    public let requires: Int
    public let items: [WorldItem]

    public var words: [VocabWord] { items.map(\.word) }
}

/// Kames Welt: Wörter werden zu Items, Items füllen Gebiete, Gebiete bilden die Welt.
///
/// Regeln:
///  * Ein Wort wird zum Item, sobald es `unlockThreshold` Mal richtig beantwortet wurde.
///  * Gutes Schreiben eines Kanji zählt als `writingBonus` richtige Antworten fürs Wort.
///  * Ein Gebiet ist offen, wenn weltweit genug Items freigeschaltet sind (`requires`),
///    und vollständig, wenn all seine Items freigeschaltet sind.
public enum World {
    public static let unlockThreshold = 5
    public static let writingBonus = 2
    public static let itemXP = 5
    public static let regionBonusXP = 50
    public static let regionBonusHearts = 3
    /// Ab dieser Schreibnote bekommt ein Kanji-Item den Tusche-Stempel.
    public static let stampScore = 65

    public static let regions: [WorldRegion] = buildRegions()

    public static let allItems: [WorldItem] = regions.flatMap(\.items)

    public static func region(id: String) -> WorldRegion? {
        regions.first { $0.id == id }
    }

    public static func region(containing wordID: String) -> WorldRegion? {
        regions.first { $0.items.contains { $0.word.id == wordID } }
    }

    // MARK: Fortschritt

    public static func correctCount(_ word: VocabWord, cards: [String: CardState]) -> Int {
        cards[word.id]?.correctCount ?? 0
    }

    public static func isUnlocked(_ word: VocabWord, cards: [String: CardState]) -> Bool {
        correctCount(word, cards: cards) >= unlockThreshold
    }

    /// Fortschritt 0...unlockThreshold fürs Wort.
    public static func progress(_ word: VocabWord, cards: [String: CardState]) -> Int {
        min(unlockThreshold, correctCount(word, cards: cards))
    }

    public static func unlockedCount(cards: [String: CardState]) -> Int {
        allItems.reduce(0) { $0 + (isUnlocked($1.word, cards: cards) ? 1 : 0) }
    }

    public static func unlockedCount(in region: WorldRegion, cards: [String: CardState]) -> Int {
        region.items.reduce(0) { $0 + (isUnlocked($1.word, cards: cards) ? 1 : 0) }
    }

    public static func isComplete(_ region: WorldRegion, cards: [String: CardState]) -> Bool {
        unlockedCount(in: region, cards: cards) == region.items.count
    }

    public static func isOpen(_ region: WorldRegion, cards: [String: CardState]) -> Bool {
        unlockedCount(cards: cards) >= region.requires
    }

    public static func openRegions(cards: [String: CardState]) -> [WorldRegion] {
        let total = unlockedCount(cards: cards)
        return regions.filter { total >= $0.requires }
    }

    /// Wörter aus offenen Gebieten: nur aus diesen werden neue Wörter eingeführt.
    public static func openWords(cards: [String: CardState]) -> [VocabWord] {
        openRegions(cards: cards).flatMap(\.words)
    }

    /// Erstes offenes Gebiet, das noch nicht vollständig ist (für „Weiter in …“).
    public static func currentRegion(cards: [String: CardState]) -> WorldRegion? {
        openRegions(cards: cards).first { !isComplete($0, cards: cards) }
    }

    /// Tusche-Stempel: alle Kanji des Wortes wurden mit mindestens „Gut“ geschrieben.
    public static func isStamped(_ word: VocabWord, writingBest: [String: Int]) -> Bool {
        guard let kanji = word.kanji else { return false }
        let characters = kanji.map(String.init).filter { StrokeCounts.kanji[$0] != nil }
        guard !characters.isEmpty else { return false }
        return characters.allSatisfy { (writingBest["kanji-\($0)"] ?? 0) >= stampScore }
    }

    // MARK: Änderungen zwischen zwei Kartenständen

    public struct Change: Equatable, Sendable {
        public var unlockedWordIDs: [String] = []
        public var openedRegionIDs: [String] = []
        public var completedRegionIDs: [String] = []
        public var xp: Int = 0
        public var hearts: Int = 0

        public static let none = Change()
        public var isEmpty: Bool { self == .none }
    }

    /// Vergleicht zwei Kartenstände und liefert, was sich in der Welt geändert hat.
    /// Gebiete, die erstmals vollständig sind, werden in `completed` vermerkt und
    /// mit Bonus belohnt – jedes Gebiet nur einmal.
    public static func change(
        before: [String: CardState],
        after: [String: CardState],
        completed: inout [String]
    ) -> Change {
        var change = Change()
        for item in allItems {
            if !isUnlocked(item.word, cards: before), isUnlocked(item.word, cards: after) {
                change.unlockedWordIDs.append(item.word.id)
            }
        }
        let totalBefore = unlockedCount(cards: before)
        let totalAfter = unlockedCount(cards: after)
        for region in regions where totalBefore < region.requires && totalAfter >= region.requires {
            change.openedRegionIDs.append(region.id)
        }
        for region in regions where !completed.contains(region.id) && isComplete(region, cards: after) {
            completed.append(region.id)
            change.completedRegionIDs.append(region.id)
        }
        change.xp = change.unlockedWordIDs.count * itemXP + change.completedRegionIDs.count * regionBonusXP
        change.hearts = change.completedRegionIDs.count * regionBonusHearts
        return change
    }

    // MARK: Aufbau

    private struct Spec {
        let id: String
        let title: String
        let japanese: String
        let reading: String
        let tagline: String
        let symbol: String
        let requires: Int
        /// Wörter, die unabhängig von ihrer Kategorie hierher gehören (Anzeige-Schreibung).
        let explicit: [String]
        /// Restliche Wörter nach Kategorie.
        let categories: [WordCategory]
    }

    private static let specs: [Spec] = [
        Spec(id: "pond", title: "Teich", japanese: "池", reading: "いけ",
             tagline: "Wasser, Fische und ein ruhiger Morgen.", symbol: "drop.fill", requires: 0,
             explicit: ["水", "魚", "亀", "波", "池", "蛙", "鯉", "船", "橋", "石"], categories: []),
        Spec(id: "teahouse", title: "Teehaus", japanese: "茶屋", reading: "ちゃや",
             tagline: "Reis, Tee und alles, was auf den Tisch kommt.", symbol: "cup.and.saucer.fill", requires: 5,
             explicit: [], categories: [.food]),
        Spec(id: "torii", title: "Torii-Tor", japanese: "鳥居", reading: "とりい",
             tagline: "Grüßen, danken, fragen – das Tor zum Gespräch.", symbol: "hand.wave.fill", requires: 10,
             explicit: [], categories: [.greetings, .questions]),
        Spec(id: "garden", title: "Garten", japanese: "庭", reading: "にわ",
             tagline: "Blumen, Bäume und die Tiere, die hier wohnen.", symbol: "leaf.fill", requires: 16,
             explicit: ["花", "木", "雨", "風"], categories: [.animals]),
        Spec(id: "village", title: "Dorf", japanese: "町", reading: "まち",
             tagline: "Bahnhof, Schule, Laden: Wege durch den Ort.", symbol: "building.2.fill", requires: 24,
             explicit: [], categories: [.places]),
        Spec(id: "mountain", title: "Berg", japanese: "山", reading: "やま",
             tagline: "Fluss, Meer, Himmel und Schnee.", symbol: "mountain.2.fill", requires: 32,
             explicit: [], categories: [.nature]),
        Spec(id: "plaza", title: "Marktplatz", japanese: "広場", reading: "ひろば",
             tagline: "Menschen treffen: Familie, Freunde, Körper.", symbol: "person.2.fill", requires: 42,
             explicit: [], categories: [.people, .body]),
        Spec(id: "shop", title: "Kramladen", japanese: "雑貨屋", reading: "ざっかや",
             tagline: "Dinge des Alltags vom Schirm bis zum Telefon.", symbol: "shippingbox.fill", requires: 52,
             explicit: [], categories: [.objects]),
        Spec(id: "sundial", title: "Sonnenuhr", japanese: "日時計", reading: "ひどけい",
             tagline: "Zahlen, Tage und die Uhrzeit.", symbol: "clock.fill", requires: 64,
             explicit: [], categories: [.time, .numbers]),
        Spec(id: "path", title: "Pfad der Tat", japanese: "道", reading: "みち",
             tagline: "Verben: essen, gehen, lesen, schreiben.", symbol: "signpost.right.fill", requires: 76,
             explicit: [], categories: [.verbs]),
        Spec(id: "lanterns", title: "Laternen-Allee", japanese: "灯", reading: "あかり",
             tagline: "Adjektive und kleine Wörter, die Sätze leuchten lassen.", symbol: "lamp.floor.fill", requires: 92,
             explicit: [], categories: [.adjectives, .misc]),
    ]

    /// Eigene Bilder für besonders anschauliche Wörter (Anzeige-Schreibung → SF-Symbol).
    private static let itemSymbols: [String: String] = [
        "水": "drop.fill", "魚": "fish.fill", "亀": "tortoise.fill", "波": "water.waves", "船": "ferry.fill",
        "お茶": "cup.and.saucer.fill", "ご飯": "fork.knife", "野菜": "carrot.fill",
        "花": "camera.macro", "木": "leaf.fill", "雨": "cloud.rain.fill", "風": "wind",
        "犬": "dog.fill", "猫": "cat.fill", "鳥": "bird.fill", "馬": "hare.fill",
        "家": "house.fill", "駅": "tram.fill", "電車": "tram.fill", "車": "car.fill", "病院": "cross.case.fill",
        "銀行": "building.columns.fill", "学校": "building.columns.fill",
        "山": "mountain.2.fill", "雪": "snowflake", "星": "star.fill", "空": "cloud.sun.fill",
        "本": "book.fill", "時計": "clock.fill", "電話": "phone.fill", "傘": "umbrella.fill", "お金": "yensign.circle.fill",
        "鞄": "bag.fill", "写真": "camera.fill", "新聞": "newspaper.fill", "手紙": "envelope.fill", "テレビ": "tv.fill",
        "薬": "pills.fill", "切符": "ticket.fill",
        "目": "eye.fill", "耳": "ear.fill", "口": "mouth.fill", "手": "hand.raised.fill", "足": "figure.walk",
        "こんにちは": "sun.max.fill", "おやすみなさい": "moon.fill", "月": "moon.fill", "日": "sun.max.fill",
    ]

    private static func buildRegions() -> [WorldRegion] {
        let byDisplay: [String: VocabWord] = Dictionary(
            Vocabulary.all.map { ($0.display, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var assigned: [String: Int] = [:]   // wordID → Index der Spezifikation
        for (index, spec) in specs.enumerated() {
            for key in spec.explicit {
                if let word = byDisplay[key], assigned[word.id] == nil { assigned[word.id] = index }
            }
        }
        for word in Vocabulary.all where assigned[word.id] == nil {
            if let index = specs.firstIndex(where: { $0.categories.contains(word.category) }) {
                assigned[word.id] = index
            }
        }

        return specs.enumerated().map { index, spec in
            var words: [VocabWord] = spec.explicit.compactMap { byDisplay[$0] }.filter { assigned[$0.id] == index }
            let explicitIDs = Set(words.map(\.id))
            words += Vocabulary.all.filter { assigned[$0.id] == index && !explicitIDs.contains($0.id) }
            let items = words.map { WorldItem(word: $0, symbol: itemSymbols[$0.display] ?? spec.symbol) }
            return WorldRegion(
                id: spec.id, title: spec.title, japanese: spec.japanese, reading: spec.reading,
                tagline: spec.tagline, symbol: spec.symbol, requires: spec.requires, items: items
            )
        }
    }
}
