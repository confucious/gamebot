//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/7/19.
//

import Foundation
import SlackModels

extension GameState.State: Codable {
    private enum CodableState: String, Codable {
        case setup, waitingForClue, waitingForGuesses, gameOver
    }

    private enum CodingKeys: String, CodingKey {
        case state, side, clue, cluedGuesses, guessesTaken, winningPlayers, losingPlayers
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let state = try container.decode(CodableState.self, forKey: .state)

        switch state {
        case .setup:
            self = .setup
        case .waitingForClue:
            let side = try container.decode(GameState.Side.self, forKey: .side)
            self = .waitingForClue(side: side)
        case .waitingForGuesses:
            let side = try container.decode(GameState.Side.self, forKey: .side)
            let clue = try container.decode(String.self, forKey: .clue)
            let cluedGuesses = try container.decode(Int.self, forKey: .cluedGuesses)
            let guessesTaken = try container.decode(Int.self, forKey: .guessesTaken)
            self = .waitingForGuesses(side: side, clue: clue, cluedGuesses: cluedGuesses, guessesTaken: guessesTaken)
        case .gameOver:
            let side = try container.decode(GameState.Side.self, forKey: .side)
            let winningPlayers = try container.decode(Array<UserId>.self, forKey: .winningPlayers)
            let losingPlayers = try container.decode(Array<UserId>.self, forKey: .losingPlayers)
            self = .gameOver(winningSide: side, winningPlayers: winningPlayers, losingPlayers: losingPlayers)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .setup:
            try container.encode(CodableState.setup, forKey: .state)
        case let .waitingForClue(side: side):
            try container.encode(CodableState.waitingForClue, forKey: .state)
            try container.encode(side, forKey: .side)
        case let .waitingForGuesses(side: side, clue: clue, cluedGuesses: cluedGuesses, guessesTaken: guessesTaken):
            try container.encode(CodableState.waitingForGuesses, forKey: .state)
            try container.encode(side, forKey: .side)
            try container.encode(clue, forKey: .clue)
            try container.encode(cluedGuesses, forKey: .cluedGuesses)
            try container.encode(guessesTaken, forKey: .guessesTaken)
        case let .gameOver(winningSide: side, winningPlayers: winningPlayers, losingPlayers: losingPlayers):
            try container.encode(CodableState.gameOver, forKey: .state)
            try container.encode(side, forKey: .side)
            try container.encode(winningPlayers, forKey: .winningPlayers)
            try container.encode(losingPlayers, forKey: .losingPlayers)
        }
    }
}
