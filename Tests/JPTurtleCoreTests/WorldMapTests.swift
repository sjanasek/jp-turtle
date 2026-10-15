import XCTest
@testable import JPTurtleCore

final class WorldMapTests: XCTestCase {
    func testRoutePassesThroughEveryRegionAnchor() {
        for (i, region) in World.regions.enumerated() {
            let p = WorldMap.point(atFraction: WorldMap.fraction(of: region.id))
            XCTAssertLessThan(p.distance(to: WorldMap.anchor(index: i)), 0.001, region.title)
        }
    }

    func testFractionsIncreaseFromZeroToOne() {
        let fractions = World.regions.map { WorldMap.fraction(of: $0.id) }
        XCTAssertEqual(fractions.first ?? -1, 0, accuracy: 1e-9)
        XCTAssertEqual(fractions.last ?? -1, 1, accuracy: 1e-9)
        for (a, b) in zip(fractions, fractions.dropFirst()) {
            XCTAssertLessThan(a, b)
        }
    }

    func testPointClampsOutsideRange() {
        XCTAssertEqual(WorldMap.point(atFraction: -1), WorldMap.anchor(index: 0))
        XCTAssertEqual(WorldMap.point(atFraction: 2), WorldMap.anchor(index: World.regions.count - 1))
    }

    func testRouteStaysOnMap() {
        for p in WorldMap.route {
            XCTAssertGreaterThan(p.x, 0.05)
            XCTAssertLessThan(p.x, 0.95)
            XCTAssertGreaterThan(p.y, 0)
            XCTAssertLessThan(p.y, WorldMap.height)
        }
    }

    func testSceneryFitsInsideMapAndBesideRoute() {
        let half = WorldMap.scenerySize / 2
        for i in World.regions.indices {
            let c = WorldMap.sceneryCenter(index: i)
            XCTAssertGreaterThanOrEqual(c.x - half, 0)
            XCTAssertLessThanOrEqual(c.x + half, 1)
            // Kame steht neben der Landschaft, nicht mitten drin
            XCTAssertGreaterThan(abs(WorldMap.anchor(index: i).x - c.x), half)
        }
    }

    func testZigZagAlternatesSides() {
        XCTAssertLessThan(WorldMap.anchor(index: 0).x, 0.5)
        XCTAssertGreaterThan(WorldMap.anchor(index: 1).x, 0.5)
        XCTAssertLessThan(WorldMap.anchor(index: 2).x, 0.5)
    }
}
