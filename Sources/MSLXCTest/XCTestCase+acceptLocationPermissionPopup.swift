import XCTest

extension XCTestCase {
    /// TODO: Documentation
    public func acceptLocationPermissionPopup() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowBtn = springboard.buttons["Allow While Using App"]
        if allowBtn.exists {
            allowBtn.tap()
        }
    }
}
