import Foundation

enum APIErrorMapper {
    static func toDomain(_ error: APIError) -> WeatherError {
        switch error {
        case .httpError(404):
            .notFound
        case .decodingError:
            .decodingError
        case .invalidURL, .invalidResponse, .httpError, .underlying:
            .networkError
        }
    }
}
