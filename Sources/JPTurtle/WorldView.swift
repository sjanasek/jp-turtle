#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Banner eines offenen Gebiets.
struct RegionCard: View {
    let region: WorldRegion
    let cards: [String: CardState]
    let writingBest: [String: Int]

    var body: some View {
        let style = RegionStyle.of(region.id)
        let done = World.unlockedCount(in: region, cards: cards)
        let complete = done == region.items.count
        ZStack(alignment: .leading) {
            style.gradient
            Text(region.japanese)
                .font(.system(size: 96, weight: .black))
                .foregroundStyle(.white.opacity(0.18))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: region.symbol)
                    Text(region.title).font(.title3.bold())
                    if complete { Image(systemName: "checkmark.seal.fill") }
                }
                Text(region.tagline)
                    .font(.caption)
                    .opacity(0.92)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    ProgressView(value: Double(done), total: Double(max(1, region.items.count)))
                        .tint(.white)
                    Text("\(done)/\(region.items.count)")
                        .font(.caption.monospacedDigit().bold())
                }
            }
            .foregroundStyle(.white)
            .padding(14)
        }
        .frame(minHeight: 116)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

/// Ein Gebiet mit all seinen Items.
struct RegionView: View {
    let region: WorldRegion

    @EnvironmentObject private var model: AppModel
    @State private var session: ReviewSession?
    @State private var detail: WorldItem?

    var body: some View {
        let style = RegionStyle.of(region.id)
        ScrollView {
            VStack(spacing: 14) {
                RegionCard(region: region, cards: model.cards, writingBest: model.progress.writingBest)

                Button {
                    session = ReviewSession(words: model.makeRegionSession(region))
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(World.isComplete(region, cards: model.cards) ? "Auffrischen" : "Hier lernen (5 Wörter)")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(style.accent, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                    ForEach(region.items) { item in
                        Button {
                            detail = item
                        } label: {
                            ItemTile(
                                item: item,
                                count: World.progress(item.word, cards: model.cards),
                                stamped: World.isStamped(item.word, writingBest: model.progress.writingBest),
                                style: style
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(region.title) \(region.japanese)")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $session) { s in
            ReviewView(words: s.words)
        }
        .sheet(item: $detail) { item in
            ItemDetailView(item: item, style: style)
                .presentationDetents([.medium])
        }
    }
}

/// Kachel eines Items: freigeschaltet mit Bild und Wort, sonst mit Fortschrittspunkten.
struct ItemTile: View {
    let item: WorldItem
    let count: Int
    let stamped: Bool
    let style: RegionStyle

    var body: some View {
        let unlocked = count >= World.unlockThreshold
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(unlocked ? AnyShapeStyle(style.gradient) : AnyShapeStyle(Color(.tertiarySystemGroupedBackground)))
                    .frame(height: 64)
                Image(systemName: unlocked ? item.symbol : "questionmark")
                    .font(.title)
                    .foregroundStyle(unlocked ? Color.white : Color.secondary)
                    .frame(maxWidth: .infinity, minHeight: 64)
                if stamped {
                    Text("筆")
                        .font(.caption2.bold())
                        .padding(4)
                        .background(Theme.danger, in: Circle())
                        .foregroundStyle(.white)
                        .padding(4)
                        .accessibilityLabel("Mit Tusche-Stempel")
                }
            }
            Text(unlocked ? item.word.display : "???")
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if unlocked {
                Text(item.word.meaning)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                HStack(spacing: 3) {
                    ForEach(0..<World.unlockThreshold, id: \.self) { i in
                        Circle()
                            .fill(i < count ? style.accent : Color.secondary.opacity(0.25))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 18))
    }
}

/// Detailblatt eines Items mit Aussprache und Hinweis zum Freischalten.
struct ItemDetailView: View {
    let item: WorldItem
    let style: RegionStyle

    @EnvironmentObject private var model: AppModel

    var body: some View {
        let count = World.progress(item.word, cards: model.cards)
        let unlocked = count >= World.unlockThreshold
        let stamped = World.isStamped(item.word, writingBest: model.progress.writingBest)
        VStack(spacing: 14) {
            Image(systemName: unlocked ? item.symbol : "questionmark")
                .font(.system(size: 44))
                .foregroundStyle(.white)
                .frame(width: 92, height: 92)
                .background(unlocked ? AnyShapeStyle(style.gradient) : AnyShapeStyle(Color.secondary.opacity(0.4)), in: RoundedRectangle(cornerRadius: 24))
            Text(item.word.display).font(.system(size: 44, weight: .bold))
            VStack(spacing: 2) {
                if item.word.hasSeparateReading { Text(item.word.kana).font(.title3) }
                Text(item.word.romaji).foregroundStyle(.secondary)
                Text(item.word.meaning).font(.headline)
            }
            SpeakButton(text: SpokenText.text(for: item.word))
            if unlocked {
                Label(stamped ? "In Kames Welt, mit Tusche-Stempel" : "In Kames Welt eingezogen", systemImage: "checkmark.seal.fill")
                    .font(.subheadline)
                    .foregroundStyle(Theme.accent)
            } else {
                Text("\(count) von \(World.unlockThreshold) richtigen Antworten. Noch \(World.unlockThreshold - count), dann zieht das Wort ein.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if item.word.kanji != nil, !stamped {
                Text("Tipp: Schreib das Kanji im Schreib-Dojo. Gutes Schreiben zählt doppelt und bringt den Tusche-Stempel.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
#endif
