import MSLXCTest
import XCTest

/// An example of a UI Test Case that deletes the app to have a fresh start, passes in any default launch arguments,
/// launches the app, accepts a location
/// permission popup, and then if there are any launch arguments, waits a few seconds to allow any launch related setup
/// to finish
open class ExampleUITestCase: XCTestCase {
    public var app: XCUIApplication!
    public var launchArguments: [String] = []

    override open func setUp() {
        deleteApp(appNameToDelete: "Example")

        super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = launchArguments
        app.launch()

        acceptLocationPermissionPopup()

        // Somewhat hacky way to make sure that debug setup stuff has a chance to finish running
        if !launchArguments.isEmpty {
            sleep(3)
        }
    }

    override open func tearDown() {
        app.terminate()

        super.tearDown()
    }
}
