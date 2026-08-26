enum WeatherError: Error, Sendable {
    case invalidCity
    case networkError
    case decodingError
    case notFound
    case noWeatherData
    case invalidForecastDays
}
