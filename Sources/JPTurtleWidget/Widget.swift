#if os(iOS)
import WidgetKit
import SwiftUI
import AppIntents
import JPTurtleCore

/// Alle Widgets der App. `@main` + WidgetBundle ist die von xtool
/// erwartete Form für eine WidgetKit-Extension.
@main
struct JPTurtleWidgetBundle: WidgetBundle {
    var body: some Widget {
        VocabQuizWidget()
        LockScreenWordWidget()
        StreakWidget()
    }
}

// MARK: - Gemeinsamer Timeline-Provider

struct QuizEntry: TimelineEntry {
    let date: Date
    let state: WidgetQuizState
    let progress: StudyProgress
    let dueCount: Int

    static func placeholder() -> QuizEntry {
        let w = Vocabulary.all[0]
        var rng = SeededGenerator(seed: 7)
        let q = QuizFactory.question(for: w, mode: .wordToMeaning, choiceCount: 3, using: &rng)
        let state = WidgetQuizState(
            wordID: w.id, choiceIDs: q.choices.map(\.id), correctIndex: q.correctIndex,
            answeredIndex: nil, revealed: false, createdAt: .now, correctToday: 0, day: ""
        )
        return QuizEntry(date: .now, state: state, progress: StudyProgress(), dueCount: 0)
    }
}

struct QuizProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuizEntry {
        .placeholder()
    }

    func getSnapshot(in context: Context, completion: @escaping (QuizEntry) -> Void) {
        completion(context.isPreview ? .placeholder() : entry(now: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuizEntry>) -> Void) {
        let now = Date()
        let e = entry(now: now)
        // Nach Ablauf der Frage (bzw. des Ergebnisses) neu laden → neue Vokabel.
        let lifetime = e.state.isAnswered ? WidgetQuiz.resultLifetime : WidgetQuiz.questionLifetime
        let refresh = e.state.createdAt.addingTimeInterval(lifetime + 5)
        completion(Timeline(entries: [e], policy: .after(max(refresh, now.addingTimeInterval(60)))))
    }

    private func entry(now: Date) -> QuizEntry {
        let store = SharedStore.shared
        let state = WidgetQuiz.current(store: store, now: now)
        var progress = store.loadProgress()
        progress.rollDay(now: now)
        return QuizEntry(date: now, state: state, progress: progress, dueCount: StudyEngine(store: store).dueCount(now: now))
    }
}

// MARK: - Homescreen: interaktives Quiz

struct VocabQuizWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VocabQuizWidget", provider: QuizProvider()) { entry in
            VocabQuizView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.98, blue: 0.96), Color(red: 0.86, green: 0.94, blue: 0.90)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Vokabel-Quiz")
        .description("Eine Vokabel, drei Antworten – direkt im Widget tippen.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct VocabQuizView: View {
    let entry: QuizEntry
    @Environment(\.widgetFamily) private var family

    private let accent = Color(red: 0.13, green: 0.55, blue: 0.45)

    var body: some View {
        if let word = entry.state.word {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(word.display)
                            .font(.system(size: family == .systemLarge ? 44 : 32, weight: .bold))
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            if word.hasSeparateReading { Text(word.kana) }
                            Text(word.romaji).foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Label("\(entry.progress.streak)", systemImage: "flame.fill")
                            .foregroundStyle(.orange)
                        Label("\(entry.state.correctToday)", systemImage: "checkmark.circle")
                            .foregroundStyle(accent)
                    }
                    .font(.caption2.bold())
                }

                if entry.state.isAnswered {
                    result(word: word)
                } else {
                    choices
                }

                if family == .systemLarge {
                    Spacer()
                    HStack {
                        KameFigure(stage: entry.progress.stage).frame(width: 24)
                        Text(entry.dueCount > 0 ? "\(entry.dueCount) Karten fällig" : "Alles wiederholt – Kame ist stolz.")
                        Spacer()
                        Text(entry.progress.stage.title)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .widgetURL(DeepLink.review(wordID: word.id).url)
        } else {
            Text("JP Turtle").font(.headline)
        }
    }

    private var choices: some View {
        VStack(spacing: 6) {
            ForEach(Array(entry.state.choices.enumerated()), id: \.offset) { i, choice in
                Button(intent: AnswerQuizIntent(index: i)) {
                    HStack {
                        Text(choice.meaning)
                            .font(.footnote.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        }
    }

    private func result(word: VocabWord) -> some View {
        let correct = entry.state.answeredCorrectly ?? false
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(correct ? accent : .red)
                Text(correct ? "Richtig! +10 XP" : "Nicht ganz. Kommt wieder dran.")
                    .font(.footnote.bold())
            }
            Text("\(word.display) = \(word.meaning)")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(intent: NextWordIntent()) {
                Label("Nächstes Wort", systemImage: "arrow.right.circle.fill")
                    .font(.footnote.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .foregroundStyle(accent)
        }
    }
}

// MARK: - Sperrbildschirm: Wort des Moments

struct LockScreenWordWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LockScreenWordWidget", provider: QuizProvider()) { entry in
            LockScreenWordView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Wort auf dem Sperrbildschirm")
        .description("Zeigt eine Vokabel. Antippen deckt die Bedeutung auf; „Gewusst“ zählt als Wiederholung.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

struct LockScreenWordView: View {
    let entry: QuizEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let word = entry.state.word {
            switch family {
            case .accessoryInline:
                if entry.state.revealed {
                    Text("🐢 \(word.display) = \(word.meaning)")
                } else {
                    Text("🐢 \(word.display) · \(word.romaji)")
                }
            case .accessoryCircular:
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        Text(word.display)
                            .font(.system(size: 20, weight: .bold))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                        Text(word.romaji)
                            .font(.system(size: 9))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(4)
                }
                .widgetURL(DeepLink.review(wordID: word.id).url)
            default:
                rectangular(word: word)
            }
        } else {
            Text("JP Turtle")
        }
    }

    private func rectangular(word: VocabWord) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(word.display)
                    .font(.system(size: 22, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(word.romaji)
                    .font(.caption)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            if entry.state.isAnswered {
                Text((entry.state.answeredCorrectly ?? false) ? "✓ Gewusst · \(word.meaning)" : "↻ \(word.meaning)")
                    .font(.caption)
                    .lineLimit(2)
            } else if entry.state.revealed {
                Text(word.meaning)
                    .font(.caption)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Button(intent: SelfGradeIntent(knew: true)) {
                        Label("Gewusst", systemImage: "checkmark")
                            .font(.caption2.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    Button(intent: SelfGradeIntent(knew: false)) {
                        Label("Nochmal", systemImage: "arrow.counterclockwise")
                            .font(.caption2.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(intent: RevealWordIntent()) {
                    HStack(spacing: 4) {
                        Image(systemName: "eye")
                        Text("Bedeutung aufdecken")
                    }
                    .font(.caption2.bold())
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .widgetURL(DeepLink.review(wordID: word.id).url)
    }
}

// MARK: - Serie & Kame

struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StreakWidget", provider: QuizProvider()) { entry in
            StreakView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(colors: [Color(red: 0.98, green: 0.93, blue: 0.80), Color(red: 0.98, green: 0.85, blue: 0.70)], startPoint: .top, endPoint: .bottom)
                }
        }
        .configurationDisplayName("Serie & Kame")
        .description("Deine Lernserie, fällige Karten und Kames Stufe.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryInline])
    }
}

struct StreakView: View {
    let entry: QuizEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "flame.fill").font(.caption)
                    Text("\(entry.progress.streak)").font(.system(size: 18, weight: .bold))
                    Text(entry.dueCount > 0 ? "\(entry.dueCount) fällig" : "✓")
                        .font(.system(size: 8))
                }
            }
            .widgetURL(DeepLink.home.url)
        case .accessoryInline:
            Text("🔥 \(entry.progress.streak) Tage · \(entry.dueCount) fällig")
                .widgetURL(DeepLink.home.url)
        default:
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    KameFigure(stage: entry.progress.stage)
                        .frame(width: 46)
                    Spacer()
                    Label("\(entry.progress.streak)", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
                Spacer()
                Text(entry.progress.stage.title).font(.headline)
                Text("\(entry.progress.xp) XP").font(.caption).foregroundStyle(.secondary)
                Text(entry.dueCount > 0 ? "\(entry.dueCount) Karten warten" : "Nichts fällig – Bonusrunde?")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .widgetURL(DeepLink.home.url)
        }
    }
}
#endif
