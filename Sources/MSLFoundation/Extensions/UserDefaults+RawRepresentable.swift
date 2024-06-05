import Foundation

public extension UserDefaults {
    func setRawRepresentable<T: RawRepresentable>(_ value: T, forKey key: String) throws where T.RawValue: Codable {
        try self.setCodable(value.rawValue, forKey: key)
    }

    func getRawRepresentable<T: RawRepresentable>(forKey key: String) throws -> T where T.RawValue: Codable {
        let enumRaw = try self.getCodable(forKey: key) as T.RawValue

        // swiftlint:disable:next explicit_init
        guard let enumValue = T(rawValue: enumRaw) else { throw CodableError.badData }

        return enumValue
    }
}
