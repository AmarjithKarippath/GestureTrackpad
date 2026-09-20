import Foundation
import SwiftUI

enum PageMode: String, CaseIterable, Identifiable {
    case pageKeys
    case backForward

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pageKeys: return "Page Up / Page Down"
        case .backForward: return "Back / Forward"
        }
    }
}

final class SettingsStore: ObservableObject {
    @Published var scrollSensitivity: Double {
        didSet { UserDefaults.standard.set(scrollSensitivity, forKey: Keys.scrollSensitivity) }
    }

    @Published var swipeThreshold: Double {
        didSet { UserDefaults.standard.set(swipeThreshold, forKey: Keys.swipeThreshold) }
    }

    @Published var scrollDeadZone: Double {
        didSet { UserDefaults.standard.set(scrollDeadZone, forKey: Keys.scrollDeadZone) }
    }

    @Published var pageMode: PageMode {
        didSet { UserDefaults.standard.set(pageMode.rawValue, forKey: Keys.pageMode) }
    }

    @Published var isPaused: Bool {
        didSet { UserDefaults.standard.set(isPaused, forKey: Keys.isPaused) }
    }

    @Published var cameraEnabled: Bool {
        didSet { UserDefaults.standard.set(cameraEnabled, forKey: Keys.cameraEnabled) }
    }

    init() {
        let defaults = UserDefaults.standard
        scrollSensitivity = defaults.object(forKey: Keys.scrollSensitivity) as? Double ?? 1.0
        swipeThreshold = defaults.object(forKey: Keys.swipeThreshold) as? Double ?? 0.18
        scrollDeadZone = defaults.object(forKey: Keys.scrollDeadZone) as? Double ?? 0.04
        pageMode = PageMode(rawValue: defaults.string(forKey: Keys.pageMode) ?? "") ?? .pageKeys
        isPaused = defaults.bool(forKey: Keys.isPaused)
        cameraEnabled = defaults.object(forKey: Keys.cameraEnabled) as? Bool ?? true
    }

    private enum Keys {
        static let scrollSensitivity = "scrollSensitivity"
        static let swipeThreshold = "swipeThreshold"
        static let scrollDeadZone = "scrollDeadZone"
        static let pageMode = "pageMode"
        static let isPaused = "isPaused"
        static let cameraEnabled = "cameraEnabled"
    }
}
