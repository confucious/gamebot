//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/26/19.
//

import XCTest
import Codenames

final class StateSerializationTests: XCTestCase {
    func testGameStateSerialization() throws {
        let state = GameState()
        let jsonData = try JSONEncoder().encode(state)
        let json = String(data: jsonData, encoding: .utf8)!
        let expected = """
{"words":[],"state":{"state":"setup"},"clues":[],"players":[]}
"""
        XCTAssertEqual(json, expected)
    }

    func testGameStateDeserialization() throws {
        let json = """
{"words":[],"state":{"state":"setup"},"clues":[],"players":[]}
"""
        let jsonData = json.data(using: .utf8)!
        let state = try JSONDecoder().decode(GameState.self, from: jsonData)
        XCTAssertEqual(state.state, .setup)
    }
}
