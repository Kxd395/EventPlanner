import SwiftUI
import EventDeskCoreBindings

struct StatusChip: View {
    let title: String
    let color: Color
    var active: Bool = false
    var small: Bool = false
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 6) {
                if active && title.lowercased().contains("check") {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                Text(title)
                    .font(small ? .caption2.weight(active ? .semibold : .regular) : .caption.weight(active ? .semibold : .regular))
            }
            .padding(.horizontal, small ? 8 : 10).padding(.vertical, small ? 4 : 6)
            .background(active ? color.opacity(0.95) : color.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color.opacity(active ? 0.0 : 0.7), lineWidth: active ? 0 : 1)
            )
            .foregroundColor(active ? .white : color.opacity(0.95))
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Status: \(title)"))
    }
}

struct StatusFilterBar: View {
    enum Status: String, CaseIterable, Identifiable {
        case all, preregistered, walkin, checkedin, dna
        var id: String { rawValue }
        var title: String {
            switch self {
            case .all: return "All"
            case .preregistered: return "Pre-Registered"
            case .walkin: return "Walk-in"
            case .checkedin: return "Checked-In"
            case .dna: return "DNA"
            }
        }
        var color: Color {
            switch self {
            case .all: return .secondary
            case .preregistered: return EDPDesign.Status.preregistered
            case .walkin: return EDPDesign.Status.walkin
            case .checkedin: return EDPDesign.Status.checkedin
            case .dna: return EDPDesign.Status.dna
            }
        }
    }

    @Binding var selected: Status
    var counts: EDPCore.StatusCounts? = nil
    var onChange: ((Status) -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Status.allCases) { s in
                let isSel = (s == selected)
                Button(action: { set(s) }) {
                    Text(s.title)
                        .font(.callout.weight(isSel ? .semibold : .regular))
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(isSel ? s.color : Color.clear)
                        .foregroundColor(isSel ? Color.white : s.color)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(s.color, lineWidth: isSel ? 0 : 1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(keyFor(s))
                .accessibilityLabel(Text(s.title))
                .accessibilityAddTraits(isSel ? .isSelected : [])
                .accessibilityRole(.tab)
            }
            Spacer()
            Text("Total: \(totalCount ?? 0)").foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityRole(.tabGroup)
        .accessibilityLabel("Attendee filter")
    }

    private var totalCount: Int? {
        guard let c = counts else { return nil }
        return Int(c.preregistered + c.walkin + c.checkedin + c.dna)
    }

    private func set(_ s: Status) { selected = s; onChange?(s) }

    private func keyFor(_ s: Status) -> KeyEquivalent {
        switch s {
        case .all: return "1"
        case .preregistered: return "2"
        case .walkin: return "3"
        case .checkedin: return "4"
        case .dna: return "5"
        }
    }
}
