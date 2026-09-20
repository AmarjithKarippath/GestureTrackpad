import SwiftUI

@main
struct GestureScrollerApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        Window("Gesture Scroller", id: "preview") {
            ContentView()
                .environmentObject(model)
                .onAppear { model.start() }
        }
        .defaultSize(width: 740, height: 680)

        MenuBarExtra("Gesture Scroller", systemImage: model.menuBarSymbol) {
            MenuBarView()
                .environmentObject(model)
        }
    }
}
