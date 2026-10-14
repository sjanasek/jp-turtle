import Foundation

/// Thematische Kategorie eines Vokabels. Jede Kategorie ist gleichzeitig ein
/// "Panzer-Muster", das Kame (die Schildkröte) freischaltet, sobald genug
/// Wörter der Kategorie gemeistert sind.
public enum WordCategory: String, Codable, CaseIterable, Sendable {
    case greetings, numbers, time, food, animals, people, places
    case verbs, adjectives, objects, nature, body, questions, misc

    /// Deutscher Anzeigename.
    public var title: String {
        switch self {
        case .greetings: return "Begrüßungen"
        case .numbers: return "Zahlen"
        case .time: return "Zeit"
        case .food: return "Essen & Trinken"
        case .animals: return "Tiere"
        case .people: return "Menschen"
        case .places: return "Orte"
        case .verbs: return "Verben"
        case .adjectives: return "Adjektive"
        case .objects: return "Gegenstände"
        case .nature: return "Natur"
        case .body: return "Körper"
        case .questions: return "Fragewörter"
        case .misc: return "Verschiedenes"
        }
    }

    /// SF-Symbol für die Kategorie (nur Darstellung, keine Logik).
    public var symbol: String {
        switch self {
        case .greetings: return "hand.wave"
        case .numbers: return "number"
        case .time: return "clock"
        case .food: return "fork.knife"
        case .animals: return "pawprint"
        case .people: return "person.2"
        case .places: return "mappin.and.ellipse"
        case .verbs: return "figure.run"
        case .adjectives: return "paintpalette"
        case .objects: return "shippingbox"
        case .nature: return "leaf"
        case .body: return "figure.stand"
        case .questions: return "questionmark.circle"
        case .misc: return "sparkles"
        }
    }
}

/// Ein Vokabel. `id` ist stabil und wird im Speicher (SRS-Karten, Widget-Zustand)
/// referenziert – also nie umbenennen, nur neue IDs hinzufügen.
public struct VocabWord: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    /// Schreibung mit Kanji, falls üblich. `nil` bei reinen Kana-Wörtern.
    public let kanji: String?
    /// Lesung in Hiragana bzw. Katakana.
    public let kana: String
    public let romaji: String
    /// Deutsche Bedeutung.
    public let meaning: String
    public let category: WordCategory
    /// JLPT-Stufe (5 = Anfänger ... 1 = Fortgeschritten).
    public let level: Int

    public init(
        id: String, kanji: String?, kana: String, romaji: String,
        meaning: String, category: WordCategory, level: Int = 5
    ) {
        self.id = id
        self.kanji = kanji
        self.kana = kana
        self.romaji = romaji
        self.meaning = meaning
        self.category = category
        self.level = level
    }

    /// Bevorzugte Anzeige (Kanji, sonst Kana).
    public var display: String { kanji ?? kana }

    /// Zeigt Kana unter dem Kanji nur, wenn beides unterschiedlich ist.
    public var hasSeparateReading: Bool { kanji != nil && kanji != kana }
}

/// Der eingebaute Wortschatz (ca. JLPT N5). Bewusst als Code statt JSON,
/// damit kein Resource-Bundle nötig ist – das vereinfacht xtool-Builds und
/// die Widget-Extension enorm.
public enum Vocabulary {
    public static let all: [VocabWord] = build()

    public static let byID: [String: VocabWord] = Dictionary(
        uniqueKeysWithValues: all.map { ($0.id, $0) }
    )

    public static func word(id: String) -> VocabWord? { byID[id] }

    public static func words(in category: WordCategory) -> [VocabWord] {
        all.filter { $0.category == category }
    }

    // swiftlint:disable function_body_length
    private static func build() -> [VocabWord] {
        var list: [VocabWord] = []
        var counter = 0
        func add(_ kanji: String?, _ kana: String, _ romaji: String, _ meaning: String, _ cat: WordCategory, level: Int = 5) {
            counter += 1
            list.append(VocabWord(
                id: String(format: "w%04d", counter),
                kanji: kanji, kana: kana, romaji: romaji,
                meaning: meaning, category: cat, level: level
            ))
        }

        // MARK: Begrüßungen & Floskeln
        add(nil, "こんにちは", "konnichiwa", "Guten Tag", .greetings)
        add(nil, "おはよう", "ohayou", "Guten Morgen", .greetings)
        add(nil, "こんばんは", "konbanwa", "Guten Abend", .greetings)
        add(nil, "ありがとう", "arigatou", "Danke", .greetings)
        add(nil, "すみません", "sumimasen", "Entschuldigung", .greetings)
        add(nil, "さようなら", "sayounara", "Auf Wiedersehen", .greetings)
        add(nil, "おやすみなさい", "oyasuminasai", "Gute Nacht", .greetings)
        add(nil, "はい", "hai", "Ja", .greetings)
        add(nil, "いいえ", "iie", "Nein", .greetings)
        add(nil, "おねがいします", "onegaishimasu", "Bitte (um etwas bitten)", .greetings)
        add(nil, "いただきます", "itadakimasu", "Guten Appetit (vor dem Essen)", .greetings)
        add(nil, "はじめまして", "hajimemashite", "Freut mich (beim Kennenlernen)", .greetings)
        add(nil, "どういたしまして", "douitashimashite", "Gern geschehen", .greetings)

        // MARK: Zahlen
        add("一", "いち", "ichi", "eins", .numbers)
        add("二", "に", "ni", "zwei", .numbers)
        add("三", "さん", "san", "drei", .numbers)
        add("四", "よん", "yon", "vier", .numbers)
        add("五", "ご", "go", "fünf", .numbers)
        add("六", "ろく", "roku", "sechs", .numbers)
        add("七", "なな", "nana", "sieben", .numbers)
        add("八", "はち", "hachi", "acht", .numbers)
        add("九", "きゅう", "kyuu", "neun", .numbers)
        add("十", "じゅう", "juu", "zehn", .numbers)
        add("百", "ひゃく", "hyaku", "hundert", .numbers)
        add("千", "せん", "sen", "tausend", .numbers)
        add("万", "まん", "man", "zehntausend", .numbers)

        // MARK: Zeit
        add("今日", "きょう", "kyou", "heute", .time)
        add("明日", "あした", "ashita", "morgen", .time)
        add("昨日", "きのう", "kinou", "gestern", .time)
        add("今", "いま", "ima", "jetzt", .time)
        add("朝", "あさ", "asa", "Morgen (Tageszeit)", .time)
        add("昼", "ひる", "hiru", "Mittag", .time)
        add("夜", "よる", "yoru", "Nacht", .time)
        add("時間", "じかん", "jikan", "Zeit, Stunde", .time)
        add("毎日", "まいにち", "mainichi", "jeden Tag", .time)
        add("年", "とし", "toshi", "Jahr", .time)
        add("月", "つき", "tsuki", "Mond, Monat", .time)
        add("日", "ひ", "hi", "Tag, Sonne", .time)
        add("分", "ふん", "fun", "Minute", .time)
        add("午前", "ごぜん", "gozen", "Vormittag", .time)
        add("午後", "ごご", "gogo", "Nachmittag", .time)
        add("週末", "しゅうまつ", "shuumatsu", "Wochenende", .time)

        // MARK: Essen & Trinken
        add("水", "みず", "mizu", "Wasser", .food)
        add("お茶", "おちゃ", "ocha", "Tee", .food)
        add("ご飯", "ごはん", "gohan", "Reis, Mahlzeit", .food)
        add(nil, "パン", "pan", "Brot", .food)
        add("魚", "さかな", "sakana", "Fisch", .food)
        add("肉", "にく", "niku", "Fleisch", .food)
        add("野菜", "やさい", "yasai", "Gemüse", .food)
        add("果物", "くだもの", "kudamono", "Obst", .food)
        add("卵", "たまご", "tamago", "Ei", .food)
        add("牛乳", "ぎゅうにゅう", "gyuunyuu", "Milch", .food)
        add(nil, "コーヒー", "koohii", "Kaffee", .food)
        add(nil, "りんご", "ringo", "Apfel", .food)
        add("お酒", "おさけ", "osake", "Alkohol, Sake", .food)
        add("塩", "しお", "shio", "Salz", .food)
        add("砂糖", "さとう", "satou", "Zucker", .food)
        add(nil, "ラーメン", "raamen", "Ramen (Nudelsuppe)", .food)

        // MARK: Tiere
        add("犬", "いぬ", "inu", "Hund", .animals)
        add("猫", "ねこ", "neko", "Katze", .animals)
        add("鳥", "とり", "tori", "Vogel", .animals)
        add("馬", "うま", "uma", "Pferd", .animals)
        add("亀", "かめ", "kame", "Schildkröte", .animals, level: 4)
        add("牛", "うし", "ushi", "Kuh, Rind", .animals, level: 4)

        // MARK: Menschen
        add("人", "ひと", "hito", "Mensch, Person", .people)
        add("男", "おとこ", "otoko", "Mann", .people)
        add("女", "おんな", "onna", "Frau", .people)
        add("子供", "こども", "kodomo", "Kind", .people)
        add("友達", "ともだち", "tomodachi", "Freund, Freundin", .people)
        add("先生", "せんせい", "sensei", "Lehrer, Lehrerin", .people)
        add("学生", "がくせい", "gakusei", "Student, Schüler", .people)
        add("父", "ちち", "chichi", "(mein) Vater", .people)
        add("母", "はは", "haha", "(meine) Mutter", .people)
        add("家族", "かぞく", "kazoku", "Familie", .people)
        add("私", "わたし", "watashi", "ich", .people)
        add("名前", "なまえ", "namae", "Name", .people)

        // MARK: Orte
        add("家", "いえ", "ie", "Haus, Zuhause", .places)
        add("学校", "がっこう", "gakkou", "Schule", .places)
        add("駅", "えき", "eki", "Bahnhof", .places)
        add("店", "みせ", "mise", "Laden, Geschäft", .places)
        add("会社", "かいしゃ", "kaisha", "Firma", .places)
        add("病院", "びょういん", "byouin", "Krankenhaus", .places)
        add("銀行", "ぎんこう", "ginkou", "Bank (Geldinstitut)", .places)
        add("国", "くに", "kuni", "Land", .places)
        add("町", "まち", "machi", "Stadt, Ort", .places)
        add("部屋", "へや", "heya", "Zimmer", .places)
        add("道", "みち", "michi", "Weg, Straße", .places)
        add("日本", "にほん", "nihon", "Japan", .places)
        add(nil, "トイレ", "toire", "Toilette", .places)
        add("公園", "こうえん", "kouen", "Park", .places)
        add("図書館", "としょかん", "toshokan", "Bibliothek", .places)

        // MARK: Verben
        add("食べる", "たべる", "taberu", "essen", .verbs)
        add("飲む", "のむ", "nomu", "trinken", .verbs)
        add("行く", "いく", "iku", "gehen", .verbs)
        add("来る", "くる", "kuru", "kommen", .verbs)
        add("見る", "みる", "miru", "sehen", .verbs)
        add("聞く", "きく", "kiku", "hören, fragen", .verbs)
        add("話す", "はなす", "hanasu", "sprechen", .verbs)
        add("読む", "よむ", "yomu", "lesen", .verbs)
        add("書く", "かく", "kaku", "schreiben", .verbs)
        add("買う", "かう", "kau", "kaufen", .verbs)
        add("寝る", "ねる", "neru", "schlafen", .verbs)
        add("起きる", "おきる", "okiru", "aufstehen, aufwachen", .verbs)
        add(nil, "する", "suru", "machen, tun", .verbs)
        add("分かる", "わかる", "wakaru", "verstehen", .verbs)
        add("待つ", "まつ", "matsu", "warten", .verbs)
        add("会う", "あう", "au", "treffen", .verbs)
        add("帰る", "かえる", "kaeru", "zurückkehren, nach Hause gehen", .verbs)
        add("勉強する", "べんきょうする", "benkyou suru", "lernen", .verbs)
        add("働く", "はたらく", "hataraku", "arbeiten", .verbs)
        add("泳ぐ", "およぐ", "oyogu", "schwimmen", .verbs)
        add("遊ぶ", "あそぶ", "asobu", "spielen", .verbs)
        add("歩く", "あるく", "aruku", "zu Fuß gehen", .verbs)
        add("立つ", "たつ", "tatsu", "stehen, aufstehen", .verbs)
        add("座る", "すわる", "suwaru", "sitzen", .verbs)
        add("使う", "つかう", "tsukau", "benutzen", .verbs)
        add("作る", "つくる", "tsukuru", "machen, herstellen", .verbs)
        add("教える", "おしえる", "oshieru", "lehren, beibringen", .verbs)
        add(nil, "ある", "aru", "es gibt (Dinge)", .verbs)
        add(nil, "いる", "iru", "es gibt (Lebewesen)", .verbs)

        // MARK: Adjektive
        add("大きい", "おおきい", "ookii", "groß", .adjectives)
        add("小さい", "ちいさい", "chiisai", "klein", .adjectives)
        add("新しい", "あたらしい", "atarashii", "neu", .adjectives)
        add("古い", "ふるい", "furui", "alt (Dinge)", .adjectives)
        add("高い", "たかい", "takai", "hoch, teuer", .adjectives)
        add("安い", "やすい", "yasui", "billig", .adjectives)
        add("暑い", "あつい", "atsui", "heiß (Wetter)", .adjectives)
        add("寒い", "さむい", "samui", "kalt (Wetter)", .adjectives)
        add("美味しい", "おいしい", "oishii", "lecker", .adjectives)
        add("楽しい", "たのしい", "tanoshii", "lustig, unterhaltsam", .adjectives)
        add("難しい", "むずかしい", "muzukashii", "schwierig", .adjectives)
        add("簡単", "かんたん", "kantan", "einfach, leicht", .adjectives)
        add("優しい", "やさしい", "yasashii", "freundlich, nett", .adjectives)
        add("忙しい", "いそがしい", "isogashii", "beschäftigt", .adjectives)
        add("元気", "げんき", "genki", "gesund, munter", .adjectives)
        add("静か", "しずか", "shizuka", "ruhig, still", .adjectives)
        add(nil, "きれい", "kirei", "schön, sauber", .adjectives)
        add("早い", "はやい", "hayai", "früh", .adjectives)
        add("長い", "ながい", "nagai", "lang", .adjectives)
        add("短い", "みじかい", "mijikai", "kurz", .adjectives)
        add("多い", "おおい", "ooi", "viele", .adjectives)
        add("少ない", "すくない", "sukunai", "wenige", .adjectives)
        add("白い", "しろい", "shiroi", "weiß", .adjectives)
        add("黒い", "くろい", "kuroi", "schwarz", .adjectives)
        add("赤い", "あかい", "akai", "rot", .adjectives)
        add("青い", "あおい", "aoi", "blau", .adjectives)
        add("面白い", "おもしろい", "omoshiroi", "interessant", .adjectives)
        add("好き", "すき", "suki", "mögen, gern haben", .adjectives)

        // MARK: Gegenstände
        add("本", "ほん", "hon", "Buch", .objects)
        add("車", "くるま", "kuruma", "Auto", .objects)
        add("電車", "でんしゃ", "densha", "Zug", .objects)
        add("傘", "かさ", "kasa", "Regenschirm", .objects)
        add("机", "つくえ", "tsukue", "Schreibtisch", .objects)
        add("椅子", "いす", "isu", "Stuhl", .objects)
        add("時計", "とけい", "tokei", "Uhr", .objects)
        add("電話", "でんわ", "denwa", "Telefon", .objects)
        add("お金", "おかね", "okane", "Geld", .objects)
        add("服", "ふく", "fuku", "Kleidung", .objects)
        add("靴", "くつ", "kutsu", "Schuhe", .objects)
        add("鞄", "かばん", "kaban", "Tasche", .objects)
        add("写真", "しゃしん", "shashin", "Foto", .objects)
        add("新聞", "しんぶん", "shinbun", "Zeitung", .objects)
        add("手紙", "てがみ", "tegami", "Brief", .objects)
        add(nil, "テレビ", "terebi", "Fernseher", .objects)
        add(nil, "ドア", "doa", "Tür", .objects)
        add("窓", "まど", "mado", "Fenster", .objects)
        add("薬", "くすり", "kusuri", "Medizin", .objects)
        add("切符", "きっぷ", "kippu", "Fahrkarte", .objects)

        // MARK: Natur
        add("山", "やま", "yama", "Berg", .nature)
        add("川", "かわ", "kawa", "Fluss", .nature)
        add("海", "うみ", "umi", "Meer", .nature)
        add("空", "そら", "sora", "Himmel", .nature)
        add("雨", "あめ", "ame", "Regen", .nature)
        add("雪", "ゆき", "yuki", "Schnee", .nature)
        add("花", "はな", "hana", "Blume", .nature)
        add("木", "き", "ki", "Baum", .nature)
        add("天気", "てんき", "tenki", "Wetter", .nature)
        add("風", "かぜ", "kaze", "Wind", .nature)
        add("星", "ほし", "hoshi", "Stern", .nature)
        add("森", "もり", "mori", "Wald", .nature)

        // MARK: Körper
        add("手", "て", "te", "Hand", .body)
        add("目", "め", "me", "Auge", .body)
        add("口", "くち", "kuchi", "Mund", .body)
        add("耳", "みみ", "mimi", "Ohr", .body)
        add("足", "あし", "ashi", "Fuß, Bein", .body)
        add("頭", "あたま", "atama", "Kopf", .body)
        add("体", "からだ", "karada", "Körper", .body)
        add("顔", "かお", "kao", "Gesicht", .body)

        // MARK: Fragewörter
        add("何", "なに", "nani", "was", .questions)
        add("誰", "だれ", "dare", "wer", .questions)
        add(nil, "どこ", "doko", "wo", .questions)
        add(nil, "いつ", "itsu", "wann", .questions)
        add(nil, "いくら", "ikura", "wie viel (Preis)", .questions)
        add(nil, "どうして", "doushite", "warum", .questions)
        add(nil, "どう", "dou", "wie", .questions)

        // MARK: Verschiedenes
        add(nil, "これ", "kore", "dies (hier bei mir)", .misc)
        add(nil, "それ", "sore", "das (da bei dir)", .misc)
        add(nil, "あれ", "are", "das (dort drüben)", .misc)
        add(nil, "とても", "totemo", "sehr", .misc)
        add("少し", "すこし", "sukoshi", "ein bisschen", .misc)
        add("一緒に", "いっしょに", "isshoni", "zusammen", .misc)
        add(nil, "もう", "mou", "schon", .misc)
        add(nil, "まだ", "mada", "noch (nicht)", .misc)
        add(nil, "たくさん", "takusan", "viel", .misc)
        add(nil, "ゆっくり", "yukkuri", "langsam, gemütlich", .misc)

        return list
    }
    // swiftlint:enable function_body_length
}
