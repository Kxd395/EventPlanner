import SwiftUI
import EventDeskCoreBindings

struct MergeDuplicatesSheet: View {
    let selection: [String]
    let members: [EDPCore.MemberDTO]
    var onMerge: (_ primary: String, _ duplicate: String) -> Void

    @State private var primaryId: String = ""
    @State private var duplicateId: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Merge Duplicates").font(.headline)
            Text("Select the primary member (kept) and the duplicate (merged into primary).")
                .font(.caption).foregroundColor(.secondary)
            HStack {
                VStack(alignment: .leading) {
                    Text("Primary (kept)")
                    Picker("Primary", selection: $primaryId) {
                        ForEach(members, id: \.id) { m in
                            Text("\(m.firstName) \(m.lastName) \(m.email ?? "")").tag(m.id)
                        }
                    }.labelsHidden().frame(width: 380)
                }
                VStack(alignment: .leading) {
                    Text("Duplicate (merged)")
                    Picker("Duplicate", selection: $duplicateId) {
                        ForEach(members, id: \.id) { m in
                            Text("\(m.firstName) \(m.lastName) \(m.email ?? "")").tag(m.id)
                        }
                    }.labelsHidden().frame(width: 380)
                }
            }
            HStack {
                Spacer()
                Button("Cancel") { primaryId = ""; duplicateId = ""; }
                Button("Merge") { onMerge(primaryId, duplicateId) }
                    .disabled(primaryId.isEmpty || duplicateId.isEmpty || primaryId == duplicateId)
            }
        }
        .padding(16)
        .onAppear {
            if selection.count >= 2 {
                primaryId = selection.first ?? ""
                duplicateId = selection.dropFirst().first ?? ""
            }
        }
    }
}

