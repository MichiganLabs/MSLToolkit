import Foundation
import Combine

public protocol Publishing {
    associatedtype Output
    var publisher: AnyPublisher<Output, Never> { get }
}
