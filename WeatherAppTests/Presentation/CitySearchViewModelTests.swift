import XCTest
@testable import WeatherApp

final class CitySearchViewModelTests: XCTestCase {
    @MainActor
    func testSearchCitiesPublishesResultsForValidQuery() async {
        let repository = CityRepositoryMock()
        let viewModel = CitySearchViewModel(searchCitiesUseCase: SearchCitiesUseCase(repository: repository))

        await viewModel.searchCities(matching: "  London ")

        XCTAssertEqual(viewModel.state, .results([TestFixtures.city]))
        XCTAssertEqual(repository.queries, ["London"])
    }

    @MainActor
    func testSearchCitiesPublishesEmptyAndFailureStates() async {
        let emptyRepository = CityRepositoryMock(result: .success([]))
        let emptyViewModel = CitySearchViewModel(
            searchCitiesUseCase: SearchCitiesUseCase(repository: emptyRepository)
        )
        await emptyViewModel.searchCities(matching: "Paris")
        XCTAssertEqual(emptyViewModel.state, .empty)

        let failedRepository = CityRepositoryMock(result: .failure(CitySearchError.serverError))
        let failedViewModel = CitySearchViewModel(
            searchCitiesUseCase: SearchCitiesUseCase(repository: failedRepository)
        )
        await failedViewModel.searchCities(matching: "Paris")
        XCTAssertEqual(failedViewModel.state, .failure(StringConstant.Error.CitySearch.server))
    }

    @MainActor
    func testSearchCitiesResetsToIdleForShortQueryWithoutCallingRepository() async {
        let repository = CityRepositoryMock()
        let viewModel = CitySearchViewModel(searchCitiesUseCase: SearchCitiesUseCase(repository: repository))

        await viewModel.searchCities(matching: " L ")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(repository.queries.isEmpty)
    }

    @MainActor
    func testQueryBindingSearchesAfterDebounceUsingInjectedZeroDelay() async {
        let repository = CityRepositoryMock()
        let searched = expectation(description: "search started")
        repository.onSearch = { _ in searched.fulfill() }
        let viewModel = CitySearchViewModel(
            searchCitiesUseCase: SearchCitiesUseCase(repository: repository),
            debounceInterval: .zero
        )

        viewModel.query = "London"
        await fulfillment(of: [searched], timeout: 1)

        XCTAssertEqual(repository.queries, ["London"])
        XCTAssertEqual(viewModel.state, .results([TestFixtures.city]))
    }

    @MainActor
    func testCancelSearchCancelsInFlightRequestAndClearsTask() async {
        let repository = CityRepositoryMock(result: .success([TestFixtures.city]))
        let viewModel = CitySearchViewModel(
            searchCitiesUseCase: SearchCitiesUseCase(repository: repository),
            debounceInterval: .zero
        )

        viewModel.query = "London"
        try? await Task.sleep(for: .milliseconds(10))
        viewModel.cancelSearch()

        XCTAssertEqual(repository.queries.count, 1)
    }

    @MainActor
    func testQueryBindingTrimsLeadingAndTrailingWhitespace() async {
        let repository = CityRepositoryMock()
        let searched = expectation(description: "search started")
        repository.onSearch = { _ in searched.fulfill() }
        let viewModel = CitySearchViewModel(
            searchCitiesUseCase: SearchCitiesUseCase(repository: repository),
            debounceInterval: .zero
        )

        viewModel.query = "  Paris  "
        await fulfillment(of: [searched], timeout: 1)

        XCTAssertEqual(repository.queries, ["Paris"])
    }

    @MainActor
    func testSearchCitiesWithSingleCharacterQueryReturnsIdle() async {
        let repository = CityRepositoryMock()
        let viewModel = CitySearchViewModel(searchCitiesUseCase: SearchCitiesUseCase(repository: repository))

        await viewModel.searchCities(matching: "A")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(repository.queries.isEmpty)
    }

    @MainActor
    func testSearchCitiesWithWhitespaceOnlyQueryReturnsIdle() async {
        let repository = CityRepositoryMock()
        let viewModel = CitySearchViewModel(searchCitiesUseCase: SearchCitiesUseCase(repository: repository))

        await viewModel.searchCities(matching: "   ")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(repository.queries.isEmpty)
    }
}
