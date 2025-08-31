import SwiftUI
import EventDeskCoreBindings

struct MemberProfileView: View {
    let memberId: String
    @State private var profile: EDPCore.MemberProfile? = nil
    @State private var error: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Member Profile").font(.title3).bold()
            if let p = profile {
                Text("\(p.firstName) \(p.lastName)")
                if let email = p.email { Text(email).foregroundColor(.secondary) }
                if let company = p.company { Text(company).foregroundColor(.secondary) }
                Divider()
                Text("Recent Events: \(p.events.count)").font(.caption)
                List(p.events, id: \.self) { row in
                    HStack {
                        Text(row.first ?? "-")
                        Spacer()
                        Text(row.count > 1 ? row[1] : "").foregroundColor(.secondary).font(.caption)
                        Text(row.count > 2 ? row[2] : "").foregroundColor(.secondary).font(.caption)
                    }
                }.frame(minHeight: 120)
            } else if let e = error { ErrorStateView(message: e) }
            Spacer()
        }
        .padding(16)
        .onAppear(perform: load)
        .frame(minWidth: 420, minHeight: 240)
    }

    private func load() {
        DispatchQueue.global(qos: .userInitiated).async {
            let p = EDPCore.shared.memberProfile(memberId: memberId)
            DispatchQueue.main.async {
                if let p { self.profile = p } else { self.error = "Profile not found" }
            }
        }
    }
}
