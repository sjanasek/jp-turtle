#if os(iOS)
import SwiftUI
import JPTurtleCore

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NavigationLink {
                        FriendsView()
                    } label: {
                        Label("Hana & Kame, Sticker, Achievements", systemImage: "heart")
                    }
                    NavigationLink {
                        DictionaryView()
                    } label: {
                        Label("Wörterbuch (\(Vocabulary.all.count) Wörter)", systemImage: "book")
                    }
                }

                Section {
                    Picker("Lautschrift (Romaji)", selection: Binding(
                        get: { model.progress.romajiMode },
                        set: { model.setRomajiMode($0) }
                    )) {
                        ForEach(RomajiMode.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Toggle("Aussprache automatisch abspielen", isOn: Binding(
                        get: { model.progress.autoSpeak },
                        set: { model.setAutoSpeak($0) }
                    ))
                    Button("Aussprache testen") {
                        SpeechService.shared.speak("こんにちは")
                    }
                } header: {
                    Text("Aussprache & Hilfen")
                } footer: {
                    Text(SpeechService.shared.hasJapaneseVoice
                         ? "Für eine natürlichere Stimme: Einstellungen → Bedienungshilfen → Gesprochene Inhalte → Stimmen → Japanisch."
                         : "Auf diesem iPhone ist keine japanische Stimme installiert. Lade eine unter Einstellungen → Bedienungshilfen → Gesprochene Inhalte → Stimmen → Japanisch.")
                }

                Section("Lernen") {
                    Stepper(value: Binding(
                        get: { model.progress.dailyGoal },
                        set: { model.setDailyGoal($0) }
                    ), in: 5...50, step: 5) {
                        HStack {
                            Text("Tagesziel")
                            Spacer()
                            Text("\(model.progress.dailyGoal) Karten").foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    LabeledContent("Daten mit Widget geteilt") {
                        Image(systemName: model.store.isSharedWithWidget ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundStyle(model.store.isSharedWithWidget ? Theme.accent : Theme.sun)
                    }
                    LabeledContent("App Group", value: SharedStore.appGroupID)
                        .font(.footnote)
                    Button("Widgets jetzt aktualisieren") { model.refreshWidgets() }
                } header: {
                    Text("Widgets")
                } footer: {
                    Text(model.store.isSharedWithWidget
                         ? "App und Widgets teilen sich denselben Fortschritt."
                         : "Die App Group ist nicht aktiv (Entitlement fehlt). Widgets laufen trotzdem, zählen aber getrennt. Mit bezahltem Developer-Account: in xtool.yml `entitlementsPath` einkommentieren.")
                }

                Section("Daten") {
                    Button("Von vorn beginnen", role: .destructive) { confirmReset = true }
                }

                Section("Über") {
                    LabeledContent("Streak-Schilde", value: "\(model.progress.shields) / 3")
                    Text("Ein Schild fängt automatisch einen verpassten Tag ab. Alle 5 Serientage gibt es einen neuen, außerdem manchmal aus der Tageskiste.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    LabeledContent("Version", value: "0.1.0")
                    Text("Kame - Japanisch lernen. Ein Lernspiel mit Hana und Kame.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Mehr")
            .confirmationDialog("Wirklich alles löschen?", isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Fortschritt löschen", role: .destructive) { model.resetEverything() }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("XP, Serie, Karten und Kana-Fortschritt werden zurückgesetzt. Kame wird wieder zum Ei.")
            }
        }
    }
}
#endif
