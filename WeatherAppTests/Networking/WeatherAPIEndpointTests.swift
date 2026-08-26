import XCTest
@testable import WeatherApp

@MainActor
final class WeatherAPIEndpointTests: XCTestCase {
    func testFetchForecastEndpointContainsAllRequiredQueryItems() throws {
        let endpoint = WeatherAPIEndpoint.FetchForecast(latitude: 51.5072, longitude: -0.1276, forecastDays: 9)
        let queryItems = try XCTUnwrap(URLComponents(url: endpoint.makeURL(), resolvingAgainstBaseURL: false)?.queryItems)

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(queryItems.value(named: StringConstant.API.latitudeParameter), "51.5072")
        XCTAssertEqual(queryItems.value(named: StringConstant.API.longitudeParameter), "-0.1276")
        XCTAssertEqual(queryItems.value(named: StringConstant.API.forecastDaysParameter), "9")
        XCTAssertEqual(queryItems.value(named: StringConstant.API.timezoneParameter), StringConstant.API.automaticTimezone)
        XCTAssertEqual(queryItems.value(named: StringConstant.API.dailyParameter), StringConstant.API.dailyFields)
    }

    func testWeatherAPIServiceBuildsForecastEndpointAndForwardsClientErrors() async throws {
        let client = APIClientMock()
        let service = WeatherAPIService(apiClient: client)

        let response = try await service.fetchForecast(latitude: 1.5, longitude: 2.5, forecastDays: 4)

        XCTAssertEqual(response, client.weatherResponse)
        XCTAssertEqual(client.weatherRequests.count, 1)
        XCTAssertEqual(client.weatherRequests[0].latitude, 1.5)
        XCTAssertEqual(client.weatherRequests[0].longitude, 2.5)
        XCTAssertEqual(client.weatherRequests[0].forecastDays, 4)
    }
}
