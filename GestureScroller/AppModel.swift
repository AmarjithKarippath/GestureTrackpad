import AppKit
import Combine
import CoreVideo
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    let settings = SettingsStore()
    let permissions = PermissionManager()

    @Published var frame: CGImage?
    @Published var landmarks: HandLandmarks?
    @Published var currentGesture: GestureKind = .idle
    @Published var frontmost: FrontmostApp?
    @Published var lastActionNote: String = "Waiting for a browser"

    var menuBarSymbol: String {
        if settings.isPaused { return "pause.circle" }
        if currentGesture.isActive { return "hand.draw.fill" }
        return "hand.draw"
    }

    private let camera = CameraManager()
    private let handTracker = HandTracker()
    private let gestureRecognizer = GestureRecognizer()
    private var cancellables = Set<AnyCancellable>()

    init() {
        camera.onFrame = { [weak self] buffer, image in
            Task { @MainActor in
                self?.handleFrame(buffer: buffer, image: image)
            }
        }

        settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        permissions.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        settings.$cameraEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.syncCamera(enabled: enabled)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.permissions.refresh()
            }
            .store(in: &cancellables)
    }

    func start() {
        permissions.refresh()
        syncCamera(enabled: settings.cameraEnabled)
    }

    func togglePause() {
        settings.isPaused.toggle()
    }

    func toggleCamera() {
        settings.cameraEnabled.toggle()
    }

    private func syncCamera(enabled: Bool) {
        if enabled, permissions.isCameraAuthorized {
            camera.start()
        } else {
            camera.stop()
            frame = nil
            landmarks = nil
            currentGesture = .idle
            gestureRecognizer.reset()
        }
    }

    private func handleFrame(buffer: CVPixelBuffer, image: CGImage?) {
        let detected = handTracker.detect(in: buffer)
        let settingsSnapshot = GestureSettings(
            scrollSensitivity: settings.scrollSensitivity,
            swipeThreshold: settings.swipeThreshold,
            scrollDeadZone: settings.scrollDeadZone
        )
        let gesture = gestureRecognizer.update(landmarks: detected, settings: settingsSnapshot)
        let frontmostApp = BrowserDetector.frontmost()

        frame = image
        landmarks = detected
        currentGesture = gesture
        frontmost = frontmostApp
        dispatchIfNeeded(gesture, frontmost: frontmostApp)
    }

    private func dispatchIfNeeded(_ gesture: GestureKind, frontmost: FrontmostApp?) {
        guard !settings.isPaused else {
            lastActionNote = "Paused"
            return
        }
        guard permissions.accessibilityTrusted else {
            lastActionNote = "Accessibility permission required"
            return
        }
        guard let frontmost, frontmost.isBrowser else {
            lastActionNote = frontmost.map { "Ignored — \($0.name) is not a browser" } ?? "No frontmost app"
            return
        }
        guard gesture.isActive else {
            lastActionNote = "Ready — \(frontmost.name)"
            return
        }

        BrowserActionDispatcher.perform(gesture, pageMode: settings.pageMode)
        lastActionNote = "\(gesture.label) → \(frontmost.name)"
    }
}
