//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/1/20.
//

import XCTest
@testable import SlackMessageEnqueuerLib

final class EventDeserializationTests: XCTestCase {
    func testChallengeEventDeserialization() throws {
        let json = """
        { "challenge" : "echo value" }
        """
        let jsonData = json.data(using: .utf8)!
        let state = try JSONDecoder().decode(Event.self, from: jsonData)
        XCTAssertNil(state.event)
        XCTAssertEqual(state.challenge, "echo value")
    }
    func testAppMentionEventDeserialization() throws {
        let json = """
        { "event" : {
            "type": "app_mention",
            "user": "U061F7AUR",
            "text": "<@U0LAN0Z89> is it everything a river should be?",
            "ts": "1515449522.000016",
            "channel": "C0LAN2Q65",
            "event_ts": "1515449522000016"
        } }
        """
        let jsonData = json.data(using: .utf8)!
        do {
            let state = try JSONDecoder().decode(Event.self, from: jsonData)
            print(state)
        } catch {
            XCTFail("error \(error)")
        }
    }
}
