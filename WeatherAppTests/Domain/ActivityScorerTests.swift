import XCTest
@testable import WeatherApp

private func assertScoreRange(
    _ scores: [ActivityScore],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    for score in scores {
        XCTAssertGreaterThanOrEqual(score.score, 0, file: file, line: line)
        XCTAssertLessThanOrEqual(score.score, 100, file: file, line: line)
    }
}

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

    func testRankActivitiesClampsOutdoorSightseeingScoreToZeroForExtremeConditions() {
        let day = TestFixtures.day(
            weatherCode: 99,
            maximumTemperature: 40,
            precipitation: 50
        )

        let scores = ActivityScorer().rankActivities(for: day)
        let outdoor = scores.first { $0.activity == .outdoorSightseeing }

        XCTAssertEqual(outdoor?.score, 0)
        XCTAssertTrue(outdoor?.reasons.contains(.extremeTemperature(40)) ?? false)
        XCTAssertTrue(outdoor?.reasons.contains(.heavyRain(50)) ?? false)
        XCTAssertTrue(outdoor?.reasons.contains(.thunderstormRisk) ?? false)
    }

    func testRankActivitiesForSnowyFreezingDayFavorsSkiingOverOutdoor() {
        let day = TestFixtures.day(
            maximumTemperature: -5,
            snowfall: 10,
            maximumWindSpeed: 5
        )

        let scores = ActivityScorer().rankActivities(for: day)

        XCTAssertEqual(scores.first?.activity, .skiing)
        let skiing = scores.first { $0.activity == .skiing }
        XCTAssertEqual(skiing?.score, 100)
        XCTAssertEqual(skiing?.reasons, [.freshSnow(10), .freezingConditions(-5)])
    }

    func testRankActivitiesForStrongWindPenalizesSurfing() {
        let day = TestFixtures.day(maximumWindSpeed: 40)

        let scores = ActivityScorer().rankActivities(for: day)
        let surfing = scores.first { $0.activity == .surfing }

        XCTAssertEqual(surfing?.score, 10)
        XCTAssertEqual(surfing?.reasons, [.windTooStrong(40)])
    }

    func testRankActivitiesForNearFreezingWithSnowFavorsSkiing() {
        let day = TestFixtures.day(maximumTemperature: 2, snowfall: 1)

        let scores = ActivityScorer().rankActivities(for: day)
        let skiing = scores.first { $0.activity == .skiing }

        XCTAssertEqual(skiing?.score, 35)
        XCTAssertEqual(skiing?.reasons, [.freshSnow(1), .nearFreezing(2)])
    }

    func testRankActivitiesReturnsAllFourActivities() {
        let day = TestFixtures.day()

        let scores = ActivityScorer().rankActivities(for: day)

        XCTAssertEqual(scores.count, 4)
        let activities = Set(scores.map(\.activity))
        XCTAssertTrue(activities.contains(.outdoorSightseeing))
        XCTAssertTrue(activities.contains(.indoorSightseeing))
        XCTAssertTrue(activities.contains(.surfing))
        XCTAssertTrue(activities.contains(.skiing))
    }
}
