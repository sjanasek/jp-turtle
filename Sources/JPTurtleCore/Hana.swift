import Foundation

/// Hana Kamei (亀井 花) – die Tutorin der App.
///
/// Charakterblatt:
///  * Aus Kyoto, ewig gut gelaunt, ein bisschen tollpatschig, liebt Taiyaki.
///  * Trägt ihre Schildkröte Kame im Rucksack mit sich herum.
///  * Hana schimpft nie. Fehler sind "Futter für Kame" – also wertvoll.
///  * Lieblingssatz: "Ganbatte, ne!"
///
/// Die Freundschaft mit Hana wächst über Herzen, die es für jede Lernsitzung
/// gibt. Höhere Stufen schalten Outfits/Accessoires frei (siehe App).
public enum FriendshipLevel: Int, CaseIterable, Comparable, Sendable {
    case stranger = 0, acquaintance, friend, bestFriend, soulmate

    public static func < (lhs: FriendshipLevel, rhs: FriendshipLevel) -> Bool { lhs.rawValue < rhs.rawValue }

    public var minHearts: Int {
        switch self {
        case .stranger: return 0
        case .acquaintance: return 5
        case .friend: return 20
        case .bestFriend: return 50
        case .soulmate: return 120
        }
    }

    public var title: String {
        switch self {
        case .stranger: return "Neu kennengelernt"
        case .acquaintance: return "Bekannte"
        case .friend: return "Freunde"
        case .bestFriend: return "Beste Freunde"
        case .soulmate: return "Nakama"
        }
    }

    /// Was auf dieser Stufe freigeschaltet wird (Darstellung in der App).
    public var unlock: String {
        switch self {
        case .stranger: return "Hana begleitet dich"
        case .acquaintance: return "Hanas rote Haarschleife"
        case .friend: return "Hanas Schuluniform"
        case .bestFriend: return "Hanas Sommer-Yukata"
        case .soulmate: return "Hanas Kyoto-Kimono + Kame-Haarspange"
        }
    }

    public static func level(forHearts hearts: Int) -> FriendshipLevel {
        allCases.last { hearts >= $0.minHearts } ?? .stranger
    }

    public var next: FriendshipLevel? { FriendshipLevel(rawValue: rawValue + 1) }
}

/// Stimmungen für Hanas Gesicht und Sprüche.
public enum HanaMood: String, CaseIterable, Sendable {
    case happy, cheer, proud, comfort, think, sleepy, surprised, welcomeBack
}

/// Hanas Sprüche. Deutsch mit japanischen Einsprengseln, damit nebenbei
/// Alltagsjapanisch hängen bleibt.
public enum HanaLines {
    public static func line(for mood: HanaMood, streak: Int = 0, gapDays: Int = 0) -> String {
        var rng = SystemRandomNumberGenerator()
        return line(for: mood, streak: streak, gapDays: gapDays, using: &rng)
    }

    public static func line<G: RandomNumberGenerator>(for mood: HanaMood, streak: Int = 0, gapDays: Int = 0, using rng: inout G) -> String {
        let options: [String]
        switch mood {
        case .happy:
            options = [
                "Yatta! Genau so!",
                "Sugoi! Kame klatscht mit den Flossen.",
                "Perfekt. Das merkt sich dein Kopf jetzt.",
                "Oh, das ging ja schnell! Ii ne!",
            ]
        case .cheer:
            options = [
                "Ganbatte, ne! Nur eine Karte nach der anderen.",
                "Drei Karten reichen heute völlig. Ehrlich.",
                "Kein Druck. Kame braucht auch Stunden für einen Meter.",
                "Lass uns kurz aufwärmen – mehr musst du nicht versprechen.",
            ]
        case .proud:
            options = [
                "Ich bin so stolz! Kame auch, aber der zeigt es nicht.",
                "Schau dir deine Serie an! Sugoi sugoi!",
                "Du hast mehr gelernt, als du denkst.",
            ]
        case .comfort:
            options = [
                "Daijoubu! Fehler sind Futter für Kame.",
                "Das Wort kommt wieder. Beim dritten Mal sitzt es.",
                "Niemand lernt Japanisch ohne hundert kleine Stolperer.",
                "Hab ich am Anfang auch verwechselt. Weiter!",
            ]
        case .think:
            options = [
                "Hmm … denk an die Lesung. Was hörst du im Kopf?",
                "Tipp: Schau auf das erste Zeichen.",
                "Chotto matte – lass dir ruhig Zeit.",
            ]
        case .sleepy:
            options = [
                "Oyasumi … noch eine Karte, dann schlafen Kame und ich.",
                "Spät schon! Aber Lernen vorm Schlafen bleibt gut hängen.",
            ]
        case .surprised:
            options = [
                "Ehhh?! Neues Level! Kame ist gewachsen!",
                "Wow, Achievement! Das muss gefeiert werden – Taiyaki!",
            ]
        case .welcomeBack:
            if gapDays >= 3 {
                options = [
                    "Okaeri! \(gapDays) Tage Pause – kein Problem. Comeback-Bonus ist aktiv: doppelte XP!",
                    "Da bist du ja wieder! Kame hat die ganze Zeit hier gewartet. Doppelte XP für den Neustart!",
                    "Willkommen zurück! Pausen sind okay. Lass uns ganz klein anfangen – 3 Karten?",
                ]
            } else {
                options = [
                    "Okaeri! Serie: \(streak) Tage. Weiter geht's!",
                    "Konnichiwa! Heute wieder ein kleines Stück Japan.",
                    "Hallo! Kame hat schon die Karten gemischt.",
                ]
            }
        }
        return options.randomElement(using: &rng) ?? options[0]
    }
}
