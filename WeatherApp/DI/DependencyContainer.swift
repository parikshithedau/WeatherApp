import Foundation

enum DependencyContainer {

    static func makeWeatherViewModel() -> WeatherViewModel {
        let apiClient = APIClient()
        let weatherAPIService = WeatherAPIService(apiClient: apiClient)
        let weatherRemoteDataSource = WeatherRemoteDataSource(weatherAPIService: weatherAPIService)
        let weatherRepository = WeatherRepository(remoteDataSource: weatherRemoteDataSource)
        let getWeatherUseCase = GetWeatherUseCase(repository: weatherRepository)
        let getActivityRecommendationsUseCase = GetActivityRecommendationsUseCase(
            activityScorer: ActivityScorer()
        )
        let forecastViewDataMapper = WeatherForecastViewDataMapper(
            getActivityRecommendationsUseCase: getActivityRecommendationsUseCase
        )
        return WeatherViewModel(
            getWeatherUseCase: getWeatherUseCase,
            forecastViewDataMapper: forecastViewDataMapper
        )
    }

    static func makeCitySearchViewModel() -> CitySearchViewModel {
        let apiClient = APIClient()
        let geocodingAPIService = GeocodingAPIService(apiClient: apiClient)
        let remoteDataSource = CitySearchRemoteDataSource(geocodingAPIService: geocodingAPIService)
        let repository = CitySearchRepository(remoteDataSource: remoteDataSource)
        let useCase = SearchCitiesUseCase(repository: repository)
        return CitySearchViewModel(searchCitiesUseCase: useCase)
    }
}
