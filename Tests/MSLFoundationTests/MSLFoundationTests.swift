@testable import MSLFoundation
import XCTest

final class MSLFoundationTests: XCTestCase {
    struct MockCodableObject: Codable {
        let name: String
        let profile: URL?
        let age: Int
    }

    enum MockEnum: String {
        case login
        case addFriend
        case logout
    }

    func testUserDefaultsCodable() {
        let personDemo = MockCodableObject(
            name: "John Doe",
            profile: URL(string: "www.google.com"),
            age: 30
        )

        let stateDemo: MockEnum = .addFriend
        let codableKey = "codable_key"
        let enumKey = "enum_key"

        do {
            try UserDefaults.standard.setCodable(personDemo, forKey: codableKey)
        } catch {
            XCTFail("Failed to save codable object")
        }

        do {
            let savedPerson: MockCodableObject = try UserDefaults.standard.getCodable(forKey: codableKey)
            XCTAssert(savedPerson.name == "John Doe")
        } catch {
            XCTFail("Failed to get codable object")
        }

        do {
            try UserDefaults.standard.setRawRepresentable(stateDemo, forKey: enumKey)
        } catch {
            XCTFail("Failed to save RawRepresentable")
        }

        do {
            let savedEnum: MockEnum = try UserDefaults.standard.getRawRepresentable(forKey: enumKey)
            XCTAssert(savedEnum == .addFriend)
        } catch {
            XCTFail("Failed to get RawRepresentable")
        }
    }
}
