//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/29/19.
//

import Foundation
import XCTest
@testable import GamebotLib

struct TestObject: Codable {
    let intValue: Int
    let stringValue: String
}

final class DynamoDbIntegrationTests: XCTestCase {
    let reallyRun = false

    func testSetGet() throws {
        guard reallyRun else { return }
        let setObject = TestObject(intValue: 99, stringValue: "SomeValue")
        try Cache.set(setObject, into: "test")
        let getObject: TestObject? = try Cache.get(from: "test")
        XCTAssertEqual(getObject?.intValue, 99)
        XCTAssertEqual(getObject?.stringValue, "SomeValue")
    }
}
