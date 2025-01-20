@testable import MSLFoundation
import XCTest
import MSLXCTest

class User {
    let id: Int
    var name: String
    var friends: [String]?
    var coolestFriend: User?
    
    init(id: Int, name: String, friends: [String]? = nil) {
        self.id = id
        self.name = name
        self.friends = friends
    }
    
    var hasFriends: Bool {
        return !self.friends.isEmptyOrNil
    }
    
    func favoriteFriend() -> String? {
        return self.friends?.first
    }
}

class UserBuilder: Buildable {
    var id: Int = 0
    var name: String = "John Doe"
    var friends: [String]?
    
    lazy var coolestFriend: User? = {
        return UserBuilder().build()
    }()
    
    func build() -> User {
        return User(id: self.id, name: self.name, friends: self.friends)
    }
}

struct Animal {
    let legs: Int
    var type: String
    var name: String
}

struct DogBuilder: Buildable {
    let legs: Int = 4
    private let type: String = "Dog"
    var name: String = "Rex"
    
    func build() -> Animal {
        Animal(legs: self.legs, type: self.type, name: self.name)
    }
}

struct CatBuilder: Buildable {
    let legs: Int = 4
    private let type: String = "Cot"
    var name: String = "Spot"
    
    func build() -> Animal {
        Animal(legs: self.legs, type: self.type, name: self.name)
    }
}

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
    
    
    
    func testBuilder() {
        let user1 = UserBuilder().build()
        XCTAssertTrue(user1.favoriteFriend() == nil)
        
        let user2 = UserBuilder()
            .set(\.friends, ["Mei"])
            .build()
        
        XCTAssertTrue(user2.favoriteFriend() == "Mei")
        
        let user3 = UserBuilder()
            .set(\.friends, ["Mei", "Ryan"])
            .build()
        
        XCTAssertTrue(user3.favoriteFriend() == "Mei")
        
        let user4 = UserBuilder()
            .set(\.name, "John")
            .set(\.id, {
                let user = UserBuilder().build()
                return user.id
            })
            .build()
        
        XCTAssert(user4.id == 0)
    }
}
