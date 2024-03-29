import XCTest

extension XCTestCase {
    /// Delete the app of the given from the simulator, with the optional ability to close an app (intended to be the
    /// running app) before deleting it
    /// Adapted from https://stackoverflow.com/a/58509930
    public func deleteApp(appNameToDelete: String, appToTerminate: XCUIApplication? = nil) {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        appToTerminate?.terminate()

        let icon = springboard.icons[appNameToDelete]
        if icon.exists {
            let iconFrame = icon.frame
            let springboardFrame = springboard.frame
            icon.press(forDuration: 5)

            // Tap the little "X" button at approximately where it is. The X is not exposed directly
            springboard.coordinate(
                withNormalizedOffset: CGVector(
                    dx: (iconFrame.minX + 3) / springboardFrame.maxX,
                    dy: (iconFrame.minY + 3) / springboardFrame.maxY
                )
            ).tap()

            springboard.alerts.buttons["Delete App"].tap()
            sleep(1)
            springboard.alerts.buttons["Delete"].tap()
        }
    }
}
