import XCTest
@testable import WeatherApp

@MainActor
final class ErrorMessageMapperTests: XCTestCase {
    func testMessageMapsEachDomainFailureToAnActionableUserMessage() {
        let testCases: [(WeatherError, String)] = [
            (.invalidCity, StringConstant.Error.invalidCity),
            (.invalidSearchQuery, StringConstant.Error.invalidSearchQuery),
            (.invalidRequest, StringConstant.Error.invalidRequest),
            (.networkError, StringConstant.Error.network),
            (.requestTimeout, StringConstant.Error.requestTimeout),
            (.unauthorized, StringConstant.Error.unauthorized),
            (.forbidden, StringConstant.Error.forbidden),
            (.rateLimited, StringConstant.Error.rateLimited),
            (.serverError, StringConstant.Error.server),
            (.decodingError, StringConstant.Error.decoding),
            (.invalidResponse, StringConstant.Error.invalidResponse),
            (.notFound, StringConstant.Error.cityNotFound),
            (.noWeatherData, StringConstant.Error.noWeatherData),
            (.invalidForecastDays, StringConstant.Error.invalidForecastDays)
        ]

        for (error, expectedMessage) in testCases {
            XCTAssertEqual(ErrorMessageMapper.message(for: error), expectedMessage)
        }
    }

    func testMessageUsesSafeFallbackForUnexpectedErrors() {
        XCTAssertEqual(ErrorMessageMapper.message(for: TestError.expected), StringConstant.Error.unexpected)
    }
}

@MainActor
final class CityErrorMessageMapperTests: XCTestCase {
    func testMessageMapsEachCitySearchFailureToAnActionableUserMessage() {
        let testCases: [(CitySearchError, String)] = [
            (.invalidRequest, StringConstant.Error.CitySearch.invalidRequest),
            (.networkError, StringConstant.Error.CitySearch.network),
            (.requestTimeout, StringConstant.Error.CitySearch.requestTimeout),
            (.unauthorized, StringConstant.Error.CitySearch.unauthorized),
            (.forbidden, StringConstant.Error.CitySearch.forbidden),
            (.rateLimited, StringConstant.Error.CitySearch.rateLimited),
            (.serverError, StringConstant.Error.CitySearch.server),
            (.decodingError, StringConstant.Error.CitySearch.decoding),
            (.invalidResponse, StringConstant.Error.CitySearch.invalidResponse),
            (.noResults, StringConstant.Error.CitySearch.noResults)
        ]

        for (error, expectedMessage) in testCases {
            XCTAssertEqual(CityErrorMessageMapper.message(for: error), expectedMessage)
        }
    }

    func testMessageUsesSafeFallbackForUnexpectedErrors() {
        XCTAssertEqual(CityErrorMessageMapper.message(for: TestError.expected), StringConstant.Error.CitySearch.unexpected)
    }
}

@MainActor
final class WeatherForecastViewDataMapperTests: XCTestCase {
    func testMapCreatesDisplayReadyForecastAndActivityInformation() {
        let mapper = WeatherForecastViewDataMapper(
            getActivityRecommendationsUseCase: GetActivityRecommendationsUseCase(activityScorer: ActivityScorer())
        )
        let forecast = TestFixtures.forecast(days: [
            TestFixtures.day(
                weatherCode: 61,
                maximumTemperature: 21.6,
                minimumTemperature: 11.4,
                precipitation: 1.2,
                snowfall: 0.5,
                maximumWindSpeed: 18.2,
                maximumUVIndex: 4.8
            )
        ])

        let viewData = mapper.map(forecast)

        XCTAssertEqual(viewData.cityName, "London, England, United Kingdom")
        XCTAssertEqual(viewData.timeZone, "Europe/London")
        XCTAssertEqual(viewData.days.count, 1)
        XCTAssertEqual(viewData.days[0].id, "2026-08-26")
        XCTAssertEqual(viewData.days[0].conditionDescription, StringConstant.Weather.rain)
        XCTAssertEqual(viewData.days[0].temperatureSummary, "22° / 11°")
        XCTAssertEqual(viewData.days[0].windAndUVSummary, "Wind 18 · UV 5")
        XCTAssertEqual(viewData.days[0].precipitationAndSnowSummary, "Rain 1.2 mm · Snow 0.5 cm")
        XCTAssertEqual(viewData.days[0].activityRecommendations.map(\.title), [
            StringConstant.Activity.surfingTitle,
            StringConstant.Activity.outdoorSightseeingTitle,
            StringConstant.Activity.indoorSightseeingTitle,
            StringConstant.Activity.skiingTitle
        ])
        XCTAssertEqual(viewData.days[0].activityRecommendations[0].scoreTone, .favorable)
        XCTAssertTrue(viewData.days[0].activityRecommendations[0].accessibilityLabel.contains("percent suitable"))
    }

    func testMapUsesScoreToneBoundariesAndCombinesReasons() {
        let recommendations = [
            ActivityScore(activity: .outdoorSightseeing, score: 70, reasons: [.noRain]),
            ActivityScore(activity: .indoorSightseeing, score: 69, reasons: [.rainyOutside(2)]),
            ActivityScore(activity: .surfing, score: 39, reasons: [.windTooWeak(5), .heavyRain(6)])
        ]
        let scorer = ActivityScorerSpy(results: recommendations)
        let mapper = WeatherForecastViewDataMapper(
            getActivityRecommendationsUseCase: GetActivityRecommendationsUseCase(activityScorer: scorer)
        )

        let result = mapper.map(TestFixtures.forecast()).days[0].activityRecommendations

        XCTAssertEqual(result.map(\.scoreTone), [.favorable, .neutral, .unfavorable])
        XCTAssertEqual(result[0].reason, StringConstant.Activity.noRain)
        XCTAssertEqual(result[1].reason, "Rainy outside (2.0 mm)")
        XCTAssertEqual(result[2].reason, "Wind too weak (5 km/h), Heavy rain (6.0 mm)")
        XCTAssertEqual(result[2].scoreText, "39%")
        XCTAssertEqual(scorer.receivedDays, [TestFixtures.day()])
    }
}

@MainActor
final class PresentationFormattingTests: XCTestCase {
    func testWeatherConditionDescriptionCoversAllAPICategoriesAndFallback() {
        let testCases: [(Int, String)] = [
            (0, StringConstant.Weather.clearSky),
            (2, StringConstant.Weather.partlyCloudy),
            (45, StringConstant.Weather.foggy),
            (53, StringConstant.Weather.drizzle),
            (63, StringConstant.Weather.rain),
            (75, StringConstant.Weather.snow),
            (96, StringConstant.Weather.thunderstorm),
            (-1, StringConstant.Weather.unknownConditions)
        ]

        for (code, expected) in testCases {
            XCTAssertEqual(StringConstant.Weather.conditionDescription(for: code), expected)
        }
    }

    func testCityFormattingHandlesOptionalRegionAndTimezone() {
        XCTAssertEqual(
            StringConstant.City.displayName(name: "London", region: "England", country: "United Kingdom"),
            "London, England, United Kingdom"
        )
        XCTAssertEqual(
            StringConstant.City.displayName(name: "Paris", region: "", country: "France"),
            "Paris, France"
        )
        XCTAssertEqual(StringConstant.City.timezoneDisplayName("America/New_York"), "America/New York")
        XCTAssertEqual(StringConstant.City.timezoneDisplayName(nil), StringConstant.City.unknownTimezone)
    }
}

final class WeatherViewModelTests: XCTestCase {
    @MainActor
    func testSelectCityLoadsForecastAndPublishesMappedContent() async {
        let repository = WeatherRepositorySpy()
        let mapper = WeatherForecastViewDataMapperSpy()
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
        let repository = WeatherRepositorySpy(result: .failure(WeatherError.rateLimited))
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperSpy()
        )

        await viewModel.selectCity(TestFixtures.city)

        XCTAssertEqual(viewModel.state, .error(StringConstant.Error.rateLimited))
    }

    @MainActor
    func testRefreshForecastDoesNothingUntilACityIsSelectedAndUsesUpdatedDayCountAfterwards() async {
        let repository = WeatherRepositorySpy()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperSpy()
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
        let repository = WeatherRepositorySpy()
        let viewModel = WeatherViewModel(
            getWeatherUseCase: GetWeatherUseCase(repository: repository),
            forecastViewDataMapper: WeatherForecastViewDataMapperSpy()
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

final class CitySearchViewModelTests: XCTestCase {
    @MainActor
    func testSearchCitiesPublishesResultsForValidQuery() async {
        let repository = CityRepositorySpy()
        let viewModel = CitySearchViewModel(searchCitiesUseCase: SearchCitiesUseCase(repository: repository))

        await viewModel.searchCities(matching: "  London ")

        XCTAssertEqual(viewModel.state, .results([TestFixtures.city]))
        XCTAssertEqual(repository.queries, ["London"])
    }

    @MainActor
    func testSearchCitiesPublishesEmptyAndFailureStates() async {
        let emptyRepository = CityRepositorySpy(result: .success([]))
        let emptyViewModel = CitySearchViewModel(
            searchCitiesUseCase: SearchCitiesUseCase(repository: emptyRepository)
        )
        await emptyViewModel.searchCities(matching: "Paris")
        XCTAssertEqual(emptyViewModel.state, .empty)

        let failedRepository = CityRepositorySpy(result: .failure(CitySearchError.serverError))
        let failedViewModel = CitySearchViewModel(
            searchCitiesUseCase: SearchCitiesUseCase(repository: failedRepository)
        )
        await failedViewModel.searchCities(matching: "Paris")
        XCTAssertEqual(failedViewModel.state, .failure(StringConstant.Error.CitySearch.server))
    }

    @MainActor
    func testSearchCitiesResetsToIdleForShortQueryWithoutCallingRepository() async {
        let repository = CityRepositorySpy()
        let viewModel = CitySearchViewModel(searchCitiesUseCase: SearchCitiesUseCase(repository: repository))

        await viewModel.searchCities(matching: " L ")

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(repository.queries.isEmpty)
    }

    @MainActor
    func testQueryBindingSearchesAfterDebounceUsingInjectedZeroDelay() async {
        let repository = CityRepositorySpy()
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
}
