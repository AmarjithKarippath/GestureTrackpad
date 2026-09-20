import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            permissionBanners
            CameraPreview(frame: model.frame, landmarks: model.landmarks)
                .frame(minHeight: 320)
            statusRow
            SettingsPanel(settings: model.settings)
        }
        .padding(20)
        .frame(minWidth: 680, minHeight: 620)
    }

    @ViewBuilder
    private var permissionBanners: some View {
        if !model.permissions.isCameraAuthorized {
            PermissionBanner(
                title: "Camera access is required",
                detail: "The app tracks your hand with the FaceTime camera. Nothing is uploaded.",
                buttonTitle: model.permissions.cameraStatus == .denied ? "Open Settings" : "Allow Camera"
            ) {
                Task {
                    if model.permissions.cameraStatus == .denied {
                        model.permissions.openCameraSettings()
                    } else {
                        await model.permissions.requestCamera()
                        if model.permissions.isCameraAuthorized {
                            model.settings.cameraEnabled = true
                            model.start()
                        }
                    }
                }
            }
        }

        if !model.permissions.accessibilityTrusted {
            PermissionBanner(
                title: "Accessibility access is required",
                detail: "macOS needs this so Gesture Scroller can scroll the frontmost browser.",
                buttonTitle: "Enable Accessibility"
            ) {
                model.permissions.promptAccessibility()
                model.permissions.openAccessibilitySettings()
            }
        }
    }

    private var statusRow: some View {
        HStack(spacing: 16) {
            StatusChip(title: "Gesture", value: model.currentGesture.label)
            StatusChip(title: "Target", value: model.frontmost.map { $0.isBrowser ? $0.name : "Not a browser" } ?? "—")
            StatusChip(title: "Action", value: model.lastActionNote)
            Spacer()
        }
    }

}

private struct SettingsPanel: View {
    @ObservedObject var settings: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Toggle("Camera", isOn: $settings.cameraEnabled)
                Toggle("Pause gestures", isOn: $settings.isPaused)
                Spacer()
            }

            labeledSlider("Scroll sensitivity", value: $settings.scrollSensitivity, range: 0.3...2.5)
            labeledSlider("Swipe distance", value: $settings.swipeThreshold, range: 0.08...0.40)
            labeledSlider("Scroll dead zone", value: $settings.scrollDeadZone, range: 0.01...0.12)

            Picker("Page turn", selection: $settings.pageMode) {
                ForEach(PageMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("Open palm + move up/down to scroll. Swipe left/right to turn the page. Close your fist to idle. Gestures only affect Safari, Chrome, Firefox, Arc, Edge, and Brave.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func labeledSlider(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(title)
                .frame(width: 140, alignment: .leading)
            Slider(value: value, in: range)
            Text(value.wrappedValue, format: .number.precision(.fractionLength(2)))
                .monospacedDigit()
                .frame(width: 44, alignment: .trailing)
        }
    }
}

private struct PermissionBanner: View {
    let title: String
    let detail: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Button(buttonTitle, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(.yellow.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct StatusChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
