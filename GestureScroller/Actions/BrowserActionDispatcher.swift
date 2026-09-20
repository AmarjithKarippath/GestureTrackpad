import CoreGraphics
import Foundation

enum BrowserActionDispatcher {
    private static let pageUpKey: CGKeyCode = 0x74
    private static let pageDownKey: CGKeyCode = 0x79
    private static let leftBracketKey: CGKeyCode = 0x21
    private static let rightBracketKey: CGKeyCode = 0x1E

    static func perform(_ gesture: GestureKind, pageMode: PageMode) {
        switch gesture {
        case .idle, .fist:
            return
        case .scrolling(let deltaY):
            scroll(deltaY: deltaY)
        case .swipeLeft:
            previousPage(pageMode: pageMode)
        case .swipeRight:
            nextPage(pageMode: pageMode)
        }
    }

    private static func scroll(deltaY: Double) {
        // Positive deltaY means the hand moved down → scroll the page down.
        let pixels = Int32((-deltaY * 48.0).clamped(to: -120...120))
        guard pixels != 0 else { return }
        let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: pixels,
            wheel2: 0,
            wheel3: 0
        )
        event?.post(tap: .cghidEventTap)
    }

    private static func previousPage(pageMode: PageMode) {
        switch pageMode {
        case .pageKeys:
            tap(pageUpKey)
        case .backForward:
            tap(leftBracketKey, flags: .maskCommand)
        }
    }

    private static func nextPage(pageMode: PageMode) {
        switch pageMode {
        case .pageKeys:
            tap(pageDownKey)
        case .backForward:
            tap(rightBracketKey, flags: .maskCommand)
        }
    }

    private static func tap(_ keyCode: CGKeyCode, flags: CGEventFlags = []) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
