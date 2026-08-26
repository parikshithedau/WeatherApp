import Foundation

enum GeocodingAPIEndpoint {
    struct SearchCities: APIRequest {
        typealias Response = CitySearchResponseDTO

        let query: String
        let limit: Int

        var baseURL: String { APIConstants.geocodingBaseURL }
        var path: String { APIConstants.geocodingSearchPath }
        var queryItems: [URLQueryItem]? {
            [
                URLQueryItem(name: APIConstants.cityNameParameter, value: query),
                URLQueryItem(name: APIConstants.cityCountParameter, value: String(limit)),
                URLQueryItem(name: APIConstants.languageParameter, value: APIConstants.englishLanguage),
                URLQueryItem(name: APIConstants.formatParameter, value: APIConstants.jsonFormat)
            ]
        }
    }
}
