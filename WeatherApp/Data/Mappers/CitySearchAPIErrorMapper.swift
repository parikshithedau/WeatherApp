import Foundation

enum CitySearchAPIErrorMapper {
    static func toDomain(_ error: APIError) -> CitySearchError {
        switch error {
        case .invalidURL:
            return .invalidRequest
        case .invalidResponse:
            return .invalidResponse
        case .decodingError:
            return .decodingError
        case .httpError(let statusCode):
            return switch statusCode {
            case 400:
                .invalidRequest
            case 401:
                .unauthorized
            case 403:
                .forbidden
            case 404:
                .noResults
            case 408:
                .requestTimeout
            case 429:
                .rateLimited
            case 500...599:
                .serverError
            default:
                .networkError
            }
        case .underlying(let error):
            if let urlError = error as? URLError, urlError.code == .timedOut {
                return .requestTimeout
            }
            return .networkError
        }
    }
}
