import AppKit

struct FrontmostApp {
    let bundleIdentifier: String
    let name: String
    let isBrowser: Bool
}

enum BrowserDetector {
    static let browserBundleIDs: Set<String> = [
        "com.apple.Safari",
        "com.apple.SafariTechnologyPreview",
        "com.google.Chrome",
        "com.google.Chrome.canary",
        "com.google.Chrome.dev",
        "org.mozilla.firefox",
        "org.mozilla.firefoxdeveloperedition",
        "company.thebrowser.Browser",
        "com.microsoft.edgemac",
        "com.brave.Browser"
    ]

    static func frontmost() -> FrontmostApp? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let bundleID = app.bundleIdentifier ?? ""
        return FrontmostApp(
            bundleIdentifier: bundleID,
            name: app.localizedName ?? "Unknown",
            isBrowser: browserBundleIDs.contains(bundleID)
        )
    }
}
