//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/7/19.
//

import Foundation

open class TypedId: Equatable, Hashable, Codable, ExpressibleByStringLiteral, CustomStringConvertible {
    public typealias StringLiteralType = String

    public let id: String

    required public init(stringLiteral id: StringLiteralType) {
        self.id = id
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.id = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: TypedId, rhs: TypedId) -> Bool {
        String(describing: type(of: lhs)) == String(describing: type(of: rhs))
            && lhs.id == rhs.id
    }

    public var description: String {
        "\(type(of: self))(\(id))"
    }
}

public class UserId: TypedId { }

public class ChannelId: TypedId { }

public class TeamId: TypedId { }

public class TriggerId: TypedId { }

public class BlockId: TypedId { }

public class ActionId: TypedId { }

public struct SlackEvent: Codable {

    public enum EventType {
        case message(Message)
        case appMention(AppMention)
        case command(Command)
        case interactive(Interactive)
    }

    public struct Command: Codable {
        public let channel: ChannelId
        public let text: String
        public let responseUrl: String
        public let triggerId: TriggerId
        public let command: String
    }

    public struct Message: Codable {
        public enum ChannelType: String, Codable {
            case channel
            case im
        }

        public let channel: ChannelId
        public let text: String
        public let channelType: ChannelType
        public let ts: String
        public let eventTs: String
    }

    public struct AppMention: Codable {
        public let channel: ChannelId
        public let text: String
        public let ts: String
        public let eventTs: String
    }

    public struct Interactive: Codable {
        public let channel: ChannelId
        public let responseUrl: String
        public let triggerId: TriggerId
        public let actions: [Action]
    }

    public struct Action: Codable {
        public enum ActionType: String, Codable {
            case button
        }
        public let type: ActionType
        public let blockId: BlockId
        public let actionId: ActionId
        public let value: String?
        public let actionTs: String

        private enum CodingKeys: String, CodingKey {
            case type
            case blockId = "block_id"
            case actionId = "action_id"
            case value
            case actionTs = "action_ts"
        }
    }

    public let type: EventType
    public let team: TeamId
    public let user: UserId

    public var channel: ChannelId? {
        switch type {
        case let .command(command): return command.channel
        case let .interactive(interactive): return interactive.channel
        case let .appMention(mention): return mention.channel
        case let .message(message): return message.channel
        }
    }

    public init(type: SlackEvent.EventType, team: TeamId, user: UserId) {
        self.type = type
        self.team = team
        self.user = user
    }

    private enum CodingKeys: String, CodingKey {
        case type, team, user, data
    }

    private enum CodableType: String, Codable {
        case appMention, command, interactive, message
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(CodableType.self, forKey: .type)
        self.team = try container.decode(TeamId.self, forKey: .team)
        self.user = try container.decode(UserId.self, forKey: .user)

        switch type {
        case .appMention:
            let appMention = try container.decode(AppMention.self, forKey: .data)
            self.type = .appMention(appMention)
        case .command:
            let command = try container.decode(Command.self, forKey: .data)
            self.type = .command(command)
        case .interactive:
            let interactive = try container.decode(Interactive.self, forKey: .data)
            self.type = .interactive(interactive)
        case .message:
            let message = try container.decode(Message.self, forKey: .data)
            self.type = .message(message)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(team, forKey: .team)
        try container.encode(user, forKey: .user)
        switch self.type {
        case let .appMention(appMention):
            try container.encode(CodableType.appMention, forKey: .type)
            try container.encode(appMention, forKey: .data)
        case let .command(command):
            try container.encode(CodableType.command, forKey: .type)
            try container.encode(command, forKey: .data)
        case let .interactive(interactive):
            try container.encode(CodableType.interactive, forKey: .type)
            try container.encode(interactive, forKey: .data)
        case let .message(message):
            try container.encode(CodableType.message, forKey: .type)
            try container.encode(message, forKey: .data)
        }
    }
}
