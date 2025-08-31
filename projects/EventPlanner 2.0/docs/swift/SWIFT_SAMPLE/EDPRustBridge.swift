// Sample Swift wrapper for Rust C FFI
// Requires bridging header importing: #include "eventdesk_core.h"

import Foundation

public enum EDPStatus: Int32 {
    case preregistered = 0, walkin = 1, checkedin = 2, dna = 3
}

public enum EDPTransitionCheck: Int32 {
    case ok = 0, needsReason = 1, needsManagerOverride = 2
}

public enum EDPRustBridge {
    public static func status(from string: String) -> EDPStatus? {
        return string.withCString { ptr in
            let code = edp_status_from_str(ptr)
            return EDPStatus(rawValue: code)
        }
    }

    public static func codeString(for status: EDPStatus) -> String? {
        guard let cstr = edp_status_to_str(status.rawValue) else { return nil }
        return String(cString: cstr)
    }

    public static func label(for status: EDPStatus) -> String? {
        guard let cstr = edp_status_label(status.rawValue) else { return nil }
        return String(cString: cstr)
    }

    public static func validateTransition(current: EDPStatus, new: EDPStatus, eventInProgress: Bool, hasOverride: Bool) -> EDPTransitionCheck {
        let res = edp_validate_transition(current.rawValue, new.rawValue, eventInProgress, hasOverride)
        return EDPTransitionCheck(rawValue: res) ?? .ok
    }
}
// Last Updated: 2025-08-29 23:15:47Z
