import Foundation

enum APIConstants {
    static let weatherBaseURL = "https://api.open-meteo.com/v1"
    static let weatherForecastPath = "/forecast"
    static let geocodingBaseURL = "https://geocoding-api.open-meteo.com/v1"
    static let geocodingSearchPath = "/search"
    static let latitudeParameter = "latitude"
    static let longitudeParameter = "longitude"
    static let forecastDaysParameter = "forecast_days"
    static let timezoneParameter = "timezone"
    static let automaticTimezone = "auto"
    static let dailyParameter = "daily"
    static let dailyFields = "weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,snowfall_sum,wind_speed_10m_max,uv_index_max"
    static let cityNameParameter = "name"
    static let cityCountParameter = "count"
    static let languageParameter = "language"
    static let englishLanguage = "en"
    static let formatParameter = "format"
    static let jsonFormat = "json"
}
