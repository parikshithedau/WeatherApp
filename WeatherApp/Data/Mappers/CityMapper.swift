import Foundation

enum CityMapper {
    static func toDomain(_ dto: CitySearchResultDTO) -> City? {
        guard let country = dto.country, !country.isEmpty else {
            return nil
        }

        return City(
            id: dto.id,
            name: dto.name,
            region: dto.admin1,
            country: country,
            timeZone: dto.timezone,
            latitude: dto.latitude,
            longitude: dto.longitude
        )
    }

    static func toDomain(_ dtos: [CitySearchResultDTO]) -> [City] {
        dtos.compactMap { toDomain($0) }
    }
}
