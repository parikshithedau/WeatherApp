import Foundation

protocol GeocodingAPIServiceProtocol: Sendable {
    func searchCities(query: String, limit: Int) async throws -> [CitySearchResultDTO]
}
