import SwiftUI

struct ResetParticipationSheet: View {
    enum Option: String, CaseIterable, Identifiable { case preregistered, remove
        var id: String { rawValue }
        var title: String {
            switch self {
            case .preregistered: return "Set to Pre‑Registered"
            case .remove: return "Remove from this event"
            }
        }
    }

    let name: String
    var onConfirm: (_ option: Option, _ reason: String?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Option = .preregistered
    @State private var reason: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reset Participation — \(name)").font(.headline)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Option.allCases) { opt in
                    HStack {
                        Image(systemName: selected == opt ? "largecircle.fill.circle" : "circle")
                            .foregroundColor(.accentColor)
                        Text(opt.title)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { selected = opt }
                }
            }
            TextField("Reason (optional)", text: $reason)
                .textFieldStyle(.roundedBorder)
            Text("This action updates counts immediately and is auditable.")
                .font(.footnote)
                .foregroundColor(.secondary)
            HStack { Spacer(); Button("Cancel") { dismiss() }; Button("Reset") { onConfirm(selected, reason.isEmpty ? nil : reason); dismiss() }.keyboardShortcut(.defaultAction) }
        }
        .padding(16)
        .frame(minWidth: 440)
    }
}

