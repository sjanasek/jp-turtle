#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Schreib-Dojo: Zeichen mit dem Finger (oder Apple Pencil) schreiben.
/// Modus "Nachspuren" zeigt die Vorlage grau im Hintergrund, Modus "Aus dem
/// Kopf" nur die Lesung. Bewertet wird gegen die Vorlage im Systemfont.
struct WritingDojoView: View {
    enum Script: String, CaseIterable, Identifiable {
        case hiragana, katakana, kanji
        var id: String { rawValue }
        var title: String {
            switch self {
            case .hiragana: return "Hiragana"
            case .katakana: return "Katakana"
            case .kanji: return "Kanji"
            }
        }
    }

    @EnvironmentObject private var model: AppModel
    @State private var script: Script = .hiragana
    @State private var traced = true
    @State private var session: WritingSession?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HanaBubble(
                        mood: .cheer,
                        friendship: model.progress.friendship,
                        text: "Schreiben ist der schnellste Weg, Zeichen wirklich zu behalten. Erst nachspuren, dann aus dem Kopf – ich sag dir, wie gut es aussieht.",
                        compact: true
                    )

                    Picker("Zeichensatz", selection: $script) {
                        ForEach(Script.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Picker("Modus", selection: $traced) {
                        Text("Nachspuren").tag(true)
                        Text("Aus dem Kopf (+5 XP)").tag(false)
                    }
                    .pickerStyle(.segmented)

                    progressCard

                    Button {
                        session = WritingSession(targets: targets(count: 8))
                    } label: {
                        Label("Runde starten (8 Zeichen)", systemImage: "pencil.and.scribble")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 18))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .disabled(availableTargets.isEmpty)

                    if script == .kanji && availableTargets.isEmpty {
                        Text("Lerne zuerst ein paar Wörter mit Kanji – dann tauchen sie hier auf.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    bestScores
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Schreib-Dojo")
            .fullScreenCover(item: $session) { s in
                WritingSessionView(session: s, traced: traced)
            }
        }
    }

    /// Kanji nur aus bereits gelernten Wörtern, damit es nicht überfordert.
    private var availableTargets: [WritingTarget] {
        switch script {
        case .hiragana: return KanaTable.all(.hiragana, includeVoiced: false).map(WritingTarget.kana)
        case .katakana: return KanaTable.all(.katakana, includeVoiced: false).map(WritingTarget.kana)
        case .kanji:
            let learned = Vocabulary.all.filter { model.card(for: $0)?.isNew == false }
            let pool = learned.isEmpty ? Array(Vocabulary.all.prefix(30)) : learned
            return WritingTarget.allKanjiTargets(from: pool)
        }
    }

    /// Schwächste Zeichen zuerst, mit Zufall.
    private func targets(count: Int) -> [WritingTarget] {
        let best = model.progress.writingBest
        let ranked = availableTargets.shuffled().sorted { (best[$0.id] ?? -1) < (best[$1.id] ?? -1) }
        return Array(ranked.prefix(count)).shuffled()
    }

    private var progressCard: some View {
        let all = availableTargets
        let best = model.progress.writingBest
        let done = all.filter { (best[$0.id] ?? 0) >= 65 }.count
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(script.title) sauber geschrieben").font(.headline)
                Spacer()
                Text("\(done)/\(all.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(done), total: Double(max(1, all.count))).tint(Theme.accent)
            Text("Zählt ab Note „Gut“ (65 Punkte). Heute geschrieben: \(model.progress.writingsToday) · Bestnoten gesamt: \(model.progress.perfectWritings)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private var bestScores: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(availableTargets) { t in
                let score = model.progress.writingBest[t.id]
                VStack(spacing: 0) {
                    Text(t.character).font(.title3)
                    Text(score.map(String.init) ?? "–").font(.caption2).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(color(for: score), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func color(for score: Int?) -> Color {
        guard let score else { return Color(.secondarySystemGroupedBackground) }
        if score >= 85 { return Theme.sakura.opacity(0.4) }
        if score >= 65 { return Theme.accent.opacity(0.3) }
        return Theme.sun.opacity(0.25)
    }
}

struct WritingSession: Identifiable {
    let id = UUID()
    let targets: [WritingTarget]
}

struct WritingSessionView: View {
    let session: WritingSession
    let traced: Bool

    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var index = 0
    @State private var strokes: [[CGPoint]] = []
    @State private var current: [CGPoint] = []
    @State private var score: InkScore?
    @State private var showTemplate = false
    @State private var sessionXP = 0
    @State private var perfects = 0
    @State private var hanaLine = ""
    @State private var hanaMood: HanaMood = .cheer
    @State private var finished = false

    private var target: WritingTarget { session.targets[index] }

    var body: some View {
        NavigationStack {
            Group {
                if finished { summary } else { practice }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Beenden") { dismiss() } }
                ToolbarItem(placement: .principal) {
                    Text("\(index + 1)/\(session.targets.count)").font(.subheadline.monospacedDigit())
                }
            }
        }
        .onAppear {
            hanaLine = traced ? "Fahr die graue Vorlage nach – langsam, Strich für Strich." : "Schreib \(target.reading) aus dem Kopf. Danach zeige ich dir die Vorlage."
        }
        .sensoryFeedback(.success, trigger: perfects)
    }

    // MARK: Übung

    private var practice: some View {
        VStack(spacing: 14) {
            HanaBubble(mood: hanaMood, friendship: model.progress.friendship, text: hanaLine, compact: true)

            VStack(spacing: 2) {
                HStack(spacing: 8) {
                    Text(target.reading).font(.title2.bold())
                    if let s = target.strokes {
                        Text("· \(s) Strich\(s == 1 ? "" : "e")").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                if let m = target.meaning {
                    Text(m).font(.footnote).foregroundStyle(.secondary)
                }
                if !traced, score == nil {
                    Text("Zeichen: ?").font(.caption).foregroundStyle(.secondary)
                }
            }

            canvas

            HStack {
                Button {
                    if !strokes.isEmpty { strokes.removeLast() }
                } label: { Label("Strich zurück", systemImage: "arrow.uturn.backward") }
                .disabled(strokes.isEmpty || score != nil)

                Spacer()
                Text("\(strokes.count) Strich\(strokes.count == 1 ? "" : "e")")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()

                Button {
                    strokes = []
                    score = nil
                    showTemplate = traced
                } label: { Label("Löschen", systemImage: "trash") }
                .disabled(strokes.isEmpty)
            }
            .font(.subheadline)
            .padding(.horizontal, 4)

            if let score {
                scoreCard(score)
            } else {
                Button {
                    evaluate()
                } label: {
                    Text("Bewerten")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(strokes.isEmpty ? Color.secondary : Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .disabled(strokes.isEmpty)
            }
        }
        .padding()
        .onAppear { showTemplate = traced }
    }

    private var canvas: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemGroupedBackground))
                // Hilfslinien wie auf Genkō-yōshi-Papier
                Path { p in
                    p.move(to: CGPoint(x: side / 2, y: 0)); p.addLine(to: CGPoint(x: side / 2, y: side))
                    p.move(to: CGPoint(x: 0, y: side / 2)); p.addLine(to: CGPoint(x: side, y: side / 2))
                }
                .stroke(Color.secondary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [6, 6]))

                if showTemplate || score != nil {
                    Text(target.character)
                        .font(.system(size: side * 0.78))
                        .foregroundStyle(score == nil ? Color.secondary.opacity(0.25) : Theme.accent.opacity(0.3))
                        .frame(width: side, height: side)
                }

                Canvas { ctx, _ in
                    for stroke in strokes + [current] where stroke.count > 1 {
                        var p = Path()
                        p.move(to: CGPoint(x: stroke[0].x * side, y: stroke[0].y * side))
                        for pt in stroke.dropFirst() { p.addLine(to: CGPoint(x: pt.x * side, y: pt.y * side)) }
                        ctx.stroke(p, with: .color(Color.primary), style: StrokeStyle(lineWidth: side * 0.05, lineCap: .round, lineJoin: .round))
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { v in
                            guard score == nil else { return }
                            let pt = CGPoint(x: min(1, max(0, v.location.x / side)), y: min(1, max(0, v.location.y / side)))
                            current.append(pt)
                        }
                        .onEnded { _ in
                            guard score == nil else { return }
                            if current.count == 1 { current.append(current[0]) }
                            if !current.isEmpty { strokes.append(current) }
                            current = []
                        }
                )
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func evaluate() {
        guard let templateMask = Rasterizer.templateMask(for: target.character),
              let ink = Rasterizer.inkMask(strokes: strokes) else { return }
        let s = InkScorer.score(template: templateMask, user: ink, strokesDrawn: strokes.count, expectedStrokes: target.strokes)
        score = s
        showTemplate = true
        let outcome = model.recordWriting(target: target, score: s, traced: traced)
        sessionXP += outcome.xpGained
        if s.isPerfect { perfects += 1 }

        switch s.verdict {
        case .perfect:
            hanaMood = .proud
            hanaLine = HanaLines.line(for: .happy)
        case .good:
            hanaMood = .happy
            hanaLine = "Gut! \(hint(for: s))"
        case .okay:
            hanaMood = .think
            hanaLine = "Fast. \(hint(for: s))"
        case .practice:
            hanaMood = .comfort
            hanaLine = "\(HanaLines.line(for: .comfort)) \(hint(for: s))"
        }
    }

    private func hint(for s: InkScore) -> String {
        if s.strokeDelta > 0, let e = target.strokes {
            return "Das Zeichen hat \(e) Striche, du hattest \(strokes.count)."
        }
        if s.coverage < 0.6 { return "Ein Teil des Zeichens fehlt noch." }
        if s.precision < 0.6 { return "Die Linien wandern aus der Form – etwas enger." }
        if s.placement < 0.6 { return "Größe oder Position passen noch nicht ganz zur Vorlage." }
        return "Nur noch die Feinheiten."
    }

    private func scoreCard(_ s: InkScore) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text(s.verdict.title).font(.title3.bold())
                Spacer()
                Text("\(s.total) / 100").font(.title3.monospacedDigit())
            }
            HStack(spacing: 8) {
                metric("Form", s.coverage)
                metric("Präzision", s.precision)
                metric("Lage", s.placement)
            }
            Button {
                next()
            } label: {
                Text(index + 1 < session.targets.count ? "Nächstes Zeichen" : "Fertig")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }

    private func metric(_ label: String, _ v: Double) -> some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            ProgressView(value: v).tint(v >= 0.7 ? Theme.accent : Theme.sun)
        }
    }

    private func next() {
        if index + 1 < session.targets.count {
            index += 1
            strokes = []
            current = []
            score = nil
            showTemplate = traced
            hanaMood = .cheer
            hanaLine = traced ? "Weiter: \(target.reading). Du schaffst das." : "Jetzt \(target.reading) – wie sah das nochmal aus?"
        } else {
            finished = true
        }
    }

    private var summary: some View {
        VStack(spacing: 20) {
            Spacer()
            HanaView(mood: perfects >= 4 ? .proud : .happy, friendship: model.progress.friendship, size: 140)
            Text(perfects >= 4 ? "Pinselmeister-Niveau! 筆が上手!" : "Jeder Strich zählt. おつかれさま!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            HStack(spacing: 10) {
                StatPill(symbol: "star.fill", value: "+\(sessionXP)", label: "XP", tint: Theme.sun)
                StatPill(symbol: "paintbrush.pointed.fill", value: "\(perfects)", label: "Bestnoten", tint: Theme.sakura)
                StatPill(symbol: "pencil", value: "\(session.targets.count)", label: "geschrieben")
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
