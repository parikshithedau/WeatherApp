import XCTest
@testable import WeatherApp

@MainActor
final class RemoteDataSourceTests: XCTestCase {
    func testWeatherRemoteDataSourceForwardsCoordinatesAndForecastDays() async throws {
        let service = WeatherAPIServiceMock()
        let dataSource = WeatherRemoteDataSource(weatherAPIService: service)

        let response = try await dataSource.fetchWeather(for: TestFixtures.city, forecastDays: 12)

        XCTAssertEqual(response.timezone, "Europe/London")
        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(service.requests[0].latitude, TestFixtures.city.latitude)
        XCTAssertEqual(service.requests[0].longitude, TestFixtures.city.longitude)
        XCTAssertEqual(service.requests[0].forecastDays, 12)
    }

    func testCityRemoteDataSourceUsesConfiguredLimit() async throws {
        let service = GeocodingAPIServiceMock()
        let dataSource = CitySearchRemoteDataSource(geocodingAPIService: service, resultLimit: 3)

        let cities = try await dataSource.searchCities(matching: "London")

        XCTAssertEqual(cities, [TestFixtures.cityDTO()])
        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(service.requests[0].query, "London")
        XCTAssertEqual(service.requests[0].limit, 3)
    }

    func testRemoteDataSourcesMapAPIErrorsAndUnknownFailures() async {
        let weatherService = WeatherAPIServiceMock(result: .failure(APIError.httpError(statusCode: 429)))
        let cityService = GeocodingAPIServiceMock(result: .failure(APIError.decodingError))
        let unknownFailureService = WeatherAPIServiceMock(result: .failure(TestError.expected))

        do {
            _ = try await WeatherRemoteDataSource(weatherAPIService: weatherService)
                .fetchWeather(for: TestFixtures.city, forecastDays: 7)
            XCTFail("Expected a rate-limited error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .rateLimited)
        }

        do {
            _ = try await CitySearchRemoteDataSource(geocodingAPIService: cityService)
                .searchCities(matching: "London")
            XCTFail("Expected a decoding error")
        } catch {
            XCTAssertEqual(error as? CitySearchError, .decodingError)
        }

        do {
            _ = try await WeatherRemoteDataSource(weatherAPIService: unknownFailureService)
                .fetchWeather(for: TestFixtures.city, forecastDays: 7)
            XCTFail("Expected a network error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .networkError)
        }
    }

    func testCitySearchRemoteDataSourceMapsUnknownFailuresToNetworkError() async {
        let service = GeocodingAPIServiceMock(result: .failure(TestError.expected))

        do {
            _ = try await CitySearchRemoteDataSource(geocodingAPIService: service)
                .searchCities(matching: "London")
            XCTFail("Expected a network error")
        } catch {
            XCTAssertEqual(error as? CitySearchError, .networkError)
        }
    }

    func testWeatherRemoteDataSourceMapsTimeoutToRequestTimeout() async {
        let service = WeatherAPIServiceMock(result: .failure(URLError(.timedOut)))

        do {
            _ = try await WeatherRemoteDataSource(weatherAPIService: service)
                .fetchWeather(for: TestFixtures.city, forecastDays: 7)
            XCTFail("Expected a request timeout error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .requestTimeout)
        }
    }

    func testCitySearchRemoteDataSourceMapsTimeoutToRequestTimeout() async {
        let service = GeocodingAPIServiceMock(result: .failure(URLError(.timedOut)))

        do {
            _ = try await CitySearchRemoteDataSource(geocodingAPIService: service)
                .searchCities(matching: "London")
            XCTFail("Expected a request timeout error")
        } catch {
            XCTAssertEqual(error as? CitySearchError, .requestTimeout)
        }
    }

    func testWeatherRemoteDataSourceMapsURLErrorToNetworkError() async {
        let service = WeatherAPIServiceMock(result: .failure(URLError(.notConnectedToInternet)))

        do {
            _ = try await WeatherRemoteDataSource(weatherAPIService: service)
                .fetchWeather(for: TestFixtures.city, forecastDays: 7)
            XCTFail("Expected a network error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .networkError)
        }
    }

    func testCitySearchRemoteDataSourceMapsURLErrorToNetworkError() async {
        let service = GeocodingAPIServiceMock(result: .failure(URLError(.notConnectedToInternet)))

        do {
            _ = try await CitySearchRemoteDataSource(geocodingAPIService: service)
                .searchCities(matching: "London")
            XCTFail("Expected a network error")
        } catch {
            XCTAssertEqual(error as? CitySearchError, .networkError)
        }
    }
}
