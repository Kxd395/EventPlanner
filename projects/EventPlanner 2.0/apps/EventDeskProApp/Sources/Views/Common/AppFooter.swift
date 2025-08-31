import SwiftUI

struct AppFooter: View {
    let version: String
    var apiLatencyMs: Int? = nil
    var body: some View {
        let items: [AnyView] = [
            AnyView(Text("© 2025 EventDeskPro")),
            AnyView(Text("v\(version)")),
            AnyView(Text("Keyboard: ?")),
            AnyView(Text("API: \(apiLatencyMs != nil ? "OK (\(apiLatencyMs!)ms)" : "OK")"))
        ]

        let cols = [GridItem(.adaptive(minimum: 160), spacing: 12)]

        LazyVGrid(columns: cols, alignment: .center, spacing: 4) {
            ForEach(items.indices, id: \.self) { idx in
                HStack(spacing: 8) {
                    items[idx]
                    Spacer(minLength: 8)
                }
                .padding(.vertical, 4)
            }
        }
        .font(.footnote)
        .foregroundColor(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 28, idealHeight: 28, maxHeight: 44)
        .background(Color.clear)
    }
}

