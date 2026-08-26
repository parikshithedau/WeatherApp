import XCTest
@testable import WeatherApp

@MainActor
final class ActivityScorerTests: XCTestCase {
    func testRankActivitiesForIdealSightseeingDayRanksAndExplainsRecommendations() {
        let day = TestFixtures.day()

        let scores = ActivityScorer().rankActivities(for: day)

        XCTAssertEqual(scores.map(\.activity), [.outdoorSightseeing, .surfing, .indoorSightseeing, .skiing])
        XCTAssertEqual(scores.map(\.score), [100, 90, 20, 0])
        XCTAssertEqual(scores[0].reasons, [.idealTemperature(22), .noRain])
        XCTAssertEqual(scores[1].reasons, [.idealWind(18)])
        XCTAssertEqual(scores[2].reasons, [.weatherTooNiceToStayInside])
        XCTAssertEqual(scores[3].reasons, [.noSnowAndTemperature(22)])
    }

    func testRankActivitiesForStormyDayClampsScoresAndPrioritizesIndoorActivity() {
        let day = TestFixtures.day(
            weatherCode: 95,
            maximumTemperature: 35,
            precipitation: 12,
            maximumWindSpeed: 30
        )

        let scores = ActivityScorer().rankActivities(for: day)

        XCTAssertEqual(scores.map(\.activity), [.indoorSightseeing, .outdoorSightseeing, .surfing, .skiing])
        XCTAssertEqual(scores.map(\.score), [100, 0, 0, 0])
        XCTAssertEqual(
            scores[0].reasons,
            [.heavyRainOutside(12), .thunderstormExpected, .uncomfortableOutdoorTemperature]
        )
        XCTAssertEqual(
            scores[1].reasons,
            [.extremeTemperature(35), .heavyRain(12), .thunderstormRisk]
        )
        XCTAssertEqual(
            scores[2].reasons,
            [.windTooStrong(30), .thunderstormSafetyHazard, .heavyRain(12)]
        )
    }

    func testRankActivitiesHonorsPrecipitationAndWindBoundaryValues() {
        let day = TestFixtures.day(
            maximumTemperature: 26,
            precipitation: 2,
            maximumWindSpeed: 10
        )

        let scores = ActivityScorer().rankActivities(for: day)

        XCTAssertEqual(scores.map(\.score), [70, 65, 50, 0])
        XCTAssertEqual(scores[0].reasons, [.idealTemperature(26), .lightRain(2)])
        XCTAssertEqual(scores[1].reasons, [.moderateWind(10)])
        XCTAssertEqual(scores[2].reasons, [.rainyOutside(2)])
    }

    func testRankActivitiesAwardsSkiingForFreshSnowAndFreezingConditions() {
        let day = TestFixtures.day(maximumTemperature: -1, snowfall: 3)

        let skiing = ActivityScorer().rankActivities(for: day).first { $0.activity == .skiing }

        XCTAssertEqual(skiing?.score, 100)
        XCTAssertEqual(skiing?.reasons, [.freshSnow(3), .freezingConditions(-1)])
    }
}

@MainActor
final class GetActivityRecommendationsUseCaseTests: XCTestCase {
    func testExecuteDelegatesToActivityScorer() {
        let expected = [ActivityScore(activity: .surfing, score: 90, reasons: [.idealWind(20)])]
        let scorer = ActivityScorerSpy(results: expected)
        let day = TestFixtures.day(maximumWindSpeed: 20)

        let results = GetActivityRecommendationsUseCase(activityScorer: scorer).execute(for: day)

        XCTAssertEqual(results, expected)
        XCTAssertEqual(scorer.receivedDays, [day])
    }
}

@MainActor
final class GetWeatherUseCaseTests: XCTestCase {
    func testExecuteForwardsValidCityAndForecastDaysToRepository() async throws {
        let repository = WeatherRepositorySpy()
        let useCase = GetWeatherUseCase(repository: repository)

        let forecast = try await useCase.execute(city: TestFixtures.city, forecastDays: 10)

        XCTAssertEqual(forecast, TestFixtures.forecast())
        XCTAssertEqual(repository.requests.count, 1)
        XCTAssertEqual(repository.requests[0].city, TestFixtures.city)
        XCTAssertEqual(repository.requests[0].forecastDays, 10)
    }

    func testExecuteRejectsBlankCityWithoutCallingRepository() async {
        let repository = WeatherRepositorySpy()
        let invalidCity = City(
            id: 1,
            name: "  ",
            region: nil,
            country: "United Kingdom",
            timeZone: nil,
            latitude: 0,
            longitude: 0
        )

        do {
            _ = try await GetWeatherUseCase(repository: repository).execute(city: invalidCity)
            XCTFail("Expected an invalid city error")
        } catch {
            XCTAssertEqual(error as? WeatherError, .invalidCity)
        }
        XCTAssertTrue(repository.requests.isEmpty)
    }

    func testExecuteRejectsForecastDaysOutsideSupportedRangeWithoutCallingRepository() async {
        for forecastDays in [0, 17] {
            let repository = WeatherRepositorySpy()

            do {
                _ = try await GetWeatherUseCase(repository: repository).execute(
                    city: TestFixtures.city,
                    forecastDays: forecastDays
                )
                XCTFail("Expected an invalid forecast day error")
            } catch {
                XCTAssertEqual(error as? WeatherError, .invalidForecastDays)
            }
            XCTAssertTrue(repository.requests.isEmpty)
        }
    }
}

@MainActor
final class SearchCitiesUseCaseTests: XCTestCase {
    func testExecuteTrimsQueryBeforeForwardingItToRepository() async throws {
        let repository = CityRepositorySpy()
        let useCase = SearchCitiesUseCase(repository: repository)

        let cities = try await useCase.execute(query: "  London  ")

        XCTAssertEqual(cities, [TestFixtures.city])
        XCTAssertEqual(repository.queries, ["London"])
    }

    func testExecuteRejectsQueriesShorterThanTwoCharactersWithoutCallingRepository() async {
        for query in ["", " ", "L"] {
            let repository = CityRepositorySpy()

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
