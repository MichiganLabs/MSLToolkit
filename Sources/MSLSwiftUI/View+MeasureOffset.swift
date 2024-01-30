import SwiftUI

/// Example Usage:
///
/// ```
/// GeometryReader { geo in
///     ScrollView(showsIndicators: false) {
///         content()
///             .background(theme.background)
///             .padding(.top, imageSize.height - geo.safeAreaInsets.top)
///             .measureOffset(in: .named("scroll")) { offset in
///                 self.offset = offset
///             }
///         }
///         .coordinateSpace(name: "scroll")
/// }
/// ```

public struct OffsetKey: PreferenceKey {
    public static let defaultValue: CGFloat = .zero
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

public extension View {
    func measureOffset(in coords: CoordinateSpace, _ f: @escaping (CGFloat) -> Void) -> some View {
        self.overlay(GeometryReader { geo in
            Color.clear.preference(key: OffsetKey.self, value: geo.frame(in: coords).origin.y)
        }
        .onPreferenceChange(OffsetKey.self, perform: f))
    }
}
