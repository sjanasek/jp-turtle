# JP Turtle 🐢 – spielerisch Japanisch lernen

Eine iOS-App zum Japanischlernen, die ohne Xcode-Projekt auskommt: ein reines
Swift Package, das mit [xtool](https://github.com/xtool-org/xtool) gebaut,
signiert und direkt aufs iPhone installiert wird – von macOS, Linux oder
Windows (WSL).

Die App ist für Leute gebaut, die beim Sprachenlernen schnell die Lust
verlieren. Darum: winzige Einstiegshürden, sofortige Belohnungen, keine
Bestrafung für Pausen – und zwei Begleiter, die mitfiebern.

## Die Begleiter

**Hana Kamei (亀井 花)** – deine Tutorin. Aus Kyoto, immer gut gelaunt, ein
bisschen tollpatschig, liebt Taiyaki. Hana schimpft nie: Fehler sind „Futter
für Kame“. Sie kommentiert jede Antwort, gibt Tipps, begrüßt dich nach Pausen
extra herzlich und hat je nach Stimmung ein anderes Gesicht (Vektor-Avatar,
keine Bilddateien nötig). Die Freundschaft mit ihr wächst über **Herzen** und
schaltet Outfits frei: Haarschleife → Schuluniform → Yukata → Kyoto-Kimono.

**Kame (亀)** – Hanas Schildkröte und dein Lernfortschritt in Tierform. Kame
beginnt als Ei und wächst mit deinen XP: Schlüpfling, Jungtier, Wanderer,
Weise Kame, Kame-Sensei. Für jede Wortkategorie, in der du 5 Wörter
gemeistert hast, bekommt der Panzer ein neues Muster.

## Was die App kann

### Lernen
- **Vokabeln (JLPT N5, ~190 Wörter, Deutsch)** als Multiple Choice in beide
  Richtungen, mit **Spaced Repetition** (vereinfachtes SM-2). Fällige Karten
  kommen zuerst, dann wenige neue Wörter pro Sitzung.
- **Schreib-Dojo (Fokus!)**: Hiragana, Katakana und die Kanji aus bereits
  gelernten Wörtern mit dem Finger oder Apple Pencil schreiben. Zwei Modi:
  *Nachspuren* (Vorlage grau im Hintergrund) und *Aus dem Kopf* (nur die
  Lesung, Vorlage erst nach der Bewertung). Die App bewertet Form,
  Präzision, Lage und Strichzahl (0–100 Punkte) und Hana sagt dir, was
  noch fehlt. Bestnoten pro Zeichen werden gespeichert.
- **Kana-Dojo**: Zeichen erkennen, schwache Zeichen kommen öfter dran,
  Fortschrittsraster für alle 46 Grundzeichen pro Schrift.
- **Wörterbuch** mit Suche, Kategorie-Filter und Lernstatus pro Wort.

### Gamification (für schlechte Lerner gebaut)
- **„Nur 3 Karten“**: Eine Minute reicht, damit der Tag zählt.
- **Tagesquests**, die klein anfangen („Aufwärmen: 3 Karten“).
- **Serie mit Schutzschilden**: Ein verpasster Tag wird automatisch von
  einem Schild abgefangen. Alle 5 Serientage gibt es einen neuen.
- **Comeback-Bonus statt Strafe**: Nach 3+ Tagen Pause gibt es doppelte XP
  für die nächsten 10 Antworten und Hana freut sich – kein schlechtes Gewissen.
- **Combo-Multiplikator** in der Sitzung (x1.5 ab 3, x2 ab 6 Richtigen).
- **Tipp-Knopf** von Hana (halbe XP, aber kein Frust).
- **Tageskiste**: Tagesziel geschafft → Kiste mit Zufallsbelohnung (XP,
  Schild, Herzen oder Sticker).
- **Sticker-Album** (12 Sticker in drei Seltenheitsstufen).
- **19 Achievements** vom ersten Wort bis zum Hiragana-Meister.
- **XP, Stufen, Panzer-Sammlung, Statistik** – alles auf der Seite „Hana & Kame“.

### Widgets (Sperrbildschirm & Homescreen)
- **Wort auf dem Sperrbildschirm** (rechteckig, rund, inline): zeigt eine
  Vokabel mit Romaji. Tippen auf „Bedeutung aufdecken“, dann „Gewusst“ /
  „Nochmal“ – das zählt als echte Wiederholung in der Spaced-Repetition.
- **Vokabel-Quiz** (Homescreen, mittel/groß): drei Antworten direkt im
  Widget antippen (interaktive Widgets über App Intents), danach „Nächstes
  Wort“. Jede Antwort gibt XP und zählt für die Quest „Widget-Fragen“.
- **Serie & Kame** (klein / rund / inline): Serie, fällige Karten, Kames Stufe.
- Jedes Widget öffnet per Deep Link (`jpturtle://…`) die passende Stelle in der App.

### Aussprache und Lautschrift
- **Sprachausgabe** (Systemstimme ja-JP, offline, etwas langsamer als normal):
  Lautsprecher-Knopf im Quiz, im Kana-Dojo, im Schreib-Dojo und im Wörterbuch.
  Optional automatisch: Vokabeln werden beim Erscheinen vorgelesen, im
  Kana-Quiz erst nach der Antwort (sonst wäre die Antwort verraten).
  Gesprochen wird immer die Kana-Lesung, nie das Kanji.
- **Lautschrift (Romaji)** steht von Anfang an unter den Zeichen. Standard
  ist „Ausblenden, wenn gemeistert“: Die Stütze verschwindet pro Wort von
  selbst. Einstellbar unter „Mehr“ (immer / ausblenden / nie).
- Für eine natürlichere Stimme: Einstellungen → Bedienungshilfen →
  Gesprochene Inhalte → Stimmen → Japanisch (erweiterte Stimme laden).
- Die Widgets spielen keinen Ton ab, das erlaubt iOS dort nicht ohne App-Start.

Noch nicht drin, bewusst für später: **Nachsprechen und Aussprache bewerten**
(Spracherkennung). Anhören gibt es, Selbst-Sprechen nicht.

## Projektstruktur

```
Package.swift                      SwiftPM-Manifest (xtool-Konventionen)
xtool.yml                          Bundle-ID, App-Produkt, Extensions, Info.plist, Icon
Support/                           Info.plists, Entitlements, App-Icon
Sources/JPTurtleCore/              Foundation-only Kern – läuft auch unter Linux/macOS
  Vocabulary.swift                 Wortschatz (Code statt JSON, kein Resource-Bundle nötig)
  Kana.swift, Strokes.swift        Kana-Tabellen, Strichzahlen, Schreib-Ziele
  SRS.swift                        Spaced-Repetition-Scheduler
  Progress.swift                   XP, Serie, Schilde, Quests, Tageszähler
  Hana.swift, Rewards.swift        Charakter, Freundschaft, Kiste, Sticker, Achievements
  Ink.swift                        Bewertung von Handschrift (BitMask + InkScorer)
  StudyEngine.swift                Einzige Schreib-API auf den Speicher (App + Widget)
  WidgetQuiz.swift                 Zustand und Regeln des Widget-Quiz
  SharedStore.swift                UserDefaults, App Group wenn verfügbar
Sources/JPTurtle/                  SwiftUI-App (iOS 17+)
Sources/JPTurtleWidget/            WidgetKit-Extension + App Intents
Tests/JPTurtleCoreTests/           Unit-Tests für den Kern (`swift test`)
```

App und Widget teilen sich `JPTurtleCore`. Alles, was Fortschritt verändert,
läuft durch `StudyEngine`, damit eine Antwort im Widget exakt so zählt wie in
der App.

## Bauen und aufs iPhone bringen (xtool)

### Was xtool ist – und was nicht
xtool baut das Swift Package für iOS, erzeugt das `.app`-Bundle, holt sich
über deine Apple-ID ein Zertifikat + Provisioning Profile, signiert die App und
installiert sie per USB. Es ersetzt Xcode als *Build-System*; den iOS-SDK
braucht es trotzdem (auf dem Mac aus Xcode, unter Linux aus einer
`Xcode.xip`). Mit einer **kostenlosen Apple-ID** gilt wie bei Xcode: die App
läuft 7 Tage, dann neu installieren (`xtool dev` nochmal), max. 3 Apps
gleichzeitig, kein App Store. Mit bezahltem Developer-Account entfällt das.

### macOS (empfohlen, wenn du einen Mac hast)
1. Xcode aus dem App Store installieren und einmal starten (für SDK + Toolchain).
   ```bash
   xcrun -sdk iphoneos -show-sdk-path   # muss einen Pfad ausgeben
   swift --version                      # Swift 6.x
   ```
2. xtool installieren:
   ```bash
   brew install xtool-org/tap/xtool
   xtool --help
   ```
3. Einmalig einrichten (Apple-ID-Login; mit kostenloser Apple-ID Option „1: Password“ wählen):
   ```bash
   xtool setup
   ```
4. Repo klonen, iPhone per Kabel anschließen, **Entwicklermodus** auf dem
   iPhone aktivieren (Einstellungen → Datenschutz & Sicherheit → Entwicklermodus):
   ```bash
   git clone https://github.com/sjanasek/jp-turtle
   cd jp-turtle
   xtool dev
   ```
   Beim ersten Mal: „Vertrauen“ auf dem iPhone bestätigen, danach ggf.
   `xtool dev` erneut ausführen. Nach der Installation: Einstellungen →
   Allgemein → VPN & Geräteverwaltung → deiner Apple-ID vertrauen.
5. Danach ist jeder Durchlauf nur noch `xtool dev` (baut inkrementell und
   installiert neu).

Nützlich:
```bash
xtool dev build          # nur bauen, Ergebnis in ./xtool/JPTurtle.app
xtool devices            # verbundene Geräte
xtool install xtool/JPTurtle.ipa
swift test               # Unit-Tests des Kerns (laufen nativ auf dem Mac)
```

### Linux / Windows (WSL)
Siehe die [xtool-Anleitung](https://github.com/xtool-org/xtool/blob/main/Documentation/xtool.docc/Installation-Linux.md):
Swift 6.4 von swift.org, `usbmuxd`, das `xtool`-AppImage, und eine
`Xcode.xip` (Xcode 27), die du eingeloggt bei Apple herunterlädst –
`xtool setup` extrahiert daraus den iOS-SDK (ca. 7 GB, `--slim` ist kleiner).
Unter WSL zusätzlich USB-Passthrough (usbipd). Die Befehle sind danach dieselben.

### Bundle-ID anpassen
In `xtool.yml` steht `bundleID: com.sjanasek.jpturtle`. Ändere sie auf etwas
Eigenes, bevor du baust; die Widget-Extension bekommt automatisch
`<bundleID>.JPTurtleWidget`. Die App Group in `Support/JPTurtle.entitlements`
und `SharedStore.appGroupID` müssen zusammenpassen (`group.<bundleID>`).

## Widgets einrichten

- **Sperrbildschirm**: Sperrbildschirm lange drücken → „Anpassen“ →
  Sperrbildschirm → Widget-Bereich antippen → „JP Turtle“ → „Wort auf dem
  Sperrbildschirm“ (rechteckig) und/oder „Serie & Kame“ (rund).
- **Homescreen**: Homescreen lange drücken → „+“ → „JP Turtle“ →
  „Vokabel-Quiz“ (mittel oder groß).

## Bekannte Einschränkungen (Stand 14. Oktober 2026)

1. **Widget-Extensions mit xtool – offener Bug.** xtool unterstützt
   App-Extensions offiziell (so ist dieses Projekt konfiguriert), aber im
   xtool-Repo ist [Issue #313](https://github.com/xtool-org/xtool/issues/313)
   offen: Mit Swift 6.4 / Xcode 27 wird das WidgetKit-Binary leer gelinkt
   (xtool setzt `-e _NSExtensionMain` als Entry Point) und die Extension
   stürzt beim Start ab. Die App selbst läuft davon unberührt. Wenn das
   Widget bei dir nicht in der Widget-Galerie auftaucht: Issue beobachten
   oder temporär in `xtool.yml` den `extensions:`-Block auskommentieren.
   Der im Issue beschriebene Workaround (Linker-Flag im generierten
   `xtool/.xtool-tmp/Package.swift` entfernen) behebt nur den ersten Teil.
2. **App Group mit kostenloser Apple-ID.** Damit Widget und App denselben
   Fortschritt sehen, braucht es eine App Group. xtool kann die mit freien
   Teams noch nicht provisionieren ([PR #284](https://github.com/xtool-org/xtool/pull/284)
   ist in Review). Darum ist `entitlementsPath` in `xtool.yml` auskommentiert.
   Ohne App Group läuft alles trotzdem: Das Widget nutzt dann seinen eigenen
   kleinen Speicher, XP aus dem Widget kommen aber nicht in der App an. Die
   App zeigt unter „Mehr“ an, welcher Fall gerade gilt. Mit bezahltem
   Account (oder nach dem Merge): Zeile einkommentieren, fertig.
3. **Interaktive Buttons auf dem Sperrbildschirm.** Homescreen-Widgets sind
   seit iOS 17 interaktiv. Falls iOS die Buttons im rechteckigen
   Sperrbildschirm-Widget nicht ausführt, öffnet ein Tipp aufs Widget die
   App direkt bei dem Wort – nichts geht verloren.
4. **Nicht hier kompiliert.** Dieser Stand wurde in einer Linux-Umgebung ohne
   Swift-Toolchain geschrieben. Erwartbar sind kleine Compiler-Korrekturen
   beim ersten `xtool dev` (die Logik in `JPTurtleCore` ist durch Tests
   abgedeckt und läuft mit `swift test` auf dem Mac).
5. **Strichzahlen** für Kana und ~190 Kanji sind handgepflegt
   (`Sources/JPTurtleCore/Strokes.swift`). Sie gehen nur weich in die Note
   ein; eine Strichreihenfolge wird nicht geprüft.
6. **Lizenz-Hinweis**: Die Nutzung von Xcode/iOS-SDK außerhalb von Apple-Hardware
   (Linux/WSL-Weg) bewegt sich laut mehreren Kommentatoren in einer Grauzone
   der Apple-Lizenz. Auf dem Mac stellt sich die Frage nicht.

## Weiterentwickeln

- **Neue Wörter**: in `Vocabulary.swift` eine `add(...)`-Zeile ergänzen. IDs
  werden fortlaufend vergeben – neue Wörter deshalb **ans Ende** einer
  Kategorie oder ans Ende der Liste setzen, sonst verschieben sich IDs und
  gespeicherte Karten zeigen auf andere Wörter. Bei Kanji die Strichzahl in
  `Strokes.swift` nachtragen (ein Test meckert sonst).
- **Neue Quests / Achievements / Sticker**: `Progress.swift` bzw. `Rewards.swift`.
- **Hanas Sprüche**: `Hana.swift`.
- **Roadmap**: Nachsprechen (Speech-Framework), Beispielsätze, Grammatik-Dojo,
  Strichreihenfolge-Animationen, Lernstatistik-Diagramme.

## Tests

```bash
swift test
```
Deckt Scheduler, Serie/Schilde/Comeback, Quests, Quiz-Generator, Widget-Quiz,
Tageskiste, Schreib-Bewertung und die Konsistenz des Wortschatzes ab
(Strichzahlen vorhanden, keine doppelten Bedeutungen).
