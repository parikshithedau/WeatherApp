import XCTest
@testable import WeatherApp

@MainActor
final class CityMapperTests: XCTestCase {
    func testToDomainMapsEveryDisplayAndLocationFieldForValidCity() {
        let dto = TestFixtures.cityDTO()

        let city = CityMapper.toDomain(dto)

        XCTAssertEqual(city, TestFixtures.city)
    }

    func testToDomainRejectsCityWithoutCountry() {
        XCTAssertNil(CityMapper.toDomain(TestFixtures.cityDTO(country: nil)))
        XCTAssertNil(CityMapper.toDomain(TestFixtures.cityDTO(country: "")))
    }

    func testToDomainCollectionDropsInvalidCitiesAndPreservesOrder() {
        let paris = TestFixtures.cityDTO(id: 2, name: "Paris", country: "France", admin1: nil)
        let cities = CityMapper.toDomain([TestFixtures.cityDTO(country: nil), paris])

        XCTAssertEqual(cities.map(\.id), [2])
        XCTAssertEqual(cities.map(\.name), ["Paris"])
        XCTAssertEqual(cities.first?.region, nil)
    }
}
