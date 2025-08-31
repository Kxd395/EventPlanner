import SwiftUI
import EventDeskCoreBindings

struct AttendeeCard: View {
    let attendee: EDPCore.AttendeeDTO
    var onCheckIn: ((String)->Void)? = nil
    var onEmail: ((String)->Void)? = nil
    var onRemove: ((String)->Void)? = nil
    var onChangeStatus: ((String)->Void)? = nil // canonical codes
    var onReset: ((String)->Void)? = nil
    var onUndo: (() -> Void)? = nil
    var statusOverride: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Identity line + status dot
            let statusStr = statusOverride ?? attendee.status
            HStack(alignment: .firstTextBaseline) {
                Text(attendee.name).font(.headline).lineLimit(1)
                MemberBadges(isGlobalMember: !attendee.memberId.isEmpty)
                Spacer()
                Circle().fill(EDPDesign.color(for: statusStr)).frame(width: 8, height: 8)
                Menu(content: {
                    if statusStr == "checkedin" { Button("Undo Check-In…") { onUndo?() } }
                    Button("Reset Participation…") { onReset?(attendee.attendeeId) }
                    Divider()
                    Button("Remove from Event…", role: .destructive) { onRemove?(attendee.attendeeId) }
                }, label: { Image(systemName: "ellipsis.circle").imageScale(.medium) })
            }
            // Metadata line
            HStack(spacing: 8) {
                if let company = attendee.company, !company.isEmpty { Text(company) }
                if attendee.email != nil && attendee.company != nil { Text("•").foregroundColor(.secondary) }
                if let email = attendee.email { Text(email) }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            // Status chips (interactive, exclusive selection)
            if let cur = AttendanceStatus(code: statusStr) {
                AttendeeStatusChipGroup(current: cur) { next in
                    onChangeStatus?(next.code)
                }
                .font(.caption2)
            }

            // Primary action varies by status
            HStack(spacing: 6) {
                if statusStr == "checkedin" {
                    Button { onUndo?() } label: { Label("Undo Check-In", systemImage: "arrow.uturn.backward") }
                        .buttonStyle(.bordered)
                } else if statusStr == "dna" {
                    Button { onReset?(attendee.attendeeId) } label: { Label("Revert to Pre-Registered", systemImage: "arrow.uturn.backward") }
                        .buttonStyle(.bordered)
                } else {
                    Button { onCheckIn?(attendee.attendeeId) } label: { Label("Check-In", systemImage: "checkmark") }
                        .buttonStyle(.borderedProminent)
                }
                Button { if let e = attendee.email { onEmail?(e) } } label: { Label("Email", systemImage: "paperplane") }
                Spacer()
                Button(role: .destructive) { onRemove?(attendee.attendeeId) } label: { Label("Remove", systemImage: "trash") }
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary))
        .contextMenu { Button("Open Profile") { /* hook */ } }
    }
}

private extension AttendeeCard {
    @ViewBuilder
    func statusChip(title: String, code: String, color: Color) -> some View {
        let isActive = attendee.status == code
        Button(action: { onChangeStatus?(code) }) {
            HStack(spacing: 4) {
                if isActive && code == "checkedin" { Image(systemName: "checkmark").font(.caption2.weight(.bold)) }
                Text(title)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isActive ? color.opacity(0.95) : color.opacity(0.07))
            .foregroundColor(isActive ? .white : color.opacity(0.95))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(color.opacity(isActive ? 0.0 : 0.7), lineWidth: isActive ? 0 : 1))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .disabled(isActive)
        .accessibilityLabel(Text("Set status: \(title)"))
    }
}
