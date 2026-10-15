#if os(iOS)
import SwiftUI
import JPTurtleCore

/// Kames Welt als Abenteuerkarte: Ein Weg schlängelt sich von Gebiet zu Gebiet,
/// Kame läuft beim Antippen dorthin. Gebiete im Nebel sind noch gesperrt.
struct WorldView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("kameRegionID") private var kameRegionID = "pond"

    @State private var kameProgress: Double = 0
    @State private var facingLeft = false
    @State private var walking = false
    @State private var selected: WorldRegion?
    @State private var openRegion: WorldRegion?
    @State private var session: ReviewSession?

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let width = geo.size.width
                ScrollViewReader { proxy in
                    ScrollView {
                        ZStack(alignment: .topLeading) {
                            MapBackground(reachedFraction: reachedFraction)

                            ForEach(Array(World.regions.enumerated()), id: \.element.id) { index, region in
                                RegionNode(
                                    region: region,
                                    index: index,
                                    width: width,
                                    cards: model.cards,
                                    writingBest: model.progress.writingBest,
                                    open: World.isOpen(region, cards: model.cards),
                                    worldUnlocked: model.worldUnlocked,
                                    onTap: { tap(region, proxy: proxy) }
                                )
                            }

                            // Unsichtbare Sprungmarken für das automatische Scrollen.
                            ForEach(Array(World.regions.enumerated()), id: \.element.id) { index, region in
                                let a = WorldMap.anchor(index: index)
                                Color.clear
                                    .frame(width: 1, height: 1)
                                    .id(region.id)
                                    .position(x: a.x * width, y: a.y * width)
                            }

                            KameSprite(stage: model.progress.stage, walking: walking, facingLeft: facingLeft, size: width * 0.11)
                                .modifier(FollowRoute(progress: kameProgress, width: width))
                                .allowsHitTesting(false)
                        }
                        .frame(width: width, height: width * WorldMap.height)
                    }
                    .onAppear { placeKame(proxy: proxy) }
                }
            }
            .background(MapPalette.grassTop)
            .overlay(alignment: .bottom) {
                if let region = selected, !walking {
                    RegionPopup(
                        region: region,
                        open: World.isOpen(region, cards: model.cards),
                        unlocked: World.unlockedCount(in: region, cards: model.cards),
                        missing: max(0, region.requires - model.worldUnlocked),
                        onEnter: { openRegion = region },
                        onLearn: { session = ReviewSession(words: model.makeRegionSession(region)) },
                        onClose: { selected = nil }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: selected)
            .navigationTitle("Kames Welt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(model.worldUnlocked)/\(model.worldTotal)", systemImage: "sparkles")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.monospacedDigit().bold())
                }
            }
            .navigationDestination(item: $openRegion) { region in
                RegionView(region: region)
            }
            .fullScreenCover(item: $session) { s in
                ReviewView(words: s.words)
            }
        }
    }

    /// Bis wohin der Weg schon begehbar ist (letztes offenes Gebiet).
    private var reachedFraction: Double {
        let lastOpen = World.regions.lastIndex { World.isOpen($0, cards: model.cards) } ?? 0
        return WorldMap.fraction(ofIndex: lastOpen)
    }

    private func placeKame(proxy: ScrollViewProxy) {
        let stored = World.region(id: kameRegionID).flatMap { World.isOpen($0, cards: model.cards) ? $0 : nil }
        let start = stored ?? model.currentRegion ?? World.regions[0]
        kameRegionID = start.id
        kameProgress = WorldMap.fraction(of: start.id)
        DispatchQueue.main.async {
            proxy.scrollTo(start.id, anchor: .center)
        }
    }

    private func tap(_ region: WorldRegion, proxy: ScrollViewProxy) {
        guard !walking else { return }
        guard World.isOpen(region, cards: model.cards) else {
            selected = region      // Nebel-Hinweis
            return
        }
        let target = WorldMap.fraction(of: region.id)
        guard abs(target - kameProgress) > 0.0005 else {
            selected = region
            return
        }
        let forward = target > kameProgress
        facingLeft = WorldMap.facesLeft(at: kameProgress, movingForward: forward)
        selected = nil
        walking = true
        let duration = min(3.2, max(0.7, abs(target - kameProgress) * 9))
        withAnimation(.easeInOut(duration: duration)) {
            proxy.scrollTo(region.id, anchor: .center)
        }
        withAnimation(.easeInOut(duration: duration)) {
            kameProgress = target
        } completion: {
            walking = false
            kameRegionID = region.id
            selected = region
            if model.progress.autoSpeak {
                SpeechService.shared.speak(region.reading)
            }
        }
    }
}

// MARK: - Kame auf dem Weg

/// Setzt eine Ansicht auf den Weg; animierbar, damit Kame entlang der Kurve läuft
/// statt quer übers Feld zu fliegen.
struct FollowRoute: ViewModifier, Animatable {
    var progress: Double
    let width: CGFloat

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let p = WorldMap.point(atFraction: progress)
        content.position(x: p.x * width, y: p.y * width - width * 0.03)
    }
}

struct KameSprite: View {
    let stage: TurtleStage
    let walking: Bool
    let facingLeft: Bool
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(paused: !walking)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let wiggle = walking ? sin(t * 16) : 0
            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.22))
                    .frame(width: size * 0.9, height: size * 0.22)
                    .offset(y: size * 0.42)
                Image(systemName: "tortoise.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundStyle(
                        LinearGradient(colors: [MapPalette.shellLight, MapPalette.shellDark], startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: .white.opacity(0.9), radius: 0, x: 0, y: -1)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
                    .scaleEffect(x: facingLeft ? -1 : 1, y: 1)
                    .rotationEffect(.degrees(wiggle * 5))
                    .offset(y: walking ? -abs(wiggle) * size * 0.08 : 0)
                if stage == .sensei {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: size * 0.32))
                        .foregroundStyle(.black)
                        .offset(x: facingLeft ? size * 0.28 : -size * 0.28, y: -size * 0.32)
                }
            }
        }
        .accessibilityLabel("Kame")
    }
}

// MARK: - Gebiet auf der Karte

struct RegionNode: View {
    let region: WorldRegion
    let index: Int
    let width: CGFloat
    let cards: [String: CardState]
    let writingBest: [String: Int]
    let open: Bool
    let worldUnlocked: Int
    let onTap: () -> Void

    var body: some View {
        let size = WorldMap.scenerySize * width
        let scenery = WorldMap.sceneryCenter(index: index)
        let plaque = WorldMap.plaqueCenter(index: index)
        let itemsAt = WorldMap.itemsCenter(index: index)
        let done = World.unlockedCount(in: region, cards: cards)
        let complete = done == region.items.count

        ZStack {
            RegionScenery(id: region.id, size: size)
                .frame(width: size, height: size)
                .saturation(open ? 1 : 0.1)
                .opacity(open ? 1 : 0.6)
                .overlay {
                    if !open { FogCloud(size: size) }
                }
                .overlay(alignment: .topTrailing) {
                    if complete {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: size * 0.16))
                            .foregroundStyle(MapPalette.gold)
                            .shadow(radius: 2)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
                .position(x: scenery.x * width, y: scenery.y * width)

            MapPlaque(
                title: open ? "\(region.title) \(region.japanese)" : "Im Nebel · \(region.japanese)",
                detail: open ? "\(done)/\(region.items.count)" : "noch \(max(0, region.requires - worldUnlocked))",
                locked: !open,
                accent: RegionStyle.of(region.id).accent
            )
            .onTapGesture(perform: onTap)
            .position(x: plaque.x * width, y: plaque.y * width)

            if open, done > 0 {
                ItemChips(
                    items: region.items.filter { World.isUnlocked($0.word, cards: cards) },
                    accent: RegionStyle.of(region.id).accent,
                    chip: width * 0.05
                )
                .onTapGesture(perform: onTap)
                .position(x: itemsAt.x * width, y: itemsAt.y * width)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(open ? "\(region.title), \(done) von \(region.items.count) Items" : "\(region.title), noch im Nebel")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
    }
}

struct MapPlaque: View {
    let title: String
    let detail: String
    let locked: Bool
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            if locked { Image(systemName: "lock.fill").font(.caption2) }
            Text(title).font(.caption.bold()).lineLimit(1)
            Text(detail)
                .font(.caption2.monospacedDigit().bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(locked ? Color.gray.opacity(0.25) : accent.opacity(0.18), in: Capsule())
        }
        .foregroundStyle(MapPalette.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(MapPalette.parchment, in: Capsule())
        .overlay(Capsule().strokeBorder(locked ? Color.gray.opacity(0.4) : accent.opacity(0.7), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
}

/// Freigeschaltete Items als kleine Plaketten (max. 10, danach „+N“).
struct ItemChips: View {
    let items: [WorldItem]
    let accent: Color
    let chip: CGFloat

    var body: some View {
        let shown = Array(items.prefix(10))
        let rows = stride(from: 0, to: shown.count, by: 5).map { Array(shown[$0..<min($0 + 5, shown.count)]) }
        VStack(spacing: chip * 0.25) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: chip * 0.25) {
                    ForEach(rows[r]) { item in
                        Image(systemName: item.symbol)
                            .font(.system(size: chip * 0.5))
                            .foregroundStyle(accent)
                            .frame(width: chip, height: chip)
                            .background(Color.white, in: Circle())
                            .overlay(Circle().strokeBorder(accent, lineWidth: 1.5))
                    }
                }
            }
            if items.count > shown.count {
                Text("+\(items.count - shown.count)")
                    .font(.caption2.bold())
                    .foregroundStyle(MapPalette.ink)
            }
        }
    }
}

struct FogCloud: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().frame(width: size * 0.6).offset(x: -size * 0.2, y: size * 0.05)
            Circle().frame(width: size * 0.7).offset(x: size * 0.15, y: -size * 0.05)
            Circle().frame(width: size * 0.55).offset(x: size * 0.05, y: size * 0.2)
            Circle().frame(width: size * 0.45).offset(x: -size * 0.3, y: -size * 0.15)
        }
        .foregroundStyle(Color.white.opacity(0.85))
        .blur(radius: size * 0.06)
        .overlay {
            Image(systemName: "cloud.fog.fill")
                .font(.system(size: size * 0.22))
                .foregroundStyle(Color.gray.opacity(0.7))
        }
        .allowsHitTesting(false)
    }
}

/// Karte unten beim Ankommen in einem Gebiet (oder beim Antippen eines Nebelgebiets).
struct RegionPopup: View {
    let region: WorldRegion
    let open: Bool
    let unlocked: Int
    let missing: Int
    let onEnter: () -> Void
    let onLearn: () -> Void
    let onClose: () -> Void

    var body: some View {
        let style = RegionStyle.of(region.id)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: open ? region.symbol : "cloud.fog.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(open ? AnyShapeStyle(style.gradient) : AnyShapeStyle(Color.gray), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 1) {
                    Text(open ? "\(region.title) \(region.japanese)" : "Im Nebel · \(region.japanese)").font(.headline)
                    Text(open ? region.tagline : "Noch \(missing) Items freischalten, dann lichtet sich der Nebel.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill").font(.title3).foregroundStyle(.secondary)
                }
                .accessibilityLabel("Schließen")
            }
            if open {
                ProgressView(value: Double(unlocked), total: Double(max(1, region.items.count))) {
                    Text("\(unlocked) von \(region.items.count) Items").font(.caption2)
                }
                .tint(style.accent)
                HStack(spacing: 10) {
                    Button(action: onLearn) {
                        Label("Hier lernen", systemImage: "play.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(style.accent, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                    Button(action: onEnter) {
                        Label("Gebiet ansehen", systemImage: "square.grid.3x3.fill")
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 11)
                            .background(Theme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(style.accent.opacity(0.6)))
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Hintergrund

enum MapPalette {
    static let grassTop = Color(red: 0.62, green: 0.82, blue: 0.48)
    static let grassBottom = Color(red: 0.48, green: 0.72, blue: 0.42)
    static let sand = Color(red: 0.96, green: 0.88, blue: 0.68)
    static let sandDark = Color(red: 0.78, green: 0.64, blue: 0.42)
    static let treeDark = Color(red: 0.20, green: 0.48, blue: 0.28)
    static let treeLight = Color(red: 0.32, green: 0.62, blue: 0.34)
    static let trunk = Color(red: 0.50, green: 0.34, blue: 0.20)
    static let parchment = Color(red: 1.0, green: 0.98, blue: 0.92)
    static let ink = Color(red: 0.16, green: 0.20, blue: 0.18)
    static let gold = Color(red: 0.96, green: 0.72, blue: 0.16)
    static let shellLight = Color(red: 0.42, green: 0.70, blue: 0.36)
    static let shellDark = Color(red: 0.20, green: 0.44, blue: 0.22)
}

/// Bäume, Büsche, Blumen und Steine abseits von Weg und Gebieten (fest verteilt).
enum MapDecor {
    struct Item {
        let point: MapPoint
        let kind: Int
        let scale: Double
    }

    static let items: [Item] = {
        var rng = SeededGenerator(seed: 2026)
        var out: [Item] = []
        var tries = 0
        while out.count < 80 && tries < 4000 {
            tries += 1
            let p = MapPoint(
                x: Double.random(in: 0.03...0.97, using: &rng),
                y: Double.random(in: 0.03...(WorldMap.height - 0.03), using: &rng)
            )
            if WorldMap.route.contains(where: { $0.distance(to: p) < 0.075 }) { continue }
            let blocked = World.regions.indices.contains { i in
                let c = WorldMap.sceneryCenter(index: i)
                let a = WorldMap.anchor(index: i)
                return abs(c.x - p.x) < 0.2 && p.y > c.y - 0.19 && p.y < a.y + 0.3
            }
            if blocked { continue }
            if out.contains(where: { $0.point.distance(to: p) < 0.06 }) { continue }
            out.append(Item(point: p, kind: Int.random(in: 0..<4, using: &rng), scale: Double.random(in: 0.8...1.25, using: &rng)))
        }
        return out
    }()
}

struct MapBackground: View {
    let reachedFraction: Double

    var body: some View {
        Canvas { ctx, size in
            let w = size.width
            func pt(_ p: MapPoint) -> CGPoint { CGPoint(x: p.x * w, y: p.y * w) }

            ctx.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    Gradient(colors: [MapPalette.grassTop, MapPalette.grassBottom]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: 0, y: size.height)
                )
            )

            // Helle Wiesenflecken
            for (i, d) in MapDecor.items.enumerated() where i % 5 == 0 {
                let c = pt(d.point)
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - w * 0.12, y: c.y - w * 0.05, width: w * 0.24, height: w * 0.1)),
                         with: .color(.white.opacity(0.12)))
            }

            for d in MapDecor.items {
                let c = pt(d.point)
                let s = w * 0.045 * d.scale
                switch d.kind {
                case 0: // Laubbaum
                    ctx.fill(Path(CGRect(x: c.x - s * 0.15, y: c.y, width: s * 0.3, height: s * 0.7)), with: .color(MapPalette.trunk))
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.7, y: c.y - s * 0.9, width: s * 1.4, height: s * 1.3)), with: .color(MapPalette.treeDark))
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.45, y: c.y - s * 0.85, width: s * 0.8, height: s * 0.7)), with: .color(MapPalette.treeLight))
                case 1: // Kiefer
                    var tri = Path()
                    tri.move(to: CGPoint(x: c.x, y: c.y - s * 1.2))
                    tri.addLine(to: CGPoint(x: c.x + s * 0.65, y: c.y + s * 0.4))
                    tri.addLine(to: CGPoint(x: c.x - s * 0.65, y: c.y + s * 0.4))
                    tri.closeSubpath()
                    ctx.fill(Path(CGRect(x: c.x - s * 0.12, y: c.y + s * 0.3, width: s * 0.24, height: s * 0.4)), with: .color(MapPalette.trunk))
                    ctx.fill(tri, with: .color(MapPalette.treeDark))
                case 2: // Busch
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.8, y: c.y - s * 0.4, width: s * 0.9, height: s * 0.7)), with: .color(MapPalette.treeLight))
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - s * 0.2, y: c.y - s * 0.5, width: s * 0.9, height: s * 0.8)), with: .color(MapPalette.treeDark))
                default: // Blumen
                    let colors: [Color] = [Color(red: 0.98, green: 0.62, blue: 0.72), .white, Color(red: 0.98, green: 0.85, blue: 0.35)]
                    for k in 0..<3 {
                        let dx = Double(k - 1) * s * 0.45
                        let dy = (k == 1 ? -s * 0.25 : 0)
                        ctx.fill(Path(ellipseIn: CGRect(x: c.x + dx - s * 0.15, y: c.y + dy - s * 0.15, width: s * 0.3, height: s * 0.3)),
                                 with: .color(colors[k]))
                    }
                }
            }

            // Der Weg
            var path = Path()
            if let first = WorldMap.route.first {
                path.move(to: pt(first))
                for p in WorldMap.route.dropFirst() { path.addLine(to: pt(p)) }
            }
            // Noch nicht begehbarer Teil: zarte Trittsteine
            ctx.stroke(path, with: .color(MapPalette.sandDark.opacity(0.45)),
                       style: StrokeStyle(lineWidth: w * 0.035, lineCap: .round, dash: [w * 0.001, w * 0.06]))
            // Begehbarer Teil: Sandweg mit Rand
            let reached = path.trimmedPath(from: 0, to: max(0.0001, reachedFraction))
            ctx.stroke(reached, with: .color(MapPalette.sandDark),
                       style: StrokeStyle(lineWidth: w * 0.075, lineCap: .round, lineJoin: .round))
            ctx.stroke(reached, with: .color(MapPalette.sand),
                       style: StrokeStyle(lineWidth: w * 0.058, lineCap: .round, lineJoin: .round))
            ctx.stroke(reached, with: .color(MapPalette.sandDark.opacity(0.35)),
                       style: StrokeStyle(lineWidth: w * 0.012, lineCap: .round, dash: [w * 0.001, w * 0.04]))
        }
    }
}
#endif
