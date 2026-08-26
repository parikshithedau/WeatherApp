import Foundation

protocol CitySearchRepositoryProtocol: Sendable {
    func searchCities(matching query: String) async throws -> [City]
}
