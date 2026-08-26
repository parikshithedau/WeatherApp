import Foundation

final class WeatherRepository: WeatherRepositoryProtocol, @unchecked Sendable {
    private let remoteDataSource: WeatherRemoteDataSourceProtocol

    init(remoteDataSource: WeatherRemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    func fetchWeather(for city: City, forecastDays: Int) async throws -> WeatherForecast {
        let dto = try await remoteDataSource.fetchWeather(for: city, forecastDays: forecastDays)
        return try WeatherMapper.toDomain(dto, city: city)
    }
}
