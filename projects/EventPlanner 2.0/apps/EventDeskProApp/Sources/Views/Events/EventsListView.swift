import SwiftUI
import EventDeskCoreBindings

struct EventsListView: View {
    @State private var events: [EDPCore.EventDTO] = []
    @State private var selection = Set<String>()
    @State private var error: String? = nil
    @State private var searchText: String = ""
    @State private var sortKey: SortKey = .date
    @AppStorage("piiExportAllowed") private var piiExportAllowed: Bool = true

    enum SortKey: String, CaseIterable { case name = "Name", date = "Date", status = "Status" }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Search events…", text: $searchText).textFieldStyle(.roundedBorder).frame(maxWidth: 280)
                Picker("Status", selection: .constant("All")) { Text("All").tag("All") }
                    .labelsHidden()
                Picker("Sort", selection: $sortKey) { ForEach(SortKey.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
                    .pickerStyle(.segmented)
                Spacer()
                Button("New Event") { NotificationCenter.default.post(name: .edpOpenNewEventSheet, object: nil) }
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
                } label: {
                    Label("Export", systemImage: "tray.and.arrow.up")
                }
                Button(action: { load() }) { Label("Refresh", systemImage: "arrow.clockwise") }
            }
            if let e = error { ErrorStateView(message: e, retry: { load() }) }
            if filtered.isEmpty {
                EmptyStateView(title: "No events yet – Create your first event", actionTitle: "Create Event") {
                    NotificationCenter.default.post(name: .edpOpenNewEventSheet, object: nil)
                }
            } else {
                List(selection: $selection) {
                    Section {
                        ForEach(filtered, id: \.id) { ev in
                            NavigationLink(destination: EventDetailView(event: ev)) {
                                EventRowView(event: ev)
                            }
                            .contextMenu {
                                Button("Open") {}
                                Button("Duplicate") {}
                                Divider()
                                Button("Delete", role: .destructive) {}
                            }
                        }
                    } header: {
                        HStack {
                            Text("Name").frame(minWidth: 220, alignment: .leading)
                            Text("Date").frame(minWidth: 260, alignment: .leading)
                            Text("Status").frame(width: 80, alignment: .leading)
                            Text("Max Guests").frame(width: 80, alignment: .trailing)
                            Text("Reg (%)").frame(width: 80, alignment: .trailing)
                            Spacer()
                        }.font(.caption).foregroundColor(.secondary)
                    }
                }
                // macOS SwiftUI does not support _defaultListRowSeparatorVisibility; relying on default separators
                HStack {
                    Text("Bulk:")
                    Button("Delete") {}
                    Button("Duplicate") {}
                    Button("Export CSV") {}
                    Spacer()
                    Text("Pagination: « Prev | 1 | 2 | 3 | Next » Rows per page: 25 ▼")
                        .font(.caption).foregroundColor(.secondary)
                }.padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onAppear { load() }
        .onReceive(NotificationCenter.default.publisher(for: .edpEventsShouldRefresh)) { _ in
            load()
        }
    }

    private var filtered: [EDPCore.EventDTO] {
        let base = events
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let searched = q.isEmpty ? base : base.filter { $0.name.lowercased().contains(q) || ($0.location ?? "").lowercased().contains(q) }
        return searched.sorted { a,b in
            switch sortKey {
            case .name: return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            case .date: return a.startsAt < b.startsAt
            case .status: return (a.status ?? "").localizedCaseInsensitiveCompare(b.status ?? "") == .orderedAscending
            }
        }
    }

    private func load() {
        do { events = try EDPCore.shared.listEvents(limit: 200, offset: 0) } catch { self.error = "Failed to load events" }
    }
}

private struct EventRowView: View {
    let event: EDPCore.EventDTO
    @State private var counts: EDPCore.StatusCounts? = nil
    @State private var loading = false
    var body: some View {
        HStack {
            Text(event.name).frame(minWidth: 220, alignment: .leading)
            Text("\(event.startsAt) – \(event.endsAt)")
                .frame(minWidth: 260, alignment: .leading)
                .foregroundColor(.secondary)
            StatusChipView(text: (event.status ?? "-").uppercased(), color: statusColor)
                .frame(width: 100, alignment: .leading)
            Text(event.capacity != nil ? String(event.capacity!) : "-")
                .frame(width: 80, alignment: .trailing)
            HStack(spacing: 6) {
                MiniBarView(ratio: regRatio)
                Text(regPercentText).foregroundColor(.secondary)
            }
            .frame(width: 120, alignment: .trailing)
            Spacer()
        }
        .onAppear(perform: fetchCounts)
        .onReceive(NotificationCenter.default.publisher(for: .edpEventCountsShouldRefresh)) { note in
            if let eid = note.userInfo?["eventId"] as? String, eid == event.id {
                fetchCounts()
            }
        }
    }

    private var regPercentText: String {
        guard let cap = event.capacity, cap > 0 else { return "-" }
        let total = Int((counts?.preregistered ?? 0) + (counts?.walkin ?? 0) + (counts?.checkedin ?? 0))
        let pct = max(0, min(100, Int((Double(total) / Double(cap)) * 100.0)))
        return "\(pct)%"
    }

    private var regRatio: Double {
        guard let cap = event.capacity, cap > 0 else { return 0 }
        let total = Double((counts?.preregistered ?? 0) + (counts?.walkin ?? 0) + (counts?.checkedin ?? 0))
        return max(0, min(1, total / Double(cap)))
    }

    private var statusColor: Color {
        switch (event.status ?? "").lowercased() {
        case "active": return .green
        case "draft": return .orange
        case "completed": return .blue
        default: return .secondary
        }
    }

    private func fetchCounts() {
        guard !loading else { return }
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let c = try? EDPCore.shared.countsByStatus(eventId: event.id)
            DispatchQueue.main.async { counts = c; loading = false }
        }
    }
}

// MARK: - Export helpers

private enum EventsExportFormat { case csv, json, md, txt }
private enum EventsExportScope { case all, filtered, selected }

extension EventsListView {

    private struct EventsExportRow: Codable {
        let id: String
        let name: String
        let startsAt: String
        let endsAt: String
        let location: String
        let capacity: String
        let status: String
        let timezone: String
        let description: String
    }

    private func export(_ format: EventsExportFormat, _ scope: EventsExportScope) {
        let list: [EDPCore.EventDTO]
        switch scope {
        case .all: list = events
        case .filtered: list = filtered
        case .selected:
            let ids = selection
            list = events.filter { ids.contains($0.id) }
        }
        let rows = list.map { e in
            EventsExportRow(
                id: e.id,
                name: e.name,
                startsAt: e.startsAt,
                endsAt: e.endsAt,
                location: e.location ?? "",
                capacity: e.capacity != nil ? String(e.capacity!) : "",
                status: e.status ?? "",
                timezone: e.timezone ?? "",
                description: e.description ?? ""
            )
        }
        let ext = extFor(format)
        let filename = eventsExportFilename(ext: ext)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            let data: Data
            switch format {
            case .csv: data = eventsCSV(rows)
            case .json: data = (try? JSONEncoder().encode(rows)) ?? Data()
            case .md: data = eventsMD(rows).data(using: .utf8) ?? Data()
            case .txt: data = eventsTXT(rows).data(using: .utf8) ?? Data()
            }
            try data.write(to: url)
            #if os(macOS)
            NSWorkspace.shared.open(url)
            #endif
        } catch { /* ignore for now; could show a toast if present */ }
    }

    private func eventsCSV(_ rows: [EventsExportRow]) -> Data {
        var out = "id,name,startsAt,endsAt,location,capacity,status,timezone,description\n"
        for r in rows {
            func esc(_ s: String) -> String { "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
            out.append([r.id,r.name,r.startsAt,r.endsAt,r.location,r.capacity,r.status,r.timezone,r.description].map(esc).joined(separator: ","))
            out.append("\n")
        }
        return out.data(using: .utf8) ?? Data()
    }

    private func eventsMD(_ rows: [EventsExportRow]) -> String {
        var out = "| id | name | startsAt | endsAt | location | capacity | status | timezone | description |\n"
        out += "|---|---|---|---|---|---|---|---|---|\n"
        for r in rows { out += "| \(r.id) | \(r.name) | \(r.startsAt) | \(r.endsAt) | \(r.location) | \(r.capacity) | \(r.status) | \(r.timezone) | \(r.description) |\n" }
        return out
    }

    private func eventsTXT(_ rows: [EventsExportRow]) -> String {
        var out = "id\tname\tstartsAt\tendsAt\tlocation\tcapacity\tstatus\ttimezone\tdescription\n"
        for r in rows { out += "\(r.id)\t\(r.name)\t\(r.startsAt)\t\(r.endsAt)\t\(r.location)\t\(r.capacity)\t\(r.status)\t\(r.timezone)\t\(r.description)\n" }
        return out
    }

    private func extFor(_ f: EventsExportFormat) -> String { switch f { case .csv: return "csv"; case .json: return "json"; case .md: return "md"; case .txt: return "txt" } }
    private func eventsExportFilename(ext: String) -> String {
        let today = ISO8601DateFormatter().string(from: Date()).split(separator: "T").first.map(String.init) ?? "date"
        return "events_\(today)_events.\(ext)"
    }
}

private struct MiniBarView: View {
    let ratio: Double
    var body: some View {
        GeometryReader { geo in
            let w = max(0, min(1, ratio)) * geo.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color.secondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 3).fill(EDPDesign.Status.checkedin).frame(width: w)
            }
        }
        .frame(width: 60, height: 8)
    }
}

private struct StatusChipView: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.caption2).bold()
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}
