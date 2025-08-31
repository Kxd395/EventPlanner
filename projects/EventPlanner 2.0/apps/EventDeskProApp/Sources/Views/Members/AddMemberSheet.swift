import SwiftUI
import EventDeskCoreBindings

struct AddMemberSheet: View {
    var onDone: ((_ memberId: String?) -> Void)? = nil

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var company: String = ""
    @State private var tags: String = ""
    @State private var notes: String = ""
    @State private var error: String? = nil
    @State private var creating = false
    @FocusState private var focused: Field?
    enum Field { case first, email }

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Member").font(.headline)
            if let e = error { ErrorStateView(message: e) }
            HStack {
                TextField("First Name", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused, equals: .first)
                TextField("Last Name", text: $lastName).textFieldStyle(.roundedBorder)
            }
            HStack {
                TextField("Email", text: $email).textFieldStyle(.roundedBorder).focused($focused, equals: .email)
                TextField("Phone", text: $phone).textFieldStyle(.roundedBorder)
            }
            HStack {
                TextField("Company", text: $company).textFieldStyle(.roundedBorder)
            }
            TextField("Tags (comma-separated)", text: $tags).textFieldStyle(.roundedBorder)
            TextField("Notes", text: $notes).textFieldStyle(.roundedBorder)
            HStack { Spacer(); Button("Cancel") { dismiss() }; Button(creating ? "Adding…" : "Add Member") { create() }.keyboardShortcut(.defaultAction).disabled(creating || !canSubmit) }
        }
        .padding(16)
        .frame(minWidth: 520)
        .onAppear { focused = .first }
    }

    private var canSubmit: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty || !email.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func create() {
        creating = true; self.error = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let id = try EDPCore.shared.createMember(email: email.isEmpty ? nil : email, firstName: firstName, lastName: lastName, phone: phone.isEmpty ? nil : phone, company: company.isEmpty ? nil : company, tags: tags.isEmpty ? nil : tags, notes: notes.isEmpty ? nil : notes)
                DispatchQueue.main.async { self.creating = false; onDone?(id); dismiss() }
            } catch {
                DispatchQueue.main.async { self.creating = false; self.error = EDPCore.shared.lastError() ?? "Failed to add member" }
            }
        }
    }
}
