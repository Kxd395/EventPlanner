import Foundation

// Requires bridging header that includes: #include "eventdesk_core.h"

public enum EDPCoreError: Error {
    case invalidStatus
    case csvPreviewFailed
    case csvCommitFailed
    case analyticsInvalid
}

public final class EDPCore {
    public static let shared = EDPCore()
    private init() {}

    public var version: String { String(cString: edp_core_version()) }

    public func canonicalCodes() -> [String] {
        (0..<Int(edp_ssot_status_count())).compactMap { idx in
            guard let c = edp_ssot_status_code_at(Int32(idx)) else { return nil }
            return String(cString: c)
        }
    }

    public func isCanonical(_ code: String) -> Bool {
        code.withCString { edp_validate_status_code($0) == 1 }
    }

    public func normalize(_ raw: String) -> String? {
        raw.withCString { ptr in
            let code = edp_normalize_status(ptr)
            guard let c = edp_status_to_str(code) else { return nil }
            return String(cString: c)
        }
    }

    public func validateTransition(current: String, new: String, inProgress: Bool, override: Bool) throws -> Int32 {
        guard let cCur = current.cString(using: .utf8), edp_validate_status_code(cCur) == 1,
              let cNew = new.cString(using: .utf8), edp_validate_status_code(cNew) == 1 else {
            throw EDPCoreError.invalidStatus
        }
        let curCode = edp_status_from_str(cCur)
        let newCode = edp_status_from_str(cNew)
        return edp_validate_transition(curCode, newCode, inProgress, override)
    }

    public func autoRolloverDue(eventEnd: TimeInterval, graceSeconds: TimeInterval = 3*3600, now: TimeInterval = Date().timeIntervalSince1970) -> Bool {
        edp_auto_rollover_due(Int64(eventEnd), Int64(graceSeconds), Int64(now)) == 1
    }

    public func csvPreview(_ csvText: String) throws -> CSVPreviewResult {
        return try csvText.withCString { ptr in
            guard let raw = edp_csv_preview_utf8(ptr) else { throw EDPCoreError.csvPreviewFailed }
            defer { edp_free_cstr(raw) }
            let data = Data(bytesNoCopy: raw, count: strlen(raw), deallocator: .none)
            guard let decoded = try? JSONDecoder().decode(CSVPreviewResult.self, from: data) else {
                throw EDPCoreError.csvPreviewFailed
            }
            return decoded
        }
    }

    public func csvCommit(preview: CSVPreviewResult) throws -> CSVCommitResult {
        let jsonData = try JSONEncoder().encode(preview)
        return try jsonData.withUnsafeBytes { buf in
            let ptr = buf.bindMemory(to: CChar.self).baseAddress!
            guard let raw = edp_csv_commit_preview_json(ptr) else { throw EDPCoreError.csvCommitFailed }
            defer { edp_free_cstr(raw) }
            let data = Data(bytesNoCopy: raw, count: strlen(raw), deallocator: .none)
            guard let decoded = try? JSONDecoder().decode(CSVCommitResult.self, from: data) else {
                throw EDPCoreError.csvCommitFailed
            }
            return decoded
        }
    }

    public func analyticsValidate(_ json: String) -> Bool {
        json.withCString { edp_analytics_validate($0) == 1 }
    }

    public func analyticsEmit(_ json: String) throws {
        guard analyticsValidate(json) else { throw EDPCoreError.analyticsInvalid }
        _ = json.withCString { edp_analytics_emit($0) }
    }
}
// Last Updated: 2025-08-29 23:15:47Z
