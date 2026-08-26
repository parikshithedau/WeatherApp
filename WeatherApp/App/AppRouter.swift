import Foundation

@MainActor
@Observable
final class AppRouter {
    enum Route: Hashable {
        case citySearch
    }

    var path: [Route] = []
    var selectedCity: City?

    func showCitySearch() {
        path.append(.citySearch)
    }

    func selectCity(_ city: City) {
        selectedCity = city

        if path.last == .citySearch {
            path.removeLast()
        }
    }
}
