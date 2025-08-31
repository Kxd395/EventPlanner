import Foundation

final class AttendeesViewModel: ObservableObject {
    @Published var errorMessage: String?
    @Published var preview: CSVPreviewResult?
    private let core = EDPCore.shared

    func attemptStatusChange(current: String, new: String, inProgress: Bool, managerOverride: Bool, commit: (_ proceed: Bool, _ needsReason: Bool) -> Void) {
        do {
            let check = try core.validateTransition(current: current, new: new, inProgress: inProgress, override: managerOverride)
            switch check {
            case 0: commit(true, false)
            case 1: commit(false, true) // needs reason
            case 2: errorMessage = "Manager override required for early DNA."
            default: commit(false, false)
            }
        } catch {
            errorMessage = "Invalid status change"
        }
    }

    func loadCSVPreview(text: String) {
        do { preview = try core.csvPreview(text) } catch { errorMessage = "CSV preview failed" }
    }

    func commitCSV() {
        guard let p = preview else { return }
        do {
            let result = try core.csvCommit(preview: p)
            // Replace with real toast/alert
            print("Imported: \(result.rowsImported), Errors: \(result.rowsErrored)")
        } catch {
            errorMessage = "CSV commit failed"
        }
    }
}
// Last Updated: 2025-08-29 23:15:47Z
