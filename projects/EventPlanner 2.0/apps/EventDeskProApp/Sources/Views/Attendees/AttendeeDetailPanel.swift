import SwiftUI
import EventDeskCoreBindings

struct AttendeeDetailPanel: View {
    let attendee: EDPCore.AttendeeDTO
    let event: EDPCore.EventDTO
    var onClose: (() -> Void)? = nil

    @State private var profile: EDPCore.MemberProfile? = nil
    @State private var newStatus: String = ""
    @State private var reason: String = ""
    @State private var override: Bool = false
    @State private var error: String? = nil
    @State private var needsReason = false
    @State private var needsOverride = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Attendee — \(attendee.name)").font(.headline)
                Spacer()
                Button(action: { onClose?() }) { Image(systemName: "xmark") }
                    .buttonStyle(.plain)
            }
            if let e = error { ErrorStateView(message: e) }
            GroupBox(label: Text("Contact (Global)")) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name: \(attendee.name)")
                    if let email = attendee.email { Text("Email: \(email)") }
                    if let company = attendee.company { Text("Company: \(company)") }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            GroupBox(label: Text("Participation (Event-specific)")) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Status:")
                        Picker("Status", selection: $newStatus) {
                            Text("Pre-Registered").tag("preregistered")
                            Text("Walk-in").tag("walkin")
                            Text("Checked-In").tag("checkedin")
                            Text("DNA").tag("dna")
                        }.pickerStyle(.segmented)
                    }
                    if needsReason { TextField("Reason (required)", text: $reason).textFieldStyle(.roundedBorder) }
                    if needsOverride { Toggle("Manager Override", isOn: $override) }
                    HStack {
                        Button("Remove from Event", role: .destructive) { _ = EDPCore.shared.removeAttendance(attendanceId: attendee.attendeeId, reason: "panel_remove", changedBy: "ui_panel"); onClose?() }
                        Spacer()
                        Button("Save Changes") { applyStatus() }
                    }
                }
            }
            Spacer()
        }
        .padding(12)
        .background(.thickMaterial)
        .onAppear { newStatus = attendee.status; recomputeGuards() }
        .onChange(of: newStatus) { _ in recomputeGuards() }
    }

    private func recomputeGuards() {
        do {
            let check = try EDPCore.shared.validateTransition(current: attendee.status, new: newStatus, inProgress: isEventInProgress(event: event), override: override)
            needsReason = (check == 1)
            needsOverride = (check == 2)
        } catch {
            needsReason = false; needsOverride = false
        }
    }

    private func applyStatus() {
        do {
            let _ = try EDPCore.shared.updateStatus(attendanceId: attendee.attendeeId, newStatus: newStatus, inProgress: isEventInProgress(event: event), override: override, reason: needsReason ? reason : nil, changedBy: "ui_panel")
            Analytics.emit("attendee_status_change", payload: ["eventId": attendee.eventId, "attendanceId": attendee.attendeeId, "newStatus": newStatus])
            NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": attendee.eventId])
            onClose?()
        } catch {
            self.error = EDPCore.shared.lastError() ?? "Failed to update"
        }
    }
}

private func isEventInProgress(event: EDPCore.EventDTO) -> Bool {
    let fmt = ISO8601DateFormatter()
    guard let start = fmt.date(from: event.startsAt), let end = fmt.date(from: event.endsAt) else { return true }
    let now = Date(); return now >= start && now <= end
}
