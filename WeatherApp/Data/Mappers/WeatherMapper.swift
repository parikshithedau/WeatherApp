import Foundation

enum WeatherMapper {
    static func toDomain(_ dto: WeatherResponseDTO, city: City) throws -> WeatherForecast {
        let daily = dto.daily
        guard !daily.time.isEmpty else {
            throw WeatherError.noWeatherData
        }

        let days = daily.time.indices.compactMap { index -> DailyWeather? in
            guard daily.weatherCode.indices.contains(index),
                  daily.maximumTemperature.indices.contains(index),
                  daily.minimumTemperature.indices.contains(index),
                  daily.precipitation.indices.contains(index),
                  daily.snowfall.indices.contains(index),
                  daily.maximumWindSpeed.indices.contains(index),
                  daily.maximumUVIndex.indices.contains(index) else {
                return nil
            }

            return DailyWeather(
                date: daily.time[index],
                weatherCode: daily.weatherCode[index],
                maximumTemperature: daily.maximumTemperature[index],
                minimumTemperature: daily.minimumTemperature[index],
                precipitation: daily.precipitation[index],
                snowfall: daily.snowfall[index],
                maximumWindSpeed: daily.maximumWindSpeed[index],
                maximumUVIndex: daily.maximumUVIndex[index]
            )
        }
        guard !days.isEmpty else { throw WeatherError.noWeatherData }

        return WeatherForecast(
            city: city,
            timeZone: dto.timezone,
            days: days
        )
    }
}
