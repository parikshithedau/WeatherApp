import SwiftUI

struct WeatherView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: WeatherViewModel

    init(viewModel: WeatherViewModel = DependencyContainer.makeWeatherViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                citySearchField
                forecastDaysPicker
            }
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)

            switch viewModel.state {
            case .idle:
                Section {
                    placeholderContent
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            case .loading:
                Section {
                    ProgressView(StringConstant.Weather.loading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

            case .loaded(let forecast):
                Section {
                    Text(forecast.cityName)
                        .font(.largeTitle.bold())
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                ForEach(forecast.days) { day in
                    Section {
                        dayContent(day)
                    }
                    .listRowBackground(Color.clear)
                }

            case .error(let message):
                Section {
                    errorContent(message)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.refreshForecast()
        }
        .navigationTitle(StringConstant.Weather.title)
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: router.selectedCity) { _, city in
            guard let city else { return }
            Task { await viewModel.selectCity(city) }
        }
    }

    private var citySearchField: some View {
        ZStack(alignment: .trailing) {
            TextField(StringConstant.Weather.searchCityPlaceholder, text: .constant(viewModel.selectedCityDisplayName))
                .textFieldStyle(.roundedBorder)
                .allowsHitTesting(false)

            Button {
                router.showCitySearch()
            } label: {
                Color.clear
                    .contentShape(Rectangle())
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .buttonStyle(.plain)
            .accessibilityLabel(StringConstant.Weather.searchCityAccessibilityLabel)

            Image(systemName: StringConstant.Icon.search)
                .foregroundStyle(.secondary)
                .padding(.trailing, 12)
                .allowsHitTesting(false)
        }
    }

    private var forecastDaysPicker: some View {
        Stepper(
            StringConstant.Weather.forecastDays(viewModel.forecastDays),
            value: $viewModel.forecastDays,
            in: 1...16
        )
            .onChange(of: viewModel.forecastDays) { _, _ in
                Task { await viewModel.refreshForecast() }
            }
    }

    private func dayContent(_ day: WeatherDayViewData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(day.date)
                        .font(.headline)
                    Text(day.conditionDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(day.temperatureSummary)
                        .font(.headline)
                    Text(day.windAndUVSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(day.precipitationAndSnowSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            activityRecommendations(day.activityRecommendations)
        }
        .padding(.vertical, 8)
    }

    private func activityRecommendations(_ recommendations: [ActivityRecommendationViewData]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(StringConstant.Weather.activitiesTitle)
                .font(.subheadline.weight(.semibold))

            ForEach(recommendations) { recommendation in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: recommendation.iconName)
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .frame(width: 24)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(recommendation.title)
                            .font(.subheadline.weight(.medium))
                        Text(recommendation.reason)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(recommendation.scoreText)
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(recommendation.scoreTone.color.opacity(0.15), in: Capsule())
                        .foregroundStyle(recommendation.scoreTone.color)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(recommendation.accessibilityLabel)
            }
        }
    }

    private func errorContent(_ message: String) -> some View {
        ContentUnavailableView {
            Label(StringConstant.Weather.genericErrorTitle, systemImage: StringConstant.Icon.error)
        } description: {
            Text(message)
        }
    }

    private var placeholderContent: some View {
        ContentUnavailableView {
            Label(StringConstant.Weather.searchCityTitle, systemImage: StringConstant.Icon.weather)
        } description: {
            Text(StringConstant.Weather.searchCityDescription)
        }
    }
}

#Preview {
    WeatherView()
}
