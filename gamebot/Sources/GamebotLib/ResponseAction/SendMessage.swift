//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/11/20.
//

import AsyncHTTPClient
import Foundation
import LambdaSwiftSprinter
import LambdaSwiftSprinterNioPlugin
import SlackModels

struct SlackEphemeralMessage: Encodable {
    let channel: ChannelId
    let user: UserId
    let text: String
    let attachments: String
    let blocks: Blocks?

    init(channel: ChannelId, user: UserId, text: String, attachments: String, blocks: Blocks?) {
        self.channel = channel
        self.user = user
        self.text = text
        self.attachments = attachments
        self.blocks = blocks
    }
}

struct SlackChannelMessage: Encodable {
    let channel: ChannelId
    let text: String
    let blocks: Blocks?

    /// If blocks is specified, text is what wil be shown in push notifications if any would be generated.
    init(channel: ChannelId, text: String, blocks: Blocks?) {
        self.channel = channel
        self.text = text
        self.blocks = blocks
    }
}

struct MessageResponse: Codable {
    let ok: Bool
    let error: String?
}

func sendResponses(_ responses: [ResponseAction], teamId: TeamId, channel: ChannelId) throws {
    guard let token = getToken(for: teamId) else { return }

    let ephemeralUrl = "https://slack.com/api/chat.postEphemeral"
    let channelUrl = "https://slack.com/api/chat.postMessage"

    let requests = try responses.compactMap { response -> HTTPClient.Request? in
        switch response {
        case let .ephemeralMessage(message, recipient: user):
            let slackMessage = SlackEphemeralMessage(
                channel: channel,
                user: user,
                text: message,
                attachments: "",
                blocks: nil)
            return try postJson(to: ephemeralUrl, message: slackMessage, token: token)
        case let .message(message, recipient: user):
            let output: String
            if let user = user {
                output = "<@\(user.id)>: \(message)"
            } else {
                output = message
            }
            let slackMessage = SlackChannelMessage(
                channel: channel,
                text: output,
                blocks: nil)
            return try postJson(to: channelUrl, message: slackMessage, token: token)
        case let .ephemeralMessageBlock(blocks, message, user):
            let slackMessage = SlackEphemeralMessage(
                channel: channel,
                user: user,
                text: message,
                attachments: "",
                blocks: blocks)
            return try postJson(to: ephemeralUrl, message: slackMessage, token: token)
        case let .messageBlock(blocks, message, recipient: user):
            let output: String
            if let user = user {
                output = "<@\(user.id)>: \(message)"
            } else {
                output = message
            }
            let slackMessage = SlackChannelMessage(
                channel: channel,
                text: output,
                blocks: blocks)
            return try postJson(to: channelUrl, message: slackMessage, token: token)
        }
    }
    try requests.forEach { (request) in
        let future = httpClient.execute(request: request, deadline: nil)
            .flatMapThrowing { (response) throws -> MessageResponse in
                guard let body = response.body,
                    let value = body.getString(at: 0, length: body.readableBytes) else {
                        throw SprinterError.invalidJSON
                }
                let result: MessageResponse = try value.decodeJson()
                return result
        }
        let response = try future.wait()
        if !response.ok {
            if let error = response.error {
                log("error sending to slack \(error)")
//                throw SprinterError.endpointError(error)
            } else {
                log("error sending to slack. no error provided")
//                throw SprinterError.endpointError("Error not provided")
            }
        }
    }
}

private func getToken(for teamId: TeamId) -> String? {
    guard let token = ProcessInfo.processInfo.environment[teamId.id] else {
        return nil
    }
    return token
}

private func postJson<T: Encodable>(to url: String, message: T, token: String) throws -> HTTPClient.Request {
    return try HTTPClient.Request(
        url: url,
        method: .POST,
        headers: [
            "Content-type": "application/json",
            "Authorization": "Bearer \(token)"
        ],
        body: .data(try JSONEncoder().encode(message)))
}
