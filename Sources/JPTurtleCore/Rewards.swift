import Foundation

/// Sammelbare Sticker (Belohnungen aus der Tageskiste). Die Darstellung in der
/// App komponiert SF Symbols – hier nur Metadaten.
public struct Sticker: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let symbol: String
    public let caption: String
    public let rarity: Rarity

    public enum Rarity: Int, Comparable, Sendable {
        case common = 0, rare, epic
        public static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rawValue < rhs.rawValue }

        public var title: String {
            switch self {
            case .common: return "Gewöhnlich"
            case .rare: return "Selten"
            case .epic: return "Episch"
            }
        }
    }

    public static let all: [Sticker] = [
        Sticker(id: "taiyaki", title: "Taiyaki", symbol: "fish.fill", caption: "Hanas Lieblingssnack.", rarity: .common),
        Sticker(id: "onigiri", title: "Onigiri", symbol: "triangle.fill", caption: "Reisbällchen für die Pause.", rarity: .common),
        Sticker(id: "torii", title: "Torii", symbol: "building.columns.fill", caption: "Das Tor zum Schrein in Kyoto.", rarity: .common),
        Sticker(id: "sakura", title: "Sakura", symbol: "camera.macro", caption: "Kirschblüten im April.", rarity: .common),
        Sticker(id: "shinkansen", title: "Shinkansen", symbol: "tram.fill", caption: "Kame will auch mal so schnell sein.", rarity: .common),
        Sticker(id: "fuji", title: "Fuji-san", symbol: "mountain.2.fill", caption: "Hanas Postkartenmotiv.", rarity: .rare),
        Sticker(id: "lantern", title: "Laterne", symbol: "lamp.floor.fill", caption: "Sommerfest-Laterne.", rarity: .rare),
        Sticker(id: "koi", title: "Koi", symbol: "fish", caption: "Kames bester Freund im Teich.", rarity: .rare),
        Sticker(id: "maneki", title: "Maneki-neko", symbol: "cat.fill", caption: "Die winkende Glückskatze.", rarity: .rare),
        Sticker(id: "kame-crown", title: "Kame mit Krone", symbol: "crown.fill", caption: "Königliche Schildkröte.", rarity: .epic),
        Sticker(id: "hana-star", title: "Hana-Star", symbol: "star.circle.fill", caption: "Hana auf dem Schulfest.", rarity: .epic),
        Sticker(id: "daruma", title: "Daruma", symbol: "eye.fill", caption: "Ein Auge pro erreichtem Ziel.", rarity: .epic),
    ]

    public static func byID(_ id: String) -> Sticker? { all.first { $0.id == id } }
}

/// Inhalt einer geöffneten Tageskiste.
public enum ChestReward: Equatable, Sendable {
    case xp(Int)
    case shield
    case sticker(Sticker)
    case hearts(Int)

    public var title: String {
        switch self {
        case .xp(let n): return "+\(n) XP"
        case .shield: return "Streak-Schild"
        case .sticker(let s): return "Sticker: \(s.title)"
        case .hearts(let n): return "+\(n) Herzen für Hana"
        }
    }
}

public enum Chest {
    /// Zufällige Belohnung. Sticker, die man noch nicht hat, werden bevorzugt.
    public static func roll<G: RandomNumberGenerator>(owned: [String], shields: Int, using rng: inout G) -> ChestReward {
        let missing = Sticker.all.filter { !owned.contains($0.id) }
        let r = Int.random(in: 0..<100, using: &rng)
        switch r {
        case 0..<40 where !missing.isEmpty:
            // Seltenheit gewichten: gewöhnlich 60 %, selten 30 %, episch 10 %.
            let roll = Int.random(in: 0..<100, using: &rng)
            let wanted: Sticker.Rarity = roll < 60 ? .common : (roll < 90 ? .rare : .epic)
            let pool = missing.filter { $0.rarity == wanted }
            if let s = (pool.isEmpty ? missing : pool).randomElement(using: &rng) {
                return .sticker(s)
            }
            return .xp(30)
        case 40..<60 where shields < 3:
            return .shield
        case 60..<75:
            return .hearts(Int.random(in: 2...4, using: &rng))
        default:
            return .xp(Int.random(in: 20...60, using: &rng))
        }
    }
}

/// Achievements. Die Bedingung wird gegen Progress + Karten geprüft.
public struct Achievement: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let detail: String
    public let symbol: String
    public let rewardXP: Int

    public static let all: [Achievement] = [
        Achievement(id: "first-word", title: "Erstes Wort", detail: "Eine Vokabel beantwortet.", symbol: "1.circle.fill", rewardXP: 10),
        Achievement(id: "words-25", title: "Wortsammler", detail: "25 Wörter gelernt.", symbol: "text.book.closed.fill", rewardXP: 30),
        Achievement(id: "words-100", title: "Wortschatz-Kame", detail: "100 Wörter gelernt.", symbol: "books.vertical.fill", rewardXP: 80),
        Achievement(id: "mastered-10", title: "Sitzt!", detail: "10 Wörter gemeistert.", symbol: "checkmark.seal.fill", rewardXP: 40),
        Achievement(id: "streak-3", title: "Drei Tage", detail: "3 Tage am Stück gelernt.", symbol: "flame", rewardXP: 20),
        Achievement(id: "streak-7", title: "Eine Woche", detail: "7 Tage am Stück gelernt.", symbol: "flame.fill", rewardXP: 50),
        Achievement(id: "streak-30", title: "Ein Monat", detail: "30 Tage am Stück. Unfassbar.", symbol: "flame.circle.fill", rewardXP: 200),
        Achievement(id: "comeback", title: "Comeback", detail: "Nach einer Pause wieder angefangen. Das ist das Schwerste.", symbol: "arrow.uturn.backward.circle.fill", rewardXP: 30),
        Achievement(id: "shield-used", title: "Gerettet", detail: "Ein Streak-Schild hat deine Serie gerettet.", symbol: "shield.fill", rewardXP: 10),
        Achievement(id: "kana-first", title: "Erstes Kana", detail: "Ein Zeichen im Dojo erkannt.", symbol: "character", rewardXP: 10),
        Achievement(id: "hiragana-master", title: "Hiragana-Meister", detail: "Alle 46 Hiragana gemeistert.", symbol: "character.book.closed.fill", rewardXP: 150),
        Achievement(id: "katakana-master", title: "Katakana-Meister", detail: "Alle 46 Katakana gemeistert.", symbol: "character.book.closed.fill", rewardXP: 150),
        Achievement(id: "write-first", title: "Erster Pinselstrich", detail: "Ein Zeichen geschrieben.", symbol: "pencil.tip", rewardXP: 10),
        Achievement(id: "write-25", title: "Kalligraf", detail: "25 Zeichen geschrieben.", symbol: "pencil.and.outline", rewardXP: 40),
        Achievement(id: "write-perfect-10", title: "Pinselmeister", detail: "10 Zeichen mit Bestnote geschrieben.", symbol: "paintbrush.pointed.fill", rewardXP: 80),
        Achievement(id: "widget-first", title: "Sperrbildschirm-Lerner", detail: "Erste Antwort über ein Widget.", symbol: "lock.iphone", rewardXP: 15),
        Achievement(id: "hana-friend", title: "Hanas Freund", detail: "Freundschaftsstufe „Freunde“ erreicht.", symbol: "heart.fill", rewardXP: 50),
        Achievement(id: "stickers-6", title: "Halbes Album", detail: "6 Sticker gesammelt.", symbol: "square.grid.3x3.fill", rewardXP: 40),
        Achievement(id: "turtle-wanderer", title: "Reisende Kame", detail: "Kame ist Wanderer geworden.", symbol: "tortoise.fill", rewardXP: 60),
    ]

    public static func byID(_ id: String) -> Achievement? { all.first { $0.id == id } }

    /// Prüft alle Bedingungen und gibt neu erreichte Achievements zurück.
    /// XP werden direkt gutgeschrieben.
    public static func evaluate(progress: inout Progress, cards: [String: CardState], streakEvent: Progress.StreakEvent? = nil, viaWidget: Bool = false) -> [Achievement] {
        let learned = cards.values.filter { !$0.isNew }.count
        let mastered = cards.values.filter(\.isMastered).count
        let kanaAny = progress.kanaCorrectCounts.values.contains { $0 > 0 }

        func met(_ id: String) -> Bool {
            switch id {
            case "first-word": return progress.totalReviews >= 1
            case "words-25": return learned >= 25
            case "words-100": return learned >= 100
            case "mastered-10": return mastered >= 10
            case "streak-3": return progress.streak >= 3
            case "streak-7": return progress.streak >= 7
            case "streak-30": return progress.streak >= 30
            case "comeback":
                if case .restarted(let gap)? = streakEvent { return gap >= 3 }
                return false
            case "shield-used": return streakEvent == .shieldUsed
            case "kana-first": return kanaAny
            case "hiragana-master": return progress.kanaMastered(.hiragana) >= KanaTable.basicCount(.hiragana)
            case "katakana-master": return progress.kanaMastered(.katakana) >= KanaTable.basicCount(.katakana)
            case "write-first": return progress.totalWritings >= 1
            case "write-25": return progress.totalWritings >= 25
            case "write-perfect-10": return progress.perfectWritings >= 10
            case "widget-first": return viaWidget
            case "hana-friend": return progress.friendship >= .friend
            case "stickers-6": return progress.stickers.count >= 6
            case "turtle-wanderer": return progress.stage >= .wanderer
            default: return false
            }
        }

        var unlocked: [Achievement] = []
        for a in all where !progress.achievements.contains(a.id) && met(a.id) {
            progress.achievements.append(a.id)
            progress.xp += a.rewardXP
            unlocked.append(a)
        }
        return unlocked
    }
}
