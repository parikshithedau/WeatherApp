enum WeatherError: Error, Sendable, Equatable {
    case invalidCity
    case invalidSearchQuery
    case invalidRequest
    case networkError
    case requestTimeout
    case unauthorized
    case forbidden
    case rateLimited
    case serverError
    case decodingError
    case invalidResponse
    case notFound
    case noWeatherData
    case invalidForecastDays
}
