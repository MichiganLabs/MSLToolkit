import Combine
import UIKit

public extension Publishers {
    static var keyboard: AnyPublisher<Notification, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)

        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}
