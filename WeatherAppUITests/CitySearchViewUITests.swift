import XCTest

final class CitySearchViewUITests: XCTestCase, UITestBase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = launchApp()
    }

    func testCitySearchShowsIdleState() throws {
        let searchButton = app.buttons["searchCityButton"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()

        let idleLabel = app.staticTexts["Find a city"]
        XCTAssertTrue(idleLabel.waitForExistence(timeout: 5), "City search idle state should appear")
    }

    func testCitySearchShowsResultsForValidQuery() throws {
        let searchButton = app.buttons["searchCityButton"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("London")

        let firstResult = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "cityRow_")).firstMatch
        XCTAssertTrue(firstResult.waitForExistence(timeout: 10), "City search results should appear for 'London'")
    }

    func testCitySearchShowsEmptyStateForNonExistentCity() throws {
        let searchButton = app.buttons["searchCityButton"]
        XCTAssertTrue(searchButton.waitForExistence(timeout: 5))
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("zzzznotacity12345")

        let emptyLabel = app.staticTexts["No cities found"]
        XCTAssertTrue(emptyLabel.waitForExistence(timeout: 10), "Empty state should appear for non-existent city")
    }
}
