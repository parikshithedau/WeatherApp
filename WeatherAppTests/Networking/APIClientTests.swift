import Foundation
import XCTest
@testable import WeatherApp

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
