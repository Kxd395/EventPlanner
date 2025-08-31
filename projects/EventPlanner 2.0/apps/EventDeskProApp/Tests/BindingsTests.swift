import XCTest
import EventDeskCoreBindings

final class BindingsTests: XCTestCase {
    func testCanonicalCodesContainAllStatuses() {
        let codes = Set(EDPCore.shared.canonicalCodes())
        XCTAssertTrue(codes.contains("preregistered"))
        XCTAssertTrue(codes.contains("walkin"))
        XCTAssertTrue(codes.contains("checkedin"))
        XCTAssertTrue(codes.contains("dna"))
    }

    func testAnalyticsValidation() {
        let json = """
        {"name":"csv_export","timestamp":"2025-01-01T00:00:00Z","payload":{"eventId":"evt_test"}}
        """
        XCTAssertTrue(EDPCore.shared.analyticsValidate(json))
    }
}

