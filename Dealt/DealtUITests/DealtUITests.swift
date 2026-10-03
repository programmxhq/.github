import XCTest

/// Plays one whole life through the real UI: start flow, tutorial, cards until death,
/// the summary and the heirloom that starts the next generation. Screenshots are kept
/// in the test results so a run can be checked by eye.
final class DealtUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiTestReset"]
        app.launch()
    }

    func testPlayAWholeLife() throws {
        snapshot("01-start")
        tap("start.next")
        snapshot("02-ambition")
        tap("start.beBorn")

        let skip = app.buttons["tutorial.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: 5), "first-run tutorial should show")
        snapshot("03-tutorial")
        skip.tap()

        var turns = 0
        var shotCard = false
        var shotOutcome = false
        var shotLate = false
        let heirloom = app.buttons["heirloom.0"]
        while !heirloom.exists {
            turns += 1
            XCTAssertLessThan(turns, 80, "a life should end well before 80 turns")

            let card = app.buttons["hand.card." + String(turns % 3)]
            let liveOn = app.buttons["resolved.liveOn"]
            if card.waitForExistence(timeout: 3) {
                if turns == 12 && !shotLate { snapshot("06-midlife-hand"); shotLate = true }
                reveal(card)
                card.tap()
                let choice = app.buttons["choice.0"]
                XCTAssertTrue(choice.waitForExistence(timeout: 3), "an opened card shows its choices")
                if !shotCard { snapshot("04-card"); shotCard = true }
                reveal(choice)
                choice.tap()
                let next = app.buttons["outcome.continue"]
                XCTAssertTrue(next.waitForExistence(timeout: 3), "a choice shows its outcome")
                if !shotOutcome { snapshot("05-outcome"); shotOutcome = true }
                next.tap()
            } else if liveOn.exists {
                liveOn.tap()
            } else {
                // Possibly mid-transition to the summary.
                _ = heirloom.waitForExistence(timeout: 3)
            }
        }

        XCTAssertGreaterThan(turns, 5, "a life lasts more than a handful of turns")
        snapshot("07-summary")
        app.swipeUp()
        snapshot("08-summary-scrolled")
        app.swipeDown()
        reveal(heirloom)
        heirloom.tap()

        XCTAssertTrue(app.buttons["start.next"].waitForExistence(timeout: 5),
                      "picking an heirloom returns to the start of the next generation")
        snapshot("09-next-generation")
    }

    // MARK: - Helpers

    private func tap(_ id: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[id]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "missing button " + id, file: file, line: line)
        reveal(button)
        button.tap()
    }

    /// Scrolls until the element can be tapped.
    private func reveal(_ element: XCUIElement) {
        var tries = 0
        while !element.isHittable && tries < 4 {
            app.swipeUp()
            tries += 1
        }
    }

    private func snapshot(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
