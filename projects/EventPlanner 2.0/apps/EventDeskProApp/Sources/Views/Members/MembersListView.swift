import SwiftUI
import EventDeskCoreBindings
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct MembersListView: View {
    @State private var query: String = ""
    @State private var results: [EDPCore.MemberDTO] = []
    @State private var selection = Set<String>()
    @State private var error: String? = nil
    @State private var showMerge = false
    @State private var showAddToEvent = false
    @State private var showAddMember = false
    @State private var toast: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Search members…", text: $query).textFieldStyle(.roundedBorder).frame(maxWidth: 320)
                Button("Search") { search() }
                Button("Clear") { query = ""; results = [] }
                Spacer()
                Menu {
                    // CSV (PII)
                    Menu("CSV") {
                        Button("Filtered") { export(.csv, .filtered) }
                        Button("Selected") { export(.csv, .selected) }
                        Button("All") { export(.csv, .all) }
                    }.disabled(!piiExportAllowed)
                    // JSON (PII)
                    Menu("JSON") {
                        Button("Filtered") { export(.json, .filtered) }
                        Button("Selected") { export(.json, .selected) }
                        Button("All") { export(.json, .all) }
                    }.disabled(!piiExportAllowed)
                    // Markdown
                    Menu("Markdown (.md)") {
                        Button("Filtered") { export(.md, .filtered) }
                        Button("Selected") { export(.md, .selected) }
                        Button("All") { export(.md, .all) }
                    }
                    // Plain text
                    Menu("Plain Text (.txt)") {
                        Button("Filtered") { export(.txt, .filtered) }
                        Button("Selected") { export(.txt, .selected) }
                        Button("All") { export(.txt, .all) }
                    }
                    Divider()
                    Menu("Import") {
                        Button("From Files…") { importMembersFromFiles() }
                    }
                } label: {
                    Label("Export/Import", systemImage: "square.and.arrow.down.on.square")
                }
                Button("+ Add Member") { showAddMember = true }
                Button("Add to Event") { showAddToEvent = true }.disabled(selection.isEmpty)
                Button("Merge Duplicates") { showMerge = true }.disabled(selection.count < 2)
            }
            if let e = error { ErrorStateView(message: e) }
            if results.isEmpty {
                EmptyStateView(title: "Global Member Database – Search to begin")
            } else {
                List(selection: $selection) {
                    Section {
                        ForEach(results, id: \.id) { m in
                            HStack {
                                Text("\(m.firstName) \(m.lastName)").frame(minWidth: 220, alignment: .leading)
                                Text(m.email ?? "").frame(minWidth: 240, alignment: .leading).foregroundColor(.secondary)
                                Text(m.company ?? "").frame(minWidth: 180, alignment: .leading).foregroundColor(.secondary)
                                MemberEventsCountView(memberId: m.id).frame(width: 100, alignment: .trailing)
                                Spacer()
                                Button("Profile") { openProfile(m.id) }
                            }
                        }
                    } header: {
                        HStack {
                            Text("Name").frame(minWidth: 220, alignment: .leading)
                            Text("Email").frame(minWidth: 240, alignment: .leading)
                            Text("Company").frame(minWidth: 180, alignment: .leading)
                            Text("Events").frame(width: 100, alignment: .trailing)
                            Spacer()
                        }.font(.caption).foregroundColor(.secondary)
                    }
        }
        .frame(maxHeight: .infinity)
            }
        }
    .padding(.horizontal, 16)
    .padding(.bottom, 8)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            HStack {
                Text("Pagination: « Prev | 1 | 2 | 3 | Next »  Rows per page: 25 ▼")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
        .sheet(isPresented: $showMerge) {
            MergeDuplicatesSheet(selection: Array(selection), members: results) { primary, duplicate in
                do {
                    _ = try EDPCore.shared.mergeMembers(primaryId: primary, duplicateId: duplicate)
                    showMerge = false
                    // Refresh search results
                    search()
                } catch { self.error = "Merge failed" }
            }
            .frame(minWidth: 520)
        }
        .sheet(isPresented: $showAddToEvent) {
            AddToEventSheet(memberIds: Array(selection)) {
                showAddToEvent = false
                // no refresh necessary
            }
        }
        .sheet(isPresented: $showAddMember) {
            AddMemberSheet { id in
                showAddMember = false
                toast = "Member added"
                if !query.isEmpty { search() }
            }
        }
        .overlay(alignment: .bottom) {
            if let t = toast {
                ToastView(text: t)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 3) { withAnimation { toast = nil } } }
            }
        }
    }

    private func search() {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do { results = try EDPCore.shared.searchMembers(query: query, limit: 50) } catch { self.error = "Search failed" }
    }

    private func openProfile(_ id: String) {
        // Could present MemberProfileView sheet from parent
        // Placeholder: fetch to warm cache
        _ = EDPCore.shared.memberProfile(memberId: id)
    }

    // MARK: - Export/Import helpers
    @AppStorage("piiExportAllowed") private var piiExportAllowed: Bool = true
    private enum ExportFormat { case csv, json, md, txt }
    private enum ExportScope { case all, filtered, selected }

    private struct Row: Codable { let id, firstName, lastName, email, phone, company, tags, notes: String }

    private func computeRows(_ scope: ExportScope) -> [Row] {
        let src: [EDPCore.MemberDTO]
        switch scope {
        case .all: src = results
        case .filtered: src = results
        case .selected: src = results.filter { selection.contains($0.id) }
        }
        return src.map { m in Row(id: m.id, firstName: m.firstName, lastName: m.lastName, email: piiExportAllowed ? (m.email ?? "") : "", phone: "", company: m.company ?? "", tags: "", notes: "") }
    }

    private func export(_ format: ExportFormat, _ scope: ExportScope) {
        let rows = computeRows(scope)
        let ext = extFor(format)
        let filename = exportFilename(ext: ext)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        let data: Data
        switch format {
        case .csv: data = csv(rows)
        case .json: data = (try? JSONEncoder().encode(rows)) ?? Data()
        case .md: data = md(rows).data(using: .utf8) ?? Data()
        case .txt: data = txt(rows).data(using: .utf8) ?? Data()
        }
        do {
            try data.write(to: url)
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
            toast = "Exported \(rows.count) rows → \(filename)"
        } catch {
            toast = "Export failed"
        }
    }

    private func csv(_ rows: [Row]) -> Data {
        var out = "id,firstName,lastName,email,phone,company,tags,notes\n"
        func esc(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        for r in rows { out.append([r.id,r.firstName,r.lastName,r.email,r.phone,r.company,r.tags,r.notes].map(esc).joined(separator: ",")); out.append("\n") }
        return out.data(using: .utf8) ?? Data()
    }
    private func md(_ rows: [Row]) -> String {
        var out = "| id | firstName | lastName | email | phone | company | tags | notes |\n|---|---|---|---|---|---|---|---|\n"
        for r in rows { out += "| \(r.id) | \(r.firstName) | \(r.lastName) | \(r.email) | \(r.phone) | \(r.company) | \(r.tags) | \(r.notes) |\n" }
        return out
    }
    private func txt(_ rows: [Row]) -> String {
        var out = "id\tfirstName\tlastName\temail\tphone\tcompany\ttags\tnotes\n"
        for r in rows { out += "\(r.id)\t\(r.firstName)\t\(r.lastName)\t\(r.email)\t\(r.phone)\t\(r.company)\t\(r.tags)\t\(r.notes)\n" }
        return out
    }
    private func extFor(_ f: ExportFormat) -> String { switch f { case .csv: return "csv"; case .json: return "json"; case .md: return "md"; case .txt: return "txt" } }
    private func exportFilename(ext: String) -> String { let today = ISO8601DateFormatter().string(from: Date()).split(separator: "T").first.map(String.init) ?? "date"; return "members_\(today)_members.\(ext)" }

    #if os(macOS)
    private func importMembersFromFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        if panel.runModal() == .OK {
            DispatchQueue.global(qos: .userInitiated).async {
                var created = 0
                for url in panel.urls {
                    if let text = try? String(contentsOf: url) {
                        created += importMembersCSV(text)
                    }
                }
                DispatchQueue.main.async {
                    toast = created > 0 ? "Imported \(created) member(s)" : "No members imported"
                    if !query.isEmpty { search() }
                }
            }
        }
    }
    #endif

#if false
    private func importMembersCSV(_ csvText: String) -> Int {
        let lines = csvText.split(whereSeparator: \.isNewline)
        guard let header = lines.first else { return 0 }
        let cols = header.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        func idx(_ name: String) -> Int? { cols.firstIndex(of: name) }
        let iEmail = idx("email"); let iFirst = idx("firstname") ?? idx("first_name") ?? idx("first"); let iLast = idx("lastname") ?? idx("last_name") ?? idx("last"); let iPhone = idx("phone"); let iCompany = idx("company"); let iTags = idx("tags"); let iNotes = idx("notes")
        var count = 0
        for raw in lines.dropFirst() {
            let parts = raw.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
            func val(_ i: Int?) -> String? { guard let i, i < parts.count else { return nil }; let v = parts[i].trimmingCharacters(in: .whitespacesAndNewlines); return v.isEmpty ? nil : v }
            do {
                let _ = try EDPCore.shared.createMember(email: val(iEmail), firstName: val(iFirst) ?? "", lastName: val(iLast) ?? "", phone: val(iPhone), company: val(iCompany), tags: val(iTags), notes: val(iNotes))
                count += 1
            } catch { /* continue */ }
        }
        return count
    }
#endif

    private func importMembersCSV(_ csvText: String) -> Int {
        let lines = csvText.split(whereSeparator: \.isNewline).filter { !$0.isEmpty }
        guard let header = lines.first else { return 0 }
        let cols = header.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        func idx(_ name: String) -> Int? { cols.firstIndex(of: name) }
        let iEmail = idx("email"); let iFirst = idx("firstname") ?? idx("first_name") ?? idx("first"); let iLast = idx("lastname") ?? idx("last_name") ?? idx("last"); let iPhone = idx("phone"); let iCompany = idx("company"); let iTags = idx("tags"); let iNotes = idx("notes")
        var count = 0
        for raw in lines.dropFirst() {
            let parts = raw.split(separator: ",", omittingEmptySubsequences: false).map { String($0) }
            func val(_ i: Int?) -> String? {
                guard let i, i < parts.count else { return nil }
                let v = parts[i].trimmingCharacters(in: .whitespacesAndNewlines)
                return v.isEmpty ? nil : v
            }
            do {
                _ = try EDPCore.shared.createMember(email: val(iEmail), firstName: val(iFirst) ?? "", lastName: val(iLast) ?? "", phone: val(iPhone), company: val(iCompany), tags: val(iTags), notes: val(iNotes))
                count += 1
            } catch { /* continue */ }
        }
        return count
    }
}
