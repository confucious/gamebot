//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/1/20.
//

import Foundation

import XCTest
@testable import SlackMessageEnqueuerLib

final class SQSIntegrationTests: XCTestCase {
    let reallyRun = false

    func testEnqueue() throws {
        guard reallyRun else { return }

        let json = """
        { "event" : {
            "type": "app_mention",
            "user": "U061F7AUR",
            "text": "<@U0LAN0Z89> is it everything a river should be?",
            "ts": "1515449522.000016",
            "channel": "C0LAN2Q65",
            "event_ts": "1515449522000016"
          },
          "team_id" : "asdf"
        }
        """
        let jsonData = json.data(using: .utf8)!
        let state = try JSONDecoder().decode(Event.self, from: jsonData)
        let sync = try queueEvent(state.event!, team: state.team_id!).wait()
        XCTAssertNil(sync.challenge)
    }
}
