import Foundation

struct WeatherForecastViewData: Equatable, Sendable {
    let cityName: String
    let timeZone: String
    let days: [WeatherDayViewData]
}

struct WeatherDayViewData: Identifiable, Equatable, Sendable {
    let id: String
    let date: String
    let conditionDescription: String
    let temperatureSummary: String
    let windAndUVSummary: String
    let precipitationAndSnowSummary: String
    let activityRecommendations: [ActivityRecommendationViewData]
}

struct ActivityRecommendationViewData: Identifiable, Equatable, Sendable {
    let id: ActivityType
    let iconName: String
    let title: String
    let reason: String
    let scoreText: String
    let scoreTone: ActivityScoreTone
    let accessibilityLabel: String
}

enum ActivityScoreTone: Equatable, Sendable {
    case favorable
    case neutral
    case unfavorable
}
