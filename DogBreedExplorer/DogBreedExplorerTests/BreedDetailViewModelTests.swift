import XCTest
@testable import DogBreedExplorer

@MainActor
final class BreedDetailViewModelTests: TestHelpers {
    
    // MARK: - Properties
    
    var viewModel: BreedDetailViewModel!
    var mockRepository: MockBreedRepository!
    var testBreed: Breed!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockRepository = MockBreedRepository()
        testBreed = Breed(name: "labrador", subBreeds: ["retriever"])
        viewModel = BreedDetailViewModel(breed: testBreed, repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        testBreed = nil
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(viewModel.breedDisplayName, "Labrador")
        XCTAssertEqual(viewModel.subBreeds, ["retriever"])
        XCTAssertTrue(viewModel.hasSubBreeds)
        XCTAssertEqual(viewModel.subBreedsCount, 1)
    }
    
    func testBreedWithoutSubBreeds() {
        // Given
        let breedWithoutSubBreeds = Breed(name: "beagle", subBreeds: [])
        let viewModel = BreedDetailViewModel(breed: breedWithoutSubBreeds, repository: mockRepository)
        
        // Then
        XCTAssertEqual(viewModel.subBreeds, [])
        XCTAssertFalse(viewModel.hasSubBreeds)
        XCTAssertEqual(viewModel.subBreedsCount, 0)
    }
    
    func testLoadImagesSuccess() async {
        // Given
        let expectedImages = MockData.images(for: testBreed.name, count: 6)
        mockRepository.images = expectedImages
        mockRepository.shouldFail = false
        
        // When
        viewModel.loadImages()
        
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
        XCTAssertEqual(viewModel.state, .loaded(expectedImages))
    }
    
    func testLoadImagesFailure() async {
        // Given
        mockRepository.shouldFail = true
        
        // When
        viewModel.loadImages()
        
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
        let expectedImages = MockData.images(for: testBreed.name, count: 6)
        mockRepository.images = expectedImages
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
        XCTAssertEqual(viewModel.state, .loaded(expectedImages))
    }
    
    func testRetryLoading() async {
        // Given
        mockRepository.shouldFail = true
        viewModel.loadImages()
        
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
        let expectedImages = MockData.images(for: testBreed.name, count: 6)
        mockRepository.images = expectedImages
        
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
        XCTAssertEqual(viewModel.state, .loaded(expectedImages))
    }
    
    func testDoesNotLoadWhenAlreadyLoading() async {
        // Given
        mockRepository.shouldFail = false
        
        // When - Call loadImages twice quickly
        viewModel.loadImages()
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        
        let initialCallCount = mockRepository.fetchImagesCallCount
        viewModel.loadImages() // This should be ignored
        
        // Then
        XCTAssertEqual(mockRepository.fetchImagesCallCount, initialCallCount,
                      "loadImages should be ignored when already loading")
    }
    
    func testTaskCancellation() async {
        // Given
        mockRepository.shouldFail = false
        
        // When - Start loading and then immediately start another load
        viewModel.loadImages()
        await waitForCondition(
            condition: { self.viewModel.state.isLoading },
            timeout: TestConstants.shortTimeout,
            description: "Loading state"
        )
        
        // Start another load (should cancel previous task)
        viewModel.loadImages()
        
        // Wait for completion
        await waitForCondition(
            condition: { !self.viewModel.state.isLoading },
            timeout: TestConstants.defaultTimeout,
            description: "State change from loading"
        )
        
        // Then - Should complete successfully (no crash from cancellation)
        XCTAssertTrue(viewModel.state.isLoading == false, "Should not be loading after completion")
    }
    
    // MARK: - Helper Methods
    
    private func stateMatches(_ state1: BreedDetailState, _ state2: BreedDetailState) -> Bool {
        switch (state1, state2) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.loaded(let images1), .loaded(let images2)):
            return images1 == images2
        case (.error(let msg1), .error(let msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}

// MARK: - Enhanced Mock Repository

extension MockBreedRepository {
    private static var _fetchImagesCallCount = 0
    
    var fetchImagesCallCount: Int {
        get { Self._fetchImagesCallCount }
        set { Self._fetchImagesCallCount = newValue }
    }
    
    func fetchRandomImages(for breed: String, count: Int) async throws -> [BreedImage] {
        Self._fetchImagesCallCount += 1
        return try await originalFetchRandomImages(for: breed, count: count)
    }
    
    private func originalFetchRandomImages(for breed: String, count: Int) async throws -> [BreedImage] {
        if shouldFail {
            throw NetworkError.unknown(NSError(domain: "Mock", code: -1))
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds for tests
        
        return images.isEmpty ? MockData.images(for: breed, count: count) : images
    }
}

