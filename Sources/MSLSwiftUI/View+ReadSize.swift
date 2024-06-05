import SwiftUI

/// https://www.fivestars.blog/articles/swiftui-share-layout-information/
struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value _: inout CGSize, nextValue _: () -> CGSize) {}
}

public extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        self.background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}
