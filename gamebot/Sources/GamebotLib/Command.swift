//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/14/19.
//

import Foundation
import SlackModels

public struct Command<T> {
    let action: T
    let remainder: String
    let user: UserId
}

public struct Input {
    enum InputType {
        case message(String)
        case button(String, value: String)
        case ignore
    }
    let type: InputType
    let user: UserId
    let team: TeamId
    let channel: ChannelId

    init(slackEvent: SlackEvent) {
        switch slackEvent.type {
        case let .command(command):
            self.type = .message(command.text)
            self.channel = command.channel
        case let .interactive(interactive):
            self.channel = interactive.channel
            guard let action = interactive.actions.first else {
                self.type = .ignore
                break
            }
            switch action.type {
            case .button:
                self.type = .button(action.actionId.id, value: action.value ?? "")
            }
        default:
            fatalError("Don't handle \(slackEvent.type) yet")
        }
        self.user = slackEvent.user
        self.team = slackEvent.team
    }

    // for test
    init(type: InputType, user: UserId) {
        self.type = type
        self.user = user
        self.team = ""
        self.channel = ""
    }
}
