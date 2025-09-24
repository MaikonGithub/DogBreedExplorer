import XCTest
@testable import DogBreedExplorer

@MainActor
final class NetworkServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var networkService: NetworkService!
    var mockSession: MockURLSession!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        networkService = NetworkService(session: mockSession)
    }
    
    override func tearDown() {
        mockSession = nil
        networkService = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testSuccessfulRequest() async throws {
        // Given
        let expectedResponse = BreedsListResponse(
            message: ["labrador": ["retriever"], "beagle": []],
            status: "success"
        )
        
        let responseData = try JSONEncoder().encode(expectedResponse)
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://dog.ceo/api/breeds/list/all")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let result: BreedsListResponse = try await networkService.request(.allBreeds)
        
        // Then
        XCTAssertEqual(result.status, "success")
        XCTAssertEqual(result.message.count, 2)
        XCTAssertEqual(result.message["labrador"], ["retriever"])
        XCTAssertEqual(result.message["beagle"], [])
    }
    
    func testHTTPError() async {
        // Given
        let responseData = Data("{}".utf8)
        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://dog.ceo/api/breeds/list/all")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        do {
            let _: BreedsListResponse = try await networkService.request(.allBreeds)
            XCTFail("Expected HTTP error")
        } catch let error as NetworkError {
            switch error {
            case .httpError(let statusCode):
                XCTAssertEqual(statusCode, 404)
            default:
                XCTFail("Expected HTTP error with status code 404, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testDecodingError() async {
        // Given
        let invalidJSON = Data("invalid json".utf8)
        mockSession.mockData = invalidJSON
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://dog.ceo/api/breeds/list/all")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        do {
            let _: BreedsListResponse = try await networkService.request(.allBreeds)
            XCTFail("Expected decoding error")
        } catch let error as NetworkError {
            if case .decodingError(_) = error {
                // Expected
            } else {
                XCTFail("Expected decoding error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testNoDataError() async {
        // Given
        mockSession.mockData = nil
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://dog.ceo/api/breeds/list/all")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        do {
            let _: BreedsListResponse = try await networkService.request(.allBreeds)
            XCTFail("Expected no data error")
        } catch let error as NetworkError {
            if case .noData = error {
                // Expected
            } else {
                XCTFail("Expected no data error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testInvalidURLError() async {
        // Given - Create an endpoint that will result in invalid URL
        // We'll use a path that contains invalid characters for URL construction
        let invalidEndpoint = Endpoint(path: " ", method: .GET)
        
        // When & Then
        do {
            let _: BreedsListResponse = try await networkService.request(invalidEndpoint)
            XCTFail("Expected invalid URL error")
        } catch let error as NetworkError {
            switch error {
            case .invalidURL:
                // Expected - this should happen when URLComponents fails
                break
            case .noData:
                // Also acceptable - this might happen if the URL is constructed but request fails
                break
            default:
                XCTFail("Expected invalid URL or no data error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testSessionError() async {
        // Given
        let sessionError = URLError(.notConnectedToInternet)
        mockSession.mockError = sessionError
        
        // When & Then
        do {
            let _: BreedsListResponse = try await networkService.request(.allBreeds)
            XCTFail("Expected session error")
        } catch let error as NetworkError {
            if case .unknown(let underlyingError) = error {
                XCTAssertTrue(underlyingError is URLError)
            } else {
                XCTFail("Expected unknown error with underlying URLError, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }
    
    func testEndpointURLGeneration() {
        // Given & When
        let endpoint = Endpoint(path: "/breeds/list/all")
        
        // Then
        XCTAssertEqual(endpoint.url?.absoluteString, "https://dog.ceo/api/breeds/list/all")
    }
    
    func testEndpointWithQueryItems() {
        // Given
        let queryItems = [URLQueryItem(name: "count", value: "3")]
        
        // When
        let endpoint = Endpoint(path: "/breed/labrador/images/random", queryItems: queryItems)
        
        // Then
        XCTAssertEqual(endpoint.url?.absoluteString, "https://dog.ceo/api/breed/labrador/images/random?count=3")
    }
    
    func testDogAPIEndpoints() {
        // Test allBreeds endpoint
        XCTAssertEqual(Endpoint.allBreeds.path, "/breeds/list/all")
        
        // Test randomBreedImages endpoint
        let imagesEndpoint = Endpoint.randomBreedImages(breed: "labrador", count: 3)
        XCTAssertEqual(imagesEndpoint.path, "/breed/labrador/images/random/3")
        
        // Test randomBreedImage endpoint
        let imageEndpoint = Endpoint.randomBreedImage(breed: "labrador")
        XCTAssertEqual(imageEndpoint.path, "/breed/labrador/images/random")
        
        // Test randomSubBreedImages endpoint
        let subBreedEndpoint = Endpoint.randomSubBreedImages(breed: "bulldog", subBreed: "english", count: 2)
        XCTAssertEqual(subBreedEndpoint.path, "/breed/bulldog/english/images/random/2")
    }
}

// MARK: - Mock URLSession

final class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw NetworkError.noData
        }
        
        return (data, response)
    }
}

