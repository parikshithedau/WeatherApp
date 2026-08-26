import Foundation

enum ErrorMessageMapper {
    static func message(for error: Error) -> String {
        guard let weatherError = error as? WeatherError else {
            return StringConstant.Error.unexpected
        }

        switch weatherError {
        case .invalidCity: return StringConstant.Error.invalidCity
        case .invalidSearchQuery: return StringConstant.Error.invalidSearchQuery
        case .invalidRequest: return StringConstant.Error.invalidRequest
        case .networkError: return StringConstant.Error.network
        case .requestTimeout: return StringConstant.Error.requestTimeout
        case .unauthorized: return StringConstant.Error.unauthorized
        case .forbidden: return StringConstant.Error.forbidden
        case .rateLimited: return StringConstant.Error.rateLimited
        case .serverError: return StringConstant.Error.server
        case .decodingError: return StringConstant.Error.decoding
        case .invalidResponse: return StringConstant.Error.invalidResponse
        case .notFound: return StringConstant.Error.cityNotFound
        case .noWeatherData: return StringConstant.Error.noWeatherData
        case .invalidForecastDays: return StringConstant.Error.invalidForecastDays
        }
    }
}
