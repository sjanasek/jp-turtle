#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Kana-Dojo: Hiragana/Katakana-Zeichen erkennen. 10 Fragen pro Runde.
struct KanaDojoView: View {
    @EnvironmentObject private var model: AppModel
    @State private var script: Kana.Script = .hiragana
    @State private var includeVoiced = false
    @State private var round: KanaRound?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Schrift", selection: $script) {
                        ForEach(Kana.Script.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Mit Dakuten (が, ぱ, …)", isOn: $includeVoiced)
                        .padding(.horizontal, 4)

                    masteryCard

                    Button {
                        round = KanaRound(script: script, includeVoiced: includeVoiced, progress: model.progress)
                    } label: {
                        Label("Runde starten (10 Zeichen)", systemImage: "figure.martial.arts")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    kanaGrid
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Kana-Dojo")
            .fullScreenCover(item: $round) { r in
                KanaRoundView(round: r)
            }
        }
    }

    private var masteryCard: some View {
        let mastered = model.progress.kanaMastered(script)
        let total = KanaTable.basicCount(script)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(script.title) gemeistert")
                    .font(.headline)
                Spacer()
                Text("\(mastered)/\(total)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(mastered), total: Double(total))
                .tint(Theme.sakura)
            Text("Ein Zeichen gilt als gemeistert, wenn du es dreimal richtig erkannt hast.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private var kanaGrid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 5)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(KanaTable.all(script, includeVoiced: includeVoiced)) { kana in
                let count = model.progress.kanaCorrectCounts[kana.id] ?? 0
                VStack(spacing: 0) {
                    Text(kana.character).font(.title2)
                    Text(kana.romaji).font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(
                    (count >= 3 ? Theme.sakura.opacity(0.35) : (count > 0 ? Theme.sun.opacity(0.25) : Color(.secondarySystemGroupedBackground))),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }
        }
    }
}

/// Eine vorbereitete Runde: 10 Zeichen, schwache zuerst.
struct KanaRound: Identifiable {
    let id = UUID()
    let script: Kana.Script
    let pool: [Kana]
    let questions: [(kana: Kana, choices: [Kana], correctIndex: Int)]

    init(script: Kana.Script, includeVoiced: Bool, progress: StudyProgress, count: Int = 10) {
        self.script = script
        self.pool = KanaTable.all(script, includeVoiced: includeVoiced)
        var rng = SystemRandomNumberGenerator()
        // Schwach gelernte Zeichen bevorzugen: sortiert nach Trefferzahl, mit Zufall.
        let ranked = pool.shuffled(using: &rng).sorted {
            (progress.kanaCorrectCounts[$0.id] ?? 0) < (progress.kanaCorrectCounts[$1.id] ?? 0)
        }
        let picked = Array(ranked.prefix(count)).shuffled(using: &rng)
        questions = picked.map { QuizFactory.kanaQuestion(for: $0, pool: pool, using: &rng) }
    }
}

struct KanaRoundView: View {
    let round: KanaRound

    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var selection: Int?
    @State private var results: [(kana: Kana, correct: Bool)] = []
    @State private var outcome: ReviewOutcome?

    var body: some View {
        NavigationStack {
            Group {
                if let outcome {
                    summary(outcome)
                } else {
                    question
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Beenden") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    Text("\(min(index + 1, round.questions.count))/\(round.questions.count)")
                        .font(.subheadline.monospacedDigit())
                }
            }
        }
        .sensoryFeedback(.success, trigger: results.count)
    }

    private var question: some View {
        let q = round.questions[index]
        return VStack(spacing: 20) {
            Spacer()
            VStack(spacing: 8) {
                Text(q.kana.character)
                    .font(.system(size: 120, weight: .bold))
                SpeakButton(text: SpokenText.text(for: q.kana))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 24))
            VStack(spacing: 10) {
                ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                    ChoiceButton(text: choice.romaji, state: state(i, q.correctIndex)) {
                        guard selection == nil else { return }
                        selection = i
                        results.append((q.kana, i == q.correctIndex))
                        if model.progress.autoSpeak {
                            SpeechService.shared.speak(SpokenText.text(for: q.kana))
                        }
                        Task {
                            try? await Task.sleep(for: .milliseconds(i == q.correctIndex ? 450 : 1100))
                            advance()
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
    }

    private func state(_ i: Int, _ correct: Int) -> ChoiceButton.Status {
        guard let selection else { return .idle }
        if i == correct { return .correct }
        if i == selection { return .wrong }
        return .dimmed
    }

    private func advance() {
        if index + 1 < round.questions.count {
            index += 1
            selection = nil
        } else {
            outcome = model.finishKanaRound(results)
        }
    }

    private func summary(_ outcome: ReviewOutcome) -> some View {
        let right = results.filter(\.correct).count
        return VStack(spacing: 20) {
            Spacer()
            KameView(stage: model.progress.stage, size: 120)
            Text(right == results.count ? "Alle richtig! すごい!" : "\(right) von \(results.count) richtig")
                .font(.title2.bold())
            Text("+\(outcome.xpGained) XP")
                .font(.title3)
                .foregroundStyle(Theme.sun)
            if !results.filter({ !$0.correct }).isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nochmal anschauen:").font(.subheadline.bold())
                    ForEach(results.filter { !$0.correct }, id: \.kana.id) { r in
                        Text("\(r.kana.character) = \(r.kana.romaji)")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
            }
            Spacer()
            Button("Fertig") { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
        }
        .padding()
    }
}
#endif
