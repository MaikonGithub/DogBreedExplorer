import Foundation

// MARK: - View State

enum BreedListState: Equatable {
    case idle
    case loading
    case loaded([Breed])
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var breeds: [Breed] {
        if case .loaded(let breeds) = self { return breeds }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

// MARK: - BreedListViewModel

@MainActor
final class BreedListViewModel: ObservableObject {
    @Published private(set) var state: BreedListState = .idle
    
    private let repository: BreedRepositoryProtocol
    private var loadTask: Task<Void, Never>?
    
    init(repository: BreedRepositoryProtocol = BreedRepository()) {
        self.repository = repository
        loadBreeds()
    }
    
    deinit {
        loadTask?.cancel()
    }
    
    func loadBreeds() {
        guard !state.isLoading else { return }
        
        loadTask?.cancel()
        state = .loading
        
        loadTask = Task {
            do {
                let breeds = try await repository.fetchBreeds()
                
                if !Task.isCancelled {
                    state = .loaded(breeds)
                }
            } catch {
                if !Task.isCancelled {
                    let errorMessage = (error as? NetworkError)?.errorDescription ?? error.localizedDescription
                    state = .error(errorMessage)
                }
            }
        }
    }
    
    func refresh() {
        loadBreeds()
    }
    
    func retryLoading() {
        loadBreeds()
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension BreedListViewModel {
    static var preview: BreedListViewModel {
        let mockRepo = MockBreedRepository()
        return BreedListViewModel(repository: mockRepo)
    }
    
    static var previewLoading: BreedListViewModel {
        let viewModel = BreedListViewModel.preview
        viewModel.state = .loading
        return viewModel
    }
    
    static var previewError: BreedListViewModel {
        let viewModel = BreedListViewModel.preview
        viewModel.state = .error("Failed to load breeds. Please check your internet connection and try again.")
        return viewModel
    }
    
    static var previewLoaded: BreedListViewModel {
        let viewModel = BreedListViewModel.preview
        viewModel.state = .loaded(MockData.breeds)
        return viewModel
    }
}
#endif
