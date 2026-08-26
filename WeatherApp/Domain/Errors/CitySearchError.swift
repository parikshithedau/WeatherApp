enum CitySearchError: Error, Sendable, Equatable {
    case invalidRequest
    case networkError
    case requestTimeout
    case unauthorized
    case forbidden
    case rateLimited
    case serverError
    case decodingError
    case invalidResponse
    case noResults
}
