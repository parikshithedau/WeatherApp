import XCTest
@testable import WeatherApp

@MainActor
final class SearchCitiesUseCaseTests: XCTestCase {
    func testExecuteTrimsQueryBeforeForwardingItToRepository() async throws {
        let repository = CityRepositoryMock()
        let useCase = SearchCitiesUseCase(repository: repository)

        let cities = try await useCase.execute(query: "  London  ")

        XCTAssertEqual(cities, [TestFixtures.city])
        XCTAssertEqual(repository.queries, ["London"])
    }

    func testExecuteRejectsQueriesShorterThanTwoCharactersWithoutCallingRepository() async {
        for query in ["", " ", "L"] {
            let repository = CityRepositoryMock()

            do {
                _ = try await SearchCitiesUseCase(repository: repository).execute(query: query)
                XCTFail("Expected an invalid search query error")
            } catch {
                XCTAssertEqual(error as? WeatherError, .invalidSearchQuery)
            }
            XCTAssertTrue(repository.queries.isEmpty)
        }
    }
}
