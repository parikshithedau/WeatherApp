import SwiftUI

struct AppRootView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            WeatherView(viewModel: DependencyContainer.makeWeatherViewModel())
                .navigationDestination(for: AppRouter.Route.self) { route in
                    switch route {
                    case .citySearch:
                        CitySearchView(viewModel: DependencyContainer.makeCitySearchViewModel())
                    }
                }
        }
        .environment(router)
    }
}
