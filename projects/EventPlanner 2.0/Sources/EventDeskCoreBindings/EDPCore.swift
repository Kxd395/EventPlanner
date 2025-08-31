import Foundation
import CEventDeskCore

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

    public struct CSVPreviewMetrics: Codable { public let total, valid, duplicates, errors: Int }
    public struct CSVRowError: Codable { public let row: UInt64; public let error: String }
    public struct CSVPreviewResult: Codable { public let totals: CSVPreviewMetrics; public let duplicate_emails: [String]; public let errors: [CSVRowError] }
    public struct CSVCommitResult: Codable { public let rowsImported, rowsErrored: UInt64 }

    public func csvPreview(_ csvText: String) throws -> CSVPreviewResult {
        return try csvText.withCString { ptr in
            guard let raw = edp_csv_preview_utf8(ptr) else { throw EDPCoreError.csvPreviewFailed }
            defer { edp_free_cstr(raw) }
            let json = String(cString: raw)
            guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(CSVPreviewResult.self, from: data) else {
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
            let json = String(cString: raw)
            guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(CSVCommitResult.self, from: data) else {
                throw EDPCoreError.csvCommitFailed
            }
            return decoded
        }
    }

    // MARK: - DB-backed CSV commit

    public func setDatabase(path: String) -> Bool {
        path.withCString { edp_set_db_path($0) == 1 }
    }

    public struct CSVCommitOutcome: Codable { public let rowsImported: UInt64; public let rowsErrored: UInt64; public let duplicates: UInt64 }

    public func csvCommit(eventId: String, csvText: String) throws -> CSVCommitOutcome {
        return try eventId.withCString { eidPtr in
            try csvText.withCString { txtPtr in
                guard let raw = edp_csv_commit_for_event(eidPtr, txtPtr) else { throw EDPCoreError.csvCommitFailed }
                defer { edp_free_cstr(raw) }
                let json = String(cString: raw)
                guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(CSVCommitOutcome.self, from: data) else {
                    throw EDPCoreError.csvCommitFailed
                }
                return decoded
            }
        }
    }

    public func csvExport(eventId: String) throws -> String {
        return try eventId.withCString { eid in
            guard let raw = edp_csv_export_for_event(eid) else { throw EDPCoreError.csvCommitFailed }
            defer { edp_free_cstr(raw) }
            return String(cString: raw)
        }
    }

    public struct StatusCounts: Codable { public let preregistered, walkin, checkedin, dna: UInt64 }
    public func countsByStatus(eventId: String) throws -> StatusCounts {
        return try eventId.withCString { eid in
            guard let raw = edp_counts_by_status(eid) else { throw EDPCoreError.csvCommitFailed }
            defer { edp_free_cstr(raw) }
            let json = String(cString: raw)
            guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(StatusCounts.self, from: data) else {
                throw EDPCoreError.csvCommitFailed
            }
            return decoded
        }
    }

    // MARK: - Attendees & Members
    public struct AttendeeDTO: Codable { public let attendeeId, memberId, eventId, name: String; public let email, company: String?; public let status: String; public let checkedInAt: String? }
    public func listAttendees(eventId: String) throws -> [AttendeeDTO] {
        return try eventId.withCString { eid in
            guard let raw = edp_list_attendance(eid) else { throw EDPCoreError.csvCommitFailed }
            defer { edp_free_cstr(raw) }
            let json = String(cString: raw)
            guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode([AttendeeDTO].self, from: data) else { throw EDPCoreError.csvCommitFailed }
            return decoded
        }
    }

    @discardableResult
    public func removeAttendance(attendanceId: String, reason: String? = nil, changedBy: String? = nil) -> Bool {
        return attendanceId.withCString { aid in
            (reason ?? "").withCString { rs in
                (changedBy ?? "").withCString { cb in
                    edp_remove_attendance(aid, (reason == nil ? nil : rs), (changedBy == nil ? nil : cb)) == 1
                }
            }
        }
    }

    public struct MemberDTO: Codable { public let id: String; public let email: String?; public let firstName: String; public let lastName: String; public let company: String? }
    public func searchMembers(query: String, limit: Int32 = 20) throws -> [MemberDTO] {
        return try query.withCString { q in
            guard let raw = edp_search_members(q, limit) else { throw EDPCoreError.csvCommitFailed }
            defer { edp_free_cstr(raw) }
            let json = String(cString: raw)
            guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode([MemberDTO].self, from: data) else { throw EDPCoreError.csvCommitFailed }
            return decoded
        }
    }

    // MARK: - Create Member
    public func createMember(email: String? = nil, firstName: String, lastName: String = "", phone: String? = nil, company: String? = nil, tags: String? = nil, notes: String? = nil) throws -> String {
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty || !(email ?? "").trimmingCharacters(in: .whitespaces).isEmpty else {
            throw EDPCoreError.csvCommitFailed
        }
        return try (email ?? "").withCString { em in
            try firstName.withCString { fn in
                try lastName.withCString { ln in
                    try (phone ?? "").withCString { ph in
                        try (company ?? "").withCString { co in
                            try (tags ?? "").withCString { tg in
                                try (notes ?? "").withCString { nt in
                                    guard let raw = edp_create_member((email == nil ? nil : em), fn, ln, (phone == nil ? nil : ph), (company == nil ? nil : co), (tags == nil ? nil : tg), (notes == nil ? nil : nt)) else { throw EDPCoreError.csvCommitFailed }
                                    defer { edp_free_cstr(raw) }
                                    return String(cString: raw)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Update Member
    @discardableResult
    public func updateMember(id: String, email: String? = nil, firstName: String? = nil, lastName: String? = nil, phone: String? = nil, company: String? = nil, tags: String? = nil, notes: String? = nil) -> Bool {
        return id.withCString { mid in
            (email ?? "").withCString { em in
                (firstName ?? "").withCString { fn in
                    (lastName ?? "").withCString { ln in
                        (phone ?? "").withCString { ph in
                            (company ?? "").withCString { co in
                                (tags ?? "").withCString { tg in
                                    (notes ?? "").withCString { nt in
                                        edp_update_member(mid,
                                                          (email == nil ? nil : em),
                                                          (firstName == nil ? nil : fn),
                                                          (lastName == nil ? nil : ln),
                                                          (phone == nil ? nil : ph),
                                                          (company == nil ? nil : co),
                                                          (tags == nil ? nil : tg),
                                                          (notes == nil ? nil : nt)) == 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public struct WalkinResult: Codable { public let attendanceId, memberId, eventId, status: String }
    public func createWalkin(eventId: String, name: String, email: String? = nil, phone: String? = nil, company: String? = nil, immediateCheckin: Bool = false, changedBy: String? = nil) throws -> WalkinResult {
        return try eventId.withCString { eid in
            try name.withCString { nm in
                try (email ?? "").withCString { em in
                    try (phone ?? "").withCString { ph in
                        try (company ?? "").withCString { co in
                            try (changedBy ?? "").withCString { cb in
                                guard let raw = edp_create_walkin(eid, nm, (email == nil ? nil : em), (phone == nil ? nil : ph), (company == nil ? nil : co), immediateCheckin, (changedBy == nil ? nil : cb)) else { throw EDPCoreError.csvCommitFailed }
                                defer { edp_free_cstr(raw) }
                                let json = String(cString: raw)
                                guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(WalkinResult.self, from: data) else { throw EDPCoreError.csvCommitFailed }
                                return decoded
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Merge Members
    @discardableResult
    public func mergeMembers(primaryId: String, duplicateId: String) throws -> Int64 {
        return try primaryId.withCString { p in
            try duplicateId.withCString { d in
                let n = edp_merge_members(p, d)
                if n < 0 { throw EDPCoreError.invalidStatus }
                return n
            }
        }
    }

    // MARK: - Events
    public struct EventDTO: Codable { public let id: String; public let name, startsAt, endsAt: String; public let location: String?; public let capacity: Int64?; public let status, timezone, description: String? }
    public func createEvent(id: String? = nil, name: String, startsAt: String, endsAt: String, location: String? = nil, capacity: Int64 = 0, status: String? = nil, timezone: String? = nil, description: String? = nil) throws -> String {
        return try name.withCString { nm in
            try startsAt.withCString { st in
                try endsAt.withCString { en in
                    try (id ?? "").withCString { idc in
                        try (location ?? "").withCString { loc in
                            try (status ?? "").withCString { stc in
                                try (timezone ?? "").withCString { tz in
                                    try (description ?? "").withCString { ds in
                                        guard let raw = edp_create_event((id == nil ? nil : idc), nm, st, en, (location == nil ? nil : loc), capacity, (status == nil ? nil : stc), (timezone == nil ? nil : tz), (description == nil ? nil : ds)) else { throw EDPCoreError.csvCommitFailed }
                                        defer { edp_free_cstr(raw) }
                                        return String(cString: raw)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    public func updateEvent(id: String, name: String? = nil, startsAt: String? = nil, endsAt: String? = nil, location: String? = nil, capacity: Int64 = 0, status: String? = nil, timezone: String? = nil, description: String? = nil) -> Bool {
        return id.withCString { idc in
            (name ?? "").withCString { nm in
                (startsAt ?? "").withCString { st in
                    (endsAt ?? "").withCString { en in
                        (location ?? "").withCString { loc in
                            (status ?? "").withCString { stc in
                                (timezone ?? "").withCString { tz in
                                    (description ?? "").withCString { ds in
                                        edp_update_event(idc, (name == nil ? nil : nm), (startsAt == nil ? nil : st), (endsAt == nil ? nil : en), (location == nil ? nil : loc), capacity, (status == nil ? nil : stc), (timezone == nil ? nil : tz), (description == nil ? nil : ds)) == 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public func listEvents(limit: Int64 = 50, offset: Int64 = 0) throws -> [EventDTO] {
        guard let raw = edp_list_events(limit, offset) else { throw EDPCoreError.csvCommitFailed }
        defer { edp_free_cstr(raw) }
        let json = String(cString: raw)
        guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode([EventDTO].self, from: data) else { throw EDPCoreError.csvCommitFailed }
        return decoded
    }

    public func analyticsValidate(_ json: String) -> Bool {
        json.withCString { edp_analytics_validate($0) == 1 }
    }

    public func analyticsEmit(_ json: String) throws {
        guard analyticsValidate(json) else { throw EDPCoreError.analyticsInvalid }
        _ = json.withCString { edp_analytics_emit($0) }
    }

    // MARK: - Analytics Store
    @discardableResult
    public func setAnalyticsPath(_ path: String) -> Bool {
        path.withCString { edp_set_analytics_path($0) == 1 }
    }

    // MARK: - Errors
    public func lastError() -> String? {
        guard let raw = edp_last_error_message() else { return nil }
        defer { edp_free_cstr(raw) }
        return String(cString: raw)
    }

    // MARK: - Migration checks
    public func statusV2Nulls(eventId: String) -> Int64 {
        return eventId.withCString { eid in
            edp_status_v2_nulls(eid)
        }
    }

    @discardableResult
    public func statusV2Backfill(eventId: String) -> Int64 {
        return eventId.withCString { eid in
            edp_status_v2_backfill(eid)
        }
    }

    // MARK: - Member Profile
    public struct MemberProfile: Codable { public let id: String; public let email: String?; public let firstName: String; public let lastName: String; public let company: String?; public let events: [[String]] }
    public func memberProfile(memberId: String) -> MemberProfile? {
        return memberId.withCString { mid in
            guard let raw = edp_member_profile(mid) else { return nil }
            defer { edp_free_cstr(raw) }
            let json = String(cString: raw)
            guard let data = json.data(using: .utf8), let decoded = try? JSONDecoder().decode(MemberProfile.self, from: data) else { return nil }
            return decoded
        }
    }

    // MARK: - Status Update (DB-backed)
    @discardableResult
    public func updateStatus(attendanceId: String, newStatus: String, inProgress: Bool, override: Bool, reason: String? = nil, changedBy: String? = nil) throws -> Bool {
        guard isCanonical(newStatus) else { throw EDPCoreError.invalidStatus }
        let ok = attendanceId.withCString { att in
            newStatus.withCString { ns in
                (reason ?? "").withCString { rs in
                    (changedBy ?? "").withCString { cb in
                        edp_update_status(att, ns, inProgress, override, (reason == nil ? nil : rs), (changedBy == nil ? nil : cb)) == 1
                    }
                }
            }
        }
        if !ok { throw EDPCoreError.invalidStatus } // retrieve lastError() for details
        return ok
    }

    // Bulk status update
    @discardableResult
    public func bulkStatusUpdate(eventId: String, attendeeIds: [String], newStatus: String, inProgress: Bool, override: Bool, reason: String? = nil, changedBy: String? = nil) throws -> Int64 {
        guard isCanonical(newStatus), !attendeeIds.isEmpty else { return 0 }
        let joined = attendeeIds.joined(separator: ",")
        return try eventId.withCString { eid in
            try joined.withCString { ids in
                try newStatus.withCString { ns in
                    try (reason ?? "").withCString { rs in
                        try (changedBy ?? "").withCString { cb in
                            let n = edp_bulk_status_update(eid, ids, ns, inProgress, override, (reason == nil ? nil : rs), (changedBy == nil ? nil : cb))
                            if n < 0 { throw EDPCoreError.invalidStatus }
                            return n
                        }
                    }
                }
            }
        }
    }
}
