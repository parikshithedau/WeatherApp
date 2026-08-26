import XCTest
@testable import WeatherApp

@MainActor
final class CityErrorMessageMapperTests: XCTestCase {
    func testMessageMapsEachCitySearchFailureToAnActionableUserMessage() {
        let testCases: [(CitySearchError, String)] = [
            (.invalidRequest, StringConstant.Error.CitySearch.invalidRequest),
            (.networkError, StringConstant.Error.CitySearch.network),
            (.requestTimeout, StringConstant.Error.CitySearch.requestTimeout),
            (.unauthorized, StringConstant.Error.CitySearch.unauthorized),
            (.forbidden, StringConstant.Error.CitySearch.forbidden),
            (.rateLimited, StringConstant.Error.CitySearch.rateLimited),
            (.serverError, StringConstant.Error.CitySearch.server),
            (.decodingError, StringConstant.Error.CitySearch.decoding),
            (.invalidResponse, StringConstant.Error.CitySearch.invalidResponse),
            (.noResults, StringConstant.Error.CitySearch.noResults)
        ]

        for (error, expectedMessage) in testCases {
            XCTAssertEqual(CityErrorMessageMapper.message(for: error), expectedMessage)
        }
    }

    func testMessageUsesSafeFallbackForUnexpectedErrors() {
        XCTAssertEqual(CityErrorMessageMapper.message(for: TestError.expected), StringConstant.Error.CitySearch.unexpected)
    }
}
