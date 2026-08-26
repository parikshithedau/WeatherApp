import Foundation

protocol WeatherRemoteDataSourceProtocol: Sendable {
    func fetchWeather(for city: City, forecastDays: Int) async throws -> WeatherResponseDTO
}

final class WeatherRemoteDataSource: WeatherRemoteDataSourceProtocol, @unchecked Sendable {
    private let weatherAPIService: WeatherAPIServiceProtocol

    init(weatherAPIService: WeatherAPIServiceProtocol) {
        self.weatherAPIService = weatherAPIService
    }

    func fetchWeather(for city: City, forecastDays: Int) async throws -> WeatherResponseDTO {
        do {
            return try await weatherAPIService.fetchForecast(
                latitude: city.latitude,
                longitude: city.longitude,
                forecastDays: forecastDays
            )
        } catch let error as APIError {
            throw APIErrorMapper.toDomain(error)
        } catch {
            throw WeatherError.networkError
        }
    }
}
