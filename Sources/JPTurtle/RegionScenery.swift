#if os(iOS)
import SwiftUI

/// Kleine Landschaft je Gebiet der Abenteuerkarte, gezeichnet aus einfachen Formen.
/// Alle Maße relativ zu `size`, damit die Karte auf jedem iPhone gleich aussieht.
struct RegionScenery: View {
    let id: String
    let size: CGFloat

    var body: some View {
        ZStack {
            // Boden-Insel unter jeder Landschaft
            Ellipse()
                .fill(groundColor)
                .frame(width: size * 0.98, height: size * 0.5)
                .offset(y: size * 0.24)
            content
        }
        .frame(width: size, height: size)
    }

    private var s: CGFloat { size }

    private var groundColor: Color {
        switch id {
        case "pond": return Color(red: 0.56, green: 0.78, blue: 0.46)
        case "mountain": return Color(red: 0.66, green: 0.72, blue: 0.62)
        case "village", "plaza", "shop", "sundial": return Color(red: 0.90, green: 0.82, blue: 0.64)
        default: return Color(red: 0.55, green: 0.76, blue: 0.44)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch id {
        case "pond": pond
        case "teahouse": teahouse
        case "torii": torii
        case "garden": garden
        case "village": village
        case "mountain": mountain
        case "plaza": plaza
        case "shop": shop
        case "sundial": sundial
        case "path": signposts
        default: lanterns
        }
    }

    // MARK: Teich

    private var pond: some View {
        ZStack {
            Ellipse()
                .fill(LinearGradient(colors: [Color(red: 0.45, green: 0.78, blue: 0.95), Color(red: 0.16, green: 0.50, blue: 0.76)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: s * 0.88, height: s * 0.52)
                .offset(y: s * 0.12)
            Ellipse().stroke(.white.opacity(0.55), lineWidth: s * 0.012)
                .frame(width: s * 0.42, height: s * 0.14).offset(x: s * 0.1, y: s * 0.06)
            Ellipse().stroke(.white.opacity(0.35), lineWidth: s * 0.01)
                .frame(width: s * 0.26, height: s * 0.08).offset(x: -s * 0.16, y: s * 0.24)
            // Seerosenblätter
            Circle().fill(Color(red: 0.30, green: 0.62, blue: 0.30)).frame(width: s * 0.12).offset(x: -s * 0.24, y: s * 0.06)
            Circle().fill(Color(red: 0.36, green: 0.68, blue: 0.34)).frame(width: s * 0.09).offset(x: -s * 0.12, y: s * 0.17)
            Circle().fill(Color(red: 0.98, green: 0.70, blue: 0.80)).frame(width: s * 0.045).offset(x: -s * 0.24, y: s * 0.05)
            // Koi
            Image(systemName: "fish.fill").font(.system(size: s * 0.1)).foregroundStyle(Color(red: 0.98, green: 0.52, blue: 0.22))
                .offset(x: s * 0.2, y: s * 0.2)
            // Bogenbrücke
            BridgeArc()
                .stroke(Color(red: 0.80, green: 0.26, blue: 0.22), lineWidth: s * 0.035)
                .frame(width: s * 0.34, height: s * 0.14)
                .offset(x: s * 0.24, y: -s * 0.08)
            // Schilf
            ForEach(0..<3, id: \.self) { i in
                Capsule().fill(Color(red: 0.28, green: 0.52, blue: 0.26))
                    .frame(width: s * 0.018, height: s * (0.14 + Double(i) * 0.03))
                    .rotationEffect(.degrees(Double(i - 1) * 12))
                    .offset(x: -s * 0.38 + Double(i) * s * 0.03, y: -s * 0.02)
            }
        }
    }

    // MARK: Teehaus

    private var teahouse: some View {
        ZStack {
            Rectangle().fill(Color(red: 0.93, green: 0.85, blue: 0.70))
                .frame(width: s * 0.56, height: s * 0.3).offset(y: s * 0.1)
            Trapezoid(inset: 0.2)
                .fill(Color(red: 0.55, green: 0.18, blue: 0.18))
                .frame(width: s * 0.82, height: s * 0.24).offset(y: -s * 0.14)
            Rectangle().fill(Color(red: 0.32, green: 0.10, blue: 0.10))
                .frame(width: s * 0.86, height: s * 0.035).offset(y: -s * 0.02)
            Rectangle().fill(Color(red: 0.30, green: 0.22, blue: 0.18))
                .frame(width: s * 0.14, height: s * 0.2).offset(y: s * 0.15)
            Rectangle().fill(Color(red: 0.20, green: 0.32, blue: 0.62))
                .frame(width: s * 0.18, height: s * 0.08).offset(y: s * 0.06)
            Circle().fill(.white).frame(width: s * 0.04).offset(y: s * 0.06)
            Capsule().fill(Color(red: 0.92, green: 0.30, blue: 0.24))
                .frame(width: s * 0.07, height: s * 0.1).offset(x: s * 0.24, y: s * 0.05)
            // Dampf aus der Teetasse
            Image(systemName: "cup.and.saucer.fill").font(.system(size: s * 0.1)).foregroundStyle(.white)
                .offset(x: -s * 0.36, y: s * 0.2)
            SteamLines().stroke(.white.opacity(0.8), style: StrokeStyle(lineWidth: s * 0.012, lineCap: .round))
                .frame(width: s * 0.1, height: s * 0.12).offset(x: -s * 0.36, y: s * 0.08)
        }
    }

    // MARK: Torii

    private var torii: some View {
        let red = Color(red: 0.84, green: 0.22, blue: 0.17)
        return ZStack {
            Rectangle().fill(red).frame(width: s * 0.07, height: s * 0.56).offset(x: -s * 0.22, y: s * 0.06)
            Rectangle().fill(red).frame(width: s * 0.07, height: s * 0.56).offset(x: s * 0.22, y: s * 0.06)
            Rectangle().fill(red).frame(width: s * 0.62, height: s * 0.05).offset(y: -s * 0.1)
            Capsule().fill(red).frame(width: s * 0.82, height: s * 0.07).offset(y: -s * 0.2)
            Capsule().fill(Color(red: 0.16, green: 0.10, blue: 0.10)).frame(width: s * 0.9, height: s * 0.04).offset(y: -s * 0.25)
            Rectangle().fill(Color(red: 0.16, green: 0.10, blue: 0.10)).frame(width: s * 0.06, height: s * 0.09).offset(y: -s * 0.15)
            // Steinlaternen
            stoneLantern.offset(x: -s * 0.4, y: s * 0.16)
            stoneLantern.offset(x: s * 0.4, y: s * 0.16)
        }
    }

    private var stoneLantern: some View {
        VStack(spacing: 0) {
            Triangle().fill(Color.gray).frame(width: s * 0.1, height: s * 0.05)
            Rectangle().fill(Color(red: 0.98, green: 0.86, blue: 0.48)).frame(width: s * 0.06, height: s * 0.05)
            Rectangle().fill(Color.gray).frame(width: s * 0.035, height: s * 0.08)
        }
    }

    // MARK: Garten

    private var garden: some View {
        ZStack {
            tree(color: Color(red: 0.98, green: 0.66, blue: 0.78)).offset(x: -s * 0.24, y: -s * 0.04)
            tree(color: Color(red: 0.26, green: 0.58, blue: 0.30)).offset(x: s * 0.2, y: -s * 0.08)
            tree(color: Color(red: 0.38, green: 0.68, blue: 0.34)).scaleEffect(0.8).offset(x: 0, y: s * 0.06)
            ForEach(0..<6, id: \.self) { i in
                Circle()
                    .fill(i % 2 == 0 ? Color(red: 0.98, green: 0.55, blue: 0.68) : Color(red: 0.98, green: 0.86, blue: 0.32))
                    .frame(width: s * 0.045)
                    .offset(x: -s * 0.3 + Double(i) * s * 0.12, y: s * 0.3 - Double(i % 2) * s * 0.04)
            }
            Ellipse().fill(Color.gray.opacity(0.6)).frame(width: s * 0.1, height: s * 0.05).offset(x: s * 0.06, y: s * 0.22)
        }
    }

    private func tree(color: Color) -> some View {
        ZStack {
            Rectangle().fill(Color(red: 0.48, green: 0.32, blue: 0.20)).frame(width: s * 0.05, height: s * 0.2).offset(y: s * 0.1)
            Circle().fill(color).frame(width: s * 0.3).offset(y: -s * 0.04)
            Circle().fill(.white.opacity(0.2)).frame(width: s * 0.12).offset(x: -s * 0.05, y: -s * 0.09)
        }
    }

    // MARK: Dorf

    private var village: some View {
        ZStack {
            house(roof: Color(red: 0.26, green: 0.40, blue: 0.62)).offset(x: -s * 0.24, y: -s * 0.02)
            house(roof: Color(red: 0.70, green: 0.26, blue: 0.22)).scaleEffect(1.15).offset(x: s * 0.12, y: -s * 0.1)
            house(roof: Color(red: 0.50, green: 0.36, blue: 0.24)).scaleEffect(0.9).offset(x: -s * 0.02, y: s * 0.16)
        }
    }

    private func house(roof: Color) -> some View {
        ZStack {
            Rectangle().fill(Color(red: 0.97, green: 0.93, blue: 0.84)).frame(width: s * 0.24, height: s * 0.16).offset(y: s * 0.06)
            Triangle().fill(roof).frame(width: s * 0.32, height: s * 0.14).offset(y: -s * 0.08)
            Rectangle().fill(Color(red: 0.40, green: 0.28, blue: 0.18)).frame(width: s * 0.05, height: s * 0.08).offset(y: s * 0.1)
            Rectangle().fill(Color(red: 0.60, green: 0.80, blue: 0.95)).frame(width: s * 0.05, height: s * 0.04).offset(x: s * 0.07, y: s * 0.04)
        }
    }

    // MARK: Berg

    private var mountain: some View {
        ZStack {
            Triangle().fill(Color(red: 0.45, green: 0.52, blue: 0.70)).frame(width: s * 0.72, height: s * 0.62).offset(x: -s * 0.08, y: -s * 0.04)
            Triangle().fill(.white).frame(width: s * 0.22, height: s * 0.19).offset(x: -s * 0.08, y: -s * 0.255)
            Triangle().fill(Color(red: 0.56, green: 0.63, blue: 0.80)).frame(width: s * 0.5, height: s * 0.4).offset(x: s * 0.2, y: s * 0.07)
            Triangle().fill(.white).frame(width: s * 0.14, height: s * 0.11).offset(x: s * 0.2, y: -s * 0.075)
            Image(systemName: "cloud.fill").font(.system(size: s * 0.16)).foregroundStyle(.white.opacity(0.95))
                .offset(x: s * 0.3, y: -s * 0.3)
            // Fluss am Fuß
            BridgeArc().stroke(Color(red: 0.36, green: 0.68, blue: 0.90), lineWidth: s * 0.03)
                .frame(width: s * 0.7, height: s * 0.08).rotationEffect(.degrees(180)).offset(y: s * 0.32)
        }
    }

    // MARK: Marktplatz

    private var plaza: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.7)).frame(width: s * 0.38).offset(y: s * 0.06)
            Circle().fill(Color(red: 0.45, green: 0.75, blue: 0.95)).frame(width: s * 0.3).offset(y: s * 0.06)
            Capsule().fill(Color.gray).frame(width: s * 0.05, height: s * 0.18).offset(y: -s * 0.04)
            Image(systemName: "drop.fill").font(.system(size: s * 0.08)).foregroundStyle(Color(red: 0.45, green: 0.75, blue: 0.95))
                .offset(y: -s * 0.18)
            Image(systemName: "person.fill").font(.system(size: s * 0.12)).foregroundStyle(Color(red: 0.55, green: 0.35, blue: 0.70))
                .offset(x: -s * 0.33, y: s * 0.12)
            Image(systemName: "person.fill").font(.system(size: s * 0.1)).foregroundStyle(Color(red: 0.85, green: 0.45, blue: 0.40))
                .offset(x: s * 0.33, y: s * 0.16)
        }
    }

    // MARK: Kramladen

    private var shop: some View {
        ZStack {
            Rectangle().fill(Color(red: 0.62, green: 0.42, blue: 0.24)).frame(width: s * 0.6, height: s * 0.24).offset(y: s * 0.14)
            HStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { i in
                    Rectangle().fill(i % 2 == 0 ? Color(red: 0.86, green: 0.30, blue: 0.24) : .white)
                }
            }
            .frame(width: s * 0.7, height: s * 0.12)
            .offset(y: -s * 0.06)
            Rectangle().fill(Color(red: 0.42, green: 0.28, blue: 0.16)).frame(width: s * 0.03, height: s * 0.3).offset(x: -s * 0.3, y: s * 0.04)
            Rectangle().fill(Color(red: 0.42, green: 0.28, blue: 0.16)).frame(width: s * 0.03, height: s * 0.3).offset(x: s * 0.3, y: s * 0.04)
            HStack(spacing: s * 0.03) {
                Circle().fill(Color(red: 0.98, green: 0.72, blue: 0.20))
                Circle().fill(Color(red: 0.36, green: 0.66, blue: 0.34))
                Circle().fill(Color(red: 0.86, green: 0.30, blue: 0.24))
                Circle().fill(Color(red: 0.30, green: 0.50, blue: 0.80))
            }
            .frame(width: s * 0.4, height: s * 0.07)
            .offset(y: s * 0.05)
            Image(systemName: "umbrella.fill").font(.system(size: s * 0.12)).foregroundStyle(Color(red: 0.30, green: 0.50, blue: 0.80))
                .offset(x: s * 0.4, y: s * 0.2)
        }
    }

    // MARK: Sonnenuhr

    private var sundial: some View {
        ZStack {
            Circle().fill(Color.gray.opacity(0.75)).frame(width: s * 0.56).offset(y: s * 0.08)
            Circle().fill(Color(red: 0.98, green: 0.94, blue: 0.82)).frame(width: s * 0.46).offset(y: s * 0.08)
            ForEach(0..<12, id: \.self) { i in
                Capsule().fill(Color(red: 0.40, green: 0.34, blue: 0.26))
                    .frame(width: s * 0.012, height: s * 0.04)
                    .offset(y: -s * 0.19)
                    .rotationEffect(.degrees(Double(i) * 30))
                    .offset(y: s * 0.08)
            }
            Triangle().fill(Color(red: 0.40, green: 0.34, blue: 0.26))
                .frame(width: s * 0.08, height: s * 0.2).offset(x: s * 0.02, y: -s * 0.02)
            Image(systemName: "sun.max.fill").font(.system(size: s * 0.16)).foregroundStyle(Color(red: 0.98, green: 0.72, blue: 0.18))
                .offset(x: s * 0.34, y: -s * 0.3)
        }
    }

    // MARK: Pfad der Tat

    private var signposts: some View {
        ZStack {
            Rectangle().fill(Color(red: 0.48, green: 0.32, blue: 0.20)).frame(width: s * 0.05, height: s * 0.5).offset(y: s * 0.06)
            ArrowBoard().fill(Color(red: 0.86, green: 0.70, blue: 0.46)).frame(width: s * 0.36, height: s * 0.1).offset(x: s * 0.14, y: -s * 0.12)
            ArrowBoard().fill(Color(red: 0.80, green: 0.62, blue: 0.40)).frame(width: s * 0.32, height: s * 0.09)
                .scaleEffect(x: -1, y: 1).offset(x: -s * 0.13, y: s * 0.02)
            Text("道").font(.system(size: s * 0.07, weight: .black)).foregroundStyle(Color(red: 0.32, green: 0.20, blue: 0.12))
                .offset(x: s * 0.12, y: -s * 0.12)
            ForEach(0..<3, id: \.self) { i in
                Ellipse().fill(Color.gray.opacity(0.6)).frame(width: s * 0.1, height: s * 0.05)
                    .offset(x: -s * 0.25 + Double(i) * s * 0.22, y: s * 0.3)
            }
        }
    }

    // MARK: Laternen-Allee

    private var lanterns: some View {
        ZStack {
            Rectangle().fill(Color(red: 0.42, green: 0.28, blue: 0.16)).frame(width: s * 0.03, height: s * 0.5).offset(x: -s * 0.4, y: s * 0.04)
            Rectangle().fill(Color(red: 0.42, green: 0.28, blue: 0.16)).frame(width: s * 0.03, height: s * 0.5).offset(x: s * 0.4, y: s * 0.04)
            BridgeArc().stroke(Color(red: 0.30, green: 0.22, blue: 0.16), lineWidth: s * 0.01)
                .frame(width: s * 0.8, height: s * 0.1).rotationEffect(.degrees(180)).offset(y: -s * 0.16)
            ForEach(0..<5, id: \.self) { i in
                let x = -s * 0.3 + Double(i) * s * 0.15
                let sag = (i == 2 ? 0.1 : (i == 1 || i == 3 ? 0.085 : 0.055)) * s
                ZStack {
                    Circle().fill(Color(red: 1.0, green: 0.75, blue: 0.35).opacity(0.35)).frame(width: s * 0.13)
                    Capsule().fill(Color(red: 0.90, green: 0.22, blue: 0.18)).frame(width: s * 0.08, height: s * 0.11)
                    Rectangle().fill(.black).frame(width: s * 0.05, height: s * 0.012).offset(y: -s * 0.055)
                }
                .offset(x: x, y: -s * 0.2 + sag)
            }
        }
    }
}

// MARK: - Formen

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Dachform: oben schmaler als unten.
struct Trapezoid: Shape {
    var inset: CGFloat

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * inset, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct BridgeArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY), control: CGPoint(x: r.midX, y: r.minY - r.height))
        return p
    }
}

struct SteamLines: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        for i in 0..<2 {
            let x = r.minX + r.width * (0.3 + CGFloat(i) * 0.4)
            p.move(to: CGPoint(x: x, y: r.maxY))
            p.addCurve(to: CGPoint(x: x, y: r.minY),
                       control1: CGPoint(x: x - r.width * 0.3, y: r.midY + r.height * 0.2),
                       control2: CGPoint(x: x + r.width * 0.3, y: r.midY - r.height * 0.2))
        }
        return p
    }
}

struct ArrowBoard: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.height * 0.5, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.height * 0.5, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}
#endif
