import Foundation

public extension UserDefaults {
    enum DataTransformingError: Error {
        case conversionFailure
        case emptyData
        case noData
    }

    func setDataTransforming(_ value: DataTransforming, forKey key: String) throws {
        let data = try value.toData()
        self.set(data, forKey: key)
    }

    func objectDataTransforming<T: DataTransforming>(forKey key: String) throws -> T {
        guard let data = self.data(forKey: key) else { throw DataTransformingError.noData }
        return try T.fromData(data)
    }
}
