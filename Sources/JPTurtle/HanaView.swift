#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Hana Kamei als Vektor-Avatar. Kein Bildmaterial nötig – alles aus Shapes,
/// damit der Charakter skaliert, animiert und je nach Freundschaftsstufe
/// eingekleidet werden kann.
struct HanaView: View {
    var mood: HanaMood = .happy
    var friendship: FriendshipLevel = .stranger
    var size: CGFloat = 120

    @State private var blink = false
    @State private var bounce = false

    private var hairColor: Color { Color(red: 0.24, green: 0.15, blue: 0.25) }
    private var skin: Color { Color(red: 1.0, green: 0.90, blue: 0.82) }
    private var blush: Color { Theme.sakura.opacity(0.6) }

    private var outfit: Color {
        switch friendship {
        case .stranger, .acquaintance: return Color(red: 0.95, green: 0.95, blue: 0.97)   // weißes Shirt
        case .friend: return Color(red: 0.18, green: 0.24, blue: 0.45)                   // Uniform-Blau
        case .bestFriend: return Color(red: 0.35, green: 0.62, blue: 0.80)               // Yukata
        case .soulmate: return Color(red: 0.72, green: 0.18, blue: 0.30)                 // Kimono-Rot
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Theme.sakura.opacity(0.35), Theme.sand], startPoint: .top, endPoint: .bottom))

            // Körper / Outfit
            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(outfit)
                .frame(width: size * 0.52, height: size * 0.36)
                .offset(y: size * 0.36)
                .overlay(
                    // Kimono-/Yukata-Kragen
                    friendship >= .bestFriend
                    ? AnyView(
                        Path { p in
                            p.move(to: CGPoint(x: size * 0.5 - size * 0.12, y: size * 0.54))
                            p.addLine(to: CGPoint(x: size * 0.5, y: size * 0.72))
                            p.addLine(to: CGPoint(x: size * 0.5 + size * 0.12, y: size * 0.54))
                        }
                        .stroke(Color.white.opacity(0.9), lineWidth: size * 0.025)
                    )
                    : AnyView(EmptyView())
                )

            // Hinteres Haar
            Ellipse()
                .fill(hairColor)
                .frame(width: size * 0.62, height: size * 0.70)
                .offset(y: size * 0.02)

            // Gesicht
            Ellipse()
                .fill(skin)
                .frame(width: size * 0.48, height: size * 0.52)
                .offset(y: size * 0.06)

            // Pony
            Path { p in
                let w = size * 0.5, h = size * 0.22
                let origin = CGPoint(x: size * 0.25, y: size * 0.18)
                p.move(to: origin)
                p.addQuadCurve(to: CGPoint(x: origin.x + w, y: origin.y), control: CGPoint(x: origin.x + w / 2, y: origin.y - h * 0.9))
                p.addLine(to: CGPoint(x: origin.x + w, y: origin.y + h * 0.35))
                p.addQuadCurve(to: CGPoint(x: origin.x + w * 0.62, y: origin.y + h * 0.75), control: CGPoint(x: origin.x + w * 0.85, y: origin.y + h * 0.75))
                p.addQuadCurve(to: CGPoint(x: origin.x + w * 0.35, y: origin.y + h * 0.65), control: CGPoint(x: origin.x + w * 0.48, y: origin.y + h * 0.35))
                p.addQuadCurve(to: CGPoint(x: origin.x, y: origin.y + h * 0.4), control: CGPoint(x: origin.x + w * 0.12, y: origin.y + h * 0.8))
                p.closeSubpath()
            }
            .fill(hairColor)

            // Augen
            HStack(spacing: size * 0.14) {
                eye
                eye
            }
            .offset(y: size * 0.07)

            // Wangen
            HStack(spacing: size * 0.26) {
                Circle().fill(blush).frame(width: size * 0.07)
                Circle().fill(blush).frame(width: size * 0.07)
            }
            .offset(y: size * 0.17)

            // Mund
            mouth
                .offset(y: size * 0.22)

            // Accessoires nach Freundschaft
            if friendship >= .acquaintance {
                ribbon
                    .offset(x: size * 0.2, y: -size * 0.1)
            }
            if friendship == .soulmate {
                Image(systemName: "tortoise.fill")
                    .font(.system(size: size * 0.11))
                    .foregroundStyle(Theme.shell)
                    .offset(x: -size * 0.2, y: -size * 0.08)
            }

            // Stimmungs-Extras
            if mood == .surprised || mood == .proud {
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.14))
                    .foregroundStyle(Theme.sun)
                    .offset(x: size * 0.33, y: -size * 0.3)
            }
            if mood == .comfort {
                Capsule()
                    .fill(Color.blue.opacity(0.5))
                    .frame(width: size * 0.05, height: size * 0.1)
                    .offset(x: size * 0.3, y: -size * 0.02)
            }
            if mood == .sleepy {
                Text("z")
                    .font(.system(size: size * 0.14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .offset(x: size * 0.33, y: -size * 0.28)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color.white.opacity(0.6), lineWidth: 2))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
        .offset(y: bounce ? -3 : 0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { bounce = true }
        }
        .task { await blinkLoop() }
        .accessibilityLabel("Hana, deine Tutorin")
    }

    private func blinkLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.5...5)))
            withAnimation(.easeInOut(duration: 0.08)) { blink = true }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeInOut(duration: 0.08)) { blink = false }
        }
    }

    @ViewBuilder
    private var eye: some View {
        if blink || mood == .sleepy || mood == .proud {
            // Lachende, geschlossene Augen ∩
            Path { p in
                p.move(to: CGPoint(x: 0, y: size * 0.03))
                p.addQuadCurve(to: CGPoint(x: size * 0.08, y: size * 0.03), control: CGPoint(x: size * 0.04, y: -size * 0.02))
            }
            .stroke(hairColor, style: StrokeStyle(lineWidth: size * 0.02, lineCap: .round))
            .frame(width: size * 0.08, height: size * 0.05)
        } else {
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.25, green: 0.45, blue: 0.40))
                    .frame(width: size * 0.08, height: mood == .surprised ? size * 0.13 : size * 0.10)
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.025)
                    .offset(x: -size * 0.015, y: -size * 0.025)
            }
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch mood {
        case .comfort, .think:
            Capsule().fill(hairColor).frame(width: size * 0.06, height: size * 0.015)
        case .surprised:
            Ellipse().fill(hairColor).frame(width: size * 0.05, height: size * 0.07)
        default:
            Path { p in
                p.move(to: .zero)
                p.addQuadCurve(to: CGPoint(x: size * 0.1, y: 0), control: CGPoint(x: size * 0.05, y: size * 0.06))
            }
            .stroke(hairColor, style: StrokeStyle(lineWidth: size * 0.018, lineCap: .round))
            .frame(width: size * 0.1, height: size * 0.04)
        }
    }

    private var ribbon: some View {
        HStack(spacing: -size * 0.01) {
            Circle().fill(Theme.danger).frame(width: size * 0.07)
            Circle().fill(Theme.danger).frame(width: size * 0.07)
        }
        .overlay(Circle().fill(Theme.sun).frame(width: size * 0.03))
    }
}

/// Sprechblase mit Hanas Spruch.
struct HanaBubble: View {
    let mood: HanaMood
    let friendship: FriendshipLevel
    let text: String
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            HanaView(mood: mood, friendship: friendship, size: compact ? 56 : 76)
            VStack(alignment: .leading, spacing: 4) {
                Text("Hana")
                    .font(.caption.bold())
                    .foregroundStyle(Theme.sakura)
                Text(text)
                    .font(compact ? .footnote : .subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(Theme.cardBackground, in: BubbleShape())
            .overlay(BubbleShape().strokeBorder(Theme.sakura.opacity(0.4)))
        }
    }
}

/// Sprechblase mit kleinem Zipfel links.
struct BubbleShape: InsettableShape {
    var inset: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var s = self
        s.inset += amount
        return s
    }

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        var p = Path(roundedRect: r.insetBy(dx: 6, dy: 0).offsetBy(dx: 6, dy: 0), cornerRadius: 14)
        p.move(to: CGPoint(x: r.minX + 6, y: r.minY + 22))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + 28))
        p.addLine(to: CGPoint(x: r.minX + 6, y: r.minY + 34))
        p.closeSubpath()
        return p
    }
}
#endif
