import Foundation

public struct CSVPreviewMetrics: Codable {
    public let total: Int
    public let valid: Int
    public let duplicates: Int
    public let errors: Int
}

public struct CSVRowError: Codable {
    public let row: UInt64
    public let error: String
}

public struct CSVPreviewResult: Codable {
    public let totals: CSVPreviewMetrics
    public let duplicate_emails: [String]
    public let errors: [CSVRowError]
}

public struct CSVCommitResult: Codable {
    public let rowsImported: UInt64
    public let rowsErrored: UInt64
}
// Last Updated: 2025-08-29 23:15:47Z
