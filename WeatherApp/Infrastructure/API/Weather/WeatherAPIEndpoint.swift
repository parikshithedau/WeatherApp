import Foundation

enum WeatherAPIEndpoint {
    struct FetchForecast: APIRequest {
        typealias Response = WeatherResponseDTO

        let latitude: Double
        let longitude: Double
        let forecastDays: Int

        var baseURL: String { APIConstants.weatherBaseURL }
        var path: String { APIConstants.weatherForecastPath }
        var queryItems: [URLQueryItem]? {
            [
                URLQueryItem(name: APIConstants.latitudeParameter, value: String(latitude)),
                URLQueryItem(name: APIConstants.longitudeParameter, value: String(longitude)),
                URLQueryItem(name: APIConstants.forecastDaysParameter, value: String(forecastDays)),
                URLQueryItem(name: APIConstants.timezoneParameter, value: APIConstants.automaticTimezone),
                URLQueryItem(
                    name: APIConstants.dailyParameter,
                    value: APIConstants.dailyFields
                )
            ]
        }
    }
}
