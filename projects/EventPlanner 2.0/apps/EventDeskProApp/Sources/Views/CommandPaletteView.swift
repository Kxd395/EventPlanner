import SwiftUI

struct CommandPaletteView: View {
    @Environment(\.dismiss) private var dismiss
    enum Command: String, CaseIterable, Identifiable { case newEvent = "New Event", importCSV = "Import CSV", exportCSV = "Export CSV", walkIn = "Walk-in", search = "Focus Search"; var id: String { rawValue } }
    @State private var query: String = ""
    var onAction: (Command) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Command Palette").font(.headline)
            TextField("Type a command…", text: $query)
                .textFieldStyle(.roundedBorder)
            List(filtered, id: \.id) { cmd in
                Button(cmd.rawValue) { onAction(cmd); dismiss() }
            }
            HStack { Spacer(); Button("Close") { dismiss() }.keyboardShortcut(.cancelAction) }
        }
        .padding(16)
    }

    private var filtered: [Command] {
        let all = Command.allCases
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return all }
        return all.filter { $0.rawValue.lowercased().contains(query.lowercased()) }
    }
}
