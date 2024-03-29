import MSLXCTest
import XCTest

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
