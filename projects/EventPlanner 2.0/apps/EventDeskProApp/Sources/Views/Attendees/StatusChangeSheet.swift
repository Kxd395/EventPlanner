import SwiftUI
import EventDeskCoreBindings

struct StatusChangeSheet: View {
    let current: String?
    @Binding var newStatus: String
    let event: EDPCore.EventDTO
    var onConfirm: (_ reason: String?, _ override: Bool) -> Void

    @State private var needsReason = false
    @State private var needsOverride = false
    @State private var reason: String = ""
    @State private var override = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Change Status").font(.headline)
            Picker("New Status", selection: $newStatus) {
                Text("Pre-Registered").tag("preregistered")
                Text("Walk-in").tag("walkin")
                Text("Checked-In").tag("checkedin")
                Text("DNA").tag("dna")
            }
            .pickerStyle(.segmented)

            if needsReason {
                TextField("Reason (required)", text: $reason).textFieldStyle(.roundedBorder)
            }
            if needsOverride {
                Toggle("Manager Override", isOn: $override)
            }

            HStack { Spacer(); Button("Cancel") { dismiss() }; Button("Confirm") { onConfirm(needsReason ? reason : nil, override); dismiss() }.keyboardShortcut(.defaultAction).disabled(needsReason && reason.trimmingCharacters(in: .whitespaces).isEmpty) }
        }
        .padding(16)
        .onAppear(perform: recompute)
        .onChange(of: newStatus) { _ in recompute() }
    }

    private func recompute() {
        guard let cur = current else { needsReason = false; needsOverride = false; return }
        do {
            let check = try EDPCore.shared.validateTransition(current: cur, new: newStatus, inProgress: isEventInProgress(event: event), override: override)
            needsReason = (check == 1)
            needsOverride = (check == 2)
        } catch {
            needsReason = false; needsOverride = false
        }
    }

    private func isEventInProgress(event: EDPCore.EventDTO) -> Bool {
        let fmt = ISO8601DateFormatter()
        guard let start = fmt.date(from: event.startsAt), let end = fmt.date(from: event.endsAt) else { return true }
        let now = Date(); return now >= start && now <= end
    }
}
