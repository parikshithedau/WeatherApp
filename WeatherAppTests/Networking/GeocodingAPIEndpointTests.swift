import XCTest
@testable import WeatherApp

@MainActor
final class GeocodingAPIEndpointTests: XCTestCase {
    func testSearchCitiesEndpointContainsAllRequiredQueryItems() throws {
        let endpoint = GeocodingAPIEndpoint.SearchCities(query: "New York", limit: 6)
        let queryItems = try XCTUnwrap(URLComponents(url: endpoint.makeURL(), resolvingAgainstBaseURL: false)?.queryItems)

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(queryItems.value(named: APIConstants.cityNameParameter), "New York")
        XCTAssertEqual(queryItems.value(named: APIConstants.cityCountParameter), "6")
        XCTAssertEqual(queryItems.value(named: APIConstants.languageParameter), APIConstants.englishLanguage)
        XCTAssertEqual(queryItems.value(named: APIConstants.formatParameter), APIConstants.jsonFormat)
    }

    func testGeocodingAPIServiceReturnsEmptyListWhenAPIResponseOmitsResults() async throws {
        let client = APIClientMock()
        client.cityResponse = CitySearchResponseDTO(results: nil)
        let service = GeocodingAPIService(apiClient: client)

        let cities = try await service.searchCities(query: "London", limit: 8)

        XCTAssertTrue(cities.isEmpty)
        XCTAssertEqual(client.cityRequests.count, 1)
        XCTAssertEqual(client.cityRequests[0].query, "London")
        XCTAssertEqual(client.cityRequests[0].limit, 8)
    }
}
