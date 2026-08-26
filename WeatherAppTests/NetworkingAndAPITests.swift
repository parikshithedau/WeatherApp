import Foundation
import XCTest
@testable import WeatherApp

private struct APIClientResponse: Codable, Equatable {
    let value: String
}

private struct APIClientRequest: APIRequest {
    typealias Response = APIClientResponse

    let baseURL = "https://example.test"
    let path = "/resource"
    let method: HTTPMethod = .post
    let queryItems: [URLQueryItem]? = [URLQueryItem(name: "city", value: "New York")]
    let headers: [String: String]? = ["X-Test": "weather"]
}

private struct InvalidAPIClientRequest: APIRequest {
    typealias Response = APIClientResponse

    let baseURL = "https://[invalid"
    let path = ""
}

@MainActor
final class APIRequestTests: XCTestCase {
    func testMakeURLCombinesPathAndPercentEncodesQueryValues() throws {
        let url = try APIClientRequest().makeURL()
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

        XCTAssertEqual(components.scheme, "https")
        XCTAssertEqual(components.host, "example.test")
        XCTAssertEqual(components.path, "/resource")
        XCTAssertEqual(components.queryItems, [URLQueryItem(name: "city", value: "New York")])
    }

    func testMakeURLRejectsMalformedBaseURL() {
        XCTAssertThrowsError(try InvalidAPIClientRequest().makeURL()) { error in
            guard case .invalidURL = error as? APIError else {
                return XCTFail("Expected an invalid URL error")
            }
        }
    }

    func testHTTPMethodUsesExpectedWireValues() {
        XCTAssertEqual(HTTPMethod.get.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.post.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.put.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.delete.rawValue, "DELETE")
    }
}

final class APIClientTests: XCTestCase {
    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        super.tearDown()
    }

    func testExecuteBuildsRequestAndDecodesSuccessfulResponse() async throws {
        var receivedRequest: URLRequest?
        URLProtocolStub.requestHandler = { request in
            receivedRequest = request
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("{\"value\":\"forecast\"}".utf8))
        }

        let response = try await makeClient().execute(APIClientRequest())

        XCTAssertEqual(response, APIClientResponse(value: "forecast"))
        XCTAssertEqual(receivedRequest?.httpMethod, "POST")
        XCTAssertEqual(receivedRequest?.value(forHTTPHeaderField: "X-Test"), "weather")
        XCTAssertEqual(receivedRequest?.url?.query, "city=New%20York")
    }

    func testExecuteMapsNonSuccessStatusToHTTPError() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 503,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }

        do {
            _ = try await makeClient().execute(APIClientRequest())
            XCTFail("Expected an HTTP error")
        } catch let error as APIError {
            guard case .httpError(let statusCode) = error else {
                return XCTFail("Expected an HTTP error")
            }
            XCTAssertEqual(statusCode, 503)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteMapsMalformedPayloadToDecodingError() async {
        URLProtocolStub.requestHandler = { request in
            let response = HTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data("not-json".utf8))
        }

        do {
            _ = try await makeClient().execute(APIClientRequest())
            XCTFail("Expected a decoding error")
        } catch let error as APIError {
            guard case .decodingError = error else {
                return XCTFail("Expected a decoding error")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteMapsNetworkFailureToUnderlyingError() async {
        URLProtocolStub.requestHandler = { _ in throw URLError(.notConnectedToInternet) }

        do {
            _ = try await makeClient().execute(APIClientRequest())
            XCTFail("Expected an underlying error")
        } catch let error as APIError {
            guard case .underlying = error else {
                return XCTFail("Expected an underlying error")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteMapsNonHTTPResponseToInvalidResponse() async {
        URLProtocolStub.requestHandler = { request in
            let response = URLResponse(
                url: try XCTUnwrap(request.url),
                mimeType: "application/json",
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (response, Data())
        }

        do {
            _ = try await makeClient().execute(APIClientRequest())
            XCTFail("Expected an invalid response error")
        } catch let error as APIError {
            guard case .invalidResponse = error else {
                return XCTFail("Expected an invalid response error")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func makeClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return APIClient(session: URLSession(configuration: configuration))
    }
}

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
        let client = APIClientSpy()
        let service = WeatherAPIService(apiClient: client)

        let response = try await service.fetchForecast(latitude: 1.5, longitude: 2.5, forecastDays: 4)

        XCTAssertEqual(response, client.weatherResponse)
        XCTAssertEqual(client.weatherRequests.count, 1)
        XCTAssertEqual(client.weatherRequests[0].latitude, 1.5)
        XCTAssertEqual(client.weatherRequests[0].longitude, 2.5)
        XCTAssertEqual(client.weatherRequests[0].forecastDays, 4)
    }
}

@MainActor
final class GeocodingAPIEndpointTests: XCTestCase {
    func testSearchCitiesEndpointContainsAllRequiredQueryItems() throws {
        let endpoint = GeocodingAPIEndpoint.SearchCities(query: "New York", limit: 6)
        let queryItems = try XCTUnwrap(URLComponents(url: endpoint.makeURL(), resolvingAgainstBaseURL: false)?.queryItems)

        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(queryItems.value(named: StringConstant.API.cityNameParameter), "New York")
        XCTAssertEqual(queryItems.value(named: StringConstant.API.cityCountParameter), "6")
        XCTAssertEqual(queryItems.value(named: StringConstant.API.languageParameter), StringConstant.API.englishLanguage)
        XCTAssertEqual(queryItems.value(named: StringConstant.API.formatParameter), StringConstant.API.jsonFormat)
    }

    func testGeocodingAPIServiceReturnsEmptyListWhenAPIResponseOmitsResults() async throws {
        let client = APIClientSpy()
        client.cityResponse = CitySearchResponseDTO(results: nil)
        let service = GeocodingAPIService(apiClient: client)

        let cities = try await service.searchCities(query: "London", limit: 8)

        XCTAssertTrue(cities.isEmpty)
        XCTAssertEqual(client.cityRequests.count, 1)
        XCTAssertEqual(client.cityRequests[0].query, "London")
        XCTAssertEqual(client.cityRequests[0].limit, 8)
    }
}

private extension Array where Element == URLQueryItem {
    func value(named name: String) -> String? {
        first(where: { $0.name == name })?.value
    }
}
