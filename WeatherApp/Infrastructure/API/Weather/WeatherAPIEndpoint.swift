import Foundation

enum WeatherAPIEndpoint {
    struct FetchForecast: APIRequest {
        typealias Response = WeatherResponseDTO

        let latitude: Double
        let longitude: Double
        let forecastDays: Int

        var baseURL: String { StringConstant.API.weatherBaseURL }
        var path: String { StringConstant.API.weatherForecastPath }
        var queryItems: [URLQueryItem]? {
            [
                URLQueryItem(name: StringConstant.API.latitudeParameter, value: String(latitude)),
                URLQueryItem(name: StringConstant.API.longitudeParameter, value: String(longitude)),
                URLQueryItem(name: StringConstant.API.forecastDaysParameter, value: String(forecastDays)),
                URLQueryItem(name: StringConstant.API.timezoneParameter, value: StringConstant.API.automaticTimezone),
                URLQueryItem(
                    name: StringConstant.API.dailyParameter,
                    value: StringConstant.API.dailyFields
                )
            ]
        }
    }
}
