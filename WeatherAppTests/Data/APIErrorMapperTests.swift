import XCTest
@testable import WeatherApp

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
