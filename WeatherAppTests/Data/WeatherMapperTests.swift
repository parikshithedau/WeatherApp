import XCTest
@testable import WeatherApp

@MainActor
final class WeatherMapperTests: XCTestCase {
    func testToDomainMapsCompleteDailyForecast() throws {
        let dto = TestFixtures.weatherResponse(
            times: ["2026-08-26", "2026-08-27"],
            weatherCodes: [0, 61],
            maximumTemperatures: [22, 18],
            minimumTemperatures: [12, 10],
            precipitation: [0, 3.5],
            snowfall: [0, 0],
            maximumWindSpeeds: [18, 14],
            maximumUVIndexes: [5, 2]
        )

        let forecast = try WeatherMapper.toDomain(dto, city: TestFixtures.city)

        XCTAssertEqual(forecast.city, TestFixtures.city)
        XCTAssertEqual(forecast.timeZone, "Europe/London")
        XCTAssertEqual(
            forecast.days,
            [
                TestFixtures.day(),
                TestFixtures.day(
                    date: "2026-08-27",
                    weatherCode: 61,
                    maximumTemperature: 18,
                    minimumTemperature: 10,
                    precipitation: 3.5,
                    maximumWindSpeed: 14,
                    maximumUVIndex: 2
                )
            ]
        )
    }

    func testToDomainSkipsIncompleteDailyEntriesButKeepsCompleteOnes() throws {
        let dto = TestFixtures.weatherResponse(
            times: ["2026-08-26", "2026-08-27"],
            weatherCodes: [0],
            maximumTemperatures: [22, 18],
            minimumTemperatures: [12, 10],
            precipitation: [0, 0],
            snowfall: [0, 0],
            maximumWindSpeeds: [18, 18],
            maximumUVIndexes: [5, 5]
        )

        let forecast = try WeatherMapper.toDomain(dto, city: TestFixtures.city)

        XCTAssertEqual(forecast.days, [TestFixtures.day()])
    }

    func testToDomainThrowsWhenNoCompleteForecastDayExists() {
        let empty = TestFixtures.weatherResponse(times: [])
        let incomplete = TestFixtures.weatherResponse(
            times: ["2026-08-26"],
            weatherCodes: [],
            maximumTemperatures: [],
            minimumTemperatures: [],
            precipitation: [],
            snowfall: [],
            maximumWindSpeeds: [],
            maximumUVIndexes: []
        )

        for dto in [empty, incomplete] {
            XCTAssertThrowsError(try WeatherMapper.toDomain(dto, city: TestFixtures.city)) { error in
                XCTAssertEqual(error as? WeatherError, .noWeatherData)
            }
        }
    }
}
