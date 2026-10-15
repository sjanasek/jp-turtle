import Foundation

/// Punkt auf der Abenteuerkarte. Einheit: Kartenbreite = 1 (x von 0 bis 1, y von 0 bis `WorldMap.height`).
public struct MapPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func distance(to other: MapPoint) -> Double {
        ((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)).squareRoot()
    }
}

/// Geometrie der Abenteuerkarte „Kames Welt“, plattformunabhängig und testbar.
///
/// Die Gebiete liegen im Zickzack untereinander (links, rechts, links ...). Ein Weg
/// (Catmull-Rom-Spline durch die Ankerpunkte) verbindet sie; Kame läuft auf diesem Weg.
/// Neben jedem Ankerpunkt steht die Landschaft des Gebiets, darunter sein Schild und
/// die freigeschalteten Items.
public enum WorldMap {
    public enum Side: Sendable { case left, right }

    public static let spacing = 0.52
    public static let topMargin = 0.26
    public static let bottomMargin = 0.38
    /// Kantenlänge einer Gebietslandschaft (in Kartenbreiten).
    public static let scenerySize = 0.27
    public static let samplesPerSegment = 24

    public static var height: Double {
        topMargin + Double(max(0, World.regions.count - 1)) * spacing + bottomMargin
    }

    public static func side(ofIndex index: Int) -> Side {
        index % 2 == 0 ? .left : .right
    }

    /// Punkt auf dem Weg, an dem Kame im Gebiet steht.
    public static func anchor(index: Int) -> MapPoint {
        MapPoint(x: side(ofIndex: index) == .left ? 0.36 : 0.64, y: topMargin + Double(index) * spacing)
    }

    /// Mittelpunkt der Landschaft (neben dem Weg, zum Rand hin).
    public static func sceneryCenter(index: Int) -> MapPoint {
        let a = anchor(index: index)
        return MapPoint(x: side(ofIndex: index) == .left ? 0.17 : 0.83, y: a.y - 0.04)
    }

    /// Mittelpunkt des Namensschilds unter der Landschaft.
    public static func plaqueCenter(index: Int) -> MapPoint {
        MapPoint(x: sceneryCenter(index: index).x, y: anchor(index: index).y + 0.11)
    }

    /// Mittelpunkt der Item-Reihe unter dem Schild.
    public static func itemsCenter(index: Int) -> MapPoint {
        MapPoint(x: sceneryCenter(index: index).x, y: anchor(index: index).y + 0.2)
    }

    public static func index(of regionID: String) -> Int? {
        World.regions.firstIndex { $0.id == regionID }
    }

    // MARK: Weg

    /// Der Weg als fein abgetastete Linie (Catmull-Rom durch alle Ankerpunkte).
    public static let route: [MapPoint] = buildRoute()

    /// Aufsummierte Weglänge bis zu jedem Punkt in `route`.
    private static let cumulative: [Double] = {
        var out: [Double] = [0]
        for i in 1..<max(1, route.count) {
            out.append(out[i - 1] + route[i].distance(to: route[i - 1]))
        }
        return out
    }()

    public static var length: Double { cumulative.last ?? 0 }

    /// Position eines Gebiets auf dem Weg als Anteil 0...1 der Gesamtlänge.
    public static func fraction(ofIndex index: Int) -> Double {
        guard length > 0 else { return 0 }
        let i = min(route.count - 1, max(0, index * samplesPerSegment))
        return cumulative[i] / length
    }

    public static func fraction(of regionID: String) -> Double {
        index(of: regionID).map(fraction(ofIndex:)) ?? 0
    }

    /// Punkt auf dem Weg bei Anteil `fraction` (0 = erstes Gebiet, 1 = letztes).
    public static func point(atFraction fraction: Double) -> MapPoint {
        guard route.count > 1, length > 0 else { return route.first ?? MapPoint(x: 0.5, y: 0) }
        let target = min(1, max(0, fraction)) * length
        var lo = 0
        var hi = cumulative.count - 1
        while hi - lo > 1 {
            let mid = (lo + hi) / 2
            if cumulative[mid] < target { lo = mid } else { hi = mid }
        }
        let segment = cumulative[hi] - cumulative[lo]
        let t = segment > 0 ? (target - cumulative[lo]) / segment : 0
        let a = route[lo], b = route[hi]
        return MapPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    /// Ob Kame beim Laufen von `from` nach `to` an dieser Stelle nach links schaut.
    public static func facesLeft(at fraction: Double, movingForward: Bool) -> Bool {
        let step = movingForward ? 0.003 : -0.003
        let here = point(atFraction: fraction)
        let next = point(atFraction: fraction + step)
        return next.x < here.x
    }

    private static func buildRoute() -> [MapPoint] {
        let anchors = (0..<World.regions.count).map(anchor(index:))
        guard anchors.count > 1 else { return anchors }
        var out: [MapPoint] = []
        for i in 0..<(anchors.count - 1) {
            let p0 = anchors[max(i - 1, 0)]
            let p1 = anchors[i]
            let p2 = anchors[i + 1]
            let p3 = anchors[min(i + 2, anchors.count - 1)]
            for s in 0..<samplesPerSegment {
                let t = Double(s) / Double(samplesPerSegment)
                out.append(catmullRom(p0, p1, p2, p3, t))
            }
        }
        out.append(anchors[anchors.count - 1])
        return out
    }

    private static func catmullRom(_ p0: MapPoint, _ p1: MapPoint, _ p2: MapPoint, _ p3: MapPoint, _ t: Double) -> MapPoint {
        let t2 = t * t, t3 = t2 * t
        func f(_ a: Double, _ b: Double, _ c: Double, _ d: Double) -> Double {
            0.5 * (2 * b + (-a + c) * t + (2 * a - 5 * b + 4 * c - d) * t2 + (-a + 3 * b - 3 * c + d) * t3)
        }
        return MapPoint(x: f(p0.x, p1.x, p2.x, p3.x), y: f(p0.y, p1.y, p2.y, p3.y))
    }
}
