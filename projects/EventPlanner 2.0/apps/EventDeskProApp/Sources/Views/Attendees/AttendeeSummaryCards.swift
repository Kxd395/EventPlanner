import SwiftUI
import EventDeskCoreBindings

struct AttendeeSummaryCards: View {
    let counts: EDPCore.StatusCounts
    enum Card { case preregistered, walkin, checkedin, dna }
    var onSelect: (Card) -> Void

    var body: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "Pre-Registered", count: Int(counts.preregistered), color: EDPDesign.Status.preregistered) { onSelect(.preregistered) }
            SummaryCard(title: "Walk-in", count: Int(counts.walkin), color: EDPDesign.Status.walkin) { onSelect(.walkin) }
            SummaryCard(title: "Checked-In", count: Int(counts.checkedin), color: EDPDesign.Status.checkedin) { onSelect(.checkedin) }
            SummaryCard(title: "DNA", count: Int(counts.dna), color: EDPDesign.Status.dna) { onSelect(.dna) }
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let count: Int
    let color: Color
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.caption).foregroundColor(.secondary)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(count)").font(.title2).bold().foregroundColor(.primary)
                    Circle().fill(color).frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(.thinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(title): \(count)"))
    }
}

