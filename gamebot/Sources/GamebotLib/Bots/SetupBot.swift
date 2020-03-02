//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/3/20.
//

import Foundation
import Codenames

class SetupBot {
    enum Action {
        case setupGame
        case tearDownGame
        case unknownCommand
    }

    let parser = Parser<Action>(
        commandMap: [
            ("shutdown game", .tearDownGame),
            ("setup game", .setupGame),
        ],
        buttonMap: [:],
        unknownCommand: .unknownCommand)

    func process(command: Command<Action>, gameState: ChannelState.GameState) -> ProcessResult {
        switch command.action {
        case .setupGame:
            switch gameState {
            case .none:
                switch command.remainder.lowercased() {
                case "codenames":
                    return ProcessResult(
                        gameState: .codenames(Codenames.GameState()),
                        responses: [.ephemeralMessage("Initialized codenames.", recipient: command.user)])
                case "test":
                    return ProcessResult(
                        gameState: .test,
                        responses: [.ephemeralMessage("Initialized test.", recipient: command.user)])
                default:
                    return ProcessResult(
                        gameState: .none,
                        responses: [.ephemeralMessage("Unknown game. Available: `codenames`", recipient: command.user)])
                }
            default:
                return ProcessResult(
                    gameState: gameState,
                    responses: [.ephemeralMessage("A game is already in progress. `shutdown game` to setup a new one.", recipient: command.user)])
            }
        case .tearDownGame:
            switch gameState {
            case .none:
                return ProcessResult(
                    gameState: gameState,
                    responses: [.ephemeralMessage("There is no game active.", recipient: command.user)])
            case .test:
                return ProcessResult(
                    gameState: .none, responses: [.ephemeralMessage("Test shutdown.", recipient: command.user)])
            case .codenames:
                if command.remainder.lowercased() == "codenames" {
                    return ProcessResult(
                        gameState: .none,
                        responses: [.ephemeralMessage("Game shutdown.", recipient: command.user)])
                } else {
                    return ProcessResult(
                        gameState: gameState,
                        responses: [.ephemeralMessage("Use `shutdown game codenames` to confirm.", recipient: command.user)])
                }
            }
        case .unknownCommand:
            return ProcessResult(gameState: .none, responses: [])
        }
    }
}

