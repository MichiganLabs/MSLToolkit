import Foundation
import XCTest

/**
 Helper class to interact with the Springboard.

 Example usage:
 ```
 let systemAlert = Springboard.getAlert(.locationPermission, for: app)
 if !systemAlert.dialog.waitForExistence(timeout: 5) {
     XCTFail("System Location Permission dialog not shown")
 }

 // Dismiss the system alert
 systemAlert.positiveButton.tap()
 ```
 */
class Springboard {
    static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    static let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")

    /**
     Terminate and delete the app via springboard
     */
    static func deleteApp(named appName: String) {
        XCUIApplication().terminate()

        // Resolve the query for the springboard rather than launching it
        self.springboard.activate()

        // Rotate back to Portrait, just to ensure repeatability here
        XCUIDevice.shared.orientation = UIDeviceOrientation.portrait
        // Sleep to let the device finish its rotation animation, if it needed rotating
        sleep(2)

        // Force delete the app from the springboard
        // Handle iOS 11 iPad 'duplication' of icons (one nested under "Home screen icons" and the other nested
        // under "Multitasking Dock"
        let icon = self.getHomeScreenIconBy(name: appName)

        if icon.exists {
            let iconFrame = icon.frame
            let springboardFrame = self.springboard.frame
            icon.press(forDuration: 2.5)

            // Tap the little "X" button at approximately where it is. The X is not exposed directly
            self.springboard.coordinate(
                withNormalizedOffset: CGVector(
                    dx: (iconFrame.minX + 3) / springboardFrame.maxX,
                    dy: (iconFrame.minY + 3) / springboardFrame.maxY
                )
            ).tap()
            // Wait some time for the animation end
            Thread.sleep(forTimeInterval: 0.5)

            self.springboard.buttons["Delete"].firstMatch.tap()

            // Press home once make the icons stop wiggling
            XCUIDevice.shared.press(.home)

            // Wait some time for the animation end
            Thread.sleep(forTimeInterval: 0.5)
        }
    }

    static func getHomeScreenIconBy(name: String) -> XCUIElement {
        let icon: XCUIElement = if #available(iOS 13, *) {
            springboard.otherElements["Home screen icons"].icons[name]
        } else {
            self.springboard.otherElements["Home screen icons"].scrollViews.otherElements.icons[name]
        }
        return icon
    }

    struct SystemAlert {
        enum AlertType {
            case locationPermission
        }

        let dialog: XCUIElement
        let positiveButton: XCUIElement
        let negativeButton: XCUIElement
        let neutralButton: XCUIElement
    }

    static func getAlert(_ alertType: SystemAlert.AlertType, for app: XCUIApplication) -> SystemAlert {
        let title: String
        let positiveButtonText: String
        let negativeButtonText = ""
        let neutralButtonText = ""

        switch alertType {
        case .locationPermission:
            if #available(iOS 13.4, *) {
                title = "Allow “\(app.label)” to use your location?"
                positiveButtonText = "Allow While Using App"
            } else {
                title = "Allow “\(app.label)” to access your location while you are using the app?"
                positiveButtonText = "Allow"
            }
        }

        let dialog = self.springboard.alerts[title]
        return SystemAlert(
            dialog: dialog,
            positiveButton: dialog.buttons[positiveButtonText],
            negativeButton: dialog.buttons[negativeButtonText],
            neutralButton: dialog.buttons[neutralButtonText]
        )
    }
}
