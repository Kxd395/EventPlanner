import SwiftUI

struct AppHeader: View {
    let title: String
    var onNewEvent: (() -> Void)? = nil
    var onOpenSettings: (() -> Void)? = nil
    var onShowShortcuts: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title).font(.title2).bold()
            Spacer()
            Button(action: { onNewEvent?() }) { Label("New Event", systemImage: "plus") }
            Button(action: { onOpenSettings?() }) { Label("Settings", systemImage: "gear") }
            Button(action: { onShowShortcuts?() }) { Label("Keyboard", systemImage: "questionmark.circle") }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
    }
}

