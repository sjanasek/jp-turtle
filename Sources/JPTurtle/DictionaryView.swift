#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Alle eingebauten Wörter mit Lernstatus.
struct DictionaryView: View {
    @EnvironmentObject private var model: AppModel
    @State private var query = ""
    @State private var category: WordCategory?

    private var filtered: [VocabWord] {
        Vocabulary.all.filter { w in
            (category == nil || w.category == category) &&
            (query.isEmpty || w.display.localizedCaseInsensitiveContains(query)
             || w.kana.localizedCaseInsensitiveContains(query)
             || w.romaji.localizedCaseInsensitiveContains(query)
             || w.meaning.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        List {
            ForEach(filtered) { word in
                WordRow(word: word, card: model.card(for: word))
            }
        }
        .searchable(text: $query, prompt: "Wort, Kana, Romaji oder Deutsch")
        .navigationTitle("Wörter")
        .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Alle Kategorien") { category = nil }
                        ForEach(WordCategory.allCases, id: \.self) { cat in
                            Button {
                                category = cat
                            } label: {
                                Label(cat.title, systemImage: cat.symbol)
                            }
                        }
                    } label: {
                        Label(category?.title ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
    }
}

struct WordRow: View {
    let word: VocabWord
    let card: CardState?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(word.display).font(.title3.bold())
                    if word.hasSeparateReading {
                        Text(word.kana).font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                Text("\(word.romaji) · \(word.meaning)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            statusBadge
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var statusBadge: some View {
        if let card, !card.isNew {
            if card.isMastered {
                Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.sakura)
            } else if card.isDue(at: Date()) {
                Image(systemName: "clock.badge.exclamationmark").foregroundStyle(Theme.sun)
            } else {
                Text("\(Int(card.intervalDays))d")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        } else {
            Image(systemName: "circle.dotted").foregroundStyle(.secondary)
        }
    }
}
#endif
