import Foundation

protocol WeatherRepositoryProtocol: Sendable {
    func fetchWeather(for city: City, forecastDays: Int) async throws -> WeatherForecast
}
