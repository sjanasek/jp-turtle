import Foundation

/// Binäre Rastermaske (0 = leer, 1 = Tinte). Plattformunabhängig, damit die
/// Bewertung unter Linux testbar ist. Das Rasterisieren von Text und
/// Strichen passiert in der App (CoreGraphics), die Mathematik hier.
public struct BitMask: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public var bits: [UInt8]

    public init(width: Int, height: Int, bits: [UInt8]) {
        precondition(bits.count == width * height, "BitMask: bits.count != width*height")
        self.width = width
        self.height = height
        self.bits = bits
    }

    public init(width: Int, height: Int) {
        self.init(width: width, height: height, bits: Array(repeating: 0, count: width * height))
    }

    /// Aus Graustufen-Bytes (0 = weiß ... 255 = schwarz) mit Schwellwert.
    public init(width: Int, height: Int, gray: [UInt8], threshold: UInt8 = 96) {
        self.init(width: width, height: height, bits: gray.map { $0 >= threshold ? 1 : 0 })
    }

    public subscript(x: Int, y: Int) -> UInt8 {
        get { bits[y * width + x] }
        set { bits[y * width + x] = newValue }
    }

    public var inkCount: Int { bits.reduce(0) { $0 + Int($1) } }
    public var isEmpty: Bool { !bits.contains(1) }

    /// Morphologische Dilatation mit kreisförmigem Strukturelement.
    public func dilated(radius r: Int) -> BitMask {
        guard r > 0, !isEmpty else { return self }
        var out = BitMask(width: width, height: height)
        let r2 = r * r
        var offsets: [(Int, Int)] = []
        for dy in -r...r {
            for dx in -r...r where dx * dx + dy * dy <= r2 {
                offsets.append((dx, dy))
            }
        }
        for y in 0..<height {
            for x in 0..<width where self[x, y] == 1 {
                for (dx, dy) in offsets {
                    let nx = x + dx, ny = y + dy
                    if nx >= 0, ny >= 0, nx < width, ny < height {
                        out[nx, ny] = 1
                    }
                }
            }
        }
        return out
    }

    /// Anzahl Pixel, die in beiden Masken Tinte haben.
    public func overlap(with other: BitMask) -> Int {
        precondition(width == other.width && height == other.height)
        var n = 0
        for i in bits.indices where bits[i] == 1 && other.bits[i] == 1 { n += 1 }
        return n
    }

    /// Umschließendes Rechteck der Tinte (minX, minY, maxX, maxY) oder nil.
    public var bounds: (minX: Int, minY: Int, maxX: Int, maxY: Int)? {
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where self[x, y] == 1 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        return maxX < 0 ? nil : (minX, minY, maxX, maxY)
    }
}

/// Ergebnis einer Schreibbewertung.
public struct InkScore: Equatable, Sendable {
    /// Anteil der Vorlage, den die Striche treffen (0...1).
    public let coverage: Double
    /// Anteil der eigenen Tinte, der auf der Vorlage liegt (0...1).
    public let precision: Double
    /// Wie gut Größe/Position passen (0...1).
    public let placement: Double
    /// Strichzahl-Abweichung (0 = passt).
    public let strokeDelta: Int
    /// Gesamtnote 0...100.
    public let total: Int

    public enum Verdict: String, Sendable {
        case perfect, good, okay, practice

        public var title: String {
            switch self {
            case .perfect: return "Perfekt!"
            case .good: return "Gut!"
            case .okay: return "Okay"
            case .practice: return "Nochmal üben"
            }
        }

        public var xp: Int {
            switch self {
            case .perfect: return 15
            case .good: return 10
            case .okay: return 6
            case .practice: return 3
            }
        }
    }

    public var verdict: Verdict {
        switch total {
        case 85...: return .perfect
        case 65..<85: return .good
        case 45..<65: return .okay
        default: return .practice
        }
    }

    public var isPerfect: Bool { verdict == .perfect }
}

/// Bewertet eine Handschrift gegen eine Vorlage. Kein Machine Learning –
/// Überdeckung, Präzision, Platzierung und Strichzahl reichen für ein
/// ehrliches, nachvollziehbares Feedback beim Nachspuren und Freischreiben.
public enum InkScorer {
    public static func score(
        template: BitMask,
        user: BitMask,
        strokesDrawn: Int,
        expectedStrokes: Int?,
        tolerance: Int = 6
    ) -> InkScore {
        guard !user.isEmpty, !template.isEmpty else {
            return InkScore(coverage: 0, precision: 0, placement: 0, strokeDelta: expectedStrokes.map { abs($0 - strokesDrawn) } ?? 0, total: 0)
        }

        let fatUser = user.dilated(radius: tolerance)
        let fatTemplate = template.dilated(radius: tolerance)

        let coverage = Double(template.overlap(with: fatUser)) / Double(template.inkCount)
        let precision = Double(user.overlap(with: fatTemplate)) / Double(user.inkCount)

        // Platzierung: Bounding Boxes vergleichen (Größe + Mittelpunkt).
        var placement = 1.0
        if let tb = template.bounds, let ub = user.bounds {
            let tw = Double(tb.maxX - tb.minX + 1), th = Double(tb.maxY - tb.minY + 1)
            let uw = Double(ub.maxX - ub.minX + 1), uh = Double(ub.maxY - ub.minY + 1)
            let sizeRatio = min(uw / tw, tw / uw) * 0.5 + min(uh / th, th / uh) * 0.5
            let tcx = Double(tb.minX + tb.maxX) / 2, tcy = Double(tb.minY + tb.maxY) / 2
            let ucx = Double(ub.minX + ub.maxX) / 2, ucy = Double(ub.minY + ub.maxY) / 2
            let dist = ((tcx - ucx) * (tcx - ucx) + (tcy - ucy) * (tcy - ucy)).squareRoot()
            let norm = max(tw, th)
            let centerScore = max(0, 1 - dist / (norm * 0.5))
            placement = max(0, min(1, sizeRatio * 0.6 + centerScore * 0.4))
        }

        let strokeDelta = expectedStrokes.map { abs($0 - strokesDrawn) } ?? 0
        let strokePenalty = min(15, strokeDelta * 5)

        let raw = coverage * 55 + precision * 30 + placement * 15 - Double(strokePenalty)
        let total = Int(max(0, min(100, raw.rounded())))
        return InkScore(coverage: coverage, precision: precision, placement: placement, strokeDelta: strokeDelta, total: total)
    }
}
