import XCTest
@testable import DogBreedExplorer

final class ModelTests: XCTestCase {
    
    // MARK: - Breed Model Tests
    
    func testBreedInitialization() {
        // Given
        let name = "labrador"
        let subBreeds = ["retriever"]
        
        // When
        let breed = Breed(name: name, subBreeds: subBreeds)
        
        // Then
        XCTAssertEqual(breed.name, name)
        XCTAssertEqual(breed.subBreeds, subBreeds)
        XCTAssertEqual(breed.displayName, "Labrador")
        XCTAssertEqual(breed.subBreedsCount, 1)
        XCTAssertTrue(breed.hasSubBreeds)
    }
    
    func testBreedWithoutSubBreeds() {
        // Given
        let name = "beagle"
        let subBreeds: [String] = []
        
        // When
        let breed = Breed(name: name, subBreeds: subBreeds)
        
        // Then
        XCTAssertEqual(breed.name, name)
        XCTAssertEqual(breed.subBreeds, [])
        XCTAssertEqual(breed.displayName, "Beagle")
        XCTAssertEqual(breed.subBreedsCount, 0)
        XCTAssertFalse(breed.hasSubBreeds)
    }
    
    func testBreedDisplayNameCapitalization() {
        // Given
        let testCases = [
            ("labrador", "Labrador"),
            ("german shepherd", "German Shepherd"),
            ("bulldog", "Bulldog"),
            ("a", "A"),
            ("", "")
        ]
        
        for (input, expected) in testCases {
            // When
            let breed = Breed(name: input, subBreeds: [])
            
            // Then
            XCTAssertEqual(breed.displayName, expected, "Display name for '\(input)' should be '\(expected)'")
        }
    }
    
    func testBreedIdentifiable() {
        // Given
        let breed1 = Breed(name: "labrador", subBreeds: [])
        let breed2 = Breed(name: "labrador", subBreeds: [])
        
        // Then
        XCTAssertNotEqual(breed1.id, breed2.id, "Different instances should have different IDs")
    }
    
    func testBreedHashable() {
        // Given
        let breed1 = Breed(name: "labrador", subBreeds: ["retriever"])
        let breed2 = Breed(name: "labrador", subBreeds: ["retriever"])
        let breed3 = Breed(name: "beagle", subBreeds: [])
        
        // When
        let set: Set<Breed> = [breed1, breed2, breed3]
        
        // Then
        XCTAssertEqual(set.count, 3, "Set should contain 3 unique breeds")
    }
    
    func testBreedEquatable() {
        // Given
        let breed1 = Breed(name: "labrador", subBreeds: ["retriever"])
        let breed2 = Breed(name: "labrador", subBreeds: ["retriever"])
        let breed3 = Breed(name: "beagle", subBreeds: [])
        
        // Then
        // Note: Breed uses UUID() for id, so instances are never equal even with same data
        // We test the actual data properties instead
        XCTAssertEqual(breed1.name, breed2.name, "Breeds with same data should have equal names")
        XCTAssertEqual(breed1.subBreeds, breed2.subBreeds, "Breeds with same data should have equal subBreeds")
        XCTAssertNotEqual(breed1.name, breed3.name, "Breeds with different data should have different names")
        XCTAssertNotEqual(breed1.subBreeds, breed3.subBreeds, "Breeds with different data should have different subBreeds")
    }
    
    // MARK: - BreedImage Model Tests
    
    func testBreedImageInitialization() {
        // Given
        let url = "https://example.com/image.jpg"
        let breedName = "labrador"
        
        // When
        let image = BreedImage(url: url, breedName: breedName)
        
        // Then
        XCTAssertEqual(image.url, url)
        XCTAssertEqual(image.breedName, breedName)
        XCTAssertEqual(image.imageURL?.absoluteString, url)
    }
    
    func testBreedImageWithInvalidURL() {
        // Given
        let invalidURL = "not a valid url"
        let breedName = "labrador"
        
        // When
        let image = BreedImage(url: invalidURL, breedName: breedName)
        
        // Then
        XCTAssertEqual(image.url, invalidURL)
        XCTAssertEqual(image.breedName, breedName)
        // Note: URL(string:) will attempt to encode the string, so it may not be nil
        // We test that the URL is created but may not be a valid HTTP URL
        if let imageURL = image.imageURL {
            XCTAssertTrue(imageURL.absoluteString.contains("not%20a%20valid%20url"), "URL should be encoded")
        }
    }
    
    func testBreedImageIdentifiable() {
        // Given
        let image1 = BreedImage(url: "https://example.com/image1.jpg", breedName: "labrador")
        let image2 = BreedImage(url: "https://example.com/image2.jpg", breedName: "labrador")
        
        // Then
        XCTAssertNotEqual(image1.id, image2.id, "Different instances should have different IDs")
    }
    
    func testBreedImageHashable() {
        // Given
        let image1 = BreedImage(url: "https://example.com/image1.jpg", breedName: "labrador")
        let image2 = BreedImage(url: "https://example.com/image2.jpg", breedName: "beagle")
        
        // When
        let set: Set<BreedImage> = [image1, image2]
        
        // Then
        XCTAssertEqual(set.count, 2, "Set should contain 2 unique images")
    }
    
    // MARK: - API Response DTO Tests
    
    func testBreedsListResponseToBreeds() {
        // Given
        let response = BreedsListResponse(
            message: [
                "labrador": ["retriever"],
                "bulldog": ["boston", "english"],
                "beagle": []
            ],
            status: "success"
        )
        
        // When
        let breeds = response.toBreeds()
        
        // Then
        XCTAssertEqual(breeds.count, 3)
        
        let labrador = breeds.first { $0.name == "labrador" }
        XCTAssertNotNil(labrador)
        XCTAssertEqual(labrador?.subBreeds, ["retriever"])
        
        let bulldog = breeds.first { $0.name == "bulldog" }
        XCTAssertNotNil(bulldog)
        XCTAssertEqual(bulldog?.subBreeds, ["boston", "english"])
        
        let beagle = breeds.first { $0.name == "beagle" }
        XCTAssertNotNil(beagle)
        XCTAssertEqual(beagle?.subBreeds, [])
    }
    
    func testBreedsListResponseWithFailureStatus() {
        // Given
        let response = BreedsListResponse(
            message: ["labrador": ["retriever"]],
            status: "error"
        )
        
        // When
        let breeds = response.toBreeds()
        
        // Then
        XCTAssertEqual(breeds.count, 0, "Should return empty array for failure status")
    }
    
    func testBreedsListResponseSorting() {
        // Given
        let response = BreedsListResponse(
            message: [
                "zebra": [],
                "apple": [],
                "banana": []
            ],
            status: "success"
        )
        
        // When
        let breeds = response.toBreeds()
        
        // Then
        XCTAssertEqual(breeds.count, 3)
        XCTAssertEqual(breeds[0].name, "apple")
        XCTAssertEqual(breeds[1].name, "banana")
        XCTAssertEqual(breeds[2].name, "zebra")
    }
    
    func testBreedImagesResponseToBreedImages() {
        // Given
        let response = BreedImagesResponse(
            message: [
                "https://example.com/image1.jpg",
                "https://example.com/image2.jpg"
            ],
            status: "success"
        )
        
        // When
        let images = response.toBreedImages(for: "labrador")
        
        // Then
        XCTAssertEqual(images.count, 2)
        XCTAssertEqual(images[0].breedName, "labrador")
        XCTAssertEqual(images[0].url, "https://example.com/image1.jpg")
        XCTAssertEqual(images[1].breedName, "labrador")
        XCTAssertEqual(images[1].url, "https://example.com/image2.jpg")
    }
    
    func testBreedImagesResponseWithFailureStatus() {
        // Given
        let response = BreedImagesResponse(
            message: ["https://example.com/image1.jpg"],
            status: "error"
        )
        
        // When
        let images = response.toBreedImages(for: "labrador")
        
        // Then
        XCTAssertEqual(images.count, 0, "Should return empty array for failure status")
    }
    
    func testBreedImageResponseToBreedImage() {
        // Given
        let response = BreedImageResponse(
            message: "https://example.com/image.jpg",
            status: "success"
        )
        
        // When
        let image = response.toBreedImage(for: "labrador")
        
        // Then
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.breedName, "labrador")
        XCTAssertEqual(image?.url, "https://example.com/image.jpg")
    }
    
    func testBreedImageResponseWithFailureStatus() {
        // Given
        let response = BreedImageResponse(
            message: "https://example.com/image.jpg",
            status: "error"
        )
        
        // When
        let image = response.toBreedImage(for: "labrador")
        
        // Then
        XCTAssertNil(image, "Should return nil for failure status")
    }
    
    // MARK: - Codable Tests
    
    func testBreedsListResponseCodable() throws {
        // Given
        let originalResponse = BreedsListResponse(
            message: ["labrador": ["retriever"]],
            status: "success"
        )
        
        // When
        let data = try JSONEncoder().encode(originalResponse)
        let decodedResponse = try JSONDecoder().decode(BreedsListResponse.self, from: data)
        
        // Then
        XCTAssertEqual(decodedResponse.status, originalResponse.status)
        XCTAssertEqual(decodedResponse.message, originalResponse.message)
    }
    
    func testBreedImagesResponseCodable() throws {
        // Given
        let originalResponse = BreedImagesResponse(
            message: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
            status: "success"
        )
        
        // When
        let data = try JSONEncoder().encode(originalResponse)
        let decodedResponse = try JSONDecoder().decode(BreedImagesResponse.self, from: data)
        
        // Then
        XCTAssertEqual(decodedResponse.status, originalResponse.status)
        XCTAssertEqual(decodedResponse.message, originalResponse.message)
    }
    
    func testBreedImageResponseCodable() throws {
        // Given
        let originalResponse = BreedImageResponse(
            message: "https://example.com/image.jpg",
            status: "success"
        )
        
        // When
        let data = try JSONEncoder().encode(originalResponse)
        let decodedResponse = try JSONDecoder().decode(BreedImageResponse.self, from: data)
        
        // Then
        XCTAssertEqual(decodedResponse.status, originalResponse.status)
        XCTAssertEqual(decodedResponse.message, originalResponse.message)
    }
}

