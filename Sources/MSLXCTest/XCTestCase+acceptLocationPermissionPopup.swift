import XCTest

extension XCTestCase {
    /// If a location permission popup exists, selects the "Allow While Using App" option
    public func acceptLocationPermissionPopup() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowBtn = springboard.buttons["Allow While Using App"]
        if allowBtn.exists {
            allowBtn.tap()
        }
    }
}
