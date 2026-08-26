import Foundation

@MainActor
@Observable
final class WeatherViewModel {
    private(set) var state: WeatherState = .idle
    var forecastDays = 7

    private let getWeatherUseCase: GetWeatherUseCase
    private let forecastViewDataMapper: any WeatherForecastViewDataMapping
    private var selectedCity: City?

    init(
        getWeatherUseCase: GetWeatherUseCase,
        forecastViewDataMapper: any WeatherForecastViewDataMapping
    ) {
        self.getWeatherUseCase = getWeatherUseCase
        self.forecastViewDataMapper = forecastViewDataMapper
    }

    func selectCity(_ city: City) async {
        selectedCity = city
        await loadWeather(for: city)
    }

    func refreshForecast() async {
        guard let selectedCity else { return }
        await loadWeather(for: selectedCity)
    }

    private func loadWeather(for city: City) async {
        state = .loading

        do {
            let weatherForecast = try await getWeatherUseCase.execute(city: city, forecastDays: forecastDays)
            state = .loaded(forecastViewDataMapper.map(weatherForecast))
        } catch {
            state = .error(ErrorMessageMapper.message(for: error))
        }
    }

    var selectedCityDisplayName: String {
        guard let selectedCity else { return StringConstant.Common.empty }
        return StringConstant.City.displayName(
            name: selectedCity.name,
            region: selectedCity.region,
            country: selectedCity.country
        )
    }
}

extension WeatherViewModel {

    enum WeatherState: Equatable {
        case idle
        case loading
        case loaded(WeatherForecastViewData)
        case error(String)
    }
}
