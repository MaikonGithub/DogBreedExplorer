import XCTest
@testable import DogBreedExplorer

@MainActor
final class BreedRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    
    var repository: BreedRepository!
    var mockNetworkService: MockNetworkService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        repository = BreedRepository(networkService: mockNetworkService)
    }
    
    override func tearDown() {
        mockNetworkService = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testFetchBreedsSuccess() async throws {
        // Given
        let expectedResponse = BreedsListResponse(
            message: [
                "labrador": ["retriever"],
                "bulldog": ["boston", "english", "french"],
                "beagle": []
            ],
            status: "success"
        )
        mockNetworkService.mockResponse = expectedResponse
        
        // When
        let breeds = try await repository.fetchBreeds()
        
        // Then
        XCTAssertEqual(breeds.count, 3)
        
        let labrador = breeds.first { $0.name == "labrador" }
        XCTAssertNotNil(labrador)
        XCTAssertEqual(labrador?.subBreeds, ["retriever"])
        XCTAssertTrue(labrador?.hasSubBreeds == true)
        
        let bulldog = breeds.first { $0.name == "bulldog" }
        XCTAssertNotNil(bulldog)
        XCTAssertEqual(bulldog?.subBreeds, ["boston", "english", "french"])
        XCTAssertEqual(bulldog?.subBreedsCount, 3)
        
        let beagle = breeds.first { $0.name == "beagle" }
        XCTAssertNotNil(beagle)
        XCTAssertEqual(beagle?.subBreeds, [])
        XCTAssertFalse(beagle?.hasSubBreeds == true)
    }
    
    func testFetchBreedsFailure() async {
        // Given
        let networkError = NetworkError.httpError(statusCode: 500)
        mockNetworkService.mockError = networkError
        
        // When & Then
        do {
            let _ = try await repository.fetchBreeds()
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testFetchRandomImagesSuccess() async throws {
        // Given
        let expectedResponse = BreedImagesResponse(
            message: [
                "https://images.dog.ceo/breeds/labrador/n02099712_1.jpg",
                "https://images.dog.ceo/breeds/labrador/n02099712_2.jpg",
                "https://images.dog.ceo/breeds/labrador/n02099712_3.jpg"
            ],
            status: "success"
        )
        mockNetworkService.mockResponse = expectedResponse
        
        // When
        let images = try await repository.fetchRandomImages(for: "labrador", count: 3)
        
        // Then
        XCTAssertEqual(images.count, 3)
        XCTAssertEqual(images[0].breedName, "labrador")
        XCTAssertEqual(images[0].url, "https://images.dog.ceo/breeds/labrador/n02099712_1.jpg")
        XCTAssertEqual(images[1].breedName, "labrador")
        XCTAssertEqual(images[2].breedName, "labrador")
    }
    
    func testFetchRandomImagesWithSpacesInBreedName() async throws {
        // Given
        let expectedResponse = BreedImagesResponse(
            message: ["https://images.dog.ceo/breeds/german-shepherd/n02099712_1.jpg"],
            status: "success"
        )
        mockNetworkService.mockResponse = expectedResponse
        
        // When
        let images = try await repository.fetchRandomImages(for: "German Shepherd", count: 1)
        
        // Then
        XCTAssertEqual(images.count, 1)
        XCTAssertEqual(images[0].breedName, "German Shepherd")
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/breed/german-shepherd/images/random/1")
    }
    
    func testFetchRandomImagesFallbackToSingleImage() async throws {
        // Given - Test the fallback mechanism by making the first call fail
        // and the second call succeed
        let singleImageResponse = BreedImageResponse(
            message: "https://images.dog.ceo/breeds/labrador/n02099712_1.jpg",
            status: "success"
        )
        
        // Set up mock to fail first call (multiple images), succeed second call (single image)
        mockNetworkService.mockResponses = [
            (error: NetworkError.httpError(statusCode: 404), response: nil),
            (error: nil, response: singleImageResponse)
        ]
        
        // When
        let images = try await repository.fetchRandomImages(for: "labrador", count: 3)
        
        // Then
        XCTAssertEqual(images.count, 1, "Should get 1 image from fallback")
        XCTAssertEqual(images[0].breedName, "labrador")
        XCTAssertEqual(images[0].url, "https://images.dog.ceo/breeds/labrador/n02099712_1.jpg")
        
        // Verify both endpoints were called
        XCTAssertEqual(mockNetworkService.callCount, 2, "Should make 2 network calls")
    }
    
    func testFetchRandomImagesBothFail() async {
        // Given
        let networkError = NetworkError.httpError(statusCode: 500)
        mockNetworkService.mockError = networkError
        
        // When & Then
        do {
            let _ = try await repository.fetchRandomImages(for: "labrador", count: 3)
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testFetchRandomImagesWithEmptyResponse() async throws {
        // Given
        let emptyResponse = BreedImagesResponse(message: [], status: "success")
        mockNetworkService.mockResponse = emptyResponse
        
        // When
        let images = try await repository.fetchRandomImages(for: "labrador", count: 3)
        
        // Then
        XCTAssertEqual(images.count, 0)
    }
    
    func testFetchRandomImagesWithFailureStatus() async throws {
        // Given
        let failureResponse = BreedImagesResponse(message: [], status: "error")
        mockNetworkService.mockResponse = failureResponse
        
        // When
        let images = try await repository.fetchRandomImages(for: "labrador", count: 3)
        
        // Then
        XCTAssertEqual(images.count, 0)
    }
    
    func testDefaultImageCount() async throws {
        // Given
        let expectedResponse = BreedImagesResponse(
            message: ["https://images.dog.ceo/breeds/labrador/n02099712_1.jpg"],
            status: "success"
        )
        mockNetworkService.mockResponse = expectedResponse
        
        // When
        let images = try await repository.fetchRandomImages(for: "labrador")
        
        // Then
        XCTAssertEqual(images.count, 1)
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/breed/labrador/images/random/3")
    }
    
    func testBreedsAreSorted() async throws {
        // Given
        let unsortedResponse = BreedsListResponse(
            message: [
                "zebra": [],
                "apple": ["red", "green"],
                "banana": []
            ],
            status: "success"
        )
        mockNetworkService.mockResponse = unsortedResponse
        
        // When
        let breeds = try await repository.fetchBreeds()
        
        // Then
        XCTAssertEqual(breeds.count, 3)
        XCTAssertEqual(breeds[0].name, "apple")
        XCTAssertEqual(breeds[1].name, "banana")
        XCTAssertEqual(breeds[2].name, "zebra")
    }
    
    func testRepositoryProtocolConformance() {
        // Given
        let protocolRepository: BreedRepositoryProtocol = repository
        
        // Then
        XCTAssertTrue(protocolRepository is BreedRepository, "Repository should conform to protocol")
    }
}

// MARK: - Mock Network Service

final class MockNetworkService: NetworkServicing {
    var mockResponse: Any?
    var mockError: Error?
    var mockResponses: [(error: Error?, response: Any?)] = []
    var callCount = 0
    var lastEndpoint: Endpoint?
    
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        callCount += 1
        lastEndpoint = endpoint
        
        // Use mockResponses if available, otherwise fall back to single mockResponse/mockError
        if !mockResponses.isEmpty {
            let callIndex = callCount - 1
            if callIndex < mockResponses.count {
                let mock = mockResponses[callIndex]
                if let error = mock.error {
                    throw error
                }
                guard let response = mock.response as? T else {
                    throw NetworkError.noData
                }
                return response
            }
        }
        
        // Fallback to single response/error
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse as? T else {
            throw NetworkError.noData
        }
        
        return response
    }
}

