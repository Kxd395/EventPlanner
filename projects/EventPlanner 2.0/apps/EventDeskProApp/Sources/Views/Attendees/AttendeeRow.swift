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
            // Inline status controls per ASCII spec
            HStack(spacing: 6) {
                statusButton(title: "Pre-Registered", code: "preregistered", color: EDPDesign.Status.preregistered)
                statusButton(title: "Walk-in", code: "walkin", color: EDPDesign.Status.walkin)
                statusButton(title: "Check-In", code: "checkedin", color: EDPDesign.Status.checkedin)
                statusButton(title: "DNA", code: "dna", color: EDPDesign.Status.dna)
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

    @ViewBuilder
    private func statusButton(title: String, code: String, color: Color) -> some View {
        let isActive = attendee.status == code
        Button(action: { onChangeStatus?(code) }) {
            HStack(spacing: 4) {
                if isActive && code == "checkedin" {
                    Image(systemName: "checkmark")
                        .font(.caption2.weight(.bold))
                }
                Text(title)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? color.opacity(0.95) : color.opacity(0.07))
            .foregroundColor(isActive ? .white : color.opacity(0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(isActive ? 0.0 : 0.7), lineWidth: isActive ? 0 : 1)
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Set status: \(title)"))
        .disabled(isActive)
    }
}
