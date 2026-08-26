import Foundation

struct WeatherForecast: Equatable, Sendable {
    let city: City
    let timeZone: String
    let days: [DailyWeather]
}

struct DailyWeather: Equatable, Identifiable, Sendable {
    let date: String
    let weatherCode: Int
    let maximumTemperature: Double
    let minimumTemperature: Double
    let precipitation: Double
    let snowfall: Double
    let maximumWindSpeed: Double
    let maximumUVIndex: Double

    var id: String { date }

}

enum ActivityType: Int, CaseIterable, Identifiable, Sendable {
    case outdoorSightseeing
    case indoorSightseeing
    case surfing
    case skiing

    var id: Int { rawValue }
}

struct ActivityScore: Identifiable, Equatable, Sendable {
    var id: ActivityType { activity }

    let activity: ActivityType
    let score: Int
    let reasons: [ActivityReason]
}

enum ActivityReason: Equatable, Sendable {
    case idealTemperature(Int)
    case suboptimalTemperature(Int)
    case extremeTemperature(Int)
    case heavyRain(Double)
    case lightRain(Double)
    case noRain
    case thunderstormRisk
    case heavyRainOutside(Double)
    case rainyOutside(Double)
    case thunderstormExpected
    case uncomfortableOutdoorTemperature
    case weatherTooNiceToStayInside
    case idealWind(Int)
    case moderateWind(Int)
    case windTooWeak(Int)
    case windTooStrong(Int)
    case thunderstormSafetyHazard
    case noSnowAndTemperature(Int)
    case freshSnow(Double)
    case freezingConditions(Int)
    case nearFreezing(Int)
}
