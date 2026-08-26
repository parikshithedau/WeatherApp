import XCTest
@testable import WeatherApp

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
