import Foundation

protocol CitySearchRemoteDataSourceProtocol: Sendable {
    func searchCities(matching query: String) async throws -> [CitySearchResultDTO]
}

final class CitySearchRemoteDataSource: CitySearchRemoteDataSourceProtocol, @unchecked Sendable {
    private let geocodingAPIService: GeocodingAPIServiceProtocol
    private let resultLimit: Int

    init(geocodingAPIService: GeocodingAPIServiceProtocol, resultLimit: Int = 8) {
        self.geocodingAPIService = geocodingAPIService
        self.resultLimit = resultLimit
    }

    func searchCities(matching query: String) async throws -> [CitySearchResultDTO] {
        do {
            return try await geocodingAPIService.searchCities(query: query, limit: resultLimit)
        } catch let error as APIError {
            throw CitySearchAPIErrorMapper.toDomain(error)
        } catch let error as URLError where error.code == .timedOut {
            throw CitySearchError.requestTimeout
        } catch {
            throw CitySearchError.networkError
        }
    }
}
