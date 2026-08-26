import XCTest
@testable import WeatherApp

private struct TestScenarios {
    let testCases: [(WeatherError, String)]
}

@MainActor
final class ErrorMessageMapperTests: XCTestCase {
    func testMessageMapsEachDomainFailureToAnActionableUserMessage() {
        let testCases: [(WeatherError, String)] = [
            (.invalidCity, StringConstant.Error.invalidCity),
            (.invalidSearchQuery, StringConstant.Error.invalidSearchQuery),
            (.invalidRequest, StringConstant.Error.invalidRequest),
            (.networkError, StringConstant.Error.network),
            (.requestTimeout, StringConstant.Error.requestTimeout),
            (.unauthorized, StringConstant.Error.unauthorized),
            (.forbidden, StringConstant.Error.forbidden),
            (.rateLimited, StringConstant.Error.rateLimited),
            (.serverError, StringConstant.Error.server),
            (.decodingError, StringConstant.Error.decoding),
            (.invalidResponse, StringConstant.Error.invalidResponse),
            (.notFound, StringConstant.Error.cityNotFound),
            (.noWeatherData, StringConstant.Error.noWeatherData),
            (.invalidForecastDays, StringConstant.Error.invalidForecastDays)
        ]

        for (error, expectedMessage) in testCases {
            XCTAssertEqual(ErrorMessageMapper.message(for: error), expectedMessage)
        }
    }

    func testMessageUsesSafeFallbackForUnexpectedErrors() {
        XCTAssertEqual(ErrorMessageMapper.message(for: TestError.expected), StringConstant.Error.unexpected)
    }
}
