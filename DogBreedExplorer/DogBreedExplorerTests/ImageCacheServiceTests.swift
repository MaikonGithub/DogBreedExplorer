import XCTest
@testable import DogBreedExplorer
import UIKit

@MainActor
final class ImageCacheServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var cacheService: ImageCacheService!
    let testImageURL = "https://example.com/test-image.jpg"
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        cacheService = ImageCacheService.shared
        cacheService.clearCache() // Start with clean cache
    }
    
    override func tearDown() {
        cacheService.clearCache()
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testImageNotInCacheInitially() {
        // When
        let cachedImage = cacheService.image(for: testImageURL)
        
        // Then
        XCTAssertNil(cachedImage, "Image should not be in cache initially")
    }
    
    func testSetAndRetrieveImage() {
        // Given
        let testImage = createTestImage()
        
        // When
        cacheService.setImage(testImage, for: testImageURL)
        let retrievedImage = cacheService.image(for: testImageURL)
        
        // Then
        XCTAssertNotNil(retrievedImage, "Image should be retrievable from cache")
        XCTAssertEqual(retrievedImage?.size, testImage.size)
    }
    
    func testRemoveImage() {
        // Given
        let testImage = createTestImage()
        cacheService.setImage(testImage, for: testImageURL)
        
        // Verify image is cached
        XCTAssertNotNil(cacheService.image(for: testImageURL))
        
        // When
        cacheService.removeImage(for: testImageURL)
        
        // Then
        XCTAssertNil(cacheService.image(for: testImageURL), "Image should be removed from cache")
    }
    
    func testClearCache() {
        // Given
        let testImage1 = createTestImage()
        let testImage2 = createTestImage()
        
        cacheService.setImage(testImage1, for: "url1")
        cacheService.setImage(testImage2, for: "url2")
        
        // Verify images are cached
        XCTAssertNotNil(cacheService.image(for: "url1"))
        XCTAssertNotNil(cacheService.image(for: "url2"))
        
        // When
        cacheService.clearCache()
        
        // Then
        XCTAssertNil(cacheService.image(for: "url1"), "All images should be removed from cache")
        XCTAssertNil(cacheService.image(for: "url2"), "All images should be removed from cache")
    }
    
    func testCacheWithDifferentURLs() {
        // Given
        let testImage1 = createTestImage()
        let testImage2 = createTestImage()
        let url1 = "https://example.com/image1.jpg"
        let url2 = "https://example.com/image2.jpg"
        
        // When
        cacheService.setImage(testImage1, for: url1)
        cacheService.setImage(testImage2, for: url2)
        
        // Then
        let retrievedImage1 = cacheService.image(for: url1)
        let retrievedImage2 = cacheService.image(for: url2)
        
        XCTAssertNotNil(retrievedImage1, "First image should be retrievable")
        XCTAssertNotNil(retrievedImage2, "Second image should be retrievable")
        XCTAssertNotEqual(retrievedImage1, retrievedImage2, "Different URLs should return different images")
    }
    
    func testOverwriteImageWithSameURL() {
        // Given
        let originalImage = createTestImage()
        let newImage = createTestImage()
        
        cacheService.setImage(originalImage, for: testImageURL)
        
        // When
        cacheService.setImage(newImage, for: testImageURL)
        
        // Then
        let retrievedImage = cacheService.image(for: testImageURL)
        XCTAssertNotNil(retrievedImage, "Image should still be retrievable after overwrite")
        XCTAssertEqual(retrievedImage, newImage, "Should return the new image, not the original")
    }
    
    func testCacheSingleton() {
        // Given & When
        let instance1 = ImageCacheService.shared
        let instance2 = ImageCacheService.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2, "ImageCacheService should be a singleton")
    }
    
    func testCacheWithEmptyURL() {
        // Given
        let testImage = createTestImage()
        let emptyURL = ""
        
        // When
        cacheService.setImage(testImage, for: emptyURL)
        let retrievedImage = cacheService.image(for: emptyURL)
        
        // Then
        XCTAssertNotNil(retrievedImage, "Should be able to cache with empty URL")
    }
    
    func testCacheWithSpecialCharactersInURL() {
        // Given
        let testImage = createTestImage()
        let specialURL = "https://example.com/image with spaces & symbols!.jpg"
        
        // When
        cacheService.setImage(testImage, for: specialURL)
        let retrievedImage = cacheService.image(for: specialURL)
        
        // Then
        XCTAssertNotNil(retrievedImage, "Should be able to cache with special characters in URL")
    }
    
    func testConcurrentCacheAccess() async {
        // Given
        let testImage = createTestImage()
        let urlPrefix = "https://example.com/image"
        
        // When - Simulate concurrent access
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    let url = "\(urlPrefix)\(i).jpg"
                    await MainActor.run {
                        self.cacheService.setImage(testImage, for: url)
                    }
                }
            }
            
            for i in 0..<10 {
                group.addTask {
                    let url = "\(urlPrefix)\(i).jpg"
                    await MainActor.run {
                        _ = self.cacheService.image(for: url)
                    }
                }
            }
        }
        
        // Then - Verify all images are accessible
        for i in 0..<10 {
            let url = "\(urlPrefix)\(i).jpg"
            XCTAssertNotNil(cacheService.image(for: url), "Image \(i) should be accessible after concurrent access")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
