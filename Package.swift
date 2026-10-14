// swift-tools-version: 6.0

import PackageDescription

// JP Turtle – spielerisch Japanisch lernen.
//
// Das Paket folgt den xtool-Konventionen (https://xtool.sh):
//   * genau ein Library-Produkt für die App selbst        -> "JPTurtle"
//   * ein weiteres Library-Produkt pro App-Extension      -> "JPTurtleWidget"
//   * ein gemeinsamer, Foundation-only Kern, den App und Widget teilen -> "JPTurtleCore"
//
// Welche Produkte App bzw. Extension sind, steht in xtool.yml.
let package = Package(
    name: "JPTurtle",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "JPTurtle",
            targets: ["JPTurtle"]
        ),
        .library(
            name: "JPTurtleWidget",
            targets: ["JPTurtleWidget"]
        ),
    ],
    targets: [
        // Vokabeln, Spaced Repetition, Fortschritt, gemeinsamer Speicher.
        // Bewusst ohne UIKit/SwiftUI, damit der Kern auch unter Linux
        // gebaut und getestet werden kann (`swift test`).
        .target(name: "JPTurtleCore"),

        // Die eigentliche iOS-App (SwiftUI).
        .target(
            name: "JPTurtle",
            dependencies: ["JPTurtleCore"]
        ),

        // WidgetKit-Extension: Sperrbildschirm- und Homescreen-Widgets.
        .target(
            name: "JPTurtleWidget",
            dependencies: ["JPTurtleCore"]
        ),

        .testTarget(
            name: "JPTurtleCoreTests",
            dependencies: ["JPTurtleCore"]
        ),
    ],
    swiftLanguageModes: [.v5]
)
