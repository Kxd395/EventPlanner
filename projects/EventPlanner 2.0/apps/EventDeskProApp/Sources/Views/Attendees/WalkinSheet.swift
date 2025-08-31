import SwiftUI
import EventDeskCoreBindings

struct WalkinSheet: View {
    let eventId: String
    var onDone: (_ result: (attendanceId: String, immediateCheckin: Bool)) -> Void

    @State private var name = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var company: String = ""
    @State private var immediateCheckin = false
    @State private var error: String? = nil
    @FocusState private var focused: Field?
    enum Field { case name, email }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Walk-in Registration").font(.headline)
            if let e = error { ErrorStateView(message: e) }
            HStack {
                TextField("Full Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused, equals: .name)
            }
            HStack {
                TextField("Email (optional)", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused, equals: .email)
                TextField("Phone (optional)", text: $phone).textFieldStyle(.roundedBorder)
            }
            TextField("Company (optional)", text: $company).textFieldStyle(.roundedBorder)
            Toggle("Immediate check-in", isOn: $immediateCheckin)
            HStack { Spacer(); Button("Cancel") { dismiss() }; Button("Register") { submit() }.keyboardShortcut(.defaultAction).disabled(name.trimmingCharacters(in: .whitespaces).isEmpty) }
        }
        .padding(16)
        .onAppear { focused = .name }
    }

    private func submit() {
        do {
            let res = try EDPCore.shared.createWalkin(eventId: eventId, name: name, email: email.isEmpty ? nil : email, phone: phone.isEmpty ? nil : phone, company: company.isEmpty ? nil : company, immediateCheckin: immediateCheckin, changedBy: "ui_walkin")
            Analytics.emit("walk_in_create", payload: ["eventId": eventId, "immediateCheckin": immediateCheckin])
            NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": eventId])
            onDone((res.attendanceId, immediateCheckin))
            dismiss()
        } catch {
            self.error = EDPCore.shared.lastError() ?? "Walk-in failed"
        }
    }
}
