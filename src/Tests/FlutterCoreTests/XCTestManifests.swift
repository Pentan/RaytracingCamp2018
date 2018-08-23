import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RandomTests.allTests),
        testCase(AABBTests.allTests),
        testCase(MeshTests.allTests),
    ]
}
#endif
