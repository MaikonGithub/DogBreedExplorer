import XCTest
import Foundation

// MARK: - Test Helpers Base Class

@MainActor
class TestHelpers: XCTestCase {
    
    // MARK: - Generic Wait Methods
    
    func waitForCondition(
        condition: @escaping () -> Bool,
        timeout: TimeInterval = 2.0,
        description: String = "Condition not met"
    ) async {
        let startTime = Date()
        
        while !condition() {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timeout waiting for condition: \(description)")
                return
            }
            
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    func waitForStateChange<T: Equatable>(
        from currentState: T,
        getState: @escaping () -> T,
        timeout: TimeInterval = 2.0,
        description: String = "State change"
    ) async {
        let startTime = Date()
        
        while getState() == currentState {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timeout waiting for state to change from \(currentState): \(description)")
                return
            }
            
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
    
    func waitForState<T: Equatable>(
        _ expectedState: T,
        getState: @escaping () -> T,
        timeout: TimeInterval = 1.0,
        description: String = "Expected state"
    ) async {
        let startTime = Date()
        
        while getState() != expectedState {
            if Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timeout waiting for state \(expectedState): \(description)")
                return
            }
            
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }
}

// MARK: - Test Constants

enum TestConstants {
    static let defaultTimeout: TimeInterval = 2.0
    static let shortTimeout: TimeInterval = 1.0
    static let longTimeout: TimeInterval = 5.0
    static let sleepInterval: UInt64 = 10_000_000 // 10ms
}
