#if os(iOS)
import SwiftUI
import CoreGraphics
import JPTurtleCore

/// Rastert SwiftUI-Inhalte zu einer BitMask (Graustufen, dann Schwellwert).
/// Vorlage (Zeichen im Systemfont) und Nutzer-Striche werden mit derselben
/// Größe gerendert, damit der InkScorer sie direkt vergleichen kann.
@MainActor
enum Rasterizer {
    static let resolution = 128

    static func mask<V: View>(of view: V, size: Int = resolution, threshold: UInt8 = 96) -> BitMask? {
        let renderer = ImageRenderer(content: view.frame(width: CGFloat(size), height: CGFloat(size)))
        renderer.scale = 1
        guard let cg = renderer.cgImage else { return nil }

        var gray = [UInt8](repeating: 0, count: size * size)
        let space = CGColorSpaceCreateDeviceGray()
        let ok = gray.withUnsafeMutableBytes { ptr -> Bool in
            guard let ctx = CGContext(
                data: ptr.baseAddress,
                width: size, height: size,
                bitsPerComponent: 8, bytesPerRow: size,
                space: space,
                bitmapInfo: CGImageAlphaInfo.none.rawValue
            ) else { return false }
            ctx.setFillColor(gray: 1, alpha: 1)
            ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: size, height: size))
            return true
        }
        guard ok else { return nil }
        // Weiß (255) = leer, Schwarz (0) = Tinte → invertieren.
        return BitMask(width: size, height: size, gray: gray.map { 255 - $0 }, threshold: threshold)
    }

    /// Vorlage: Zeichen im Systemfont, schwarz auf weiß.
    static func templateMask(for character: String, size: Int = resolution) -> BitMask? {
        mask(of: TemplateGlyph(character: character, size: CGFloat(size)), size: size)
    }

    /// Nutzer-Striche (normiert auf 0...1) schwarz auf weiß.
    static func inkMask(strokes: [[CGPoint]], size: Int = resolution) -> BitMask? {
        mask(of: InkGlyph(strokes: strokes, size: CGFloat(size)), size: size)
    }
}

struct TemplateGlyph: View {
    let character: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Color.white
            Text(character)
                .font(.system(size: size * 0.78, weight: .regular))
                .foregroundStyle(Color.black)
        }
        .frame(width: size, height: size)
    }
}

struct InkGlyph: View {
    let strokes: [[CGPoint]]
    let size: CGFloat

    var body: some View {
        Canvas { ctx, _ in
            ctx.fill(Path(CGRect(x: 0, y: 0, width: size, height: size)), with: .color(.white))
            for stroke in strokes where stroke.count > 1 {
                var p = Path()
                p.move(to: CGPoint(x: stroke[0].x * size, y: stroke[0].y * size))
                for pt in stroke.dropFirst() {
                    p.addLine(to: CGPoint(x: pt.x * size, y: pt.y * size))
                }
                ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: size * 0.05, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
    }
}
#endif
