struct City: Equatable, Identifiable, Sendable {

    let id: Int
    let name: String
    let region: String?
    let country: String
    let timeZone: String?
    let latitude: Double
    let longitude: Double

}
