//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/3/20.
//

import Foundation

class NoneBot {
    enum Action {
        case help
        case showStatus
        case unknownCommand
    }

    let parser = Parser<Action>(
        commandMap: [
            ("status", .showStatus),
            ("s", .showStatus),
            ("help", .help),
            ("h", .help),
        ],
        buttonMap: [:],
        unknownCommand: .unknownCommand)

    func process(command: Command<Action>) -> ProcessResult {
        let responses: [ResponseAction]
        switch command.action {
        case .help:
            responses = [.ephemeralMessage("setup game <game name>", recipient: command.user)]
        case .showStatus:
            responses = [.ephemeralMessage("No game setup for this channel. Use `setup game` to begin.", recipient: command.user)]
        case .unknownCommand:
            responses = [.ephemeralMessage("Unknown command `\(command.remainder)`. `help` to see available commands.", recipient: command.user)]
        }
        return ProcessResult(gameState: .none, responses: responses)
    }
}
