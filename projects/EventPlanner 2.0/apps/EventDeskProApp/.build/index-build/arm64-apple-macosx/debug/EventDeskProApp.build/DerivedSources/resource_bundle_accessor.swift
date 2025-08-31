import Foundation

extension Foundation.Bundle {
    static let module: Bundle = {
        let mainPath = Bundle.main.bundleURL.appendingPathComponent("EventDeskProApp_EventDeskProApp.bundle").path
        let buildPath = "/Users/VScode_Projects/projects/EventPlanner 2.0/apps/EventDeskProApp/.build/index-build/arm64-apple-macosx/debug/EventDeskProApp_EventDeskProApp.bundle"

        let preferredBundle = Bundle(path: mainPath)

        guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
            // Users can write a function called fatalError themselves, we should be resilient against that.
            Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
        }

        return bundle
    }()
}