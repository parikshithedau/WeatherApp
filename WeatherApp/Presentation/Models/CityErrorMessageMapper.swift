import Foundation

enum CityErrorMessageMapper {
    static func message(for error: Error) -> String {
        guard let citySearchError = error as? CitySearchError else {
            return StringConstant.Error.CitySearch.unexpected
        }

        switch citySearchError {
        case .invalidRequest: return StringConstant.Error.CitySearch.invalidRequest
        case .networkError: return StringConstant.Error.CitySearch.network
        case .requestTimeout: return StringConstant.Error.CitySearch.requestTimeout
        case .unauthorized: return StringConstant.Error.CitySearch.unauthorized
        case .forbidden: return StringConstant.Error.CitySearch.forbidden
        case .rateLimited: return StringConstant.Error.CitySearch.rateLimited
        case .serverError: return StringConstant.Error.CitySearch.server
        case .decodingError: return StringConstant.Error.CitySearch.decoding
        case .invalidResponse: return StringConstant.Error.CitySearch.invalidResponse
        case .noResults: return StringConstant.Error.CitySearch.noResults
        }
    }
}
