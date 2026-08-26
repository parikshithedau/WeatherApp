import Foundation

final class CitySearchRepository: CitySearchRepositoryProtocol, @unchecked Sendable {
    private let remoteDataSource: CitySearchRemoteDataSourceProtocol

    init(remoteDataSource: CitySearchRemoteDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
    }

    func searchCities(matching query: String) async throws -> [City] {
        let dtos = try await remoteDataSource.searchCities(matching: query)
        return CityMapper.toDomain(dtos)
    }
}
