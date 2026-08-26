import Foundation

enum GeocodingAPIEndpoint {
    struct SearchCities: APIRequest {
        typealias Response = CitySearchResponseDTO

        let query: String
        let limit: Int

        var baseURL: String { StringConstant.API.geocodingBaseURL }
        var path: String { StringConstant.API.geocodingSearchPath }
        var queryItems: [URLQueryItem]? {
            [
                URLQueryItem(name: StringConstant.API.cityNameParameter, value: query),
                URLQueryItem(name: StringConstant.API.cityCountParameter, value: String(limit)),
                URLQueryItem(name: StringConstant.API.languageParameter, value: StringConstant.API.englishLanguage),
                URLQueryItem(name: StringConstant.API.formatParameter, value: StringConstant.API.jsonFormat)
            ]
        }
    }
}
