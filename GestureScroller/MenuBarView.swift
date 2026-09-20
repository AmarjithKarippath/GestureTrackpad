import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(model.currentGesture.label)
            Text(model.lastActionNote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)

        Divider()

        Button(model.settings.isPaused ? "Resume Gestures" : "Pause Gestures") {
            model.togglePause()
        }

        Button(model.settings.cameraEnabled ? "Turn Camera Off" : "Turn Camera On") {
            model.toggleCamera()
        }

        Button("Open Preview…") {
            openWindow(id: "preview")
        }

        if !model.permissions.accessibilityTrusted {
            Button("Enable Accessibility…") {
                model.permissions.promptAccessibility()
                model.permissions.openAccessibilitySettings()
            }
        }

        Divider()

        Button("Quit Gesture Scroller") {
            NSApplication.shared.terminate(nil)
        }
    }
}
