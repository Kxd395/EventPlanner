import SwiftUI
import EventDeskCoreBindings

struct QuickMemberPopover: View {
    let attendee: EDPCore.AttendeeDTO
    @State private var profile: EDPCore.MemberProfile? = nil
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var company: String = ""
    @State private var tags: String = ""
    @State private var error: String? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Member Profile").font(.headline)
                Spacer()
                Button("Save & Close") { saveAndClose() }
                    .keyboardShortcut("s", modifiers: [.command])
                Button(action: { dismiss() }) { Image(systemName: "xmark") }
                    .keyboardShortcut(.cancelAction)
            }
            if let e = error { ErrorStateView(message: e) }

            GroupBox(label: Text("Contact (Global)")) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text("Name:"); TextField("First", text: $firstName); TextField("Last", text: $lastName) }
                    HStack { Text("Email:"); TextField("Email", text: $email) }
                    HStack { Text("Phone:"); TextField("Phone", text: $phone); Text("Company:"); TextField("Company", text: $company) }
                    HStack { Text("Tags:"); TextField("Comma‑separated", text: $tags) }
                }
            }

            GroupBox(label: Text("Participation (This Event)")) {
                HStack(spacing: 8) {
                    Button("Pre‑Registered") { setStatus("preregistered") }
                    Button("Walk‑in") { setStatus("walkin") }
                    Button("Checked‑In") { setStatus("checkedin") }
                    Button("DNA") { setStatus("dna") }
                }.buttonStyle(.bordered)
            }

            GroupBox(label: Text("Recent Events (\(profile?.events.count ?? 0))")) {
                if let p = profile {
                    ForEach(p.events, id: \.self) { row in
                        HStack { Text(row.first ?? "-"); Spacer(); Text(row.count>1 ? row[1] : "").foregroundColor(.secondary).font(.caption) }
                    }
                } else { Text("Loading…").foregroundColor(.secondary) }
            }

            HStack { Spacer(); Button("Save & Close") { saveAndClose() } }
        }
        .padding(12)
        .frame(minWidth: 520)
        .onAppear(perform: load)
    }

    private func load() {
        if let p = EDPCore.shared.memberProfile(memberId: attendee.memberId) {
            profile = p; firstName = p.firstName; lastName = p.lastName; email = p.email ?? ""; company = p.company ?? ""
        }
    }

    private func saveAndClose() {
        let ok = EDPCore.shared.updateMember(id: attendee.memberId, email: email, firstName: firstName, lastName: lastName, phone: phone, company: company, tags: tags, notes: nil)
        if !ok { error = EDPCore.shared.lastError() ?? "Save failed" } else { dismiss() }
    }

    private func setStatus(_ code: String) {
        do {
            let _ = try EDPCore.shared.updateStatus(attendanceId: attendee.attendeeId, newStatus: code, inProgress: true, override: false, reason: nil, changedBy: "ui_quick")
        } catch {
            self.error = EDPCore.shared.lastError() ?? "Status update failed"
        }
    }
}
