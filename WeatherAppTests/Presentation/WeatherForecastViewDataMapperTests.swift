import XCTest
@testable import WeatherApp

private func assertViewData(
    _ viewData: WeatherForecastViewData,
    cityName: String,
    timeZone: String,
    dayCount: Int,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertEqual(viewData.cityName, cityName, file: file, line: line)
    XCTAssertEqual(viewData.timeZone, timeZone, file: file, line: line)
    XCTAssertEqual(viewData.days.count, dayCount, file: file, line: line)
}

@MainActor
final class WeatherForecastViewDataMapperTests: XCTestCase {
    func testMapCreatesDisplayReadyForecastAndActivityInformation() {
        let mapper = WeatherForecastViewDataMapper(
            getActivityRecommendationsUseCase: GetActivityRecommendationsUseCase(activityScorer: ActivityScorer())
        )
        let forecast = TestFixtures.forecast(days: [
            TestFixtures.day(
                weatherCode: 61,
                maximumTemperature: 21.6,
                minimumTemperature: 11.4,
                precipitation: 1.2,
                snowfall: 0.5,
                maximumWindSpeed: 18.2,
                maximumUVIndex: 4.8
            )
        ])

        let viewData = mapper.map(forecast)

        XCTAssertEqual(viewData.cityName, "London, England, United Kingdom")
        XCTAssertEqual(viewData.timeZone, "Europe/London")
        XCTAssertEqual(viewData.days.count, 1)
        XCTAssertEqual(viewData.days[0].id, "2026-08-26")
        XCTAssertEqual(viewData.days[0].conditionDescription, StringConstant.Weather.rain)
        XCTAssertEqual(viewData.days[0].temperatureSummary, "22° / 11°")
        XCTAssertEqual(viewData.days[0].windAndUVSummary, "Wind 18 · UV 5")
        XCTAssertEqual(viewData.days[0].precipitationAndSnowSummary, "Rain 1.2 mm · Snow 0.5 cm")
        XCTAssertEqual(viewData.days[0].activityRecommendations.map(\.title), [
            StringConstant.Activity.surfingTitle,
            StringConstant.Activity.outdoorSightseeingTitle,
            StringConstant.Activity.indoorSightseeingTitle,
            StringConstant.Activity.skiingTitle
        ])
        XCTAssertEqual(viewData.days[0].activityRecommendations[0].scoreTone, .favorable)
        XCTAssertTrue(viewData.days[0].activityRecommendations[0].accessibilityLabel.contains("percent suitable"))
    }

    func testMapUsesScoreToneBoundariesAndCombinesReasons() {
        let recommendations = [
            ActivityScore(activity: .outdoorSightseeing, score: 70, reasons: [.noRain]),
            ActivityScore(activity: .indoorSightseeing, score: 69, reasons: [.rainyOutside(2)]),
            ActivityScore(activity: .surfing, score: 39, reasons: [.windTooWeak(5), .heavyRain(6)])
        ]
        let scorer = ActivityScorerMock(results: recommendations)
        let mapper = WeatherForecastViewDataMapper(
            getActivityRecommendationsUseCase: GetActivityRecommendationsUseCase(activityScorer: scorer)
        )

        let result = mapper.map(TestFixtures.forecast()).days[0].activityRecommendations

        XCTAssertEqual(result.map(\.scoreTone), [.favorable, .neutral, .unfavorable])
        XCTAssertEqual(result[0].reason, StringConstant.Activity.noRain)
        XCTAssertEqual(result[1].reason, "Rainy outside (2.0 mm)")
        XCTAssertEqual(result[2].reason, "Wind too weak (5 km/h), Heavy rain (6.0 mm)")
        XCTAssertEqual(result[2].scoreText, "39%")
        XCTAssertEqual(scorer.receivedDays, [TestFixtures.day()])
    }
}
