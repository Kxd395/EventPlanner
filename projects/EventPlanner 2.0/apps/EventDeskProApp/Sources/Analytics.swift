import Foundation
import EventDeskCoreBindings

enum Analytics {
    static func emit(_ name: String, payload: [String: Any] = [:], context: [String: Any] = [:]) {
        var obj: [String: Any] = [
            "name": name,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        if !payload.isEmpty { obj["payload"] = payload }
        if !context.isEmpty { obj["context"] = context }
        guard let data = try? JSONSerialization.data(withJSONObject: obj), let json = String(data: data, encoding: .utf8) else { return }
        do { try EDPCore.shared.analyticsEmit(json) } catch { /* ignore for UI */ }
    }
}

