import Foundation

struct GetActivityRecommendationsUseCase: Sendable {
    private let activityScorer: any ActivityScoring

    init(activityScorer: any ActivityScoring) {
        self.activityScorer = activityScorer
    }

    func execute(for day: DailyWeather) -> [ActivityScore] {
        activityScorer.rankActivities(for: day)
    }
}
