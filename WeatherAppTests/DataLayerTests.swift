import XCTest
@testable import WeatherApp

@MainActor
final class CityMapperTests: XCTestCase {
    func testToDomainMapsEveryDisplayAndLocationFieldForValidCity() {
        let dto = TestFixtures.cityDTO()

        let city = CityMapper.toDomain(dto)

        XCTAssertEqual(city, TestFixtures.city)
    }

    func testToDomainRejectsCityWithoutCountry() {
        XCTAssertNil(CityMapper.toDomain(TestFixtures.cityDTO(country: nil)))
        XCTAssertNil(CityMapper.toDomain(TestFixtures.cityDTO(country: "")))
    }

    func testToDomainCollectionDropsInvalidCitiesAndPreservesOrder() {
        let paris = TestFixtures.cityDTO(id: 2, name: "Paris", country: "France", admin1: nil)
        let cities = CityMapper.toDomain([TestFixtures.cityDTO(country: nil), paris])

        XCTAssertEqual(cities.map(\.id), [2])
        XCTAssertEqual(cities.map(\.name), ["Paris"])
        XCTAssertEqual(cities.first?.region, nil)
    }
}

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

@MainActor
final class APIErrorMapperTests: XCTestCase {
    func testToDomainMapsHTTPStatusesToActionableErrors() {
        let testCases: [(statusCode: Int, expected: WeatherError)] = [
            (400, .invalidRequest),
            (401, .unauthorized),
            (403, .forbidden),
            (404, .notFound),
            (408, .requestTimeout),
            (429, .rateLimited),
            (500, .serverError),
            (599, .serverError),
            (418, .networkError)
        ]

        for testCase in testCases {
            XCTAssertEqual(
                APIErrorMapper.toDomain(.httpError(statusCode: testCase.statusCode)),
                testCase.expected
            )
        }
    }

    func testToDomainMapsTransportAndResponseFailures() {
        XCTAssertEqual(APIErrorMapper.toDomain(.invalidURL), .invalidRequest)
        XCTAssertEqual(APIErrorMapper.toDomain(.invalidResponse), .invalidResponse)
        XCTAssertEqual(APIErrorMapper.toDomain(.decodingError), .decodingError)
        XCTAssertEqual(APIErrorMapper.toDomain(.underlying(URLError(.timedOut))), .requestTimeout)
        XCTAssertEqual(APIErrorMapper.toDomain(.underlying(URLError(.notConnectedToInternet))), .networkError)
    }
}

@MainActor
final class CitySearchRepositoryTests: XCTestCase {
    func testSearchCitiesMapsRemoteDTOsAndFiltersInvalidCities() async throws {
        let remote = CityRemoteDataSourceSpy(result: .success([
            TestFixtures.cityDTO(),
            TestFixtures.cityDTO(id: 2, country: nil)
        ]))
        let repository = CitySearchRepository(remoteDataSource: remote)

        let cities = try await repository.searchCities(matching: "London")

        XCTAssertEqual(cities, [TestFixtures.city])
        XCTAssertEqual(remote.queries, ["London"])
    }

    func testSearchCitiesForwardsRemoteFailure() async {
        let remote = CityRemoteDataSourceSpy(result: .failure(TestError.expected))

        do {
            _ = try await CitySearchRepository(remoteDataSource: remote).searchCities(matching: "London")
            XCTFail("Expected the remote error to be forwarded")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
}

@MainActor
final class WeatherRepositoryTests: XCTestCase {
    func testFetchWeatherMapsRemoteDTOWithRequestedCity() async throws {
        let remote = WeatherRemoteDataSourceSpy()
        let repository = WeatherRepository(remoteDataSource: remote)

        let forecast = try await repository.fetchWeather(for: TestFixtures.city, forecastDays: 5)

        XCTAssertEqual(forecast, TestFixtures.forecast())
        XCTAssertEqual(remote.requests.count, 1)
        XCTAssertEqual(remote.requests[0].city, TestFixtures.city)
        XCTAssertEqual(remote.requests[0].forecastDays, 5)
    }

    func testFetchWeatherForwardsRemoteFailure() async {
        let remote = WeatherRemoteDataSourceSpy(result: .failure(TestError.expected))

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
        let remote = WeatherRemoteDataSourceSpy(result: .success(TestFixtures.weatherResponse(times: [])))

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

@MainActor
final class RemoteDataSourceTests: XCTestCase {
    func testWeatherRemoteDataSourceForwardsCoordinatesAndForecastDays() async throws {
        let service = WeatherAPIServiceSpy()
        let dataSource = WeatherRemoteDataSource(weatherAPIService: service)

        let response = try await dataSource.fetchWeather(for: TestFixtures.city, forecastDays: 12)

        XCTAssertEqual(response.timezone, "Europe/London")
        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(service.requests[0].latitude, TestFixtures.city.latitude)
        XCTAssertEqual(service.requests[0].longitude, TestFixtures.city.longitude)
        XCTAssertEqual(service.requests[0].forecastDays, 12)
    }

    func testCityRemoteDataSourceUsesConfiguredLimit() async throws {
        let service = GeocodingAPIServiceSpy()
        let dataSource = CitySearchRemoteDataSource(geocodingAPIService: service, resultLimit: 3)

        let cities = try await dataSource.searchCities(matching: "London")

        XCTAssertEqual(cities, [TestFixtures.cityDTO()])
        XCTAssertEqual(service.requests.count, 1)
        XCTAssertEqual(service.requests[0].query, "London")
        XCTAssertEqual(service.requests[0].limit, 3)
    }

    func testRemoteDataSourcesMapAPIErrorsAndUnknownFailures() async {
        let weatherService = WeatherAPIServiceSpy(result: .failure(APIError.httpError(statusCode: 429)))
        let cityService = GeocodingAPIServiceSpy(result: .failure(APIError.decodingError))
        let unknownFailureService = WeatherAPIServiceSpy(result: .failure(TestError.expected))

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
        let service = GeocodingAPIServiceSpy(result: .failure(TestError.expected))

        do {
            _ = try await CitySearchRemoteDataSource(geocodingAPIService: service)
                .searchCities(matching: "London")
            XCTFail("Expected a network error")
        } catch {
            XCTAssertEqual(error as? CitySearchError, .networkError)
        }
    }
}

@MainActor
final class CitySearchAPIErrorMapperTests: XCTestCase {
    func testToDomainMapsHTTPStatusesToActionableErrors() {
        let testCases: [(statusCode: Int, expected: CitySearchError)] = [
            (400, .invalidRequest),
            (401, .unauthorized),
            (403, .forbidden),
            (404, .noResults),
            (408, .requestTimeout),
            (429, .rateLimited),
            (500, .serverError),
            (599, .serverError),
            (418, .networkError)
        ]

        for testCase in testCases {
            XCTAssertEqual(
                CitySearchAPIErrorMapper.toDomain(.httpError(statusCode: testCase.statusCode)),
                testCase.expected
            )
        }
    }

    func testToDomainMapsTransportAndResponseFailures() {
        XCTAssertEqual(CitySearchAPIErrorMapper.toDomain(.invalidURL), .invalidRequest)
        XCTAssertEqual(CitySearchAPIErrorMapper.toDomain(.invalidResponse), .invalidResponse)
        XCTAssertEqual(CitySearchAPIErrorMapper.toDomain(.decodingError), .decodingError)
        XCTAssertEqual(CitySearchAPIErrorMapper.toDomain(.underlying(URLError(.timedOut))), .requestTimeout)
        XCTAssertEqual(CitySearchAPIErrorMapper.toDomain(.underlying(URLError(.notConnectedToInternet))), .networkError)
    }
}
