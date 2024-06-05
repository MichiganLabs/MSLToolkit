import Combine
import Foundation

public protocol Publishing {
    associatedtype Output
    var publisher: AnyPublisher<Output, Never> { get }
}
