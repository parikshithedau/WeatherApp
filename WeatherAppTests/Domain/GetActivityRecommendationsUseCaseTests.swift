import XCTest
@testable import WeatherApp

@MainActor
final class GetActivityRecommendationsUseCaseTests: XCTestCase {
    func testExecuteDelegatesToActivityScorer() {
        let expected = [ActivityScore(activity: .surfing, score: 90, reasons: [.idealWind(20)])]
        let scorer = ActivityScorerMock(results: expected)
        let day = TestFixtures.day(maximumWindSpeed: 20)

        let results = GetActivityRecommendationsUseCase(activityScorer: scorer).execute(for: day)

        XCTAssertEqual(results, expected)
        XCTAssertEqual(scorer.receivedDays, [day])
    }
}
