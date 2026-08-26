import Combine
import Foundation

@MainActor
final class CitySearchViewModel: ObservableObject {
    @Published var query = StringConstant.Common.empty
    @Published private(set) var state: CitySearchState = .idle
    private let minimumQueryLength = 2
    private let debounceInterval: RunLoop.SchedulerTimeType.Stride

    private let searchCitiesUseCase: SearchCitiesUseCase
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        searchCitiesUseCase: SearchCitiesUseCase,
        debounceInterval: RunLoop.SchedulerTimeType.Stride = .milliseconds(300)
    ) {
        self.searchCitiesUseCase = searchCitiesUseCase
        self.debounceInterval = debounceInterval

        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: debounceInterval, scheduler: RunLoop.main)
            .sink { [weak self] query in
                Task { @MainActor [weak self] in
                    self?.startSearch(matching: query)
                }
            }
            .store(in: &cancellables)
    }

    private func startSearch(matching query: String) {
        searchTask?.cancel()

        searchTask = Task { [weak self] in
            await self?.searchCities(matching: query)
        }
    }

    func searchCities(matching query: String) async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.count >= minimumQueryLength else {
            state = .idle
            return
        }

        state = .loading

        do {
            let cities = try await searchCitiesUseCase.execute(query: trimmedQuery)
            guard !Task.isCancelled else { return }
            state = cities.isEmpty ? .empty : .results(cities)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failure(CityErrorMessageMapper.message(for: error))
        }
    }

    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}

extension CitySearchViewModel {
    enum CitySearchState: Equatable {
        case idle
        case loading
        case results([City])
        case empty
        case failure(String)
    }
}
