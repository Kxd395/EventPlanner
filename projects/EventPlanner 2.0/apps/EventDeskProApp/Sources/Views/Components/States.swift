import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.title3).bold()
            if let subtitle { Text(subtitle).foregroundColor(.secondary) }
            if let actionTitle { Button(actionTitle) { action?() } }
        }
        .padding(24)
    }
}

struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
            Text(message).foregroundColor(.red)
            Spacer()
            if let retry { Button("Retry") { retry() } }
        }
        .padding(12)
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
    }
}

struct ToastView: View {
    let text: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    var body: some View {
        HStack(spacing: 8) {
            Text(text)
            if let actionTitle, let action {
                Button(actionTitle) { action() }
                    .buttonStyle(.borderless)
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .shadow(radius: 2)
    }
}
