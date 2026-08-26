import Foundation

protocol WeatherForecastViewDataMapping: Sendable {
    func map(_ forecast: WeatherForecast) -> WeatherForecastViewData
}

struct WeatherForecastViewDataMapper: WeatherForecastViewDataMapping, Sendable {
    private let getActivityRecommendationsUseCase: GetActivityRecommendationsUseCase

    init(getActivityRecommendationsUseCase: GetActivityRecommendationsUseCase) {
        self.getActivityRecommendationsUseCase = getActivityRecommendationsUseCase
    }

    func map(_ forecast: WeatherForecast) -> WeatherForecastViewData {
        WeatherForecastViewData(
            cityName: StringConstant.City.displayName(
                name: forecast.city.name,
                region: forecast.city.region,
                country: forecast.city.country
            ),
            timeZone: forecast.timeZone,
            days: forecast.days.map { makeDayViewData(from: $0) }
        )
    }

    private func makeDayViewData(from day: DailyWeather) -> WeatherDayViewData {
        WeatherDayViewData(
            id: day.id,
            date: day.date,
            conditionDescription: StringConstant.Weather.conditionDescription(for: day.weatherCode),
            temperatureSummary: StringConstant.Weather.temperatureRange(
                maximum: day.maximumTemperature,
                minimum: day.minimumTemperature
            ),
            windAndUVSummary: StringConstant.Weather.windAndUV(
                wind: day.maximumWindSpeed,
                uvIndex: day.maximumUVIndex
            ),
            precipitationAndSnowSummary: StringConstant.Weather.precipitationAndSnow(
                precipitation: day.precipitation,
                snowfall: day.snowfall
            ),
            activityRecommendations: getActivityRecommendationsUseCase
                .execute(for: day)
                .map { makeActivityRecommendationViewData(from: $0) }
        )
    }

    private func makeActivityRecommendationViewData(
        from recommendation: ActivityScore
    ) -> ActivityRecommendationViewData {
        let title = StringConstant.Activity.title(for: recommendation.activity)
        let reason = recommendation.reasons
            .map { StringConstant.Activity.reasonDescription(for: $0) }
            .joined(separator: StringConstant.Common.listSeparator)

        return ActivityRecommendationViewData(
            id: recommendation.activity,
            iconName: StringConstant.Activity.iconName(for: recommendation.activity),
            title: title,
            reason: reason,
            scoreText: StringConstant.Activity.scoreText(recommendation.score),
            scoreTone: scoreTone(for: recommendation.score),
            accessibilityLabel: StringConstant.Activity.accessibilityLabel(
                title: title,
                score: recommendation.score,
                reason: reason
            )
        )
    }

    private func scoreTone(for score: Int) -> ActivityScoreTone {
        switch score {
        case 70...100: .favorable
        case 40..<70: .neutral
        default: .unfavorable
        }
    }
}
