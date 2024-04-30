/// Keep the various launch arguments here
enum UITestLaunchArgument: String {
    case TestCase = "-test"
}

/// An example implementation of a UI Test class
final class ExampleUITests: ExampleUITestCase {
    var testValue = 0

    // Is run once before all tests are executed
    override func setUp() {
        launchArguments = [
            UITestLaunchArgument.TestCase.rawValue,
        ]
        super.setUp()
    }

    // Is run once after all tests are executed
    override func tearDown() {
        print(testValue)
        super.tearDown()
    }

    // An example of pressing buttons to navigate through an app
    private func navigateToTestViews() {
        let testTabButton = app.tabBars.buttons["Test"]
        let optionButton = app.buttons["Option1"]
        testTabButton.tap()
        optionButton.tap()
    }
}
