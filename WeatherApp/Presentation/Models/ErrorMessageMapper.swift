import Foundation

enum ErrorMessageMapper {
    static func message(for error: Error) -> String {
        guard let weatherError = error as? WeatherError else {
            return StringConstant.Error.unexpected
        }

        switch weatherError {
        case .invalidCity: return StringConstant.Error.invalidCity
        case .networkError: return StringConstant.Error.network
        case .decodingError: return StringConstant.Error.decoding
        case .notFound: return StringConstant.Error.cityNotFound
        case .noWeatherData: return StringConstant.Error.noWeatherData
        case .invalidForecastDays: return StringConstant.Error.invalidForecastDays
        }
    }
}
