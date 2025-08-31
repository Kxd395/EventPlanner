import Foundation
#if os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure app activation policy and bring windows to front so keyboard events route correctly.
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            for window in NSApp.windows {
                window.level = .floating
                window.makeKeyAndOrderFront(nil)
            }
            // Restore normal level after brief elevation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                for window in NSApp.windows { window.level = .normal }
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
#endif
