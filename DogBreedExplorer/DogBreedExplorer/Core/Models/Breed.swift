import Foundation

// MARK: - Domain Models

/// Domain model representing a dog breed
struct Breed: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let subBreeds: [String]
    
    var displayName: String {
        name.capitalized
    }
    
    var subBreedsCount: Int {
        subBreeds.count
    }
    
    var hasSubBreeds: Bool {
        !subBreeds.isEmpty
    }
}

/// Domain model representing a breed image
struct BreedImage: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let breedName: String
    
    var imageURL: URL? {
        URL(string: url)
    }
}

// MARK: - API Response DTOs

/// DTO for the breeds list API response
struct BreedsListResponse: Codable {
    let message: [String: [String]]
    let status: String
}

/// DTO for random breed images API response
struct BreedImagesResponse: Codable {
    let message: [String]
    let status: String
}

/// DTO for single breed image API response
struct BreedImageResponse: Codable {
    let message: String
    let status: String
}

// MARK: - Mapping Extensions

extension BreedsListResponse {
    /// Converts API response to domain models
    func toBreeds() -> [Breed] {
        message.compactMap { (breedName, subBreeds) in
            guard status == "success" else { return nil }
            return Breed(
                name: breedName,
                subBreeds: subBreeds
            )
        }
        .sorted { $0.name < $1.name }
    }
}

extension BreedImagesResponse {
    /// Converts API response to domain models
    func toBreedImages(for breedName: String) -> [BreedImage] {
        guard status == "success" else { return [] }
        return message.map { url in
            BreedImage(url: url, breedName: breedName)
        }
    }
}

extension BreedImageResponse {
    /// Converts API response to domain model
    func toBreedImage(for breedName: String) -> BreedImage? {
        guard status == "success" else { return nil }
        return BreedImage(url: message, breedName: breedName)
    }
}
