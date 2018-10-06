import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RxSmartThrottleTests.allTests),
    ]
}
#endif