#if os(iOS)
import SwiftUI
import JPTurtleCore

enum Theme {
    static let accent = Color(red: 0.13, green: 0.55, blue: 0.45)      // Teich-Grün
    static let shell = Color(red: 0.35, green: 0.56, blue: 0.30)
    static let shellDark = Color(red: 0.18, green: 0.36, blue: 0.20)
    static let sand = Color(red: 0.98, green: 0.93, blue: 0.80)
    static let sun = Color(red: 0.98, green: 0.69, blue: 0.25)
    static let sakura = Color(red: 0.98, green: 0.62, blue: 0.72)
    static let danger = Color(red: 0.86, green: 0.30, blue: 0.30)

    static let cardBackground = Color(.secondarySystemGroupedBackground)

    static func stageGradient(_ stage: TurtleStage) -> LinearGradient {
        let colors: [Color]
        switch stage {
        case .egg: colors = [sand, Color.white]
        case .hatchling: colors = [Color.mint, shell]
        case .juvenile: colors = [shell, Theme.accent]
        case .wanderer: colors = [Theme.accent, Color.teal]
        case .elder: colors = [Color.indigo, shellDark]
        case .sensei: colors = [sun, sakura]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

/// Kame, das Maskottchen. Wächst mit der Stufe und wippt leicht.
struct KameView: View {
    let stage: TurtleStage
    var size: CGFloat = 120
    var animated = true

    @State private var bob = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.stageGradient(stage))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 6)

            if stage == .egg {
                Ellipse()
                    .fill(Color.white)
                    .frame(width: size * 0.5, height: size * 0.66)
                    .overlay(
                        Path { p in
                            p.move(to: CGPoint(x: size * 0.15, y: size * 0.3))
                            p.addLine(to: CGPoint(x: size * 0.25, y: size * 0.36))
                            p.addLine(to: CGPoint(x: size * 0.2, y: size * 0.44))
                            p.addLine(to: CGPoint(x: size * 0.32, y: size * 0.5))
                        }
                        .stroke(Theme.shellDark.opacity(0.5), lineWidth: 2)
                    )
                    .shadow(radius: 2)
            } else {
                Image(systemName: "tortoise.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * scale, height: size * scale)
                    .foregroundStyle(
                        stage >= .elder ? Color.white : Theme.shellDark
                    )
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
            }

            if stage >= .wanderer {
                Image(systemName: stage == .sensei ? "graduationcap.fill" : "leaf.fill")
                    .font(.system(size: size * 0.2))
                    .foregroundStyle(stage == .sensei ? Theme.sun : Theme.sakura)
                    .offset(x: size * 0.28, y: -size * 0.3)
            }
        }
        .frame(width: size, height: size)
        .offset(y: bob ? -4 : 4)
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                bob = true
            }
        }
        .accessibilityLabel("Kame, Stufe \(stage.title)")
    }

    private var scale: CGFloat {
        switch stage {
        case .egg: return 0.3
        case .hatchling: return 0.42
        case .juvenile: return 0.5
        case .wanderer: return 0.56
        case .elder: return 0.6
        case .sensei: return 0.64
        }
    }
}

struct XPBar: View {
    let progress: Progress

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(progress.stage.title)
                    .font(.headline)
                Text(progress.stage.japanese)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(progress.xp) XP")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(Theme.stageGradient(progress.stage))
                        .frame(width: max(8, geo.size.width * progress.stageProgress))
                }
            }
            .frame(height: 10)
            if let next = progress.stage.next {
                Text("Noch \(next.minXP - progress.xp) XP bis \(next.title)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Höchste Stufe erreicht")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .animation(.easeOut(duration: 0.5), value: progress.xp)
    }
}

struct StatPill: View {
    let symbol: String
    let value: String
    let label: String
    var tint: Color = Theme.accent

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.bold().monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 14))
    }
}

struct ToastView: View {
    let toast: Toast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: toast.symbol)
                .font(.title2)
                .foregroundStyle(Theme.sun)
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title).font(.subheadline.bold())
                if let s = toast.subtitle {
                    Text(s).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 8, y: 4)
        .padding(.horizontal)
    }
}

/// Antwort-Button fürs Quiz mit Richtig/Falsch-Färbung.
struct ChoiceButton: View {
    enum Status: Equatable { case idle, correct, wrong, dimmed }

    let text: String
    let state: Status
    var caption: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.leading)
                    if let caption {
                        Text(caption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if state == .correct { Image(systemName: "checkmark.circle.fill") }
                if state == .wrong { Image(systemName: "xmark.circle.fill") }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(border, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .foregroundStyle(state == .dimmed ? .secondary : .primary)
        .disabled(state != .idle)
        .animation(.easeOut(duration: 0.2), value: state)
    }

    private var background: Color {
        switch state {
        case .idle, .dimmed: return Color(.secondarySystemGroupedBackground)
        case .correct: return Theme.accent.opacity(0.18)
        case .wrong: return Theme.danger.opacity(0.18)
        }
    }

    private var border: Color {
        switch state {
        case .idle, .dimmed: return Color.secondary.opacity(0.2)
        case .correct: return Theme.accent
        case .wrong: return Theme.danger
        }
    }
}
/// Lautsprecher-Knopf: spricht den Text mit der japanischen Systemstimme.
struct SpeakButton: View {
    let text: String
    var size: CGFloat = 44

    var body: some View {
        Button {
            SpeechService.shared.speak(text)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.system(size: size * 0.45))
                .foregroundStyle(Theme.accent)
                .frame(width: size, height: size)
                .background(Theme.accent.opacity(0.12), in: Circle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Aussprache anhören")
    }
}

#endif
