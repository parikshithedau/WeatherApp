import Foundation
import XCTest
@testable import WeatherApp

enum TestFixtures {
    static let city = City(
        id: 2643743,
        name: "London",
        region: "England",
        country: "United Kingdom",
        timeZone: "Europe/London",
        latitude: 51.5072,
        longitude: -0.1276
    )

    static func day(
        date: String = "2026-08-26",
        weatherCode: Int = 0,
        maximumTemperature: Double = 22,
        minimumTemperature: Double = 12,
        precipitation: Double = 0,
        snowfall: Double = 0,
        maximumWindSpeed: Double = 18,
        maximumUVIndex: Double = 5
    ) -> DailyWeather {
        DailyWeather(
            date: date,
            weatherCode: weatherCode,
            maximumTemperature: maximumTemperature,
            minimumTemperature: minimumTemperature,
            precipitation: precipitation,
            snowfall: snowfall,
            maximumWindSpeed: maximumWindSpeed,
            maximumUVIndex: maximumUVIndex
        )
    }

    static func forecast(days: [DailyWeather] = [day()]) -> WeatherForecast {
        WeatherForecast(city: city, timeZone: "Europe/London", days: days)
    }

    static func weatherResponse(
        times: [String] = ["2026-08-26"],
        weatherCodes: [Int] = [0],
        maximumTemperatures: [Double] = [22],
        minimumTemperatures: [Double] = [12],
        precipitation: [Double] = [0],
        snowfall: [Double] = [0],
        maximumWindSpeeds: [Double] = [18],
        maximumUVIndexes: [Double] = [5]
    ) -> WeatherResponseDTO {
        WeatherResponseDTO(
            timezone: "Europe/London",
            daily: .init(
                time: times,
                weatherCode: weatherCodes,
                maximumTemperature: maximumTemperatures,
                minimumTemperature: minimumTemperatures,
                precipitation: precipitation,
                snowfall: snowfall,
                maximumWindSpeed: maximumWindSpeeds,
                maximumUVIndex: maximumUVIndexes
            )
        )
    }

    static func cityDTO(
        id: Int = 2643743,
        name: String = "London",
        country: String? = "United Kingdom",
        admin1: String? = "England",
        timezone: String? = "Europe/London"
    ) -> CitySearchResultDTO {
        CitySearchResultDTO(
            id: id,
            name: name,
            latitude: 51.5072,
            longitude: -0.1276,
            country: country,
            admin1: admin1,
            timezone: timezone
        )
    }
}

enum TestError: Error {
    case expected
}

final class WeatherRepositoryMock: WeatherRepositoryProtocol, @unchecked Sendable {
    var result: Result<WeatherForecast, Error>
    private(set) var requests: [(city: City, forecastDays: Int)] = []

    init(result: Result<WeatherForecast, Error> = .success(TestFixtures.forecast())) {
        self.result = result
    }

    func fetchWeather(for city: City, forecastDays: Int) async throws -> WeatherForecast {
        requests.append((city, forecastDays))
        return try result.get()
    }
}

final class CityRepositoryMock: CitySearchRepositoryProtocol, @unchecked Sendable {
    var result: Result<[City], Error>
    var onSearch: ((String) -> Void)?
    private(set) var queries: [String] = []

    init(result: Result<[City], Error> = .success([TestFixtures.city])) {
        self.result = result
    }

    func searchCities(matching query: String) async throws -> [City] {
        queries.append(query)
        onSearch?(query)
        return try result.get()
    }
}

final class WeatherRemoteDataSourceMock: WeatherRemoteDataSourceProtocol, @unchecked Sendable {
    var result: Result<WeatherResponseDTO, Error>
    private(set) var requests: [(city: City, forecastDays: Int)] = []

    init(result: Result<WeatherResponseDTO, Error> = .success(TestFixtures.weatherResponse())) {
        self.result = result
    }

    func fetchWeather(for city: City, forecastDays: Int) async throws -> WeatherResponseDTO {
        requests.append((city, forecastDays))
        return try result.get()
    }
}

final class CityRemoteDataSourceMock: CitySearchRemoteDataSourceProtocol, @unchecked Sendable {
    var result: Result<[CitySearchResultDTO], Error>
    private(set) var queries: [String] = []

    init(result: Result<[CitySearchResultDTO], Error> = .success([TestFixtures.cityDTO()])) {
        self.result = result
    }

    func searchCities(matching query: String) async throws -> [CitySearchResultDTO] {
        queries.append(query)
        return try result.get()
    }
}

final class WeatherAPIServiceMock: WeatherAPIServiceProtocol, @unchecked Sendable {
    var result: Result<WeatherResponseDTO, Error>
    private(set) var requests: [(latitude: Double, longitude: Double, forecastDays: Int)] = []

    init(result: Result<WeatherResponseDTO, Error> = .success(TestFixtures.weatherResponse())) {
        self.result = result
    }

    func fetchForecast(latitude: Double, longitude: Double, forecastDays: Int) async throws -> WeatherResponseDTO {
        requests.append((latitude, longitude, forecastDays))
        return try result.get()
    }
}

final class GeocodingAPIServiceMock: GeocodingAPIServiceProtocol, @unchecked Sendable {
    var result: Result<[CitySearchResultDTO], Error>
    private(set) var requests: [(query: String, limit: Int)] = []

    init(result: Result<[CitySearchResultDTO], Error> = .success([TestFixtures.cityDTO()])) {
        self.result = result
    }

    func searchCities(query: String, limit: Int) async throws -> [CitySearchResultDTO] {
        requests.append((query, limit))
        return try result.get()
    }
}

final class ActivityScorerMock: ActivityScoring, @unchecked Sendable {
    var results: [ActivityScore]
    private(set) var receivedDays: [DailyWeather] = []

    init(results: [ActivityScore]) {
        self.results = results
    }

    func rankActivities(for day: DailyWeather) -> [ActivityScore] {
        receivedDays.append(day)
        return results
    }
}

final class WeatherForecastViewDataMapperMock: WeatherForecastViewDataMapping, @unchecked Sendable {
    var viewData: WeatherForecastViewData
    private(set) var receivedForecasts: [WeatherForecast] = []

    init(viewData: WeatherForecastViewData = .init(cityName: "Stub city", timeZone: "UTC", days: [])) {
        self.viewData = viewData
    }

    func map(_ forecast: WeatherForecast) -> WeatherForecastViewData {
        receivedForecasts.append(forecast)
        return viewData
    }
}

final class APIClientMock: APIClientProtocol, @unchecked Sendable {
    var weatherResponse = TestFixtures.weatherResponse()
    var cityResponse = CitySearchResponseDTO(results: [TestFixtures.cityDTO()])
    var error: Error?
    private(set) var weatherRequests: [WeatherAPIEndpoint.FetchForecast] = []
    private(set) var cityRequests: [GeocodingAPIEndpoint.SearchCities] = []

    func execute<R: APIRequest>(_ request: R) async throws -> R.Response {
        if let error {
            throw error
        }
        if let request = request as? WeatherAPIEndpoint.FetchForecast,
           let response = weatherResponse as? R.Response {
            weatherRequests.append(request)
            return response
        }
        if let request = request as? GeocodingAPIEndpoint.SearchCities,
           let response = cityResponse as? R.Response {
            cityRequests.append(request)
            return response
        }
        fatalError("Unexpected API request: \(R.self)")
    }
}

final class URLProtocolStub: URLProtocol, @unchecked Sendable {
    static var requestHandler: ((URLRequest) throws -> (URLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: TestError.expected)
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension Array where Element == URLQueryItem {
    func value(named name: String) -> String? {
        first(where: { $0.name == name })?.value
    }
}

func assertWeatherError(
    _ expression: @autoclosure () throws -> Void,
    equals expected: WeatherError,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertThrowsError(try expression(), file: file, line: line) { error in
        XCTAssertEqual(error as? WeatherError, expected, file: file, line: line)
    }
}
