import SwiftUI
import EventDeskCoreBindings

struct ReportsView: View {
    let event: EDPCore.EventDTO
    @State private var counts: EDPCore.StatusCounts? = nil
    @State private var errorMessage: String? = nil
    @State private var attendees: [EDPCore.AttendeeDTO] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reports").font(.title3).bold()
                Spacer()
                Menu {
                    Button("Counts (CSV)") { exportCountsCSV() }
                    Button("Check‑ins (CSV)") { exportCheckinsCSV() }
                } label: {
                    Label("Export", systemImage: "tray.and.arrow.up")
                }
            }
            if let e = errorMessage { ErrorStateView(message: e) }
            if let c = counts {
                HStack(alignment: .bottom, spacing: 16) {
                    BarView(label: "Pre-Registered", value: Double(c.preregistered), color: EDPDesign.Status.preregistered)
                    BarView(label: "Walk-in", value: Double(c.walkin), color: EDPDesign.Status.walkin)
                    BarView(label: "Checked-In", value: Double(c.checkedin), color: EDPDesign.Status.checkedin)
                    BarView(label: "DNA", value: Double(c.dna), color: EDPDesign.Status.dna)
                }.frame(height: 180)
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Check‑in Curve").font(.caption).foregroundColor(.secondary)
                    CheckinCurveView(attendees: attendees).frame(height: 120)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("No‑show Rate").font(.caption).foregroundColor(.secondary)
                    Text(noShowRateText).font(.title3).bold()
                }
            } else {
                ProgressView("Loading…")
            }
            Spacer()
        }
        .padding(12)
        .onAppear(perform: load)
    }

    private func load() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let c = try EDPCore.shared.countsByStatus(eventId: event.id)
                let list = try? EDPCore.shared.listAttendees(eventId: event.id)
                DispatchQueue.main.async { counts = c; attendees = list ?? [] }
            } catch {
                DispatchQueue.main.async { errorMessage = "Failed to load counts" }
            }
        }
    }

    private func exportCountsCSV() {
        guard let c = counts else { return }
        var csv = "metric,value\n"
        csv += "preregistered,\(c.preregistered)\n"
        csv += "walkin,\(c.walkin)\n"
        csv += "checkedin,\(c.checkedin)\n"
        csv += "dna,\(c.dna)\n"
        let fn = exportFilename(suffix: "reports_counts", ext: "csv")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fn)
        try? csv.data(using: .utf8)?.write(to: url)
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    private func exportCheckinsCSV() {
        var csv = "checkedInAt\n"
        attendees.compactMap { $0.checkedInAt }.forEach { csv += "\($0)\n" }
        let fn = exportFilename(suffix: "reports_checkins", ext: "csv")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fn)
        try? csv.data(using: .utf8)?.write(to: url)
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }

    private func exportFilename(suffix: String, ext: String) -> String {
        let dateStr = event.startsAt.split(separator: "T").first.map(String.init) ?? "date"
        let safeName = event.name.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: " ", with: "_")
        return "\(safeName)_\(dateStr)_\(suffix).\(ext)"
    }
}

private struct BarView: View {
    let label: String
    let value: Double
    let color: Color
    var body: some View {
        VStack {
            GeometryReader { geo in
                let h = max(4, value == 0 ? 4 : min(geo.size.height, CGFloat(value)))
                VStack { Spacer(); RoundedRectangle(cornerRadius: 4).fill(color).frame(height: h) }
            }
            .frame(width: 48)
            Text(label).font(.caption)
        }
    }
}

private struct CheckinCurveView: View {
    let attendees: [EDPCore.AttendeeDTO]
    var body: some View {
        GeometryReader { geo in
            let buckets = bucketize(attendees: attendees, buckets: 24)
            let maxV = max(1, buckets.max() ?? 1)
            HStack(alignment: .bottom, spacing: 2) {
                ForEach(0..<buckets.count, id: \.self) { i in
                    let h = CGFloat(buckets[i]) / CGFloat(maxV) * geo.size.height
                    RoundedRectangle(cornerRadius: 2)
                        .fill(EDPDesign.Status.checkedin)
                        .frame(width: max(2, geo.size.width/CGFloat(buckets.count) - 2), height: h)
                }
            }
        }
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(6)
    }

    private func bucketize(attendees: [EDPCore.AttendeeDTO], buckets: Int) -> [Int] {
        guard buckets > 0 else { return [] }
        let fmt = ISO8601DateFormatter()
        let times = attendees.compactMap { $0.checkedInAt }.compactMap { fmt.date(from: $0) }.sorted()
        guard let first = times.first, let last = times.last, first < last else { return Array(repeating: 0, count: buckets) }
        let total = last.timeIntervalSince(first)
        if total <= 0 { return Array(repeating: 0, count: buckets) }
        var out = Array(repeating: 0, count: buckets)
        for t in times {
            let ratio = t.timeIntervalSince(first) / total
            var idx = Int(floor(ratio * Double(buckets)))
            if idx >= buckets { idx = buckets - 1 }
            out[idx] += 1
        }
        return out
    }
}

private extension ReportsView {
    var noShowRateText: String {
        guard let c = counts else { return "-" }
        let denom = Double(c.preregistered + c.walkin)
        guard denom > 0 else { return "-" }
        let rate = (Double(c.dna) / denom) * 100.0
        return String(format: "%.0f%%", rate)
    }
}
