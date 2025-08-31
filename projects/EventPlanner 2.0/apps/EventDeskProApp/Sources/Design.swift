import SwiftUI

enum EDPDesign {
    // Status Colors (SSOT authoritative)
    static let blue = Color(red: 0x25/255.0, green: 0x63/255.0, blue: 0xeb/255.0)
    static let purple = Color(red: 0x8b/255.0, green: 0x5c/255.0, blue: 0xf6/255.0)
    static let green = Color(red: 0x16/255.0, green: 0xa3/255.0, blue: 0x4a/255.0)
    static let gray = Color(red: 0x6b/255.0, green: 0x72/255.0, blue: 0x80/255.0)

    enum Status {
        static let preregistered = EDPDesign.blue
        static let walkin = EDPDesign.purple
        static let checkedin = EDPDesign.green
        static let dna = EDPDesign.gray
    }

    static func color(for status: String) -> Color {
        switch status.lowercased() {
        case "preregistered": return Status.preregistered
        case "walkin": return Status.walkin
        case "checkedin": return Status.checkedin
        case "dna": return Status.dna
        default: return .secondary
        }
    }
}
