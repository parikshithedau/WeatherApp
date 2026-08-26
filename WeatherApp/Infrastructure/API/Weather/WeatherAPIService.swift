import Foundation

final class WeatherAPIService: WeatherAPIServiceProtocol, @unchecked Sendable {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func fetchForecast(latitude: Double, longitude: Double, forecastDays: Int) async throws -> WeatherResponseDTO {
        let request = WeatherAPIEndpoint.FetchForecast(
            latitude: latitude,
            longitude: longitude,
            forecastDays: forecastDays
        )
        return try await apiClient.execute(request)
    }
}
