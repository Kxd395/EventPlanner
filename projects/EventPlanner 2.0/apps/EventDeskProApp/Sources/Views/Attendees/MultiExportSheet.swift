import SwiftUI

struct MultiExportSheet: View {
    let onExport: (_ formats: Set<ExportFormat>, _ scope: ExportScope) -> Void
    @Binding var isPresented: Bool
    @Binding var piiExportAllowed: Bool

    @State private var formats: Set<ExportFormat> = [.csv]
    @State private var scope: ExportScope = .filtered

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Export Attendees").font(.headline)
            Text("Choose formats and scope").font(.caption).foregroundColor(.secondary)
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("Formats").font(.subheadline)
                    Toggle("CSV", isOn: Binding(get: { formats.contains(.csv) }, set: { on in if on { _ = formats.insert(.csv) } else { formats.remove(.csv) } }))
                        .disabled(!piiExportAllowed)
                    Toggle("JSON", isOn: Binding(get: { formats.contains(.json) }, set: { on in if on { _ = formats.insert(.json) } else { formats.remove(.json) } }))
                        .disabled(!piiExportAllowed)
                    Toggle("Markdown (.md)", isOn: Binding(get: { formats.contains(.md) }, set: { on in if on { _ = formats.insert(.md) } else { formats.remove(.md) } }))
                    Toggle("Plain Text (.txt)", isOn: Binding(get: { formats.contains(.txt) }, set: { on in if on { _ = formats.insert(.txt) } else { formats.remove(.txt) } }))
                }
                VStack(alignment: .leading) {
                    Text("Scope").font(.subheadline)
                    Picker("", selection: $scope) {
                        Text("Filtered").tag(ExportScope.filtered)
                        Text("Selected").tag(ExportScope.selected)
                        Text("All").tag(ExportScope.all)
                    }.pickerStyle(.segmented).frame(width: 260)
                    if !piiExportAllowed {
                        Text("PII export restricted: CSV/JSON disabled").font(.caption).foregroundColor(.orange)
                    }
                }
            }
            HStack { Spacer(); Button("Cancel") { isPresented = false }; Button("Export") { onExport(formats, scope); isPresented = false }.disabled(formats.isEmpty) }
        }
        .padding(16)
        .frame(minWidth: 520)
    }
}
