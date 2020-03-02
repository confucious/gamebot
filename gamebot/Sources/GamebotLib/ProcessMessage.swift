//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/3/20.
//

import Foundation
import SlackModels
import Codenames

func process(_ event: SlackEvent, with gameState: ChannelState.GameState) -> ProcessResult {
    return Process().process(event, with: gameState)
}

struct ProcessResult {
    let gameState: ChannelState.GameState
    let responses: [ResponseAction]
}

private class Process {
    func process(_ event: SlackEvent, with gameState: ChannelState.GameState) -> ProcessResult {
        let input = Input(slackEvent: event)

        let setupBot = SetupBot()
        if let command = setupBot.parser.getCommand(from: input),
            command.action != .unknownCommand {
            return setupBot.process(command: command, gameState: gameState)
        }

        switch gameState {
        case .none:
            return processNone(input: input)
        case .test:
            return processTest(input: input)
        case .codenames(let gameState):
            return processCodenames(input: input, gameState: gameState)
        }
    }

    func processNone(input: Input) -> ProcessResult {
        let bot = NoneBot()
        guard let command = bot.parser.getCommand(from: input) else {
            return ProcessResult(gameState: .none, responses: [])
        }
        return bot.process(command: command)
    }

    func processTest(input: Input) -> ProcessResult {
        let bot = TestBot()
        guard let command = bot.parser.getCommand(from: input) else {
            return ProcessResult(gameState: .test, responses: [])
        }
        return bot.process(command: command)
    }

    func processCodenames(input: Input, gameState: Codenames.GameState) -> ProcessResult {
        let bot = CodenamesBot(state: gameState,
                               wordListGetter: CodenamesBot.cacheWordListGetter(teamId: input.team, channelId: input.channel))
        guard let command = bot.parser.getCommand(from: input) else {
            return ProcessResult(gameState: .codenames(gameState), responses: [])
        }
        return bot.process(command: command)
    }
    
}
