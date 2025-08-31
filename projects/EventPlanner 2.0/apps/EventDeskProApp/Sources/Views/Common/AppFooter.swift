import SwiftUI

struct AppFooter: View {
    let version: String
    var apiLatencyMs: Int? = nil
    var body: some View {
        HStack(spacing: 16) {
            Text("© 2025 EventDeskPro")
            Divider()
            Text("v\(version)")
            Divider()
            Text("Keyboard: ?")
            Divider()
            Text("API: \(apiLatencyMs != nil ? "OK (\(apiLatencyMs!)ms)" : "OK")")
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

