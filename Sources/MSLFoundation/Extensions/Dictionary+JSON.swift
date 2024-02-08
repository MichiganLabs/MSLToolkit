import Foundation

public extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    func jsonString(
        _ options: JSONSerialization.WritingOptions = .prettyPrinted
    ) -> String? {
        guard let stringData = try? JSONSerialization.data(
            withJSONObject: self as NSDictionary,
            options: options
        ) else {
            return nil
        }

        return String(data: stringData, encoding: .utf8)
    }

    static func from(
        json string: String,
        options: JSONSerialization.ReadingOptions = .fragmentsAllowed
    ) -> [String: Any]? {
        guard let data = string.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: options)) as? [String: Any]
    }
}
