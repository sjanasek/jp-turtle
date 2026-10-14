#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Eine Lernsitzung: Multiple Choice mit Combo-Multiplikator, Tipp-Knopf
/// und Selbsteinschätzung (Gut/Leicht). Hana kommentiert.
struct ReviewView: View {
    let words: [VocabWord]

    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var question: QuizQuestion?
    @State private var selection: Int?
    @State private var usedHint = false
    @State private var combo = 0
    @State private var bestCombo = 0
    @State private var sessionXP = 0
    @State private var correct = 0
    @State private var finished = false
    @State private var hanaMood: HanaMood = .cheer
    @State private var hanaLine = ""

    /// x1 bis 3 Richtige, x1.5 ab 3, x2 ab 6 in Folge.
    private var multiplier: Double { combo >= 6 ? 2 : (combo >= 3 ? 1.5 : 1) }

    var body: some View {
        NavigationStack {
            Group {
                if finished {
                    summary
                } else if let q = question {
                    quiz(q)
                } else {
                    ProgressView()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Beenden") { dismiss() }
                }
                ToolbarItem(placement: .principal) {
                    ProgressView(value: Double(index), total: Double(max(1, words.count)))
                        .frame(width: 120)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if combo >= 3 {
                        Text("x\(multiplier == 2 ? "2" : "1.5") 🔥")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(Theme.sun.opacity(0.25), in: Capsule())
                    }
                }
            }
        }
        .onAppear {
            hanaLine = words.count <= 3 ? "Nur drei Karten. Das schaffen wir in einer Minute." : HanaLines.line(for: .cheer)
            loadQuestion()
        }
        .sensoryFeedback(.success, trigger: correct)
        .interactiveDismissDisabled(!finished)
    }

    // MARK: Frage

    private func loadQuestion() {
        guard index < words.count else {
            finished = true
            return
        }
        let word = words[index]
        let mode: QuizQuestion.Mode = (index % 3 == 2) ? .meaningToWord : .wordToMeaning
        question = QuizFactory.question(for: word, mode: mode)
        selection = nil
        usedHint = false
    }

    private func quiz(_ q: QuizQuestion) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                HanaBubble(mood: hanaMood, friendship: model.progress.friendship, text: hanaLine, compact: true)
                promptCard(q)
                VStack(spacing: 10) {
                    ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                        ChoiceButton(text: q.label(for: choice), state: state(for: i, in: q)) {
                            select(i, in: q)
                        }
                    }
                }
                if let selection {
                    feedback(selection: selection, q: q)
                } else {
                    Button {
                        usedHint = true
                        hanaMood = .think
                        hanaLine = HanaLines.line(for: .think)
                    } label: {
                        Label(usedHint ? "Tipp aktiv (halbe XP)" : "Tipp von Hana", systemImage: "lightbulb")
                            .font(.footnote)
                    }
                    .disabled(usedHint)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
    }

    private func promptCard(_ q: QuizQuestion) -> some View {
        let isNew = model.card(for: q.word)?.isNew != false
        return VStack(spacing: 8) {
            Text(q.mode == .wordToMeaning ? "Was bedeutet …" : "Wie heißt auf Japanisch …")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(q.prompt)
                .font(.system(size: q.mode == .wordToMeaning ? 52 : 32, weight: .bold))
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
            if q.mode == .wordToMeaning, selection != nil || isNew || usedHint {
                VStack(spacing: 2) {
                    if q.word.hasSeparateReading { Text(q.word.kana).font(.title3) }
                    Text(q.word.romaji).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            if q.mode == .meaningToWord, usedHint, selection == nil {
                Text("Beginnt mit „\(q.word.romaji.prefix(2))…“")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if isNew {
                Label("Neues Wort", systemImage: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(Theme.sun)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 24))
    }

    private func state(for i: Int, in q: QuizQuestion) -> ChoiceButton.Status {
        guard let selection else { return .idle }
        if i == q.correctIndex { return .correct }
        if i == selection { return .wrong }
        return .dimmed
    }

    private func select(_ i: Int, in q: QuizQuestion) {
        guard selection == nil else { return }
        selection = i
        if q.isCorrect(i) {
            correct += 1
            combo += 1
            bestCombo = max(bestCombo, combo)
            hanaMood = combo >= 3 ? .proud : .happy
            hanaLine = combo >= 3 ? "Combo x\(multiplier == 2 ? "2" : "1.5")! \(HanaLines.line(for: .happy))" : HanaLines.line(for: .happy)
        } else {
            combo = 0
            hanaMood = .comfort
            hanaLine = HanaLines.line(for: .comfort)
        }
    }

    private func feedback(selection: Int, q: QuizQuestion) -> some View {
        let isCorrect = q.isCorrect(selection)
        return VStack(spacing: 12) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? Theme.accent : Theme.danger)
                Text(isCorrect
                     ? "Richtig! \(q.word.display) = \(q.word.meaning)"
                     : "\(q.word.display) (\(q.word.romaji)) = \(q.word.meaning)")
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
            }
            if isCorrect {
                HStack(spacing: 10) {
                    gradeButton("Gut", grade: .good, tint: Theme.accent)
                    gradeButton("Leicht", grade: .easy, tint: Theme.sun)
                }
            } else {
                gradeButton("Weiter", grade: .again, tint: Theme.danger)
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func gradeButton(_ title: String, grade: Grade, tint: Color) -> some View {
        Button {
            commit(grade)
        } label: {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(tint, in: RoundedRectangle(cornerRadius: 14))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private func commit(_ grade: Grade) {
        guard let q = question else { return }
        let outcome = model.answer(q.word, grade: grade, comboMultiplier: multiplier, usedHint: usedHint)
        sessionXP += outcome.xpGained
        if outcome.newStage != nil || !outcome.achievements.isEmpty {
            hanaMood = .surprised
            hanaLine = HanaLines.line(for: .surprised)
        }
        withAnimation {
            index += 1
            loadQuestion()
        }
    }

    // MARK: Zusammenfassung

    private var summary: some View {
        VStack(spacing: 20) {
            Spacer()
            HStack(spacing: -20) {
                HanaView(mood: correct == words.count ? .proud : .happy, friendship: model.progress.friendship, size: 120)
                KameView(stage: model.progress.stage, size: 90)
            }
            Text(correct == words.count ? "Perfekt! かんぺき!" : (correct >= words.count / 2 ? "Gut gemacht! よくできました" : "Dranbleiben! がんばって"))
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                StatPill(symbol: "star.fill", value: "+\(sessionXP)", label: "XP", tint: Theme.sun)
                StatPill(symbol: "checkmark", value: "\(correct)/\(words.count)", label: "richtig")
                StatPill(symbol: "bolt.fill", value: "\(bestCombo)", label: "beste Combo", tint: Theme.sun)
            }
            if model.chestAvailable {
                Label("Tageskiste freigeschaltet – auf der Startseite öffnen!", systemImage: "shippingbox.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.sun)
            }
            Spacer()
            Button {
                model.refreshWidgets()
                dismiss()
            } label: {
                Text("Fertig")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}
#endif
