import SwiftUI
import EventDeskCoreBindings

struct AttendeeRow: View {
    let attendee: EDPCore.AttendeeDTO
    var onOpenProfile: ((String) -> Void)? = nil
    var onChangeStatus: ((String) -> Void)? = nil // canonical codes
    var highlighted: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Circle().fill(EDPDesign.color(for: attendee.status)).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 2) {
                Text(attendee.name).font(.headline)
                HStack(spacing: 8) {
                    if let email = attendee.email { Text(email).foregroundColor(.secondary).font(.caption) }
                    if let company = attendee.company { Text(company).foregroundColor(.secondary).font(.caption) }
                }
            }
            Spacer()
            // Inline status controls per ASCII spec — use compact StatusChip
            HStack(spacing: 6) {
                StatusChip(title: "Pre-Registered", color: EDPDesign.Status.preregistered, active: attendee.status == "preregistered", small: true) { onChangeStatus?("preregistered") }
                StatusChip(title: "Walk-in", color: EDPDesign.Status.walkin, active: attendee.status == "walkin", small: true) { onChangeStatus?("walkin") }
                StatusChip(title: "Check-In", color: EDPDesign.Status.checkedin, active: attendee.status == "checkedin", small: true) { onChangeStatus?("checkedin") }
                StatusChip(title: "DNA", color: EDPDesign.Status.dna, active: attendee.status == "dna", small: true) { onChangeStatus?("dna") }
            }
            .font(.caption2)
            if let ts = attendee.checkedInAt { Text(ts).font(.caption2).foregroundColor(.secondary) }
            Button("Profile") { onOpenProfile?(attendee.memberId) }
                .buttonStyle(.bordered)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, highlighted ? 6 : 0)
        .background(highlighted ? Color.accentColor.opacity(0.08) : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(highlighted ? Color.accentColor : Color.clear, lineWidth: highlighted ? 2 : 0)
        )
        .contentShape(Rectangle())
        .accessibilityLabel(Text("Attendee \(attendee.name), status \(attendee.status)"))
    }

    // ...existing code...
}
