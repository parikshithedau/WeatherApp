import XCTest
@testable import WeatherApp

final class WeatherViewModelTests: XCTestCase {
    @MainActor
    func testSelectCityLoadsForecastAndPublishesMappedContent() async {
        let repository = WeatherRepositoryMock()
        let mapper = WeatherForecastViewDataMapperMock()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: mapper
        )

        await viewModel.selectCity(TestFixtures.city)

        XCTAssertEqual(viewModel.state, .loaded(mapper.viewData))
        XCTAssertEqual(viewModel.selectedCityDisplayName, "London, England, United Kingdom")
        XCTAssertEqual(repository.requests.count, 1)
        XCTAssertEqual(repository.requests[0].forecastDays, 7)
        XCTAssertEqual(mapper.receivedForecasts, [TestFixtures.forecast()])
    }

    @MainActor
    func testSelectCityPublishesMappedErrorWhenLoadingFails() async {
        let repository = WeatherRepositoryMock(result: .failure(WeatherError.rateLimited))
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperMock()
        )

        await viewModel.selectCity(TestFixtures.city)

        XCTAssertEqual(viewModel.state, .error(StringConstant.Error.rateLimited))
    }

    @MainActor
    func testRefreshForecastDoesNothingUntilACityIsSelectedAndUsesUpdatedDayCountAfterwards() async {
        let repository = WeatherRepositoryMock()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperMock()
        )

        await viewModel.refreshForecast()
        XCTAssertTrue(repository.requests.isEmpty)

        await viewModel.selectCity(TestFixtures.city)
        viewModel.forecastDays = 14
        await viewModel.refreshForecast()

        XCTAssertEqual(repository.requests.map(\.forecastDays), [7, 14])
    }

    @MainActor
    func testSelectedCityDisplayNameIsEmptyBeforeSelectionAndOmitsBlankRegion() async {
        let repository = WeatherRepositoryMock()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperMock()
        )
        let cityWithoutRegion = City(
            id: 2,
            name: "Paris",
            region: "",
            country: "France",
            timeZone: "Europe/Paris",
            latitude: 48.8566,
            longitude: 2.3522
        )

        XCTAssertEqual(viewModel.selectedCityDisplayName, "")
        await viewModel.selectCity(cityWithoutRegion)
        XCTAssertEqual(viewModel.selectedCityDisplayName, "Paris, France")
    }
}

// MARK: - Additional WeatherViewModel Tests

final class WeatherViewModelStateTests: XCTestCase {
    @MainActor
    func testInitialStateIsIdle() async {
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: WeatherRepositoryMock()),
            forecastViewDataMapper: WeatherForecastViewDataMapperMock()
        )

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.forecastDays, 7)
        XCTAssertEqual(viewModel.selectedCityDisplayName, "")
    }

    @MainActor
    func testSelectCityTransitionsThroughLoadingToLoaded() async {
        let repository = WeatherRepositoryMock()
        let mapper = WeatherForecastViewDataMapperMock()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: mapper
        )

        XCTAssertEqual(viewModel.state, .idle)

        await viewModel.selectCity(TestFixtures.city)

        XCTAssertEqual(viewModel.state, .loaded(mapper.viewData))
        XCTAssertEqual(repository.requests.count, 1)
    }

    @MainActor
    func testSelectCityTransitionsThroughLoadingToError() async {
        let repository = WeatherRepositoryMock(result: .failure(WeatherError.serverError))
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperMock()
        )

        await viewModel.selectCity(TestFixtures.city)

        XCTAssertEqual(viewModel.state, .error(StringConstant.Error.server))
    }

    @MainActor
    func testRefreshUsesLatestForecastDaysAfterSelect() async {
        let repository = WeatherRepositoryMock()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperMock()
        )

        await viewModel.selectCity(TestFixtures.city)
        viewModel.forecastDays = 3
        await viewModel.refreshForecast()

        XCTAssertEqual(repository.requests.map(\.forecastDays), [7, 3])
    }

    @MainActor
    func testSelectNewCityUpdatesDisplayName() async {
        let repository = WeatherRepositoryMock()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperMock()
        )

        let paris = City(
            id: 2, name: "Paris", region: "Île-de-France",
            country: "France", timeZone: "Europe/Paris",
            latitude: 48.8566, longitude: 2.3522
        )

        await viewModel.selectCity(TestFixtures.city)
        XCTAssertEqual(viewModel.selectedCityDisplayName, "London, England, United Kingdom")

        await viewModel.selectCity(paris)
        XCTAssertEqual(viewModel.selectedCityDisplayName, "Paris, Île-de-France, France")
    }
}

// MARK: - WeatherState Equality Tests

@MainActor
final class WeatherStateEqualityTests: XCTestCase {
    func testIdleEqualsIdle() {
        XCTAssertEqual(WeatherViewModel.WeatherState.idle, .idle)
    }

    func testLoadingEqualsLoading() {
        XCTAssertEqual(WeatherViewModel.WeatherState.loading, .loading)
    }

    func testIdleDoesNotEqualLoading() {
        XCTAssertNotEqual(WeatherViewModel.WeatherState.idle, .loading)
    }

    func testLoadedEqualsLoadedWithSameData() {
        let viewData = WeatherForecastViewData(cityName: "London", timeZone: "UTC", days: [])
        XCTAssertEqual(
            WeatherViewModel.WeatherState.loaded(viewData),
            .loaded(viewData)
        )
    }

    func testLoadedDoesNotEqualLoadedWithDifferentData() {
        let a = WeatherViewModel.WeatherState.loaded(
            WeatherForecastViewData(cityName: "London", timeZone: "UTC", days: [])
        )
        let b = WeatherViewModel.WeatherState.loaded(
            WeatherForecastViewData(cityName: "Paris", timeZone: "CET", days: [])
        )
        XCTAssertNotEqual(a, b)
    }

    func testErrorEqualsErrorWithSameMessage() {
        XCTAssertEqual(
            WeatherViewModel.WeatherState.error("oops"),
            .error("oops")
        )
    }

    func testErrorDoesNotEqualErrorWithDifferentMessage() {
        XCTAssertNotEqual(
            WeatherViewModel.WeatherState.error("oops"),
            .error("different")
        )
    }

    func testErrorDoesNotEqualIdle() {
        XCTAssertNotEqual(WeatherViewModel.WeatherState.error("x"), .idle)
    }

    func testLoadedDoesNotEqualError() {
        let loaded = WeatherViewModel.WeatherState.loaded(
            WeatherForecastViewData(cityName: "London", timeZone: "UTC", days: [])
        )
        XCTAssertNotEqual(loaded, .error("x"))
    }
}
