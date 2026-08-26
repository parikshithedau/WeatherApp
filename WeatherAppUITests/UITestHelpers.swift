import XCTest

protocol UITestBase: XCTestCase {
    var app: XCUIApplication! { get set }
}

extension UITestBase {
    func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    func selectCity(_ name: String, from app: XCUIApplication) {
        let searchButton = app.buttons["searchCityButton"]
        guard searchButton.waitForExistence(timeout: 5) else { return }
        searchButton.tap()

        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else { return }
        searchField.tap()
        searchField.typeText(name)

        let firstResult = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "cityRow_")).firstMatch
        guard firstResult.waitForExistence(timeout: 10) else { return }
        firstResult.tap()
    }
}
