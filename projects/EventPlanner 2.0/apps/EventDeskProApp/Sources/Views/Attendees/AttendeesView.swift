import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif
import EventDeskCoreBindings

struct AttendeesView: View {
    let event: EDPCore.EventDTO
    var highlightId: String? = nil
    @StateObject private var sync = RegistrationSyncService()
    @State private var attendees: [EDPCore.AttendeeDTO] = []
    @State private var counts: EDPCore.StatusCounts? = nil
    @State private var selectedStatus: StatusFilterBar.Status = .all
    @State private var loading = false
    @State private var error: String? = nil
    @State private var showImport = false
    @State private var toast: String? = nil
    @State private var showProfileAttendee: EDPCore.AttendeeDTO? = nil
    @State private var searchText: String = ""
    @FocusState private var searchFocused: Bool
    @State private var selection = Set<String>()
    @State private var showWalkin = false
    @State private var showAdd = false
    @State private var showStatusSheet = false
    @State private var showResetSheet = false
    @State private var showMultiExport = false
    @State private var statusTargetIds: [String] = []
    @State private var statusNewValue: String = "checkedin"
    @State private var resetTargetIds: [String] = []
    @State private var lastStatusChange: (ids: [String], prior: [String:String], newStatus: String)? = nil
    @State private var showConfirmRemove = false
    @State private var pendingRemoveIds: [String] = []
    @State private var panelAttendee: EDPCore.AttendeeDTO? = nil
    @State private var statusV2NullsCount: Int64? = nil
    enum SortOption: String, CaseIterable { case name = "Name", status = "Status", checkin = "Check-in Time" }
    @State private var sortOption: SortOption = .name
    @State private var highlightedId: String? = nil
    @State private var returnHighlightId: String? = nil
    @AppStorage("attendees.viewMode") private var storedViewMode: String = ViewMode.table.rawValue
    private var viewModeBinding: Binding<ViewMode> {
        Binding(get: { ViewMode(rawValue: storedViewMode) ?? .table }, set: { storedViewMode = $0.rawValue })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header actions
            HStack(spacing: 8) {
                Button { showAdd = true } label: { Label("Add Attendee", systemImage: "person.crop.circle.badge.plus") }
                Button { showWalkin = true } label: { Label("Walk-in", systemImage: "figure.walk") }
                Menu {
                    Button("From Text Editor…") { showImport = true }
                    #if os(macOS)
                    Button("From Files…") { importCSVFiles() }
                    #endif
                } label: { Label("Import", systemImage: "tray.and.arrow.down") }
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
                    Button("Multi…") { showMultiExport = true }
                } label: {
                    Label("Export", systemImage: "tray.and.arrow.up")
                }
                Button { toast = "Email sending coming soon" } label: { Label("Send Emails", systemImage: "envelope") }
                Spacer()
                TextField("Search", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 260)
                    .focused($searchFocused)
                Button(action: { searchFocused = true }) { Image(systemName: "magnifyingglass") }
                Picker("Sort", selection: $sortOption) { ForEach(SortOption.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 320)
                Spacer()
                ViewModePicker(mode: viewModeBinding)
                // Total count is shown in the filter bar; avoid duplication here
            }

            // Status filter (counts are shown inside the buttons)
            StatusFilterBar(selected: $selectedStatus, counts: counts) { _ in }

            // Capacity header (always visible)
            CapacityHeaderView(event: event, counts: counts)

            if let e = error { ErrorStateView(message: e, retry: { load() }) }
            if let n = statusV2NullsCount, n > 0 {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.yellow)
                    Text("Migration pending: \(n) rows missing status_v2.").foregroundColor(.primary)
                    Spacer()
                    Button("Run Backfill") { runBackfill() }
                }
                .padding(8)
                .background(Color.yellow.opacity(0.08))
                .cornerRadius(8)
            }

            Group {
                if loading {
                    ProgressView("Loading attendees…")
                } else if attendeesFiltered.isEmpty {
                    EmptyStateView(title: "No attendees yet", actionTitle: "Add Attendee") { }
                } else {
                    switch ViewMode(rawValue: storedViewMode) ?? .table {
                    case .table:
                        ScrollViewReader { proxy in
                            List(attendeesFiltered, id: \.attendeeId, selection: $selection) { a in
                                AttendeeRow(attendee: a, onOpenProfile: { memberId in
                                    Analytics.emit("member_profile_open", payload: ["memberId": memberId])
                                    returnHighlightId = a.attendeeId
                                    showProfileAttendee = a
                                }, onChangeStatus: { newCode in
                                    openStatusSheet(ids: [a.attendeeId], new: newCode)
                                }, onReset: { _ in openResetSheet(ids: [a.attendeeId]) }, onRemove: { id in confirmRemove(ids: [id]) }, onUndo: { undoLastChange() }, highlighted: highlightedId == a.attendeeId)
                                .onTapGesture { panelAttendee = a }
                                .contextMenu {
                                    Button("Set Checked-In") { openStatusSheet(ids: [a.attendeeId], new: "checkedin") }
                                    Button("Set DNA") { openStatusSheet(ids: [a.attendeeId], new: "dna") }
                                    Divider()
                                    Button("Remove from Event") { remove(ids: [a.attendeeId]) }
                                }
                                .id(a.attendeeId)
                            }
                            .onAppear { applyInitialHighlight(proxy: proxy) }
                            .onChange(of: attendeesFiltered.count) { _ in applyInitialHighlight(proxy: proxy) }
                            .frame(maxHeight: .infinity)
                        }
                        .listStyle(.inset)
                        .toolbar {
                            ToolbarItemGroup(placement: .automatic) {
                                if !selection.isEmpty {
                                    Button("Mark Checked-In") { openStatusSheet(ids: Array(selection), new: "checkedin") }
                                    Button("Mark DNA") { openStatusSheet(ids: Array(selection), new: "dna") }
                                    Button("Send Emails") { toast = "Email sending coming soon" }
                                    Button("Remove") { confirmRemove(ids: Array(selection)) }
                                }
                            }
                        }
                    case .cards:
                        ScrollView { // single scroll surface for cards
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 280, maximum: 360), spacing: 12)], spacing: 12) {
                                ForEach(attendeesFiltered, id: \.attendeeId) { a in
                                    AttendeeCard(attendee: a,
                                                 onCheckIn: { id in openStatusSheet(ids: [id], new: "checkedin") },
                                                 onEmail: { email in /* hook */ },
                                                 onRemove: { id in remove(ids: [id]) },
                                                 onChangeStatus: { newCode in openStatusSheet(ids: [a.attendeeId], new: newCode) },
                                                 onReset: { _ in openResetSheet(ids: [a.attendeeId]) },
                                                 onUndo: { undoLastChange() })
                                        .id(a.attendeeId)
                                }
                            }
                            .padding(12)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                }
            }
            .animation(.default, value: attendeesFiltered.count)
        }
    .padding(12)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { load(); sync.start(eventId: event.id) }
        .onDisappear { sync.stop() }
        .onChange(of: attendeesFiltered.count) { _ in
            // When list changes (first load), schedule highlight if requested
        }
        .sheet(isPresented: $showImport) {
            CSVImportView(eventId: event.id) {
                showImport = false
                load()
                toast = "Import complete"
                NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id])
            }
            .frame(minWidth: 640, minHeight: 420)
        }
        .sheet(isPresented: $showWalkin) {
            WalkinSheet(eventId: event.id) { _ in
                showWalkin = false
                load()
                toast = "Walk-in added"
                NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id])
            }
            .frame(minWidth: 520, minHeight: 280)
        }
        .sheet(isPresented: $showAdd) {
            AddAttendeeSheet(eventId: event.id) {
                showAdd = false
                load()
                toast = "Attendee added"
                NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id])
            }
            .frame(minWidth: 720)
        }
        .sheet(isPresented: $showStatusSheet) {
            StatusChangeSheet(current: currentStatusFor(ids: statusTargetIds), newStatus: $statusNewValue, event: event) { reason, override in
                applyStatus(ids: statusTargetIds, newStatus: statusNewValue, reason: reason, override: override)
            }
            .frame(minWidth: 520)
        }
        .sheet(isPresented: $showResetSheet) {
            ResetParticipationSheet(name: resetTargetName) { option, reason in
                switch option {
                case .preregistered:
                    applyStatus(ids: resetTargetIds, newStatus: "preregistered", reason: reason, override: true)
                case .remove:
                    confirmRemove(ids: resetTargetIds)
                }
            }
        }
        .sheet(isPresented: Binding<Bool>(get: { showProfileAttendee != nil }, set: { if !$0 { showProfileAttendee = nil } })) {
            QuickMemberPopover(attendee: showProfileAttendee!)
                .onDisappear {
                    if let rid = returnHighlightId { highlightedId = rid; returnHighlightId = nil }
                }
        }
        .sheet(isPresented: $showMultiExport) {
            MultiExportSheet(onExport: { formats, scope in
                #if os(macOS)
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                panel.prompt = "Choose Folder"
                if panel.runModal() == .OK, let dir = panel.urls.first {
                    exportMultiple(formats: formats, scope: scope, directory: dir)
                }
                #else
                // Non-macOS: write to temp
                exportMultiple(formats: formats, scope: scope, directory: FileManager.default.temporaryDirectory)
                #endif
            }, isPresented: $showMultiExport, piiExportAllowed: $piiExportAllowed)
        }
        .overlay(alignment: .bottom) {
            if let t = toast {
                ToastView(text: t, actionTitle: toastActionTitle, action: toastAction)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: toast) { _ in
            guard toast != nil else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { toast = nil; toastActionTitle = nil; toastAction = nil }
            }
        }
        .overlay(alignment: .trailing) {
            if let att = panelAttendee, !isPresentingModal {
                AttendeeDetailPanel(attendee: att, event: event, onClose: { panelAttendee = nil; load() })
                    .frame(width: 360)
                    .transition(.move(edge: .trailing))
                    .shadow(radius: 4)
            }
        }
        .alert("Remove from Event", isPresented: $showConfirmRemove, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) { remove(ids: pendingRemoveIds) }
        }, message: { Text("This will remove \(pendingRemoveIds.count) attendee(s) from the event.") })
    }

    private var attendeesFiltered: [EDPCore.AttendeeDTO] {
        let base: [EDPCore.AttendeeDTO]
        switch selectedStatus {
        case .all: base = attendees
        case .preregistered: base = attendees.filter { $0.status == "preregistered" }
        case .walkin: base = attendees.filter { $0.status == "walkin" }
        case .checkedin: base = attendees.filter { $0.status == "checkedin" }
        case .dna: base = attendees.filter { $0.status == "dna" }
        }
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let searched = q.isEmpty ? base : base.filter { $0.name.lowercased().contains(q) || ($0.email ?? "").lowercased().contains(q) || ($0.company ?? "").lowercased().contains(q) }
        return searched.sorted { a, b in
            switch sortOption {
            case .name: return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .status: return a.status.localizedCaseInsensitiveCompare(b.status) == .orderedAscending
            case .checkin:
                let fmt = ISO8601DateFormatter()
                let da = a.checkedInAt.flatMap { fmt.date(from: $0) } ?? .distantPast
                let db = b.checkedInAt.flatMap { fmt.date(from: $0) } ?? .distantPast
                return da < db
            }
        }
    }

    private func load() {
        loading = true; error = nil
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let list = try EDPCore.shared.listAttendees(eventId: event.id)
                let c = try EDPCore.shared.countsByStatus(eventId: event.id)
                let nulls = EDPCore.shared.statusV2Nulls(eventId: event.id)
                DispatchQueue.main.async {
                    self.attendees = list
                    self.counts = c
                    self.statusV2NullsCount = nulls
                    self.loading = false
                }
            } catch {
                DispatchQueue.main.async { self.error = "Failed to load attendees"; self.loading = false }
            }
        }
    }

    // ExportFormat and ExportScope moved to ExportTypes.swift (shared)

    private struct ExportRow: Codable {
        let id: String
        let eventId: String
        let name: String
        let email: String
        let phone: String
        let status: String
        let confirmed: String
        let checkedInAt: String
        let dnaAt: String
        let createdAt: String
        let tags: String
        let notes: String
    }

    @AppStorage("piiExportAllowed") private var piiExportAllowed: Bool = true

    private func export(_ format: ExportFormat, _ scope: ExportScope) {
        let rows = computeRows(scope)
        let filename = exportFilename(ext: ext(for: format))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            let data = dataFor(format: format, rows: rows)
            try data.write(to: url)
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
            Analytics.emit("export", payload: ["eventId": event.id, "format": ext(for: format), "scope": String(describing: scope)])
            toast = "Exported \(rows.count) rows → \(filename)"
        } catch {
            toast = "Export failed"
        }
    }

    private func computeRows(_ scope: ExportScope) -> [ExportRow] {
        let records: [EDPCore.AttendeeDTO]
        switch scope {
        case .all: records = attendees
        case .filtered: records = attendeesFiltered
        case .selected: records = attendees.filter { selection.contains($0.attendeeId) }
        }
        return records.map { a in
            ExportRow(
                id: a.attendeeId,
                eventId: event.id,
                name: a.name,
                email: piiExportAllowed ? (a.email ?? "") : "",
                phone: "", // not exposed in AttendeeDTO yet
                status: a.status,
                confirmed: "", // not tracked; placeholder
                checkedInAt: a.checkedInAt ?? "",
                dnaAt: "", // not tracked; placeholder
                createdAt: "", // not exposed via DTO
                tags: "",
                notes: ""
            )
        }
    }

    private func ext(for format: ExportFormat) -> String {
        switch format { case .csv: return "csv"; case .json: return "json"; case .md: return "md"; case .txt: return "txt" }
    }

    private func exportFilename(ext: String) -> String {
        let dateStr = event.startsAt.split(separator: "T").first.map(String.init) ?? "date"
        let safeName = event.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        return "\(safeName)_\(dateStr)_attendees.\(ext)"
    }

    private func exportCSVData(rows: [ExportRow]) -> Data {
        var out = "id,eventId,name,email,phone,status,confirmed,checkedInAt,dnaAt,createdAt,tags,notes\n"
        for r in rows {
            func esc(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
            out.append([r.id, r.eventId, r.name, r.email, r.phone, r.status, r.confirmed, r.checkedInAt, r.dnaAt, r.createdAt, r.tags, r.notes].map(esc).joined(separator: ","))
            out.append("\n")
        }
        return out.data(using: .utf8) ?? Data()
    }

    private func dataFor(format: ExportFormat, rows: [ExportRow]) -> Data {
        switch format {
        case .csv: return exportCSVData(rows: rows)
        case .json: return (try? JSONEncoder().encode(rows)) ?? Data()
        case .md: return exportMarkdown(rows: rows).data(using: .utf8) ?? Data()
        case .txt: return exportPlainText(rows: rows).data(using: .utf8) ?? Data()
        }
    }

    #if os(macOS)
    private func importCSVFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.commaSeparatedText]
        if panel.runModal() == .OK {
            DispatchQueue.global(qos: .userInitiated).async {
                var totalImported: UInt64 = 0
                for url in panel.urls {
                    if let txt = try? String(contentsOf: url) {
                        if let outcome = try? EDPCore.shared.csvCommit(eventId: event.id, csvText: txt) {
                            totalImported += outcome.rowsImported
                        }
                    }
                }
                DispatchQueue.main.async {
                    load()
                    toast = totalImported > 0 ? "Imported \(totalImported) row(s)" : "No rows imported"
                    NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id])
                }
            }
        }
    }
    #endif

    private func exportMultiple(formats: Set<ExportFormat>, scope: ExportScope, directory: URL) {
        let rows = computeRows(scope)
        var written = 0
        for f in formats {
            let filename = exportFilename(ext: ext(for: f))
            let target = directory.appendingPathComponent(filename)
            let data = dataFor(format: f, rows: rows)
            do { try data.write(to: target); written += 1 } catch { /* ignore per-file errors */ }
        }
        toast = written > 0 ? "Exported \(rows.count) rows to \(written) file(s)" : "Export failed"
    }

    private func runBackfill() {
        DispatchQueue.global(qos: .userInitiated).async {
            let updated = EDPCore.shared.statusV2Backfill(eventId: event.id)
            let nulls = EDPCore.shared.statusV2Nulls(eventId: event.id)
            DispatchQueue.main.async {
                statusV2NullsCount = nulls
                toast = updated >= 0 ? "Backfilled \(updated) row(s)" : "Backfill failed"
                if updated > 0 {
                    NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id])
                }
            }
        }
    }

    private func exportMarkdown(rows: [ExportRow]) -> String {
        var out = "| id | eventId | name | email | phone | status | confirmed | checkedInAt | dnaAt | createdAt | tags | notes |\n"
        out += "|---|---|---|---|---|---|---|---|---|---|---|---|\n"
        for r in rows {
            out += "| \(r.id) | \(r.eventId) | \(r.name) | \(r.email) | \(r.phone) | \(r.status) | \(r.confirmed) | \(r.checkedInAt) | \(r.dnaAt) | \(r.createdAt) | \(r.tags) | \(r.notes) |\n"
        }
        return out
    }

    private func exportPlainText(rows: [ExportRow]) -> String {
        var out = "id\teventId\tname\temail\tphone\tstatus\tconfirmed\tcheckedInAt\tdnaAt\tcreatedAt\ttags\tnotes\n"
        for r in rows {
            out += "\(r.id)\t\(r.eventId)\t\(r.name)\t\(r.email)\t\(r.phone)\t\(r.status)\t\(r.confirmed)\t\(r.checkedInAt)\t\(r.dnaAt)\t\(r.createdAt)\t\(r.tags)\t\(r.notes)\n"
        }
        return out
    }

    private func openStatusSheet(ids: [String], new: String) { statusTargetIds = ids; statusNewValue = new; showStatusSheet = true }
    private func openResetSheet(ids: [String]) { resetTargetIds = ids; showResetSheet = true }
    private func currentStatusFor(ids: [String]) -> String? { ids.first.flatMap { id in attendees.first(where: { $0.attendeeId == id })?.status } }
    private func applyStatus(ids: [String], newStatus: String, reason: String?, override: Bool) {
        // Capture prior statuses for Undo before we mutate anything
        let priorMap: [String:String] = attendees.reduce(into: [:]) { acc, a in
            if ids.contains(a.attendeeId) { acc[a.attendeeId] = a.status }
        }
        // Optimistically update UI so primary action and chips reflect the change immediately
        if !ids.isEmpty {
            for idx in attendees.indices {
                if ids.contains(attendees[idx].attendeeId) {
                    var a = attendees[idx]
                    a = EDPCore.AttendeeDTO(attendeeId: a.attendeeId,
                                            memberId: a.memberId,
                                            eventId: a.eventId,
                                            name: a.name,
                                            email: a.email,
                                            company: a.company,
                                            status: newStatus,
                                            checkedInAt: (newStatus == "checkedin" ? ISO8601DateFormatter().string(from: Date()) : (newStatus == "preregistered" ? nil : a.checkedInAt)))
                    attendees[idx] = a
                }
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let updated = try EDPCore.shared.bulkStatusUpdate(eventId: event.id, attendeeIds: ids, newStatus: newStatus, inProgress: isEventInProgress(event: event), override: override, reason: reason, changedBy: "ui_bulk")
                Analytics.emit("attendee_status_change", payload: ["eventId": event.id, "newStatus": newStatus, "count": updated])
                DispatchQueue.main.async {
                    load(); selection.removeAll()
                    lastStatusChange = (ids: ids, prior: priorMap, newStatus: newStatus)
                    toastActionTitle = "Undo"
                    toastAction = { undoLastChange() }
                    toast = "Updated \(updated)"
                    NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id])
                }
            } catch {
                DispatchQueue.main.async { self.error = EDPCore.shared.lastError() ?? "Status update failed" }
            }
        }
    }
    
    @State private var toastActionTitle: String? = nil
    @State private var toastAction: (() -> Void)? = nil

    private func undoLastChange() {
        guard let change = lastStatusChange else { return }
        // Group IDs by prior status so we can bulk-update per status
        var groups: [String:[String]] = [:]
        for (id, status) in change.prior { groups[status, default: []].append(id) }

        // Optimistically revert in UI
        for idx in attendees.indices {
            if let prior = change.prior[attendees[idx].attendeeId] {
                var a = attendees[idx]
                a = EDPCore.AttendeeDTO(attendeeId: a.attendeeId,
                                        memberId: a.memberId,
                                        eventId: a.eventId,
                                        name: a.name,
                                        email: a.email,
                                        company: a.company,
                                        status: prior,
                                        checkedInAt: (prior == "checkedin" ? (a.checkedInAt ?? ISO8601DateFormatter().string(from: Date())) : nil))
                attendees[idx] = a
            }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            var total: Int64 = 0
            var lastErr: String? = nil
            for (status, ids) in groups {
                do {
                    // Use override: true to avoid manager-override guard when reverting to DNA
                    let n = try EDPCore.shared.bulkStatusUpdate(eventId: event.id, attendeeIds: ids, newStatus: status, inProgress: isEventInProgress(event: event), override: true, reason: "undo", changedBy: "ui_undo")
                    total += n
                } catch {
                    lastErr = EDPCore.shared.lastError() ?? "Undo failed"
                }
            }
            DispatchQueue.main.async {
                load(); selection.removeAll()
                if let e = lastErr { self.error = e } else { toast = "Undid update (\(total))" }
                // Clear undo state
                lastStatusChange = nil
                toastActionTitle = nil
                toastAction = nil
                NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id])
            }
        }
    }
    private func remove(ids: [String]) { DispatchQueue.global(qos: .userInitiated).async { var removed = 0; ids.forEach { if EDPCore.shared.removeAttendance(attendanceId: $0, reason: "ui_remove", changedBy: "ui") { removed += 1 } }; DispatchQueue.main.async { load(); selection.removeAll(); toast = "Removed \(removed)"; NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": event.id]) } } }
    private func confirmRemove(ids: [String]) { pendingRemoveIds = ids; showConfirmRemove = true }
}

private func isEventInProgress(event: EDPCore.EventDTO) -> Bool {
    let fmt = ISO8601DateFormatter()
    guard let start = fmt.date(from: event.startsAt), let end = fmt.date(from: event.endsAt) else { return true }
    let now = Date(); return now >= start && now <= end
}

private extension AttendeesView {
    var isPresentingModal: Bool { showAdd || showWalkin || showImport || showStatusSheet || showProfileAttendee != nil }
    func applyInitialHighlight(proxy: ScrollViewProxy) {
        guard highlightedId == nil, let target = highlightId, attendeesFiltered.contains(where: { $0.attendeeId == target }) else { return }
        highlightedId = target
        withAnimation(.easeInOut(duration: 0.5)) { proxy.scrollTo(target, anchor: .center) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { highlightedId = nil }
        }
    }
}

private extension AttendeesView {
    var resetTargetName: String {
        guard let id = resetTargetIds.first, let a = attendees.first(where: { $0.attendeeId == id }) else { return "Attendee" }
        return a.name
    }
}


// MARK: - Capacity Header

private struct CapacityHeaderView: View {
    let event: EDPCore.EventDTO
    let counts: EDPCore.StatusCounts?

    var body: some View {
        HStack(spacing: 12) {
            Text(capacityText).font(.subheadline)
            if let cap = event.capacity, cap > 0 {
                CapacityBar(ratio: ratio).frame(width: 160, height: 8)
                Text(percentString).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var totalReg: Int64 {
        guard let c = counts else { return 0 }
        return Int64(c.preregistered + c.walkin + c.checkedin)
    }

    private var ratio: Double {
        guard let cap = event.capacity, cap > 0 else { return 0 }
        return max(0, min(1, Double(totalReg) / Double(cap)))
    }

    private var percentString: String {
        guard let cap = event.capacity, cap > 0 else { return "" }
        let pct = Int(ratio * 100.0)
        return "\(pct)%"
    }

    private var capacityText: String {
        if let cap = event.capacity {
            if cap == 0 { return "Capacity: \(totalReg) / Unlimited guests" }
            else { return "Capacity: \(totalReg) / \(cap) guests" }
        } else {
            return "Capacity: \(totalReg) / —"
        }
    }
}

private struct CapacityBar: View {
    let ratio: Double
    var body: some View {
        GeometryReader { geo in
            let w = max(0, min(1, ratio)) * geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 3).fill(EDPDesign.Status.checkedin).frame(width: w)
            }
        }
    }
}
