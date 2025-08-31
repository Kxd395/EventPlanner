import SwiftUI
import EventDeskCoreBindings

struct AddAttendeeSheet: View {
    let eventId: String
    var onDone: (() -> Void)? = nil

    @State private var query: String = ""
    @State private var results: [EDPCore.MemberDTO] = []
    @State private var suggestion: EDPCore.MemberDTO? = nil
    @State private var newFirst: String = ""
    @State private var newLast: String = ""
    @State private var newEmail: String = ""
    @State private var newPhone: String = ""
    @State private var newCompany: String = ""
    @State private var initialStatus: String = "preregistered"
    @State private var sendConfirmation: Bool = false
    @State private var addToGlobalMembers: Bool = true
    @State private var vip: Bool = false
    @State private var tagsInput: String = ""
    @State private var duplicateWarning: String? = nil
    @State private var error: String? = nil
    @State private var loading: Bool = false
    @State private var showProfile: Bool = false
    @State private var profileMemberId: String? = nil
    @FocusState private var focused: Field?
    enum Field { case query, newFirst, newEmail }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Add Attendee").font(.title3).bold()
            if let e = error { ErrorStateView(message: e) }

            GroupBox(label: Text("Search Existing Members")) {
                HStack(spacing: 8) {
                    TextField("email or name or phone…", text: $query)
                        .textFieldStyle(.roundedBorder)
                        .focused($focused, equals: .query)
                    Button("Search", action: search)
                    Button("Clear") { query = ""; results = [] }
                }
                if !results.isEmpty {
                    List(results, id: \.id) { m in
                        HStack {
                            Text("\(m.firstName) \(m.lastName)")
                            if let email = m.email { Text(email).foregroundColor(.secondary) }
                            Spacer()
                            Button("Open Profile") { profileMemberId = m.id; showProfile = true }
                            Button("Select") { addExisting(email: m.email) }
                        }
                    }
                    .frame(minHeight: 120, maxHeight: 180)
                }
            }

            Divider()

            GroupBox(label: Text("Or Create New Member")) {
                HStack {
                    TextField("First Name", text: $newFirst)
                        .textFieldStyle(.roundedBorder)
                        .focused($focused, equals: .newFirst)
                    TextField("Last Name", text: $newLast).textFieldStyle(.roundedBorder)
                }
                HStack {
                    TextField("Email", text: $newEmail)
                        .textFieldStyle(.roundedBorder)
                        .focused($focused, equals: .newEmail)
                    TextField("Phone", text: $newPhone).textFieldStyle(.roundedBorder)
                }
                TextField("Company", text: $newCompany).textFieldStyle(.roundedBorder)
                HStack {
                    Text("Tags")
                    TextField("comma,separated,tags", text: $tagsInput)
                        .textFieldStyle(.roundedBorder)
                    Toggle("VIP ⭐", isOn: $vip)
                        .toggleStyle(.switch)
                }
                HStack {
                    Text("Initial Status:")
                    Picker("Status", selection: $initialStatus) {
                        Text("Pre-Registered").tag("preregistered")
                        Text("Walk-in").tag("walkin")
                        Text("Checked-In").tag("checkedin")
                    }.pickerStyle(.segmented)
                    Spacer()
                    Toggle("Send confirmation", isOn: $sendConfirmation)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Add to Global Member Database", isOn: $addToGlobalMembers)
                    Text("When off, attendee is added to this event only (no global record).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let warn = duplicateWarning {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(warn).font(.caption).foregroundColor(.orange)
                        if let s = suggestion {
                            HStack(spacing: 8) {
                                Text("Suggestion: \(s.firstName) \(s.lastName) \(s.company ?? "")").font(.caption)
                                Spacer()
                                Button("Open Profile") { profileMemberId = s.id; showProfile = true }
                            }
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel") { onDone?() }
                Button(loading ? "Adding…" : "Add Attendee") { addNew() }.disabled(loading || (newFirst.isEmpty && newLast.isEmpty && newEmail.isEmpty))
            }
        }
        .padding(16)
        .onChange(of: newEmail) { _ in duplicateWarning = nil; findSuggestion(from: newEmail) }
        .onChange(of: newLast) { _ in findSuggestion(from: newLast) }
        .onAppear { focused = .query }
        .frame(minWidth: 720)
        .sheet(isPresented: $showProfile) {
            if let id = profileMemberId {
                MemberProfileView(memberId: id)
            }
        }
    }

    private func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let res = try EDPCore.shared.searchMembers(query: query, limit: 20)
                DispatchQueue.main.async { results = res }
            } catch {
                DispatchQueue.main.async { self.error = "Search failed" }
            }
        }
    }

    private func addExisting(email: String?) {
        guard let email = email, !email.isEmpty else { self.error = "Member has no email"; return }
        // Use CSV commit path to honor SSOT + selected initial status
        let csv = "email,status\n\(email),\(initialStatus)\n"
        commitCSV(csv)
    }

    private func addNew() {
        // Build tags (inject vip tag if toggled)
        var tags = tagsInput
        if vip {
            let parts = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if !parts.contains(where: { $0.lowercased() == "vip" }) { tags = (tags.trimmingCharacters(in: .whitespaces).isEmpty ? "vip" : tags + ",vip") }
        }

        // Suggestion message for email reuse
        if !newEmail.isEmpty {
            DispatchQueue.global(qos: .userInitiated).async {
                let found = (try? EDPCore.shared.searchMembers(query: newEmail, limit: 1)) ?? []
                DispatchQueue.main.async { if !found.isEmpty { duplicateWarning = "Email already exists; record will be linked" } }
            }
        }

        // If adding to global members and we have an email, create or reuse member first to preserve tags/VIP
        if addToGlobalMembers, !newEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Check if exists
                    let existing = try? EDPCore.shared.searchMembers(query: newEmail, limit: 1)
                    if let ex = existing, let m = ex.first {
                        // Update tags/VIP on existing member if provided
                        if !tags.trimmingCharacters(in: .whitespaces).isEmpty || vip {
                            _ = EDPCore.shared.updateMember(id: m.id,
                                                            email: nil,
                                                            firstName: nil,
                                                            lastName: nil,
                                                            phone: nil,
                                                            company: nil,
                                                            tags: tags.trimmingCharacters(in: .whitespaces).isEmpty ? (vip ? "vip" : nil) : tags,
                                                            notes: nil)
                        }
                    } else {
                        _ = try EDPCore.shared.createMember(email: newEmail,
                                                            firstName: newFirst.isEmpty ? (newEmail.split(separator: "@").first.map(String.init) ?? "") : newFirst,
                                                            lastName: newLast,
                                                            phone: newPhone.isEmpty ? nil : newPhone,
                                                            company: newCompany.isEmpty ? nil : newCompany,
                                                            tags: tags.trimmingCharacters(in: .whitespaces).isEmpty ? nil : tags,
                                                            notes: nil)
                    }
                    // Now add to event via CSV link (by email)
                    let csv = "email,status\n\(newEmail),\(initialStatus)\n"
                    DispatchQueue.main.async { self.commitCSV(csv) }
                } catch {
                    DispatchQueue.main.async { self.error = EDPCore.shared.lastError() ?? "Create member failed" }
                }
            }
            return
        }

        // Default: add to event via CSV (this will also create a member in core if needed)
        let csv: String
        if !newEmail.isEmpty {
            csv = "email,firstname,lastname,company,status\n\(newEmail),\(newFirst),\(newLast),\(newCompany),\(initialStatus)\n"
        } else {
            csv = "firstname,lastname,company,status\n\(newFirst),\(newLast),\(newCompany),\(initialStatus)\n"
        }
        commitCSV(csv)
    }

    private func commitCSV(_ csv: String) {
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let outcome = try EDPCore.shared.csvCommit(eventId: eventId, csvText: csv)
                DispatchQueue.main.async {
                    loading = false
                    if outcome.rowsImported > 0 { onDone?() } else { error = "No rows imported (duplicates: \(outcome.duplicates))" }
                }
                Analytics.emit("attendee_status_change", payload: ["eventId": eventId, "newStatus": "\(initialStatus)", "count": outcome.rowsImported])
                NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": eventId])
            } catch {
                DispatchQueue.main.async { loading = false; self.error = EDPCore.shared.lastError() ?? "Add failed" }
            }
        }
    }

    private func findSuggestion(from text: String) {
        let q = text.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { suggestion = nil; duplicateWarning = nil; return }
        DispatchQueue.global(qos: .userInitiated).async {
            let res = (try? EDPCore.shared.searchMembers(query: q, limit: 1)) ?? []
            DispatchQueue.main.async {
                if let first = res.first {
                    suggestion = first
                    duplicateWarning = "Possible match: \"\(q)\" exists in member database"
                } else {
                    suggestion = nil
                    if duplicateWarning?.contains("Possible match") == true { duplicateWarning = nil }
                }
            }
        }
    }
}
