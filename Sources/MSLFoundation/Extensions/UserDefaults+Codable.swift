import UIKit

// Save Codable objects to UserDefaults
public extension UserDefaults {
    enum CodableError: Error {
        case noData
        case badData
    }

    func setCodable(_ value: some Codable, forKey key: String) throws {
        // Putting `value` in an array is a hack for allowing fragments
        let data = try JSONEncoder().encode([value])
        self.setValue(data, forKey: key)
    }

    func getCodable<T: Codable>(forKey key: String) throws -> T {
        guard let data = self.data(forKey: key) else { throw CodableError.noData }

        let results = try JSONDecoder().decode([T].self, from: data)
        guard let result = results.first else { throw CodableError.badData }

        return result
    }
}
