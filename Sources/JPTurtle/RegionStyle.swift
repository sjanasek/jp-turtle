#if os(iOS)
import SwiftUI

/// Farben je Gebiet von Kames Welt. Reine Darstellung, keine Logik.
struct RegionStyle {
    let accent: Color
    let secondary: Color

    var gradient: LinearGradient {
        LinearGradient(colors: [accent, secondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func of(_ id: String) -> RegionStyle {
        switch id {
        case "pond": return RegionStyle(accent: Color(red: 0.16, green: 0.52, blue: 0.72), secondary: Color(red: 0.35, green: 0.78, blue: 0.80))
        case "teahouse": return RegionStyle(accent: Color(red: 0.78, green: 0.40, blue: 0.20), secondary: Color(red: 0.95, green: 0.65, blue: 0.30))
        case "torii": return RegionStyle(accent: Color(red: 0.80, green: 0.22, blue: 0.20), secondary: Color(red: 0.95, green: 0.50, blue: 0.40))
        case "garden": return RegionStyle(accent: Color(red: 0.25, green: 0.58, blue: 0.30), secondary: Color(red: 0.62, green: 0.80, blue: 0.40))
        case "village": return RegionStyle(accent: Color(red: 0.55, green: 0.40, blue: 0.28), secondary: Color(red: 0.85, green: 0.72, blue: 0.52))
        case "mountain": return RegionStyle(accent: Color(red: 0.32, green: 0.40, blue: 0.58), secondary: Color(red: 0.62, green: 0.72, blue: 0.88))
        case "plaza": return RegionStyle(accent: Color(red: 0.55, green: 0.35, blue: 0.70), secondary: Color(red: 0.85, green: 0.55, blue: 0.80))
        case "shop": return RegionStyle(accent: Color(red: 0.80, green: 0.58, blue: 0.12), secondary: Color(red: 0.96, green: 0.80, blue: 0.35))
        case "sundial": return RegionStyle(accent: Color(red: 0.85, green: 0.62, blue: 0.10), secondary: Color(red: 0.98, green: 0.88, blue: 0.45))
        case "path": return RegionStyle(accent: Color(red: 0.30, green: 0.50, blue: 0.45), secondary: Color(red: 0.55, green: 0.78, blue: 0.62))
        default: return RegionStyle(accent: Color(red: 0.90, green: 0.45, blue: 0.55), secondary: Color(red: 0.98, green: 0.72, blue: 0.62))
        }
    }
}
#endif
