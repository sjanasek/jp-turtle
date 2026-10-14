#if os(iOS)
import SwiftUI
import JPTurtleCore

@main
struct JPTurtleApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .onOpenURL { url in
                    model.handle(url: url)
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        // Widget könnte inzwischen Fortschritt verbucht haben.
                        model.reload()
                        model.refreshHanaGreeting()
                    case .background, .inactive:
                        model.refreshWidgets()
                    @unknown default:
                        break
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView(selection: $model.selectedTab) {
            HomeView()
                .tabItem { Label("Heute", systemImage: "sun.max") }
                .tag(AppModel.Tab.home)

            WritingDojoView()
                .tabItem { Label("Schreiben", systemImage: "pencil.and.scribble") }
                .tag(AppModel.Tab.writing)

            KanaDojoView()
                .tabItem { Label("Kana", systemImage: "character.ja") }
                .tag(AppModel.Tab.kana)

            FriendsView()
                .tabItem { Label("Hana & Kame", systemImage: "heart") }
                .tag(AppModel.Tab.friends)

            SettingsView()
                .tabItem { Label("Mehr", systemImage: "ellipsis.circle") }
                .tag(AppModel.Tab.more)
        }
        .tint(Theme.accent)
        .overlay(alignment: .top) {
            if let toast = model.toast {
                ToastView(toast: toast)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: model.toast)
    }
}
#endif
