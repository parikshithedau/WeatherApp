import XCTest
@testable import WeatherApp

@MainActor
final class GetWeatherUseCaseTests: XCTestCase {
    func testExecuteForwardsValidCityAndForecastDaysToRepository() async throws {
        let repository = WeatherRepositoryMock()
        let useCase = GetWeatherUseCase(repository: repository)

        let forecast = try await useCase.execute(city: TestFixtures.city, forecastDays: 10)

        XCTAssertEqual(forecast, TestFixtures.forecast())
        XCTAssertEqual(repository.requests.count, 1)
        XCTAssertEqual(repository.requests[0].city, TestFixtures.city)
        XCTAssertEqual(repository.requests[0].forecastDays, 10)
    }

    func testExecuteRejectsBlankCityWithoutCallingRepository() async {
        let repository = WeatherRepositoryMock()
        let invalidCity = City(
            id: 1,
            name: "  ",
            region: nil,
            country: "United Kingdom",
            timeZone: nil,
            latitude: 0,
            longitude: 0
        )

        do {
            _ = try await GetWeatherUseCase(repository: repository).execute(city: invalidCity)
            XCTFail("Expected an invalid city error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .invalidCity)
        }
        XCTAssertTrue(repository.requests.isEmpty)
    }

    func testExecuteRejectsForecastDaysOutsideSupportedRangeWithoutCallingRepository() async {
        for forecastDays in [0, 17] {
            let repository = WeatherRepositoryMock()

            do {
                _ = try await GetWeatherUseCase(repository: repository).execute(
                    city: TestFixtures.city,
                    forecastDays: forecastDays
                )
                XCTFail("Expected an invalid forecast day error")
            } catch {
                XCTAssertEqual(error as? WeatherError, .invalidForecastDays)
            }
            XCTAssertTrue(repository.requests.isEmpty)
        }
    }
}
