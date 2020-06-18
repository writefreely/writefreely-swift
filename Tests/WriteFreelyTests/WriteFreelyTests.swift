import XCTest
@testable import WriteFreely

final class WriteFreelyTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(WriteFreely().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
