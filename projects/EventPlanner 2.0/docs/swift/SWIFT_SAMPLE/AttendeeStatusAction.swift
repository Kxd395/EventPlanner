import SwiftUI

enum StatusReason: Identifiable {
    case undoCheckin
    var id: Int { 1 }
}

struct StatusActionView: View {
    @State private var showReason: Bool = false
    @State private var reasonText: String = ""

    let current: EDPStatus
    let onCommit: (_ newStatus: EDPStatus, _ reason: String?, _ managerOverride: Bool) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button("Pre-Registered") { attempt(.preregistered) }
            Button("Walk-in") { attempt(.walkin) }
            Button("Checked-In") { attempt(.checkedin) }
            Button("DNA") { attempt(.dna) }
        }
        .alert("Provide reason", isPresented: $showReason) {
            TextField("Reason", text: $reasonText)
            Button("Cancel", role: .cancel) { showReason = false }
            Button("Confirm") {
                onCommit(.preregistered, reasonText.isEmpty ? nil : reasonText, false)
                reasonText = ""
            }
        } message: {
            Text("Undoing check-in requires a reason.")
        }
    }

    private func attempt(_ new: EDPStatus) {
        let check = EDPRustBridge.validateTransition(current: current, new: new, eventInProgress: isEventInProgress(), hasOverride: false)
        switch check {
        case .ok:
            onCommit(new, nil, false)
        case .needsReason:
            showReason = true
        case .needsManagerOverride:
            // Present your manager override UI; if approved:
            onCommit(.dna, nil, true)
        @unknown default:
            break
        }
    }

    private func isEventInProgress() -> Bool {
        // Replace with your event time check
        return true
    }
}
// Last Updated: 2025-08-29 23:15:47Z
