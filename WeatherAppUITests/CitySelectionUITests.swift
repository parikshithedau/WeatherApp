import XCTest

final class CitySelectionUITests: XCTestCase, UITestBase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = launchApp()
    }

    func testSelectingCityNavigatesBackAndLoadsWeather() throws {
        selectCity("Paris", from: app)

        let cityName = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(cityName.waitForExistence(timeout: 15), "Weather should load after selecting Paris")
        XCTAssertTrue(cityName.label.contains("Paris"), "City name should contain 'Paris'")
    }

    func testSelectingDifferentCitiesUpdatesWeatherDisplay() throws {
        selectCity("London", from: app)
        let londonLabel = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(londonLabel.waitForExistence(timeout: 15))
        XCTAssertTrue(londonLabel.label.contains("London"))

        let searchButton = app.buttons["searchCityButton"]
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("Tokyo")

        let tokyoResult = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "cityRow_")).firstMatch
        XCTAssertTrue(tokyoResult.waitForExistence(timeout: 10))
        tokyoResult.tap()

        let tokyoLabel = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(tokyoLabel.waitForExistence(timeout: 15), "Weather should update for Tokyo")
        XCTAssertTrue(tokyoLabel.label.contains("Tokyo"), "City name should contain 'Tokyo'")
    }
}
