/// Keep the various launch arguments here
enum UITestLaunchArgument: String {
    case TestCase = "-test"
}

/// An example implementation of a UI Test class
final class HearseeAppUITests: ExampleUITestCase {
    override func setUp() {
        launchArguments = [
            UITestLaunchArgument.TestCase.rawValue,
        ]
        super.setUp()
    }

    override func tearDown() {
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
