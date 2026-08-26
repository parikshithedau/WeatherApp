import Foundation

enum StringConstant {
    enum Common {
        static let empty = ""
        static let listSeparator = ", "
    }

    enum City {
        static let unknownTimezone = "Unknown timezone"
        static let timezoneUnderscore = "_"
        static let timezoneSpace = " "
        static let querySeparator = ","

        static func displayName(name: String, region: String?, country: String) -> String {
            guard let region, !region.isEmpty else {
                return [name, country].joined(separator: Common.listSeparator)
            }
            return [name, region, country].joined(separator: Common.listSeparator)
        }

        static func weatherQuery(name: String, country: String) -> String {
            [name, country].joined(separator: querySeparator)
        }

        static func timezoneDisplayName(_ timezone: String?) -> String {
            timezone?.replacingOccurrences(of: timezoneUnderscore, with: timezoneSpace) ?? unknownTimezone
        }
    }

    enum Weather {
        static let title = "Weather"
        static let loading = "Loading weather…"
        static let searchCityPlaceholder = "Search city"
        static let searchCityAccessibilityLabel = "Search city"
        static let activitiesTitle = "Activities"
        static let genericErrorTitle = "Something went wrong"
        static let searchCityTitle = "Search for a city"
        static let searchCityDescription = "Use the search button to find a city."
        static let clearSky = "Clear sky"
        static let partlyCloudy = "Partly cloudy"
        static let foggy = "Foggy"
        static let drizzle = "Drizzle"
        static let rain = "Rain"
        static let snow = "Snow"
        static let thunderstorm = "Thunderstorm"
        static let unknownConditions = "Unknown conditions"

        static func forecastDays(_ days: Int) -> String {
            String(format: "Forecast: %d days", days)
        }

        static func temperatureRange(maximum: Double, minimum: Double) -> String {
            String(format: "%.0f° / %.0f°", maximum, minimum)
        }

        static func windAndUV(wind: Double, uvIndex: Double) -> String {
            String(format: "Wind %.0f · UV %.0f", wind, uvIndex)
        }

        static func precipitationAndSnow(precipitation: Double, snowfall: Double) -> String {
            String(format: "Rain %.1f mm · Snow %.1f cm", precipitation, snowfall)
        }

        static func conditionDescription(for weatherCode: Int) -> String {
            switch weatherCode {
            case 0: clearSky
            case 1...3: partlyCloudy
            case 45, 48: foggy
            case 51, 53, 55, 56, 57: drizzle
            case 61, 63, 65, 66, 67, 80, 81, 82: rain
            case 71, 73, 75, 77, 85, 86: snow
            case 95, 96, 99: thunderstorm
            default: unknownConditions
            }
        }
    }

    enum CitySearch {
        static let findCityTitle = "Find a city"
        static let minimumCharactersDescription = "Enter at least two characters to search."
        static let loading = "Searching cities…"
        static let errorTitle = "Couldn’t search cities"
        static let emptyTitle = "No cities found"
        static let emptyDescription = "Try a different search term."
        static let navigationTitle = "Search City"
        static let searchPrompt = "City name"
    }

    enum Activity {
        static let outdoorSightseeingTitle = "Outdoor Sightseeing"
        static let indoorSightseeingTitle = "Indoor Sightseeing"
        static let surfingTitle = "Surfing"
        static let skiingTitle = "Skiing"

        static let outdoorSightseeingIcon = "binoculars"
        static let indoorSightseeingIcon = "building.columns"
        static let surfingIcon = "figure.surfing"
        static let skiingIcon = "figure.skiing.downhill"

        static let idealTemperatureFormat = "Ideal temp (%d°C)"
        static let suboptimalTemperatureFormat = "Sub-optimal temp (%d°C)"
        static let extremeTemperatureFormat = "Extreme temp (%d°C)"
        static let heavyRainFormat = "Heavy rain (%.1f mm)"
        static let lightRainFormat = "Light rain (%.1f mm)"
        static let noRain = "No rain"
        static let thunderstormRisk = "Thunderstorm risk"
        static let heavyRainOutsideFormat = "Heavy rain outside (%.1f mm)"
        static let rainyOutsideFormat = "Rainy outside (%.1f mm)"
        static let thunderstormExpected = "Thunderstorm expected"
        static let uncomfortableOutdoorTemperature = "Uncomfortable outdoor temp"
        static let weatherTooNiceToStayInside = "Weather is too nice to stay inside"
        static let idealWindFormat = "Ideal wind (%d km/h)"
        static let moderateWindFormat = "Moderate wind (%d km/h)"
        static let windTooWeakFormat = "Wind too weak (%d km/h)"
        static let windTooStrongFormat = "Wind too strong (%d km/h)"
        static let thunderstormSafetyHazard = "Thunderstorm safety hazard"
        static let noSnowAndTemperatureFormat = "No snow and temp is %d°C"
        static let freshSnowFormat = "Fresh snow (%.1f cm)"
        static let freezingConditionsFormat = "Freezing conditions (%d°C)"
        static let nearFreezingFormat = "Near-freezing (%d°C)"

        static func title(for activity: ActivityType) -> String {
            switch activity {
            case .outdoorSightseeing: outdoorSightseeingTitle
            case .indoorSightseeing: indoorSightseeingTitle
            case .surfing: surfingTitle
            case .skiing: skiingTitle
            }
        }

        static func iconName(for activity: ActivityType) -> String {
            switch activity {
            case .outdoorSightseeing: outdoorSightseeingIcon
            case .indoorSightseeing: indoorSightseeingIcon
            case .surfing: surfingIcon
            case .skiing: skiingIcon
            }
        }

        static func reasonDescription(for reason: ActivityReason) -> String {
            switch reason {
            case .idealTemperature(let value): String(format: idealTemperatureFormat, value)
            case .suboptimalTemperature(let value): String(format: suboptimalTemperatureFormat, value)
            case .extremeTemperature(let value): String(format: extremeTemperatureFormat, value)
            case .heavyRain(let value): String(format: heavyRainFormat, value)
            case .lightRain(let value): String(format: lightRainFormat, value)
            case .noRain: noRain
            case .thunderstormRisk: thunderstormRisk
            case .heavyRainOutside(let value): String(format: heavyRainOutsideFormat, value)
            case .rainyOutside(let value): String(format: rainyOutsideFormat, value)
            case .thunderstormExpected: thunderstormExpected
            case .uncomfortableOutdoorTemperature: uncomfortableOutdoorTemperature
            case .weatherTooNiceToStayInside: weatherTooNiceToStayInside
            case .idealWind(let value): String(format: idealWindFormat, value)
            case .moderateWind(let value): String(format: moderateWindFormat, value)
            case .windTooWeak(let value): String(format: windTooWeakFormat, value)
            case .windTooStrong(let value): String(format: windTooStrongFormat, value)
            case .thunderstormSafetyHazard: thunderstormSafetyHazard
            case .noSnowAndTemperature(let value): String(format: noSnowAndTemperatureFormat, value)
            case .freshSnow(let value): String(format: freshSnowFormat, value)
            case .freezingConditions(let value): String(format: freezingConditionsFormat, value)
            case .nearFreezing(let value): String(format: nearFreezingFormat, value)
            }
        }

        static func scoreText(_ score: Int) -> String {
            String(format: "%d%%", score)
        }

        static func accessibilityLabel(title: String, score: Int, reason: String) -> String {
            String(format: "%@, %d percent suitable. %@", title, score, reason)
        }
    }

    enum Error {
        static let invalidCity = "Please enter a valid city name."
        static let invalidSearchQuery = "Enter at least two characters to search for a city."
        static let invalidRequest = "The request could not be processed. Please try again."
        static let network = "Unable to connect. Check your network and try again."
        static let requestTimeout = "The request timed out. Please try again."
        static let unauthorized = "The service could not authorize this request. Please try again later."
        static let forbidden = "The service is not available for this request. Please try again later."
        static let rateLimited = "Too many requests were made. Please wait a moment and try again."
        static let server = "The weather service is temporarily unavailable. Please try again later."
        static let decoding = "Received an unexpected response from the server."
        static let invalidResponse = "The server returned an invalid response. Please try again."
        static let cityNotFound = "City not found. Try a different search."
        static let noWeatherData = "No weather forecast is available for this city."
        static let invalidForecastDays = "Choose between 1 and 16 forecast days."
        static let unexpected = "Something went wrong."
        static let invalidURL = "The request URL is invalid."
        static let responseDecoding = "Failed to decode the server response."

        static func httpStatus(_ statusCode: Int) -> String {
            String(format: "Request failed with status code %d.", statusCode)
        }

        enum CitySearch {
            static let network = "Unable to search cities. Check your network and try again."
            static let requestTimeout = "City search timed out. Please try again."
            static let unauthorized = "City search could not be authorized. Please try again later."
            static let forbidden = "City search is not available right now. Please try again later."
            static let rateLimited = "Too many search requests. Please wait a moment and try again."
            static let server = "The city search service is temporarily unavailable. Please try again later."
            static let decoding = "Received an unexpected response from the city search service."
            static let invalidResponse = "The city search service returned an invalid response."
            static let invalidRequest = "The city search request could not be processed."
            static let noResults = "No cities found. Try a different search term."
            static let unexpected = "Something went wrong while searching for cities."
        }
    }

    enum Icon {
        static let search = "magnifyingglass"
        static let error = "exclamationmark.triangle"
        static let emptyLocation = "mappin.slash"
        static let region = "map"
        static let country = "globe"
        static let timezone = "clock"
        static let weather = "cloud.sun"
    }

    enum AccessibilityIdentifier {
        static let searchCityButton = "searchCityButton"
        static let forecastDaysStepper = "forecastDaysStepper"
        static let cityNameLabel = "cityNameLabel"
        static let loadingIndicator = "loadingIndicator"
        static let placeholderContent = "placeholderContent"
        static let errorContent = "errorContent"
        static let citySearchField = "citySearchField"
        static let cityRowPrefix = "cityRow_"
    }
}
