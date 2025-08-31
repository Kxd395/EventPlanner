import SwiftUI

struct AppFooter: View {
    let version: String
    var apiLatencyMs: Int? = nil
    var body: some View {
        HStack(spacing: 16) {
            Text("© 2025 EventDeskPro")
            Divider().frame(height: 16)
            Text("v\(version)")
            Divider().frame(height: 16)
            Text("Keyboard: ?")
            Divider().frame(height: 16)
            Text("API: \(apiLatencyMs != nil ? "OK (\(apiLatencyMs!)ms)" : "OK")")
            Spacer(minLength: 10)
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        // Constrain height so vertical Dividers don't stretch unexpectedly
        .frame(minHeight: 28, idealHeight: 28, maxHeight: 40)
    }
}

