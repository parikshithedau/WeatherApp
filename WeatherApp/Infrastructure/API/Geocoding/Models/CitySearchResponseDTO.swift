import Foundation

/// Transport models returned by the city-search API.
/// They are mapped to the Domain `City` entity in the Data layer.
nonisolated struct CitySearchResponseDTO: Decodable, Sendable {
    let results: [CitySearchResultDTO]?
}

nonisolated struct CitySearchResultDTO: Decodable, Sendable {
    let id: Int
    let name: String
    let latitude: Double
    let longitude: Double
    let elevation: Double?
    let featureCode: String?
    let countryCode: String?
    let admin1ID: Int?
    let admin3ID: Int?
    let admin4ID: Int?
    let timezone: String?
    let population: Int?
    let postcodes: [String]?
    let countryID: Int?
    let country: String?
    let admin1: String?
    let admin3: String?
    let admin4: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case latitude
        case longitude
        case elevation
        case featureCode = "feature_code"
        case countryCode = "country_code"
        case admin1ID = "admin1_id"
        case admin3ID = "admin3_id"
        case admin4ID = "admin4_id"
        case timezone
        case population
        case postcodes
        case countryID = "country_id"
        case country
        case admin1
        case admin3
        case admin4
    }

    init(
        id: Int,
        name: String,
        latitude: Double,
        longitude: Double,
        country: String?,
        admin1: String?,
        timezone: String?,
        elevation: Double? = nil,
        featureCode: String? = nil,
        countryCode: String? = nil,
        admin1ID: Int? = nil,
        admin3ID: Int? = nil,
        admin4ID: Int? = nil,
        population: Int? = nil,
        postcodes: [String]? = nil,
        countryID: Int? = nil,
        admin3: String? = nil,
        admin4: String? = nil
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.featureCode = featureCode
        self.countryCode = countryCode
        self.admin1ID = admin1ID
        self.admin3ID = admin3ID
        self.admin4ID = admin4ID
        self.timezone = timezone
        self.population = population
        self.postcodes = postcodes
        self.countryID = countryID
        self.country = country
        self.admin1 = admin1
        self.admin3 = admin3
        self.admin4 = admin4
    }
}
