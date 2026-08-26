import Foundation

nonisolated struct WeatherResponseDTO: Decodable, Sendable {
    let timezone: String
    let daily: DailyDTO

    struct DailyDTO: Decodable, Sendable {
        let time: [String]
        let weatherCode: [Int]
        let maximumTemperature: [Double]
        let minimumTemperature: [Double]
        let precipitation: [Double]
        let snowfall: [Double]
        let maximumWindSpeed: [Double]
        let maximumUVIndex: [Double]

        enum CodingKeys: String, CodingKey {
            case time
            case weatherCode = "weather_code"
            case maximumTemperature = "temperature_2m_max"
            case minimumTemperature = "temperature_2m_min"
            case precipitation = "precipitation_sum"
            case snowfall = "snowfall_sum"
            case maximumWindSpeed = "wind_speed_10m_max"
            case maximumUVIndex = "uv_index_max"
        }
    }
}
