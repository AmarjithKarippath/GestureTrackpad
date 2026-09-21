# Gesture Scroller

A macOS menu bar app that uses the webcam and Apple’s on-device Vision hand-pose API to scroll and turn pages in your browser.

Nothing is uploaded. Hand tracking runs locally.

## Demo
https://youtu.be/8bcMFJ1cs7w?si=fwpFd93PbUptjhLV

## Gestures

Bring a browser to the front, then:

| Gesture | Action |
| --- | --- |
| Open palm, move up or down | Scroll (speed follows your hand) |
| Swipe left | Previous page |
| Swipe right | Next page |
| Closed fist or no hand | Idle |

Page turns default to **Page Up / Page Down**. You can switch that to browser **Back / Forward** (`⌘[` / `⌘]`) in the preview window.

Gestures are ignored unless a supported browser is frontmost.

## Supported browsers

Safari, Safari Technology Preview, Chrome, Chrome Canary, Chrome Dev, Firefox, Firefox Developer Edition, Arc, Edge, and Brave.

## Requirements

- macOS 13 or later
- A camera (FaceTime camera is fine)
- Xcode 15 or later to build

## Permissions

On first launch, grant both:

1. **Camera** — tracks your hand
2. **Accessibility** — sends scroll and page-turn events into the frontmost browser

The preview window prompts for these if they are missing. You can also enable Accessibility from **System Settings → Privacy & Security → Accessibility**.

The app is not sandboxed. Accessibility cannot control other apps from a sandboxed target.

## Build and run

Open the project in Xcode:

```bash
open GestureScroller.xcodeproj
```

Select the **GestureScroller** scheme and press Run.

Or build from the command line:

```bash
xcodebuild -project GestureScroller.xcodeproj -scheme GestureScroller -configuration Debug build
```

## Using the app

- The **preview window** shows the live camera, a skeleton overlay, the current gesture, and sliders for scroll sensitivity, swipe distance, and dead zone.
- The **menu bar extra** shows the last gesture and lets you pause, turn the camera off, reopen the preview, or quit.

Tune the sliders if scrolling feels too jumpy or swipes fire too easily.

## How it works

Camera frames go through `VNDetectHumanHandPoseRequest`. A small rule-based classifier turns landmark motion into idle, scroll, or swipe. If Accessibility is trusted and the frontmost app is a browser, the app posts `CGEvent` scroll-wheel or key events.
