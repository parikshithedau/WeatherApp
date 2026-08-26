import Foundation

protocol WeatherAPIServiceProtocol: Sendable {
    func fetchForecast(latitude: Double, longitude: Double, forecastDays: Int) async throws -> WeatherResponseDTO
}
