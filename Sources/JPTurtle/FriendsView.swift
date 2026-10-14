#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Hana & Kame: Freundschaft, Kames Entwicklung, Sticker-Album,
/// Achievements, Panzer-Sammlung und Statistik.
struct FriendsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    hanaCard
                    kameCard
                    stickerAlbum
                    achievements
                    shellCollection
                    stats
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Hana & Kame")
        }
    }

    // MARK: Hana

    private var hanaCard: some View {
        let f = model.progress.friendship
        return VStack(spacing: 12) {
            HanaView(mood: .happy, friendship: f, size: 150)
            Text("Hana Kamei").font(.title.bold())
            Text("亀井 花 · Tutorin aus Kyoto · liebt Taiyaki")
                .font(.footnote)
                .foregroundStyle(.secondary)
            VStack(spacing: 6) {
                HStack {
                    Label(f.title, systemImage: "heart.fill").font(.headline).foregroundStyle(Theme.sakura)
                    Spacer()
                    Text("\(model.progress.hearts) Herzen").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                }
                if let next = f.next {
                    ProgressView(value: Double(model.progress.hearts - f.minHearts), total: Double(next.minHearts - f.minHearts))
                        .tint(Theme.sakura)
                    Text("Noch \(next.minHearts - model.progress.hearts) Herzen bis „\(next.title)“ – schaltet frei: \(next.unlock)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Höchste Freundschaftsstufe. Hana trägt den Kyoto-Kimono.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text("Herzen gibt es für die erste Lernaktion des Tages, für Kana-Runden, perfekt geschriebene Zeichen und aus der Tageskiste. Nach einer Pause gibt es extra Herzen – Hana freut sich, wenn du zurückkommst.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: Kame

    private var kameCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                KameView(stage: model.progress.stage, size: 110)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Kame · \(model.progress.stage.title)").font(.headline)
                    Text(model.progress.stage.japanese).foregroundStyle(.secondary)
                    Text(model.progress.stage.flavor).font(.footnote).foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            XPBar(progress: model.progress)
            VStack(spacing: 8) {
                ForEach(TurtleStage.allCases, id: \.self) { stage in
                    HStack(spacing: 12) {
                        KameView(stage: stage, size: 30, animated: false)
                            .opacity(stage <= model.progress.stage ? 1 : 0.35)
                        Text(stage.title).font(.subheadline)
                        Spacer()
                        Text("ab \(stage.minXP) XP").font(.caption).foregroundStyle(.secondary)
                        Image(systemName: stage <= model.progress.stage ? "checkmark.circle.fill" : "lock.fill")
                            .foregroundStyle(stage <= model.progress.stage ? Theme.accent : .secondary)
                    }
                }
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Sticker

    private var stickerAlbum: some View {
        let owned = Set(model.progress.stickers)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Sticker-Album").font(.headline)
                Spacer()
                Text("\(owned.count)/\(Sticker.all.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            Text("Sticker kommen aus der Tageskiste. Die gibt es jeden Tag, an dem du dein Tagesziel schaffst.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Sticker.all) { s in
                    let have = owned.contains(s.id)
                    VStack(spacing: 4) {
                        Image(systemName: have ? s.symbol : "questionmark")
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .foregroundStyle(have ? stickerTint(s) : .secondary)
                            .background(
                                have ? stickerTint(s).opacity(0.15) : Color(.tertiarySystemGroupedBackground),
                                in: RoundedRectangle(cornerRadius: 12)
                            )
                        Text(have ? s.title : "???")
                            .font(.caption2)
                            .lineLimit(1)
                            .foregroundStyle(have ? .primary : .secondary)
                    }
                }
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func stickerTint(_ s: Sticker) -> Color {
        switch s.rarity {
        case .common: return Theme.shell
        case .rare: return Theme.accent
        case .epic: return .purple
        }
    }

    // MARK: Achievements

    private var achievements: some View {
        let done = Set(model.progress.achievements)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Achievements").font(.headline)
                Spacer()
                Text("\(done.count)/\(Achievement.all.count)").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            ForEach(Achievement.all) { a in
                let have = done.contains(a.id)
                HStack(spacing: 12) {
                    Image(systemName: a.symbol)
                        .frame(width: 28)
                        .foregroundStyle(have ? Theme.sun : .secondary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.title).font(.subheadline.bold()).foregroundStyle(have ? .primary : .secondary)
                        Text(a.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("+\(a.rewardXP)").font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                }
                .opacity(have ? 1 : 0.7)
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Panzer

    private var shellCollection: some View {
        let mastered = model.engine.masteredCounts()
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)
        return VStack(alignment: .leading, spacing: 10) {
            Text("Kames Panzer-Sammlung").font(.headline)
            Text("Meistere 5 Wörter einer Kategorie, um das Panzermuster freizuschalten.")
                .font(.caption)
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(WordCategory.allCases, id: \.self) { cat in
                    let have = mastered[cat] ?? 0
                    let total = Vocabulary.words(in: cat).count
                    let unlocked = have >= min(5, total)
                    HStack(spacing: 10) {
                        Image(systemName: cat.symbol)
                            .frame(width: 28)
                            .foregroundStyle(unlocked ? Theme.accent : .secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cat.title).font(.caption.bold())
                            Text("\(have)/\(total)").font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(10)
                    .background(
                        unlocked ? Theme.accent.opacity(0.15) : Color(.tertiarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    // MARK: Statistik

    private var stats: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Statistik").font(.headline)
            statRow("Wörter gelernt", "\(model.learnedCount) / \(Vocabulary.all.count)")
            statRow("Wörter gemeistert", "\(model.masteredCount)")
            statRow("Antworten gesamt", "\(model.progress.totalReviews)")
            statRow("Trefferquote", String(format: "%.0f %%", model.progress.accuracy * 100))
            statRow("Zeichen geschrieben", "\(model.progress.totalWritings) (Bestnote: \(model.progress.perfectWritings))")
            statRow("Beste Serie", "\(model.progress.bestStreak) Tage")
            statRow("Hiragana gemeistert", "\(model.progress.kanaMastered(.hiragana)) / \(KanaTable.basicCount(.hiragana))")
            statRow("Katakana gemeistert", "\(model.progress.kanaMastered(.katakana)) / \(KanaTable.basicCount(.katakana))")
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
        .font(.subheadline)
    }
}
#endif
