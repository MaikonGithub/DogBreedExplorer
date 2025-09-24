import Foundation

// MARK: - View State

enum BreedDetailState: Equatable {
    case idle
    case loading
    case loaded([BreedImage])
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var images: [BreedImage] {
        if case .loaded(let images) = self { return images }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let message) = self { return message }
        return nil
    }
}

// MARK: - BreedDetailViewModel

@MainActor
final class BreedDetailViewModel: ObservableObject {
    @Published private(set) var state: BreedDetailState = .idle
    
    private let breed: Breed
    private let repository: BreedRepositoryProtocol
    private var loadTask: Task<Void, Never>?
    
    init(breed: Breed, repository: BreedRepositoryProtocol = BreedRepository()) {
        self.breed = breed
        self.repository = repository
    }
    
    deinit {
        loadTask?.cancel()
    }
    
    var breedDisplayName: String {
        breed.displayName
    }
    
    var subBreeds: [String] {
        breed.subBreeds
    }
    
    var hasSubBreeds: Bool {
        breed.hasSubBreeds
    }
    
    var subBreedsCount: Int {
        breed.subBreedsCount
    }
    
    func loadImages() {
        guard !state.isLoading else { return }
        
        loadTask?.cancel()
        state = .loading
        
        loadTask = Task {
            do {
                let images = try await repository.fetchRandomImages(for: breed.name, count: 6)
                
                if !Task.isCancelled {
                    state = .loaded(images)
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
        loadImages()
    }
    
    func retryLoading() {
        loadImages()
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension BreedDetailViewModel {
    static var preview: BreedDetailViewModel {
        let mockRepo = MockBreedRepository()
        let breed = MockData.breeds.first!
        return BreedDetailViewModel(breed: breed, repository: mockRepo)
    }
    
    static var previewLoading: BreedDetailViewModel {
        let viewModel = BreedDetailViewModel.preview
        viewModel.state = .loading
        return viewModel
    }
    
    static var previewError: BreedDetailViewModel {
        let viewModel = BreedDetailViewModel.preview
        viewModel.state = .error("Failed to load images. Please check your internet connection and try again.")
        return viewModel
    }
    
    static var previewLoaded: BreedDetailViewModel {
        let viewModel = BreedDetailViewModel.preview
        let breed = MockData.breeds.first!
        viewModel.state = .loaded(MockData.images(for: breed.name, count: 6))
        return viewModel
    }
    
    static var previewWithSubBreeds: BreedDetailViewModel {
        let mockRepo = MockBreedRepository()
        let breed = MockData.breeds.first { $0.hasSubBreeds }!
        let viewModel = BreedDetailViewModel(breed: breed, repository: mockRepo)
        viewModel.state = .loaded(MockData.images(for: breed.name, count: 6))
        return viewModel
    }
}
#endif
