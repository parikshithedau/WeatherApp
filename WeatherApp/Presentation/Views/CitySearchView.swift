import SwiftUI

struct CitySearchView: View {
    @Environment(AppRouter.self) private var router
    @FocusState private var isSearchFieldFocused: Bool
    @StateObject private var viewModel: CitySearchViewModel

    init(viewModel: CitySearchViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            switch viewModel.state {
            case .idle:
                ContentUnavailableView(
                    StringConstant.CitySearch.findCityTitle,
                    systemImage: StringConstant.Icon.search,
                    description: Text(StringConstant.CitySearch.minimumCharactersDescription)
                )
                .listRowBackground(Color.clear)

            case .loading:
                HStack {
                    Spacer()
                    ProgressView(StringConstant.CitySearch.loading)
                    Spacer()
                }
                .listRowBackground(Color.clear)

            case .failure(let errorMessage):
                ContentUnavailableView(
                    StringConstant.CitySearch.errorTitle,
                    systemImage: StringConstant.Icon.error,
                    description: Text(errorMessage)
                )
                .listRowBackground(Color.clear)

            case .empty:
                ContentUnavailableView(
                    StringConstant.CitySearch.emptyTitle,
                    systemImage: StringConstant.Icon.emptyLocation,
                    description: Text(StringConstant.CitySearch.emptyDescription)
                )
                .listRowBackground(Color.clear)

            case .results(let cities):
                ForEach(cities) { city in
                    Button {
                        router.selectCity(city)
                    } label: {
                        CityRow(city: city)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("\(StringConstant.AccessibilityIdentifier.cityRowPrefix)\(city.id)")
                }
            }
        }
        .navigationTitle(StringConstant.CitySearch.navigationTitle)
        .searchable(text: $viewModel.query, prompt: StringConstant.CitySearch.searchPrompt)
        .searchFocused($isSearchFieldFocused)
        .task {
            isSearchFieldFocused = true
        }
        .onDisappear {
            viewModel.cancelSearch()
        }
    }
}

private struct CityRow: View {
    let city: City

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(city.name)
                .font(.headline)
                .foregroundStyle(.primary)

            if let region = city.region, !region.isEmpty {
                Label(region, systemImage: StringConstant.Icon.region)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Label(city.country, systemImage: StringConstant.Icon.country)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Label(StringConstant.City.timezoneDisplayName(city.timeZone), systemImage: StringConstant.Icon.timezone)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CitySearchView(viewModel: DependencyContainer.makeCitySearchViewModel())
        .environment(AppRouter())
}
