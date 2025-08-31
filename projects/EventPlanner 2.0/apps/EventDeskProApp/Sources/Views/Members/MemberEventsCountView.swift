import SwiftUI
import EventDeskCoreBindings

struct MemberEventsCountView: View {
    let memberId: String
    @State private var count: Int = 0
    var body: some View {
        Text(count == 1 ? "1 event" : "\(count) events")
            .foregroundColor(.secondary)
            .font(.caption)
            .onAppear(perform: load)
    }
    private func load() {
        // Lightweight fetch for count only
        if let p = EDPCore.shared.memberProfile(memberId: memberId) {
            count = p.events.count
        }
    }
}

