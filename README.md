# WeatherApp

A native iOS weather forecast application with activity recommendations, built with SwiftUI and Clean Architecture.

---

## a. Project Overview

WeatherApp fetches a multi-day weather forecast for any city worldwide and scores four activity types (outdoor sightseeing, indoor sightseeing, surfing, skiing) based on the conditions. Users search for a city, view a 1–16 day forecast, and see ranked activity recommendations with suitability scores.

**Core features:**
- City search with debounced input and empty/error states
- Multi-day weather forecast with pull-to-refresh
- Adjustable forecast range (1–16 days) via stepper
- Activity suitability scoring with color-coded badges
- Dark mode support with adaptive color assets

---

## b. Platform and Tooling Choices

| Choice | Detail |
|---|---|
| Platform | iOS 26.2+ (simulator: iPhone 17) |
| Language | Swift 5 |
| UI Framework | SwiftUI |
| Concurrency | async/await (primary), Combine (debounce only) |
| Architecture | Clean Architecture + MVVM |
| DI | Manual composition via `DependencyContainer` |
| Networking | `URLSession` with generic `APIRequest` protocol |
| Testing | XCTest with mock/stub pattern |
| Project format | `.xcodeproj` with file-system-synchronized groups |

**Why SwiftUI over UIKit:** The app is read-only with list-based layouts. SwiftUI's declarative model, `@Observable`, `NavigationStack`, `.refreshable`, and `.searchable` eliminate boilerplate that UIKit would require.

**Why Combine for CitySearchViewModel only:** `CitySearchViewModel` uses Combine's `debounce` to throttle search input. `WeatherViewModel` has no debounce need, so it stays pure async/await.

---

## c. Architecture and Technical Decisions

```
WeatherApp/
├── App/                    # Entry point, router, constants
├── Domain/                 # Entities, use cases, repository protocols, errors
├── Data/                   # Repository implementations, mappers, data sources
├── Infrastructure/         # Networking (API client, endpoints, DTOs)
├── Presentation/           # Views, view models, view data models
└── DI/                     # DependencyContainer (composition root)
```

**Layer responsibilities:**

| Layer | Owns | Depends on |
|---|---|---|
| Presentation | Views, ViewModels, ViewData, ErrorMessageMappers | Domain |
| Domain | Entities, UseCases, Repository protocols, Errors | Nothing |
| Data | Repository impls, RemoteDataSource, Mappers | Domain, Infrastructure |
| Infrastructure | APIClient, API endpoints, DTOs | Nothing (pure networking) |

**Key decisions:**

- **`@Observable` for WeatherViewModel, `ObservableObject` for CitySearchViewModel.** `CitySearchViewModel` uses `@Published` + Combine's `debounce`, which requires `ObservableObject`. `WeatherViewModel` has no Combine need, so it uses the lighter `@Observable`.
- **Nested state enums** (`WeatherViewModel.WeatherState`, `CitySearchViewModel.CitySearchState`) keep state modeling explicit and scoped.
- **`WeatherForecastViewData`** is a presentation-layer model. The mapper converts domain entities + activity scores into display-ready strings so views contain zero business logic.
- **`AppRouter`** is an `@Observable` navigation coordinator injected via `@Environment`. Views never push/pop directly — they call router methods.
- **`DependencyContainer`** is a static enum (not a protocol) that wires the full object graph. A single shared `APIClient` instance is reused across both feature paths.
- **RemoteDataSource layer** sits between Repository and APIService to handle error mapping (`APIError` → domain errors), keeping infrastructure concerns out of the domain.

---

## d. How to Build and Run

**Requirements:** Xcode 26+, iOS 26.2+ simulator.

```bash
# Clone the repository
git clone <https://github.com/parikshithedau/WeatherApp.git>
cd WeatherApp

# Open in Xcode
open WeatherApp.xcodeproj

# Or build from command line
xcodebuild build -scheme WeatherApp -destination 'platform=iOS Simulator,name=iPhone 17'
```

Select the `WeatherApp` scheme, choose an iPhone 17 simulator, and press Cmd+R.

No API keys required — the app uses the free Open-Meteo API.

---

## e. How to Run Tests & Testing Strategy

```bash
# Unit tests only
xcodebuild test -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WeatherAppTests

# UI tests only
xcodebuild test -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:WeatherAppUITests
```

**84 unit tests, 10 UI tests.**

**Testing strategy:**

| Layer | Approach | Files |
|---|---|---|
| Domain | Pure logic tests with no mocks needed | `ActivityScorerTests`, `GetWeatherUseCaseTests`, `SearchCitiesUseCaseTests`, `GetActivityRecommendationsUseCaseTests` |
| Data | Mock RemoteDataSource, verify mapper and repository behavior | `WeatherRepositoryTests`, `CitySearchRepositoryTests`, `CityMapperTests`, `WeatherMapperTests`, `APIErrorMapperTests`, `CitySearchAPIErrorMapperTests`, `RemoteDataSourceTests` |
| Presentation | Mock use cases/mappers, verify ViewModel state transitions | `WeatherViewModelTests`, `CitySearchViewModelTests`, `WeatherForecastViewDataMapperTests`, `ErrorMessageMapperTests`, `CityErrorMessageMapperTests`, `PresentationFormattingTests`, `WeatherStateEqualityTests` |
| Infrastructure | `URLProtocol` stub for APIClient, verify endpoint URL construction | `APIClientTests`, `APIRequestTests`, `WeatherAPIEndpointTests`, `GeocodingAPIEndpointTests` |
| UI (XCUITest) | Launch app, interact via accessibility identifiers | `WeatherViewUITests`, `CitySearchViewUITests`, `CitySelectionUITests`, `ForecastDaysUITests`, `ErrorHandlingUITests` |

**Mock pattern:** All test doubles live in `WeatherAppTests/TestHelpers/Mocks.swift`. They conform to the same protocols as production types and track call arguments for verification. No third-party mocking framework is used.

**Test file organization:** One file per test class, grouped by layer (`Presentation/`, `Domain/`, `Data/`, `Networking/`).

---

## f. API Usage Notes

The app uses two public endpoints from [Open-Meteo](https://open-meteo.com/):

**Weather forecast:**
```
GET https://api.open-meteo.com/v1/forecast
  ?latitude={lat}&longitude={lon}
  &forecast_days={1-16}
  &timezone=auto
  &daily=weather_code,temperature_2m_max,temperature_2m_min,
         precipitation_sum,snowfall_sum,wind_speed_10m_max,uv_index_max
```

**City geocoding:**
```
GET https://geocoding-api.open-meteo.com/v1/search
  ?name={query}&count=8&language=en&format=json
```

**Notes:**
- No API key required. Rate limits are generous for development use.
- The geocoding API returns results sorted by relevance. The app limits to 8 results.
- Weather codes follow the [WMO standard](https://www.dwd.de/EN/ourservices/schwarzklima/schwarzklima_node.html) (0 = clear, 95+ = thunderstorm).
- City search results without a `country` field are filtered out by `CityMapper`.

---

## g. Activity Recommendation Logic

Four activities are scored 0–100 based on daily weather, then sorted by score (descending):

**Outdoor Sightseeing** (base: 100)
- Temperature: 18–26°C ideal, 10–18 or 26–32 suboptimal (-20), outside -50
- Precipitation: 0mm ideal, 0–2mm light rain (-30), >2mm heavy rain (-70)
- Thunderstorm (code ≥95): -50

**Indoor Sightseeing** (base: 20)
- Precipitation boosts score: >10mm (+50), 2–10mm (+30)
- Thunderstorm: +30
- Extreme temp (<5°C or >32°C): +20
- If no rain and mild temp: "Weather is too nice to stay inside"

**Surfing** (base: 50)
- Wind 15–25 km/h ideal (+40), 10–15 moderate (+15), <10 weak (-40), >25 strong (-40)
- Thunderstorm: -60
- Heavy rain (>5mm): -20

**Skiing** (base: 0)
- Requires snowfall > 0 or temp ≤ 2°C, otherwise score stays 0
- Snowfall contributes up to 60 points
- Temp ≤ 0°C: +40, ≤ 3°C: +15

All scores are clamped to 0–100.

---

## h. Assumptions Made

1. **City always has a country.** `CityMapper` filters out API results with no country, so the domain `City.country` is non-optional.
2. **No offline mode.** The app requires network connectivity. No local caching or persistence.
3. **Single-city selection flow.** Selecting a city replaces the current forecast. No multi-city comparison.
4. **No user accounts or saved preferences.** Forecast days resets to 7 on each app launch.
5. **English only.** Geocoding requests use `language=en`. No localization.
6. **Free API tier is sufficient.** No rate-limit handling beyond showing a user-facing error message.
7. **Weather codes 0–99 are exhaustive.** Unknown codes display "Unknown conditions."
8. **Activity scores are deterministic.** Same weather input always produces the same scores — no randomness.

---

## i. Trade-offs and Omissions

**Trade-offs made:**
- **No local caching** — keeps the codebase simple but means every forecast requires a network call. A production app would use `URLCache` or CoreData.
- **No offline support** — the app shows an error state with no retry mechanism beyond pull-to-refresh.
- **Concrete use case types in ViewModels** — use cases are structs, not protocol-typed. This simplifies the codebase since mocking happens at the repository level. Adds a small coupling between ViewModel and use case implementation.
- **`@unchecked Sendable` on mocks and repositories** — necessary for Swift 6 concurrency compliance but bypasses compile-time sendable checking on those types.
- **`CitySearchViewModel` uses `ObservableObject`** — required for Combine's `debounce`, but means it uses `@StateObject` in SwiftUI while `WeatherViewModel` uses `@State`.

**Omissions (not implemented):**
- Unit/system tests for `AppRouter` navigation logic
- Snapshot/UI tests for dark mode variants
- Accessibility audit (VoiceOver, Dynamic Type)
- Localization / internationalization
- Logging, analytics, crash reporting
- CI/CD pipeline configuration
- App Store metadata, screenshots, privacy policy
- Push notifications for weather alerts
- Widget or Live Activity support

---

## j. Production-Readiness Notes

To ship this app, the following would be needed:

| Area | What's missing |
|---|---|
| **Networking** | Request retry with exponential backoff, `URLCache` configuration, request cancellation on deinit |
| **Caching** | Local persistence for last-viewed forecast, offline fallback |
| **Security** | API key management (if switching to a paid API), certificate pinning, entitlements review |
| **Observability** | Structured logging, network request tracing, crash reporting (e.g. Firebase Crashlytics) |
| **Accessibility** | VoiceOver labels, Dynamic Type support, Reduce Motion handling |
| **Localization** | String externalization, RTL support, locale-aware number formatting |
| **Performance** | Lazy loading for large forecast lists, image caching if weather icons are added |
| **Testing** | CI pipeline (Xcode Cloud / GitHub Actions), code coverage thresholds, snapshot tests |
| **App Store** | Privacy manifest, screenshot automation, review notes, age rating |

---

## k. Cross-Platform Delivery Notes

The app is currently iOS-only. Key considerations for extending to other Apple platforms:

| Platform | Effort | Notes |
|---|---|---|
| **iPadOS** | Low | SwiftUI adaptive layouts already work. Test with `NavigationSplitView` for side-by-side city list + forecast. |
| **macOS** | Low | Most code is platform-agnostic. Replace `NavigationStack` with macOS-appropriate navigation. `URLSession` works unchanged. |
| **watchOS** | Medium | Activity scoring logic is pure and reusable. UI would need a simplified watch-specific layout. `@Observable` is available on watchOS 10+. |
| **tvOS** | Low | Focus-based navigation would replace tap interactions. Activity scores display well on large screens. |

**Shared code:** Domain layer, Data layer, and Infrastructure layer are already platform-agnostic (no UIKit or SwiftUI dependencies). Only the Presentation layer uses SwiftUI.

---

## l. AI Usage Disclosure

AI assistance was used during development for:
- Generating initial project structure and boilerplate code
- Writing unit test cases and mock objects
- Refactoring suggestions (architecture patterns, Swift concurrency)
- README documentation drafting

**Verification:** All AI-generated code was reviewed, tested (84 unit tests + 10 UI tests passing), and refined manually. Architecture decisions were made by the developer based on established Clean Architecture principles, not blindly accepted from AI suggestions. Test coverage was verified by running the full test suite after each change.
