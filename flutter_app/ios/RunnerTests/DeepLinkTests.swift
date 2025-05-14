import XCTest
@testable import Runner

class DeepLinkTests: XCTestCase {
    
    func testDeepLinkHandling() {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for app to be ready
        sleep(2)
        
        // Test deep link
        let url = URL(string: "payviya://reset-password?token=zBG-mlgDTz5fmksbZMZE3vs8J0lzRqhSzEA0teqkf6k")!
        XCTAssertTrue(app.open(url))
        
        // Wait for navigation
        sleep(2)
        
        // Verify we're on the reset password screen
        // Add verification logic here based on your UI
    }
} 