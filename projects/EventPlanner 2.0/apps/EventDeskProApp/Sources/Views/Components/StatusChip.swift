import SwiftUI
import EventDeskCoreBindings

struct StatusChip: View {
    let title: String
    let color: Color
    var active: Bool = false
    var count: Int? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.caption).bold()
                if let c = count { Text("\(c)").font(.caption2).opacity(0.9) }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(active ? color.opacity(0.18) : Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(color, lineWidth: active ? 2 : 1)
            )
            .foregroundColor(color)
            .cornerRadius(6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Filter: \(title)"))
    }
}

struct StatusFilterBar: View {
    enum Status: String, CaseIterable { case all, preregistered, walkin, checkedin, dna }
    @Binding var selected: Status
    var counts: EDPCore.StatusCounts? = nil
    var onChange: ((Status) -> Void)? = nil

    var body: some View {
        HStack(spacing: 8) {
            StatusChip(title: "All", color: .secondary, active: selected == .all, count: totalCount) { set(.all) }
            StatusChip(title: "Pre-Registered", color: EDPDesign.Status.preregistered, active: selected == .preregistered, count: Int(counts?.preregistered ?? 0)) { set(.preregistered) }
            StatusChip(title: "Walk-in", color: EDPDesign.Status.walkin, active: selected == .walkin, count: Int(counts?.walkin ?? 0)) { set(.walkin) }
            StatusChip(title: "Checked-In", color: EDPDesign.Status.checkedin, active: selected == .checkedin, count: Int(counts?.checkedin ?? 0)) { set(.checkedin) }
            StatusChip(title: "DNA", color: EDPDesign.Status.dna, active: selected == .dna, count: Int(counts?.dna ?? 0)) { set(.dna) }
        }
    }

    private var totalCount: Int? {
        guard let c = counts else { return nil }
        return Int(c.preregistered + c.walkin + c.checkedin + c.dna)
    }

    private func set(_ s: Status) { selected = s; onChange?(s) }
}
