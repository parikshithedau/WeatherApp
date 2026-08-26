import Foundation

final class GeocodingAPIService: GeocodingAPIServiceProtocol, @unchecked Sendable {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func searchCities(query: String, limit: Int) async throws -> [CitySearchResultDTO] {
        let request = GeocodingAPIEndpoint.SearchCities(query: query, limit: limit)
        let response = try await apiClient.execute(request)
        return response.results ?? []
    }
}
