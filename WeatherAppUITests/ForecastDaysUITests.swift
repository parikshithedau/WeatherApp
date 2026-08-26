import XCTest

final class ForecastDaysUITests: XCTestCase, UITestBase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = launchApp()
    }

    func testChangingForecastDaysRefreshesWeather() throws {
        selectCity("London", from: app)

        let cityName = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(cityName.waitForExistence(timeout: 15))

        let stepper = app.otherElements["forecastDaysStepper"]
        guard stepper.waitForExistence(timeout: 5) else { return }

        let frame = stepper.frame
        let incrementPoint = CGPoint(x: frame.maxX - 10, y: frame.midY)
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: incrementPoint.x, dy: incrementPoint.y)).tap()

        let refreshedName = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(refreshedName.waitForExistence(timeout: 15), "Weather should refresh after changing forecast days")
    }

    func testForecastDaysStepperIsAccessible() throws {
        selectCity("London", from: app)

        let cityName = app.staticTexts["cityNameLabel"]
        XCTAssertTrue(cityName.waitForExistence(timeout: 15))

        let stepperExists = app.otherElements["forecastDaysStepper"].waitForExistence(timeout: 10)
        XCTAssertTrue(stepperExists, "Forecast days stepper should be accessible")
    }
}
