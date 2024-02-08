import Foundation

public extension Encodable {
    func asDictionary(
        encoder: JSONEncoder = JSONEncoder(),
        options: JSONSerialization.ReadingOptions = .fragmentsAllowed
    ) -> [String: Any]? {
        guard
            let data = try? encoder.encode(self),
            let dictionary = (try? JSONSerialization.jsonObject(
                with: data,
                options: options
            ) as? [String: Any])
        else {
            return nil
        }
        return dictionary
    }

    func jsonString(_ encoder: JSONEncoder = JSONEncoder()) -> String? {
        guard let json = try? encoder.encode(self) else { return nil }
        return String(data: json, encoding: .utf8)
    }
}

extension Decodable {
    public static func json(from string: String, decoder: JSONDecoder = JSONDecoder()) -> Self? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try? decoder.decode(self, from: data)
    }
}
