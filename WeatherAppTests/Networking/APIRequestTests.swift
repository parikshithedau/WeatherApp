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
