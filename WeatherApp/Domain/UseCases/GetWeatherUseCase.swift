import Foundation

struct GetWeatherUseCase: Sendable {
    private let repository: WeatherRepositoryProtocol

    init(repository: WeatherRepositoryProtocol) {
        self.repository = repository
    }

    func execute(city: City, forecastDays: Int = 7) async throws -> WeatherForecast {
        guard !city.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WeatherError.invalidCity
        }
        guard (1...16).contains(forecastDays) else {
            throw WeatherError.invalidForecastDays
        }
        return try await repository.fetchWeather(for: city, forecastDays: forecastDays)
    }
}
