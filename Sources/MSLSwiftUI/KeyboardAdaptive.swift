import Combine
import SwiftUI

/// Note that the `KeyboardAdaptive` modifier wraps your view in a `GeometryReader`,
/// which attempts to fill all the available space, potentially increasing content view size.
/// Based off: https://github.com/V8tr/KeyboardAvoidanceSwiftUI
struct KeyboardAdaptive: ViewModifier {
    @State
    private var bottomPadding: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .padding(.bottom, self.bottomPadding)
                .onReceive(Publishers.keyboard) { notification in
                    self.bottomPadding = max(0, notification.keyboardHeight - geometry.safeAreaInsets.bottom)
                }
                .animation(.easeOut(duration: 0.16), value: self.bottomPadding)
        }
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

public extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}
