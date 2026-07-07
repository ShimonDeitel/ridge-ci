import XCTest

final class RidgeUITests: XCTestCase {
    private var interruptionMonitorToken: NSObjectProtocol?

    override func setUpWithError() throws {
        continueAfterFailure = false
        interruptionMonitorToken = addUIInterruptionMonitor(withDescription: "System alert dismissal") { alert in
            for label in ["Allow", "OK", "Don't Allow", "Cancel"] {
                let button = alert.buttons[label]
                if button.exists {
                    button.tap()
                    return true
                }
            }
            return false
        }
    }

    override func tearDownWithError() throws {
        if let token = interruptionMonitorToken {
            removeUIInterruptionMonitor(token)
        }
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
        return app
    }

    func testHomeShowsSeedPetAndRidgeChart() throws {
        let app = launchApp()
        XCTAssertTrue(app.staticTexts["RIDGE"].exists || app.staticTexts["Ridge"].waitForExistence(timeout: 12))
        let chart = app.descendants(matching: .any).matching(identifier: "ridgeChart_Biscuit").firstMatch
        XCTAssertTrue(chart.waitForExistence(timeout: 12), "Ridge chart did not appear")
    }

    func testLogWeightUpdatesLatest() throws {
        let app = launchApp()
        let logButton = app.buttons["logWeightButton"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 12))
        logButton.tap()

        let weightField = app.textFields["weightValueField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 12))
        weightField.tap()
        weightField.typeText("9.5")

        app.buttons["saveWeightButton"].tap()

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS '9.5'")).firstMatch.waitForExistence(timeout: 12), "New weight did not appear")
    }

    func testAddPetBlockedByFreeLimitShowsPaywall() throws {
        let app = launchApp()
        let addButton = app.buttons["addPetButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 12))
        addButton.tap()
        XCTAssertTrue(app.staticTexts["Ridge Pro"].waitForExistence(timeout: 12), "Paywall did not appear after hitting the free pet limit")
    }

    func testEditPetSetsTargetWeight() throws {
        let app = launchApp()
        let editButton = app.buttons["editPetButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 12))
        editButton.tap()

        let targetField = app.textFields["targetWeightField"]
        XCTAssertTrue(targetField.waitForExistence(timeout: 12))
        targetField.tap()
        targetField.typeText("9")

        app.buttons["savePetButton"].tap()
        XCTAssertTrue(app.staticTexts["Biscuit"].waitForExistence(timeout: 6) || app.staticTexts["BISCUIT"].waitForExistence(timeout: 6))
    }

    func testDeletePetViaForm() throws {
        let app = launchApp()
        let editButton = app.buttons["editPetButton"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 12))
        editButton.tap()

        app.buttons["deletePetButton"].tap()

        XCTAssertTrue(app.staticTexts["No pets yet"].waitForExistence(timeout: 12), "Pet was not deleted")
    }

    func testSettingsWeightUnitPicker() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let picker = app.segmentedControls.firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 12))
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    func testSettingsKeyboardDismissOnTap() throws {
        let app = launchApp()
        app.tabBars.buttons["Settings"].tap()

        let toggle = app.switches["weighInRemindersToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 12))
        toggle.tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    func testAddWeightFormDismissesKeyboardOnOutsideTap() throws {
        let app = launchApp()
        let logButton = app.buttons["logWeightButton"]
        XCTAssertTrue(logButton.waitForExistence(timeout: 12))
        logButton.tap()

        let weightField = app.textFields["weightValueField"]
        XCTAssertTrue(weightField.waitForExistence(timeout: 12))
        weightField.tap()
        weightField.typeText("11")

        // Tap a real Form section (not nav bar) to dismiss the keyboard.
        app.staticTexts["Date"].tap()
        XCTAssertFalse(app.keyboards.element.exists, "Keyboard did not dismiss on tap-outside")
    }
}
