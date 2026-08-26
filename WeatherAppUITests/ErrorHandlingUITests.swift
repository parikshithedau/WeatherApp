import XCTest

final class ErrorHandlingUITests: XCTestCase, UITestBase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = launchApp()
    }

    func testWeatherViewHandlesNetworkGracefully() throws {
        let searchButton = app.buttons["searchCityButton"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("London")

        let firstResult = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "cityRow_")).firstMatch
        guard firstResult.waitForExistence(timeout: 10) else { return }
        firstResult.tap()

        let cityName = app.staticTexts["cityNameLabel"]
        let errorContent = app.otherElements["errorContent"]
        let loaded = cityName.waitForExistence(timeout: 15)
        let errored = errorContent.waitForExistence(timeout: 0)
        XCTAssertTrue(loaded || errored, "Should show either weather data or error state")
    }
}
