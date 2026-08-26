import XCTest
@testable import WeatherApp

@MainActor
final class WeatherRepositoryTests: XCTestCase {
    func testFetchWeatherMapsRemoteDTOWithRequestedCity() async throws {
        let remote = WeatherRemoteDataSourceMock()
        let repository = WeatherRepository(remoteDataSource: remote)

        let forecast = try await repository.fetchWeather(for: TestFixtures.city, forecastDays: 5)

        XCTAssertEqual(forecast, TestFixtures.forecast())
        XCTAssertEqual(remote.requests.count, 1)
        XCTAssertEqual(remote.requests[0].city, TestFixtures.city)
        XCTAssertEqual(remote.requests[0].forecastDays, 5)
    }

    func testFetchWeatherForwardsRemoteFailure() async {
        let remote = WeatherRemoteDataSourceMock(result: .failure(TestError.expected))

        do {
            _ = try await WeatherRepository(remoteDataSource: remote).fetchWeather(
                for: TestFixtures.city,
                forecastDays: 7
            )
            XCTFail("Expected the remote error to be forwarded")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testFetchWeatherExposesNoWeatherDataWhenRemotePayloadHasNoDays() async {
        let remote = WeatherRemoteDataSourceMock(result: .success(TestFixtures.weatherResponse(times: [])))

        do {
            _ = try await WeatherRepository(remoteDataSource: remote).fetchWeather(
                for: TestFixtures.city,
                forecastDays: 7
            )
            XCTFail("Expected a no weather data error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .noWeatherData)
        }
    }
}
