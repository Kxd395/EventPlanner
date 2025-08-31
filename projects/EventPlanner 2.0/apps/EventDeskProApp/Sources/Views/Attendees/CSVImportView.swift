import SwiftUI
#if os(macOS)
import AppKit
#endif
import EventDeskCoreBindings

struct CSVImportView: View {
    let eventId: String
    var onDone: (() -> Void)? = nil

    @State private var csvText: String = "email,firstName,lastName\n"
    @State private var preview: EDPCore.CSVPreviewResult? = nil
    @State private var errorMessage: String? = nil
    @State private var loading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Import Attendees CSV").font(.title3).bold()
                Spacer()
            }
            if let e = errorMessage { ErrorStateView(message: e) { previewCSV() } }
            HStack {
                TextEditor(text: $csvText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 200)
                    .border(Color.secondary.opacity(0.2))
                    .onChange(of: csvText) { _ in errorMessage = nil }
            }
            HStack {
                Button("Preview") { previewCSV() }
                if let p = preview {
                    Spacer()
                    Text("Total: \(p.totals.total)  Valid: \(p.totals.valid)  Duplicates: \(p.totals.duplicates)  Errors: \(p.totals.errors)")
                        .foregroundColor(.secondary)
                }
            }
            if let p = preview {
                if !p.duplicate_emails.isEmpty {
                    Text("Duplicates: \(p.duplicate_emails.prefix(6).joined(separator: ", "))\(p.duplicate_emails.count > 6 ? ", …" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if !p.errors.isEmpty {
                    Button("Download Errors CSV") { exportErrorsCSV(p) }
                        .buttonStyle(.bordered)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { onDone?() }
                Button("Commit", action: commit).disabled(preview == nil || loading)
            }
        }
        .padding(16)
    }

    private func previewCSV() {
    do { self.preview = try EDPCore.shared.csvPreview(csvText) } catch { self.errorMessage = "Preview failed" }
        Analytics.emit("csv_import_preview", payload: ["eventId": eventId])
    }

    private func commit() {
    guard preview != nil else { return }
        loading = true
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                _ = try EDPCore.shared.csvCommit(eventId: eventId, csvText: csvText)
                DispatchQueue.main.async { loading = false; NotificationCenter.default.post(name: .edpEventCountsShouldRefresh, object: nil, userInfo: ["eventId": eventId]); onDone?() }
                Analytics.emit("csv_import_commit", payload: ["eventId": eventId])
            } catch {
                DispatchQueue.main.async { loading = false; self.errorMessage = "Commit failed" }
            }
        }
    }

    private func exportErrorsCSV(_ p: EDPCore.CSVPreviewResult) {
        var csv = "row,error\n"
        p.errors.forEach { csv.append("\($0.row),\"\($0.error.replacingOccurrences(of: "\"", with: "\"\""))\"\n") }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("csv_errors_\(eventId).csv")
        try? csv.data(using: .utf8)?.write(to: url)
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #endif
    }
}
