import SwiftUI
import EventDeskCoreBindings

struct AddToEventSheet: View {
    let memberIds: [String]
    var onDone: (() -> Void)? = nil

    @State private var events: [EDPCore.EventDTO] = []
    @State private var selectedEventId: String = ""
    @State private var status: String = "preregistered"
    @State private var resultMsg: String? = nil
    @State private var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add to Event").font(.headline)
            if let e = error { ErrorStateView(message: e) }
            Picker("Event", selection: $selectedEventId) {
                ForEach(events, id: \.id) { ev in Text(ev.name).tag(ev.id) }
            }
            .labelsHidden()
            Picker("Status", selection: $status) {
                Text("Pre-Registered").tag("preregistered")
                Text("Walk-in").tag("walkin")
            }.pickerStyle(.segmented)
            if let msg = resultMsg { Text(msg).foregroundColor(.secondary).font(.caption) }
            HStack { Spacer(); Button("Cancel") { onDone?() }; Button("Add") { add() }.disabled(selectedEventId.isEmpty) }
        }
        .padding(16)
        .frame(minWidth: 520)
        .onAppear(perform: load)
    }

    private func load() {
        do { events = try EDPCore.shared.listEvents(limit: 200, offset: 0); selectedEventId = events.first?.id ?? "" } catch { self.error = "Failed to load events" }
    }

    private func add() {
        // Build CSV of member emails (skip missing emails)
        var rows: [String] = ["email,status"]
        var added = 0
        for mid in memberIds {
            if let p = EDPCore.shared.memberProfile(memberId: mid), let email = p.email, !email.isEmpty {
                rows.append("\(email),\(status)")
                added += 1
            }
        }
        guard added > 0 else { resultMsg = "No members with email to add"; return }
        let csv = rows.joined(separator: "\n") + "\n"
        do {
            let outcome = try EDPCore.shared.csvCommit(eventId: selectedEventId, csvText: csv)
            resultMsg = "Imported: \(outcome.rowsImported)  Duplicates: \(outcome.duplicates)"
            Analytics.emit("csv_import_commit", payload: ["eventId": selectedEventId, "count": outcome.rowsImported])
            onDone?()
        } catch { self.error = EDPCore.shared.lastError() ?? "Add failed" }
    }
}
