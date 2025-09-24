import XCTest
@testable import DogBreedExplorer

@MainActor
final class DogBreedExplorerTests: TestHelpers {
    
    // MARK: - Properties
    
    var viewModel: BreedListViewModel!
    var mockRepository: MockBreedRepository!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockBreedRepository()
        viewModel = BreedListViewModel(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInitialState() {
        // The viewModel calls loadBreeds() in init, so state will be loading initially
        // We need to check that it's in loading state
        XCTAssertTrue(viewModel.state.isLoading, "ViewModel should be in loading state initially due to init call")
    }
    
    func testLoadBreedsSuccess() async {
        // Given
        let expectedBreeds = MockData.breeds
        mockRepository.breeds = expectedBreeds
        mockRepository.shouldFail = false
        
        // When
        viewModel.loadBreeds()
        
        // Wait for async operation
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        await waitForCondition(
            condition: { !self.viewModel.state.isLoading },
            timeout: TestConstants.defaultTimeout,
            description: "State change from loading"
        )
        
        // Then
        XCTAssertEqual(viewModel.state, .loaded(expectedBreeds))
    }
    
    func testLoadBreedsFailure() async {
        // Given
        mockRepository.shouldFail = true
        
        // When
        viewModel.loadBreeds()
        
        // Wait for async operation
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        await waitForCondition(
            condition: { !self.viewModel.state.isLoading },
            timeout: TestConstants.defaultTimeout,
            description: "State change from loading"
        )
        
        // Then
        if case .error(let message) = viewModel.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected error state")
        }
    }
    
    func testRefresh() async {
        // Given
        let expectedBreeds = MockData.breeds
        mockRepository.breeds = expectedBreeds
        mockRepository.shouldFail = false
        
        // When
        viewModel.refresh()
        
        // Wait for async operation
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        await waitForCondition(
            condition: { !self.viewModel.state.isLoading },
            timeout: TestConstants.defaultTimeout,
            description: "State change from loading"
        )
        
        // Then
        XCTAssertEqual(viewModel.state, .loaded(expectedBreeds))
    }
    
    func testRetryLoading() async {
        // Given
        mockRepository.shouldFail = true
        viewModel.loadBreeds()
        
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        await waitForCondition(
            condition: { !self.viewModel.state.isLoading },
            timeout: TestConstants.defaultTimeout,
            description: "State change from loading"
        )
        
        // Verify error state first
        guard case .error(_) = viewModel.state else {
            XCTFail("Expected error state before retry")
            return
        }
        
        // Now set up for success
        mockRepository.shouldFail = false
        let expectedBreeds = MockData.breeds
        mockRepository.breeds = expectedBreeds
        
        // When
        viewModel.retryLoading()
        
        // Wait for async operation
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        await waitForCondition(
            condition: { !self.viewModel.state.isLoading },
            timeout: TestConstants.defaultTimeout,
            description: "State change from loading"
        )
        
        // Then
        XCTAssertEqual(viewModel.state, .loaded(expectedBreeds))
    }
    
    func testDoesNotLoadWhenAlreadyLoading() async {
        // Given
        mockRepository.shouldFail = false
        
        // When - Call loadBreeds twice quickly
        viewModel.loadBreeds()
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        
        let initialCallCount = mockRepository.fetchBreedsCallCount
        viewModel.loadBreeds() // This should be ignored
        
        // Then
        XCTAssertEqual(mockRepository.fetchBreedsCallCount, initialCallCount,
                      "loadBreeds should be ignored when already loading")
    }
    
    // MARK: - Helper Methods
    
    private func stateMatches(_ state1: BreedListState, _ state2: BreedListState) -> Bool {
        switch (state1, state2) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.loaded(let breeds1), .loaded(let breeds2)):
            return breeds1 == breeds2
        case (.error(let msg1), .error(let msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}

// MARK: - Enhanced Mock Repository

extension MockBreedRepository {
    private static var _fetchBreedsCallCount = 0
    
    var fetchBreedsCallCount: Int {
        get { Self._fetchBreedsCallCount }
        set { Self._fetchBreedsCallCount = newValue }
    }
    
    func fetchBreeds() async throws -> [Breed] {
        Self._fetchBreedsCallCount += 1
        return try await originalFetchBreeds()
    }
    
    private func originalFetchBreeds() async throws -> [Breed] {
        if shouldFail {
            throw NetworkError.unknown(NSError(domain: "Mock", code: -1))
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds for tests
        
        return breeds.isEmpty ? MockData.breeds : breeds
    }
}
