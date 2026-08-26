import XCTest
@testable import WeatherApp

@MainActor
final class CitySearchRepositoryTests: XCTestCase {
    func testSearchCitiesMapsRemoteDTOsAndFiltersInvalidCities() async throws {
        let remote = CityRemoteDataSourceMock(result: .success([
            TestFixtures.cityDTO(),
            TestFixtures.cityDTO(id: 2, country: nil)
        ]))
        let repository = CitySearchRepository(remoteDataSource: remote)

        let cities = try await repository.searchCities(matching: "London")

        XCTAssertEqual(cities, [TestFixtures.city])
        XCTAssertEqual(remote.queries, ["London"])
    }

    func testSearchCitiesForwardsRemoteFailure() async {
        let remote = CityRemoteDataSourceMock(result: .failure(TestError.expected))

        do {
            _ = try await CitySearchRepository(remoteDataSource: remote).searchCities(matching: "London")
            XCTFail("Expected the remote error to be forwarded")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }
}
