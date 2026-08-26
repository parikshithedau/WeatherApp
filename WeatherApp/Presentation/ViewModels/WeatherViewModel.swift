import Foundation

@MainActor
@Observable
final class WeatherViewModel {
    var forecast: WeatherForecastViewData?
    var forecastDays = 7
    var isLoading = false
    var errorMessage: String?

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
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let weatherForecast = try await getWeatherUseCase.execute(city: city, forecastDays: forecastDays)
            forecast = forecastViewDataMapper.map(weatherForecast)
        } catch {
            errorMessage = ErrorMessageMapper.message(for: error)
            forecast = nil
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
