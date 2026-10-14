#if os(iOS)
import SwiftUI
import JPTurtleCore

struct HomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var session: ReviewSession?
    @State private var chestReward: ChestRewardItem?
    @State private var chestShaking = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HanaBubble(mood: model.hanaMood, friendship: model.progress.friendship, text: model.hanaLine)
                    heroCard
                    statsRow
                    if model.progress.comebackBonusRemaining > 0 {
                        comebackBanner
                    }
                    learnButtons
                    if model.chestAvailable || model.progress.chestOpenedDay == Progress.dayKey(Date()) {
                        chestCard
                    }
                    questCard
                    widgetCard
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("JP Turtle")
            .fullScreenCover(item: $session) { s in
                ReviewView(words: s.words)
            }
            .sheet(item: $chestReward) { item in
                ChestRewardView(reward: item.reward)
                    .presentationDetents([.medium])
            }
            .onChange(of: model.requestedReview) { _, requested in
                guard requested else { return }
                model.requestedReview = false
                session = ReviewSession(words: model.makeSession())
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                KameView(stage: model.progress.stage, size: 84)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kame · \(model.progress.stage.title)")
                        .font(.headline)
                    Text(model.progress.stage.flavor)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            XPBar(progress: model.progress)
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatPill(
                symbol: model.streakAlive ? "flame.fill" : "flame",
                value: "\(model.progress.streak)",
                label: "Tage Serie",
                tint: model.streakAlive ? Theme.sun : .secondary
            )
            StatPill(symbol: "shield.fill", value: "\(model.progress.shields)", label: "Schilde", tint: .blue)
            StatPill(symbol: "tray.full", value: "\(model.dueCount)", label: "fällig")
            StatPill(symbol: "heart.fill", value: "\(model.progress.hearts)", label: "Herzen", tint: Theme.sakura)
        }
    }

    private var comebackBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.uturn.backward.circle.fill")
                .font(.title2)
                .foregroundStyle(Theme.sun)
            VStack(alignment: .leading, spacing: 2) {
                Text("Comeback-Bonus").font(.subheadline.bold())
                Text("Noch \(model.progress.comebackBonusRemaining) Antworten mit doppelten XP.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Theme.sun.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }

    private var learnButtons: some View {
        VStack(spacing: 10) {
            Button {
                session = ReviewSession(words: model.makeSession())
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lernen starten").font(.headline)
                        Text(sessionHint).font(.caption).opacity(0.85)
                    }
                    Spacer()
                    Image(systemName: "play.fill").font(.title2)
                }
                .padding()
                .foregroundStyle(.white)
                .background(
                    LinearGradient(colors: [Theme.accent, Theme.shellDark], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 18)
                )
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button {
                    session = ReviewSession(words: model.makeSession(size: 3))
                } label: {
                    Label("Nur 3 Karten", systemImage: "bolt.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.sun.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Theme.sun)
                }
                .buttonStyle(.plain)

                Button {
                    model.selectedTab = .writing
                } label: {
                    Label("Zeichen schreiben", systemImage: "pencil.and.scribble")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.sakura.opacity(0.2), in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Theme.sakura)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sessionHint: String {
        let due = model.dueCount
        let todayLeft = max(0, model.progress.dailyGoal - model.progress.reviewsToday - model.progress.writingsToday)
        if due > 0 { return "\(due) fällige Karten · Tagesziel noch \(todayLeft)" }
        if todayLeft > 0 { return "Neue Wörter entdecken · Tagesziel noch \(todayLeft)" }
        return "Tagesziel erreicht – Bonusrunde?"
    }

    private var chestCard: some View {
        let open = !model.chestAvailable
        return Button {
            guard !open else { return }
            withAnimation(.spring(duration: 0.3)) { chestShaking.toggle() }
            chestReward = model.openChest().map(ChestRewardItem.init)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: open ? "shippingbox" : "shippingbox.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(open ? Color.secondary : Theme.sun)
                    .rotationEffect(.degrees(chestShaking ? -8 : 0))
                VStack(alignment: .leading, spacing: 2) {
                    Text(open ? "Tageskiste geöffnet" : "Tageskiste bereit!").font(.headline)
                    Text(open ? "Morgen gibt es eine neue." : "Tagesziel geschafft – tippen zum Öffnen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !open { Image(systemName: "chevron.right").foregroundStyle(.secondary) }
            }
            .padding()
            .background(open ? Theme.cardBackground : Theme.sun.opacity(0.15), in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .disabled(open)
    }

    private var questCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tagesquests").font(.headline)
                Spacer()
                Text("\(model.progress.completedQuestsToday.count)/\(DailyQuest.all.count)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ForEach(DailyQuest.all) { quest in
                QuestRow(quest: quest, progress: model.progress)
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }

    private var widgetCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Vokabeln auf dem Sperrbildschirm", systemImage: "lock.iphone")
                .font(.headline)
            Text("Sperrbildschirm gedrückt halten → Anpassen → Widgets hinzufügen → „JP Turtle“. Das Wort-Widget zeigt alle paar Stunden eine neue Vokabel; auf dem Homescreen kannst du direkt im Widget antworten.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            if !model.store.isSharedWithWidget {
                Label("Ohne App Group zählt das Widget seine XP getrennt von der App (siehe „Mehr“).", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(Theme.sun)
            }
        }
        .padding()
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 20))
    }
}

struct QuestRow: View {
    let quest: DailyQuest
    let progress: Progress

    var body: some View {
        let done = progress.isQuestDone(quest)
        let value = min(quest.target, progress.questProgress(quest))
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : quest.symbol)
                .foregroundStyle(done ? Theme.accent : .secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(quest.title)
                    .font(.subheadline)
                    .strikethrough(done)
                    .foregroundStyle(done ? .secondary : .primary)
                ProgressView(value: Double(value), total: Double(quest.target))
                    .tint(done ? Theme.accent : Theme.sun)
            }
            Text("+\(quest.rewardXP)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

/// Belohnungs-Sheet nach dem Öffnen der Tageskiste.
struct ChestRewardView: View {
    let reward: ChestReward
    @Environment(\.dismiss) private var dismiss
    @State private var revealed = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Theme.sun.opacity(revealed ? 0.25 : 0.1))
                    .frame(width: 150, height: 150)
                    .scaleEffect(revealed ? 1.1 : 0.8)
                Image(systemName: symbol)
                    .font(.system(size: 64))
                    .foregroundStyle(tint)
                    .scaleEffect(revealed ? 1 : 0.3)
                    .opacity(revealed ? 1 : 0)
            }
            Text(revealed ? reward.title : "…")
                .font(.title2.bold())
            if case .sticker(let s) = reward {
                Text("\(s.rarity.title) · \(s.caption)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button("Super!") { dismiss() }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(.white)
                .buttonStyle(.plain)
        }
        .padding()
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.5).delay(0.3)) { revealed = true }
        }
        .sensoryFeedback(.success, trigger: revealed)
    }

    private var symbol: String {
        switch reward {
        case .xp: return "star.fill"
        case .shield: return "shield.fill"
        case .sticker(let s): return s.symbol
        case .hearts: return "heart.fill"
        }
    }

    private var tint: Color {
        switch reward {
        case .xp: return Theme.sun
        case .shield: return .blue
        case .sticker(let s): return s.rarity == .epic ? .purple : (s.rarity == .rare ? Theme.accent : Theme.shell)
        case .hearts: return Theme.sakura
        }
    }
}

struct ReviewSession: Identifiable {
    let id = UUID()
    let words: [VocabWord]
}

struct ChestRewardItem: Identifiable {
    let id = UUID()
    let reward: ChestReward
}
#endif
