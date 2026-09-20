import AVFoundation
import ApplicationServices
import AppKit
import Combine

@MainActor
final class PermissionManager: ObservableObject {
    @Published private(set) var cameraStatus: AVAuthorizationStatus
    @Published private(set) var accessibilityTrusted: Bool

    var isCameraAuthorized: Bool {
        cameraStatus == .authorized
    }

    init() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        accessibilityTrusted = AXIsProcessTrusted()
    }

    func refresh() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        accessibilityTrusted = AXIsProcessTrusted()
    }

    func requestCamera() async {
        _ = await AVCaptureDevice.requestAccess(for: .video)
        refresh()
    }

    func promptAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        accessibilityTrusted = AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        let candidates = [
            "x-apple.systemsettings:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systemsettings:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
    }

    func openCameraSettings() {
        let candidates = [
            "x-apple.systemsettings:com.apple.preference.security?Privacy_Camera",
            "x-apple.systemsettings:com.apple.settings.PrivacySecurity.extension?Privacy_Camera"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
