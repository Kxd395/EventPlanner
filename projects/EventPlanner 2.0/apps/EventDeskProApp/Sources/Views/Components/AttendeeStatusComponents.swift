import SwiftUI

// Canonical attendee status used by chips/buttons
enum AttendanceStatus: CaseIterable, Equatable {
    case preregistered, walkin, checkedin, dna

    init?(code: String) {
        switch code.lowercased() {
        case "preregistered": self = .preregistered
        case "walkin": self = .walkin
        case "checkedin": self = .checkedin
        case "dna": self = .dna
        default: return nil
        }
    }

    var code: String {
        switch self {
        case .preregistered: return "preregistered"
        case .walkin: return "walkin"
        case .checkedin: return "checkedin"
        case .dna: return "dna"
        }
    }

    var title: String {
        switch self {
        case .preregistered: return "Pre-Registered"
        case .walkin: return "Walk-in"
        case .checkedin: return "Checked-In"
        case .dna: return "DNA"
        }
    }

    var color: Color {
        switch self {
        case .preregistered: return EDPDesign.Status.preregistered
        case .walkin: return EDPDesign.Status.walkin
        case .checkedin: return EDPDesign.Status.checkedin
        case .dna: return EDPDesign.Status.dna
        }
    }
}

struct AttendeeStatusChip: View {
    let status: AttendanceStatus
    let isSelected: Bool
    let isDisabled: Bool
    var action: () -> Void

    var body: some View {
        Button {
            if !isDisabled { action() }
        } label: {
            let baseTitle = status.title
            let title = (status == .checkedin && isSelected) ? "\u{2713} \(baseTitle)" : baseTitle
            Text(title)
                .font(.callout.weight(isSelected ? .semibold : .regular))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .foregroundStyle(isSelected ? Color.white : status.color)
                .background(isSelected ? status.color : .clear)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? .clear : status.color, lineWidth: 1))
                .opacity(isDisabled ? 0.5 : 1)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(status.title)\(isSelected ? ", selected" : "")"))
    }
}

struct AttendeeStatusChipGroup: View {
    let current: AttendanceStatus
    var canSetDNA: Bool = true
    var setStatus: (AttendanceStatus) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AttendanceStatus.allCases, id: \.self) { s in
                AttendeeStatusChip(status: s,
                                   isSelected: current == s,
                                   isDisabled: (s == .dna && !canSetDNA)) {
                    guard current != s else { return }
                    setStatus(s)
                }
            }
        }
    }
}

struct MemberBadges: View {
    var isGlobalMember: Bool
    var isVIP: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if isGlobalMember {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.green)
                    .help("Member profile linked")
            } else {
                Image(systemName: "person.fill.badge.plus")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                    .help("Event-only contact")
            }
            if isVIP {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .help("VIP")
            }
        }
        .font(.caption)
    }
}

