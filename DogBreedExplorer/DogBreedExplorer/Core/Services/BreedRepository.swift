import Foundation

// MARK: - Repository Protocol

protocol BreedRepositoryProtocol {
    func fetchBreeds() async throws -> [Breed]
    func fetchRandomImages(for breed: String, count: Int) async throws -> [BreedImage]
}

// MARK: - Repository Implementation

final class BreedRepository: BreedRepositoryProtocol {
    private let networkService: NetworkServicing
    
    init(networkService: NetworkServicing = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchBreeds() async throws -> [Breed] {
        let response: BreedsListResponse = try await networkService.request(.allBreeds)
        return response.toBreeds()
    }
    
    func fetchRandomImages(for breed: String, count: Int = 3) async throws -> [BreedImage] {
        // Handle breed with spaces by replacing with hyphens for API
        let apiBreedName = breed.replacingOccurrences(of: " ", with: "-").lowercased()
        
        do {
            // Try to fetch multiple images first
            let response: BreedImagesResponse = try await networkService.request(
                .randomBreedImages(breed: apiBreedName, count: count)
            )
            return response.toBreedImages(for: breed)
        } catch {
            // If multiple images fail, try single image
            do {
                let response: BreedImageResponse = try await networkService.request(
                    .randomBreedImage(breed: apiBreedName)
                )
                if let image = response.toBreedImage(for: breed) {
                    return [image]
                }
                return []
            } catch {
                // Re-throw the original error
                throw error
            }
        }
    }
}

// MARK: - Mock Repository for Testing

final class MockBreedRepository: BreedRepositoryProtocol {
    var shouldFail = false
    var breeds: [Breed] = []
    var images: [BreedImage] = []
    
    func fetchBreeds() async throws -> [Breed] {
        if shouldFail {
            throw NetworkError.unknown(NSError(domain: "Mock", code: -1))
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return breeds.isEmpty ? MockData.breeds : breeds
    }
    
    func fetchRandomImages(for breed: String, count: Int) async throws -> [BreedImage] {
        if shouldFail {
            throw NetworkError.unknown(NSError(domain: "Mock", code: -1))
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return images.isEmpty ? MockData.images(for: breed, count: count) : images
    }
}

// MARK: - Mock Data

struct MockData {
    static let breeds: [Breed] = [
        Breed(name: "labrador", subBreeds: ["retriever"]),
        Breed(name: "german", subBreeds: ["shepherd"]),
        Breed(name: "bulldog", subBreeds: ["boston", "english", "french"]),
        Breed(name: "poodle", subBreeds: ["medium", "miniature", "standard", "toy"]),
        Breed(name: "beagle", subBreeds: []),
        Breed(name: "boxer", subBreeds: []),
        Breed(name: "husky", subBreeds: [])
    ]
    
    static func images(for breed: String, count: Int = 3) -> [BreedImage] {
        let sampleUrls = [
            "https://images.dog.ceo/breeds/labrador/n02099712_1.jpg",
            "https://images.dog.ceo/breeds/labrador/n02099712_2.jpg",
            "https://images.dog.ceo/breeds/labrador/n02099712_3.jpg",
            "https://images.dog.ceo/breeds/labrador/n02099712_4.jpg",
            "https://images.dog.ceo/breeds/labrador/n02099712_5.jpg"
        ]
        
        return Array(sampleUrls.prefix(count)).map { url in
            BreedImage(url: url, breedName: breed)
        }
    }
}
