//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/29/19.
//

import Foundation
import SlackModels

class ChannelCache {

    private enum Name {
        static let tableName = "gamebot-cache"
        static let keyName = "key"
        static let valueName = "value"
    }

    let teamId: TeamId
    let channelId: ChannelId

    init(teamId: TeamId, channelId: ChannelId) {
        self.teamId = teamId
        self.channelId = channelId
    }

    func makeKey(key: String) -> String {
        return "\(teamId.id)|\(channelId.id):\(key)"
    }

    func get<T: Codable>(from key: String) throws -> T? {
        return try Cache.get(from: makeKey(key: key))
    }

    func set<T: Codable>(_ value: T, into key: String) throws {
        return try Cache.set(value, into: makeKey(key: key))
    }
}
