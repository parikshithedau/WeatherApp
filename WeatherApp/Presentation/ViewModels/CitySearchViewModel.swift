import Combine
import Foundation

enum CitySearchState {
    case idle
    case loading
    case results([City])
    case empty
    case failure(String)
}

@MainActor
final class CitySearchViewModel: ObservableObject {
    @Published var query = StringConstant.Common.empty
    @Published private(set) var state: CitySearchState = .idle
    private let minimumQueryLength = 2

    private let searchCitiesUseCase: SearchCitiesUseCase
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(searchCitiesUseCase: SearchCitiesUseCase) {
        self.searchCitiesUseCase = searchCitiesUseCase

        $query
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                Task { @MainActor [weak self] in
                    self?.searchCities(matching: query)
                }
            }
            .store(in: &cancellables)
    }

    private func searchCities(matching query: String) {
        searchTask?.cancel()

        guard query.count >= minimumQueryLength else {
            state = .idle
            return
        }

        searchTask = Task { [weak self] in
            guard let self else { return }
            state = .loading

            do {
                let cities = try await searchCitiesUseCase.execute(query: query)
                guard !Task.isCancelled else { return }
                state = cities.isEmpty ? .empty : .results(cities)
            } catch {
                guard !Task.isCancelled else { return }
                state = .failure(ErrorMessageMapper.message(for: error))
            }
        }
    }

    func cancelSearch() {
        searchTask?.cancel()
        searchTask = nil
    }
}
