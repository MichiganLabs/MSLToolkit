import Foundation

/// Some objects (like NSObject) can't conform to Codable. For objects like these, you can make them conform
/// to this protocol and now you can save them to UserDefaults!
public protocol DataTransforming {
    func toData() throws -> Data
    static func fromData(_ data: Data) throws -> Self
}

public extension DataTransforming where Self: NSObject & NSCoding {
    func toData() throws -> Data {
        return try NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }

    static func fromData(_ data: Data) throws -> Self {
        var object: Self?

        let unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        unarchiver.requiresSecureCoding = false

        object = unarchiver.decodeObject(of: self, forKey: NSKeyedArchiveRootObjectKey)

        guard let result = object else { throw UserDefaults.DataTransformingError.conversionFailure }

        return result
    }
}

extension Optional: DataTransforming where Wrapped: DataTransforming {
    public func toData() throws -> Data {
        if case let .some(wrapped) = self {
            return try wrapped.toData()
        } else {
            return Data()
        }
    }

    public static func fromData(_ data: Data) throws -> Self {
        if data.isEmpty {
            return nil
        }

        return try Wrapped.fromData(data)
    }
}
