import SwiftUI

struct WeatherView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel: WeatherViewModel

    init(viewModel: WeatherViewModel = DependencyContainer.makeWeatherViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 24) {
            citySearchField

            forecastDaysPicker

            if viewModel.isLoading {
                ProgressView(StringConstant.Weather.loading)
            } else if let forecast = viewModel.forecast {
                ScrollView {
                    weatherContent(forecast)
                }
            } else if let error = viewModel.errorMessage {
                errorContent(error)
            } else {
                placeholderContent
            }

            Spacer()
        }
        .padding()
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

    private func weatherContent(_ forecast: WeatherForecastViewData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(forecast.cityName)
                .font(.largeTitle.bold())

            Text(forecast.timeZone)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(forecast.days) { day in
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

                if day.id != forecast.days.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
