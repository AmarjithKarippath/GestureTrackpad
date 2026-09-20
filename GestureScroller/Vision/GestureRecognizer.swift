import CoreGraphics
import Foundation
import Vision

enum GestureKind: Equatable {
    case idle
    case fist
    case scrolling(deltaY: Double)
    case swipeLeft
    case swipeRight

    var label: String {
        switch self {
        case .idle: return "Idle"
        case .fist: return "Fist (idle)"
        case .scrolling: return "Scrolling"
        case .swipeLeft: return "Previous page"
        case .swipeRight: return "Next page"
        }
    }

    var isActive: Bool {
        switch self {
        case .idle, .fist: return false
        default: return true
        }
    }
}

struct GestureSettings {
    var scrollSensitivity: Double
    var swipeThreshold: Double
    var scrollDeadZone: Double
}

final class GestureRecognizer {
    private struct Sample {
        let time: TimeInterval
        let palm: CGPoint
    }

    private var samples: [Sample] = []
    private var lastSwipeTime: TimeInterval = 0
    private var smoothedVelocityY: Double = 0
    private let swipeCooldown: TimeInterval = 0.6

    func reset() {
        samples.removeAll()
        smoothedVelocityY = 0
    }

    func update(landmarks: HandLandmarks?, now: TimeInterval = ProcessInfo.processInfo.systemUptime, settings: GestureSettings) -> GestureKind {
        guard let landmarks, let palm = landmarks.palmCenter, let wrist = landmarks.wrist else {
            reset()
            return .idle
        }

        samples.append(Sample(time: now, palm: palm))
        samples.removeAll { now - $0.time > 0.35 }

        let open = isOpenPalm(landmarks, wrist: wrist)
        if !open {
            smoothedVelocityY *= 0.4
            return .fist
        }

        if now - lastSwipeTime < swipeCooldown {
            return .idle
        }

        if let swipe = detectSwipe(now: now, settings: settings) {
            lastSwipeTime = now
            samples.removeAll()
            smoothedVelocityY = 0
            return swipe
        }

        return detectScroll(now: now, settings: settings)
    }

    private func isOpenPalm(_ landmarks: HandLandmarks, wrist: CGPoint) -> Bool {
        let fingers: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
            (.indexTip, .indexMCP),
            (.middleTip, .middleMCP),
            (.ringTip, .ringMCP),
            (.littleTip, .littleMCP)
        ]

        var extended = 0
        for (tipName, mcpName) in fingers {
            guard let tip = landmarks.point(tipName), let mcp = landmarks.point(mcpName) else { continue }
            if distance(tip, wrist) > distance(mcp, wrist) * 1.18 {
                extended += 1
            }
        }
        return extended >= 3
    }

    private func detectSwipe(now: TimeInterval, settings: GestureSettings) -> GestureKind? {
        let window = samples.filter { now - $0.time <= 0.22 }
        guard let first = window.first, let last = window.last, last.time - first.time >= 0.08 else {
            return nil
        }

        let dx = Double(last.palm.x - first.palm.x)
        let dy = Double(last.palm.y - first.palm.y)
        guard abs(dx) >= settings.swipeThreshold, abs(dx) > abs(dy) * 1.25 else {
            return nil
        }
        return dx < 0 ? .swipeLeft : .swipeRight
    }

    private func detectScroll(now: TimeInterval, settings: GestureSettings) -> GestureKind {
        let window = samples.filter { now - $0.time <= 0.12 }
        guard let first = window.first, let last = window.last else { return .idle }
        let dt = last.time - first.time
        guard dt >= 0.04 else { return .idle }

        let rawVelocityY = Double(last.palm.y - first.palm.y) / dt
        smoothedVelocityY = smoothedVelocityY * 0.55 + rawVelocityY * 0.45

        guard abs(smoothedVelocityY) >= settings.scrollDeadZone * 8 else {
            return .idle
        }

        let deltaY = smoothedVelocityY * settings.scrollSensitivity * 0.35
        return .scrolling(deltaY: deltaY)
    }

    private func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}
