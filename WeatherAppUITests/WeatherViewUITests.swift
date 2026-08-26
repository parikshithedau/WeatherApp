import XCTest

final class WeatherViewUITests: XCTestCase, UITestBase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = launchApp()
    }

    func testWeatherViewShowsPlaceholderOnLaunch() throws {
        let placeholderText = app.staticTexts["Search for a city"]
        XCTAssertTrue(placeholderText.waitForExistence(timeout: 5), "Placeholder title should appear on launch")
    }

    func testWeatherViewShowsLoadingThenWeatherDataAfterCitySelection() throws {
        selectCity("London", from: app)

        let cityName = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(cityName.waitForExistence(timeout: 15), "Weather data should load and display city name")
    }

    func testWeatherViewRefreshesAfterPullToRefresh() throws {
        selectCity("London", from: app)

        let cityName = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(cityName.waitForExistence(timeout: 15))

        let scrollView = app.scrollViews.firstMatch
        guard scrollView.exists else { return }

        let startCoordinate = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        let endCoordinate = startCoordinate.withOffset(CGVector(dx: 0, dy: 300))
        startCoordinate.press(forDuration: 0.1, thenDragTo: endCoordinate)

        let refreshedName = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(refreshedName.waitForExistence(timeout: 15), "Weather data should still be visible after refresh")
    }
}
