import XCTest

import FlutterCoreTests
import STBTests

var tests = [XCTestCaseEntry]()

tests += FlutterCoreTests.allTests()
tests += STBTests.allTests()

XCTMain(tests)
