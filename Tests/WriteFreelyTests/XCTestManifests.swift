import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(WriteFreelyClientCollectionTests.allTests),
        testCase(WriteFreelyClientUserTests.allTests),
    ]
}
#endif
