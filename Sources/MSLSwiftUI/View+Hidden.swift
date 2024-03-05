import SwiftUI

public extension View {

    /// A View extension that allows the passing of a boolean to determine if a View is shown or not on screen.
    /// - Parameter hidden: Determines if the View is displayed on the screen or not.
    /// - Returns: The View with the hidden view modifier added or not.
    @ViewBuilder
    func isHidden(_ hidden: Bool) -> some View {
        if hidden {
            self.hidden()
        } else {
            self
        }
    }
}
