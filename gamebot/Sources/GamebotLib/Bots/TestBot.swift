//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/25/20.
//

import Foundation
import SlackModels

class TestBot {
    enum Action {
        case buttonBlock
        case buttonBlockPrivate
        case buttonClick
        case unknownCommand
    }

    let parser = Parser<Action>(
        commandMap: [
            ("button2", .buttonBlockPrivate),
            ("button", .buttonBlock)
        ],
        buttonMap: ["status": .buttonClick],
        unknownCommand: .unknownCommand)

    func process(command: Command<Action>) -> ProcessResult {
        let responses: [ResponseAction]
        switch command.action {
        case .buttonBlock:
            responses = [.messageBlock(buttonBlock(), message: "@confucious: It is your turn.", recipient: command.user)]
        case .buttonBlockPrivate:
            responses = [.ephemeralMessageBlock(buttonBlock(), message: "defaultMessage", recipient: command.user)]
        case .buttonClick:
            responses = [.ephemeralMessage("Button clicked value: |\(command.remainder)|", recipient: command.user)]
        case .unknownCommand:
            responses = [.ephemeralMessage("Unknown command for test `\(command.remainder)`. `help` to see available commands.", recipient: command.user)]
        }
        return ProcessResult(gameState: .test, responses: responses)
    }

    func buttonBlock() -> Blocks {
        return Blocks(
            Section(text: "@confucious: Gave clue `shower` for `2`"),
            Section(fields: [
                .markDown("""
red clues:
1: "fist" for 5
"""),
                .markDown("""
blue clues:
1: "aquatic" for 3
2: "shower" for 2
"""),
                ]),
            Section(text: ":cn-red::cn-red::cn-red::cn-red::cn-red::cn-red: 6, :cn-blue::cn-blue::cn-blue::cn-blue::cn-blue: 5, :cn-neutral::cn-neutral::cn-neutral::cn-neutral::cn-neutral::cn-neutral::cn-neutral: 7, :cn-kill: 1"),
            Section(text: """
:cn-blue-picked:`CRAB` :cn-unknown:`COLD` :cn-unknown:`PILLOW ` :cn-unknown:`CROW  ` :cn-unknown:`CAPITAL  `
:cn-unknown:`CARD` :cn-unknown:`FOG ` :cn-unknown:`PYRAMID` :cn-unknown:`CHURCH` :cn-blue-picked:`LOCH NESS`
:cn-blue-picked:`CLUB` :cn-unknown:`JAIL` :cn-unknown:`SHAMPOO` :cn-unknown:`PEARL ` :cn-unknown:`LAUNDRY  `
:cn-unknown:`PAGE` :cn-unknown:`HORN` :cn-blue-picked:`STREAM ` :cn-unknown:`MOUTH ` :cn-red-picked:`MANICURE `
:cn-unknown:`MASS` :cn-unknown:`JACK` :cn-unknown:`BUBBLE ` :cn-unknown:`SNAP  ` :cn-red-picked:`KUNG FU  `
"""),
            Section(text: "Players on the blue team () should guess a word. They have 2 (+1) left for \"shower\" for 2.",
                    accessory: Button(text: "Status", actionId: "status", style: .primary))
        )
    }
}
