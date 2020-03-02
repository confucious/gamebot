//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/3/20.
//

import Foundation
import SlackModels
import Codenames

public struct ChannelState: Codable {
    public enum GameState {
        case none
        case codenames(Codenames.GameState)
        case test
    }

    public let teamId: TeamId
    public let channelId: ChannelId
    public var sequenceNumber: SequenceNumber
    public var gameState: GameState
}

extension ChannelState.GameState: Codable {
    private enum CodableState: String, Codable {
        case none, test, codenames
    }

    private enum CodingKeys: String, CodingKey {
        case game, codenamesState
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let game = try container.decode(CodableState.self, forKey: .game)

        switch game {
        case .none:
            self = .none
        case .test:
            self = .test
        case .codenames:
            let gameState = try container.decode(Codenames.GameState.self, forKey: .codenamesState)
            self = .codenames(gameState)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none:
            try container.encode(CodableState.none, forKey: .game)
        case .test:
            try container.encode(CodableState.test, forKey: .game)
        case .codenames(let gameState):
            try container.encode(CodableState.codenames, forKey: .game)
            try container.encode(gameState, forKey: .codenamesState)
        }
    }
}
