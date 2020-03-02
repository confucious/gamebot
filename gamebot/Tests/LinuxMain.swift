import XCTest
import Quick

import gamebotTests
@testable import CodenamesTests

var tests = [XCTestCaseEntry]()
tests += gamebotTests.allTests()
XCTMain(tests)

QCKMain([
    GameStateTests.self
])
