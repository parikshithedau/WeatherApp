import XCTest
@testable import WeatherApp

@MainActor
final class PresentationFormattingTests: XCTestCase {
    func testWeatherConditionDescriptionCoversAllAPICategoriesAndFallback() {
        let testCases: [(Int, String)] = [
            (0, StringConstant.Weather.clearSky),
            (2, StringConstant.Weather.partlyCloudy),
            (45, StringConstant.Weather.foggy),
            (53, StringConstant.Weather.drizzle),
            (63, StringConstant.Weather.rain),
            (75, StringConstant.Weather.snow),
            (96, StringConstant.Weather.thunderstorm),
            (-1, StringConstant.Weather.unknownConditions)
        ]

        for (code, expected) in testCases {
            XCTAssertEqual(StringConstant.Weather.conditionDescription(for: code), expected)
        }
    }

    func testCityFormattingHandlesOptionalRegionAndTimezone() {
        XCTAssertEqual(
            StringConstant.City.displayName(name: "London", region: "England", country: "United Kingdom"),
            "London, England, United Kingdom"
        )
        XCTAssertEqual(
            StringConstant.City.displayName(name: "Paris", region: "", country: "France"),
            "Paris, France"
        )
        XCTAssertEqual(StringConstant.City.timezoneDisplayName("America/New_York"), "America/New York")
        XCTAssertEqual(StringConstant.City.timezoneDisplayName(nil), StringConstant.City.unknownTimezone)
    }
}
