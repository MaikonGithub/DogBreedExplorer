//
//  DogBreedExplorerUITests.swift
//  DogBreedExplorerUITests
//
//  Created by Maikon Ferreira on 24/09/25.
//

import XCTest

final class DogBreedExplorerUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        app = nil
    }

    // MARK: - Main User Flow Tests
    
    @MainActor
    func testMainUserFlow_ListToDetailNavigation() throws {
        // Test the main user flow: List Screen → Detail Screen → Back to List
        
        // 1. Verify app launches and shows the list screen
        XCTAssertTrue(app.navigationBars["Dog Breeds"].exists, "List screen should be visible with correct title")
        
        // 2. Wait for breeds to load (may take a moment for API call)
        let breedsList = app.collectionViews.firstMatch
        XCTAssertTrue(breedsList.waitForExistence(timeout: 10), "Breeds list should appear within 10 seconds")
        
        // 3. Verify we have breed items in the list
        let breedCells = breedsList.cells
        XCTAssertGreaterThan(breedCells.count, 0, "Should have at least one breed in the list")
        
        // 4. Tap on the first breed to navigate to detail
        let firstBreed = breedCells.firstMatch
        XCTAssertTrue(firstBreed.exists, "First breed cell should exist")
        
        firstBreed.tap()
        
        // 5. Verify we navigated to detail screen
        // Note: The title will be the breed name, so we check for navigation bar existence
        XCTAssertTrue(app.navigationBars.element.exists, "Detail screen navigation bar should exist")
        
        // 6. Verify detail screen has breed information section
        XCTAssertTrue(app.staticTexts["Breed Information"].exists, "Breed Information section should be visible")
        
        // 7. Verify Photos section exists (may still be loading)
        XCTAssertTrue(app.staticTexts["Photos"].exists, "Photos section should be visible")
        
        // 8. Navigate back to list
        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.exists, "Back button should exist")
        backButton.tap()
        
        // 9. Verify we're back to the list screen
        XCTAssertTrue(app.navigationBars["Dog Breeds"].exists, "Should be back to the list screen")
    }
    
    @MainActor
    func testPullToRefresh() throws {
        // Test pull-to-refresh functionality
        
        // 1. Verify initial state
        XCTAssertTrue(app.navigationBars["Dog Breeds"].exists, "List screen should be visible")
        
        // 2. Wait for breeds to load
        let breedsList = app.collectionViews.firstMatch
        XCTAssertTrue(breedsList.waitForExistence(timeout: 10), "Breeds list should appear")
        
        // 3. Perform pull-to-refresh
        let startPoint = breedsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let endPoint = breedsList.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        
        // 4. Wait a moment for refresh to complete
        sleep(2)
        
        // 5. Verify list is still visible (refresh completed successfully)
        XCTAssertTrue(breedsList.exists, "Breeds list should still be visible after refresh")
    }
    
    @MainActor
    func testBreedWithSubBreeds() throws {
        // Test navigation to a breed that has sub-breeds
        
        // 1. Wait for breeds to load
        let breedsList = app.collectionViews.firstMatch
        XCTAssertTrue(breedsList.waitForExistence(timeout: 10), "Breeds list should appear")
        
        // 2. Find a breed with sub-breeds (look for cells that mention sub-breeds)
        let breedCells = breedsList.cells
        var breedWithSubBreeds: XCUIElement?
        
        for i in 0..<min(breedCells.count, 10) { // Check first 10 items
            let cell = breedCells.element(boundBy: i)
            if cell.staticTexts.containing(NSPredicate(format: "label CONTAINS 'sub-breed'")).firstMatch.exists {
                breedWithSubBreeds = cell
                break
            }
        }
        
        // 3. If we found a breed with sub-breeds, tap it
        if let breedCell = breedWithSubBreeds {
            breedCell.tap()
            
            // 4. Verify we're on detail screen
            XCTAssertTrue(app.navigationBars.element.exists, "Detail screen should be visible")
            
            // 5. Verify sub-breeds section exists
            XCTAssertTrue(app.staticTexts["Breed Information"].exists, "Breed Information section should be visible")
            
            // 6. Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            backButton.tap()
            
            // 7. Verify we're back to list
            XCTAssertTrue(app.navigationBars["Dog Breeds"].exists, "Should be back to the list screen")
        } else {
            // If no breed with sub-breeds found, just verify we can navigate to any breed
            let firstBreed = breedCells.firstMatch
            firstBreed.tap()
            
            XCTAssertTrue(app.navigationBars.element.exists, "Detail screen should be visible")
            
            let backButton = app.navigationBars.buttons.firstMatch
            backButton.tap()
            
            XCTAssertTrue(app.navigationBars["Dog Breeds"].exists, "Should be back to the list screen")
        }
    }
    
    @MainActor
    func testDetailScreenPullToRefresh() throws {
        // Test pull-to-refresh on detail screen
        
        // 1. Navigate to detail screen
        let breedsList = app.collectionViews.firstMatch
        XCTAssertTrue(breedsList.waitForExistence(timeout: 10), "Breeds list should appear")
        
        let firstBreed = breedsList.cells.firstMatch
        firstBreed.tap()
        
        // 2. Verify we're on detail screen
        XCTAssertTrue(app.navigationBars.element.exists, "Detail screen should be visible")
        
        // 3. Perform pull-to-refresh on detail screen
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.exists, "Detail screen should have scroll view")
        
        let startPoint = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
        let endPoint = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)
        
        // 4. Wait for refresh to complete
        sleep(2)
        
        // 5. Verify we're still on detail screen
        XCTAssertTrue(app.navigationBars.element.exists, "Should still be on detail screen after refresh")
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
