//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/3/20.
//

import Foundation
import SlackModels

struct Parser<T> {
    let commandMap: [(String, T)]
    let buttonMap: [String:T]
    let unknownCommand: T

    private struct PartialCommand<T> {
        let action: T
        let remainder: String

        func withUser(_ user: UserId) -> Command<T> {
            Command(action: action, remainder: remainder, user: user)
        }
    }

    func getCommand(from input: Input) -> Command<T>? {
        switch input.type {
        case let .message(message):
            return lookupMessage(message).withUser(input.user)
        case let .button(button, value):
            return lookupButton(button, value: value).withUser(input.user)
        default:
            return nil
        }
    }

    private func lookupMessage(_ message: String) -> PartialCommand<T> {
        let testMessage = message.lowercased()
        guard let commandAction = commandMap.first(where: { testMessage.hasPrefix($0.0) })
            else {
                return PartialCommand(action: unknownCommand, remainder: message)
        }
        let remainder = String(message.dropFirst(commandAction.0.count + 1))
        return PartialCommand(action: commandAction.1, remainder: remainder)
    }

    private func lookupButton(_ button: String, value: String) -> PartialCommand<T> {
        guard let buttonAction = buttonMap[button] else {
            return PartialCommand(action: unknownCommand, remainder: button)
        }
        return PartialCommand(action: buttonAction, remainder: value)
    }

}

