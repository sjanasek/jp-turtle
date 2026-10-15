#if canImport(SwiftUI)
import SwiftUI

/// Kame als gezeichnete Figur: runder Panzer mit Waben, großer Kopf, Glanzauge,
/// rosa Bäckchen und Lächeln – dieselbe Figur wie in der Browser-Vorschau.
/// Liegt im Kern, damit App und Widget sie gleichermaßen nutzen.
/// Das Seitenverhältnis ist 3:2 (Breite zu Höhe); Kame schaut nach rechts.
public struct KameFigure: View {
    public let stage: TurtleStage

    public init(stage: TurtleStage) {
        self.stage = stage
    }

    public var body: some View {
        Canvas { ctx, size in
            // Zeichenfläche in Vorschau-Einheiten: x von -66 bis 84, y von -44 bis 56.
            let scale = min(size.width / 150, size.height / 100)
            ctx.translateBy(x: (size.width - 150 * scale) / 2 + 66 * scale,
                            y: (size.height - 100 * scale) / 2 + 44 * scale)
            ctx.scaleBy(x: scale, y: scale)

            let ink = Color(red: 0.11, green: 0.24, blue: 0.13)
            if stage == .egg {
                drawEgg(&ctx, ink: ink)
                return
            }

            let skin = Color(red: 0.56, green: 0.75, blue: 0.48)
            let shell = shellColor

            func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
            }
            func poly(_ pts: [(CGFloat, CGFloat)]) -> Path {
                var p = Path()
                p.move(to: CGPoint(x: pts[0].0, y: pts[0].1))
                for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
                p.closeSubpath()
                return p
            }

            // Beine und Schwänzchen
            ctx.fill(ellipse(-30, 30, 14, 10), with: .color(skin))
            ctx.fill(ellipse(28, 32, 14, 10), with: .color(skin))
            ctx.fill(ellipse(-50, 14, 9, 5), with: .color(skin))

            // Kopf
            let head = ellipse(52, 0, 21, 18)
            ctx.fill(head, with: .color(skin))
            ctx.stroke(head, with: .color(ink), lineWidth: 3)
            ctx.fill(ellipse(59, -4, 3.8, 4.2), with: .color(ink))
            ctx.fill(ellipse(60.3, -5.6, 1.3, 1.3), with: .color(.white))
            ctx.fill(ellipse(55, 7, 4.2, 3), with: .color(Color(red: 0.98, green: 0.55, blue: 0.68).opacity(0.55)))
            var smile = Path()
            smile.move(to: CGPoint(x: 58, y: 7))
            smile.addQuadCurve(to: CGPoint(x: 68, y: 6), control: CGPoint(x: 63, y: 11))
            ctx.stroke(smile, with: .color(ink), style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

            // Panzer
            let body = ellipse(0, 8, 48, 34)
            ctx.fill(body, with: .color(shell))
            ctx.stroke(body, with: .color(ink), lineWidth: 4)
            ctx.fill(ellipse(-12, -10, 20, 8), with: .color(.white.opacity(0.18)))
            let hexes = [
                poly([(0, -10), (12, -3), (12, 11), (0, 18), (-12, 11), (-12, -3)]),
                poly([(-27, 4), (-17, 10), (-17, 21), (-27, 27), (-37, 21), (-37, 10)]),
                poly([(27, 4), (37, 10), (37, 21), (27, 27), (17, 21), (17, 10)]),
            ]
            for h in hexes {
                ctx.fill(h, with: .color(.white.opacity(0.18)))
                ctx.stroke(h, with: .color(ink.opacity(0.55)), lineWidth: 2.4)
            }

            // Accessoires je Stufe
            if stage >= .wanderer {
                let petal = Color(red: 0.98, green: 0.62, blue: 0.72)
                for i in 0..<5 {
                    let a = Double(i) * .pi * 2 / 5 - .pi / 2
                    ctx.fill(ellipse(44 + 4.5 * cos(a), -19 + 4.5 * sin(a), 3.4, 3.4), with: .color(petal))
                }
                ctx.fill(ellipse(44, -19, 2.2, 2.2), with: .color(Color(red: 0.98, green: 0.85, blue: 0.35)))
            }
            if stage == .sensei {
                ctx.fill(poly([(36, -24), (56, -32), (76, -24), (56, -16)]), with: .color(ink))
                ctx.fill(Path(CGRect(x: 47, y: -22, width: 18, height: 6)), with: .color(ink))
                var tassel = Path()
                tassel.move(to: CGPoint(x: 56, y: -24))
                tassel.addLine(to: CGPoint(x: 70, y: -16))
                ctx.stroke(tassel, with: .color(Color(red: 0.96, green: 0.72, blue: 0.16)), lineWidth: 2)
            }
        }
        .aspectRatio(1.5, contentMode: .fit)
        .accessibilityLabel("Kame")
    }

    private var shellColor: Color {
        switch stage {
        case .egg, .hatchling: return Color(red: 0.53, green: 0.72, blue: 0.45)
        case .juvenile: return Color(red: 0.37, green: 0.62, blue: 0.33)
        case .wanderer: return Color(red: 0.31, green: 0.54, blue: 0.27)
        case .elder: return Color(red: 0.23, green: 0.43, blue: 0.31)
        case .sensei: return Color(red: 0.42, green: 0.65, blue: 0.42)
        }
    }

    private func drawEgg(_ ctx: inout GraphicsContext, ink: Color) {
        let egg = Path(ellipseIn: CGRect(x: -26, y: -32, width: 52, height: 68))
        ctx.fill(egg, with: .color(Color(red: 1.0, green: 0.99, blue: 0.94)))
        ctx.stroke(egg, with: .color(Color(red: 0.81, green: 0.79, blue: 0.67)), lineWidth: 2.5)
        // grüne Flecken
        ctx.fill(Path(ellipseIn: CGRect(x: -14, y: -18, width: 10, height: 8)), with: .color(Color(red: 0.56, green: 0.75, blue: 0.48).opacity(0.7)))
        ctx.fill(Path(ellipseIn: CGRect(x: 6, y: 4, width: 12, height: 9)), with: .color(Color(red: 0.56, green: 0.75, blue: 0.48).opacity(0.7)))
        var crack = Path()
        crack.move(to: CGPoint(x: -18, y: -4))
        crack.addLine(to: CGPoint(x: -10, y: 2))
        crack.addLine(to: CGPoint(x: -14, y: 9))
        crack.addLine(to: CGPoint(x: -4, y: 14))
        ctx.stroke(crack, with: .color(Color(red: 0.62, green: 0.58, blue: 0.47)), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }
}
#endif
