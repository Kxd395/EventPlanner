import SwiftUI
import EventDeskCoreBindings
#if os(macOS)
import AppKit
#endif

@main
struct EventDeskProApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    #endif
    @StateObject private var appState = AppState()
    @AppStorage("theme") private var theme: String = "system"

    init() {
        // Configure DB and analytics paths with overrides (no hardcoded absolute paths)
        let fm = FileManager.default
        let env = ProcessInfo.processInfo.environment
        let defaults = UserDefaults.standard
        let support = (try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)) ?? fm.temporaryDirectory
        let bundleDir = Bundle.main.bundleIdentifier ?? "EventDeskProApp"

        // Resolve paths in order: ENV -> UserDefaults -> AppSupport default
        let dbPath: String = env["EDP_DB_PATH"]
            ?? defaults.string(forKey: "dbPath")
            ?? support.appendingPathComponent("\(bundleDir)/eventdesk.db").path

        let analyticsPath: String = env["EDP_ANALYTICS_PATH"]
            ?? defaults.string(forKey: "analyticsPath")
            ?? support.appendingPathComponent("\(bundleDir)/analytics.jsonl").path

        // Ensure folder exists for file-backed paths
        let dbDir = URL(fileURLWithPath: dbPath).deletingLastPathComponent()
        try? fm.createDirectory(at: dbDir, withIntermediateDirectories: true)

        let analyticsDir = URL(fileURLWithPath: analyticsPath).deletingLastPathComponent()
        try? fm.createDirectory(at: analyticsDir, withIntermediateDirectories: true)

        _ = EDPCore.shared.setDatabase(path: dbPath)
        _ = EDPCore.shared.setAnalyticsPath(analyticsPath)

        #if os(macOS)
        // Set application dock icon from bundled resource (fallback to provided absolute path)
        if let url = Bundle.module.url(forResource: "AppIcon", withExtension: "png"),
           let img = NSImage(contentsOf: url) {
            NSApplication.shared.applicationIconImage = img
        } else {
            let fallback = "/Users/VScode_Projects/projects/EventPlanner 2.0/docs/reviews/Gemini_Generated_Image_dciv5mdciv5mdciv.png"
            if let img = NSImage(contentsOfFile: fallback) {
                NSApplication.shared.applicationIconImage = img
            }
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(theme == "dark" ? .dark : (theme == "light" ? .light : nil))
        }
    }
}

final class AppState: ObservableObject {
    @Published var version: String = EDPCore.shared.version
}
