import Foundation

struct SearchCitiesUseCase: Sendable {
    private let repository: CitySearchRepositoryProtocol

    init(repository: CitySearchRepositoryProtocol) {
        self.repository = repository
    }

    func execute(query: String) async throws -> [City] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return try await repository.searchCities(matching: trimmedQuery)
    }
}
