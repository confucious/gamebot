//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/31/19.
//

import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import LambdaSwiftSprinter
import LambdaSwiftSprinterNioPlugin
import NIO
import NIOFoundationCompat
import SQS
import SlackModels

struct Event: Codable {
    let event: MessageEvent?
    let challenge: String?
    let team_id: TeamId?
}

struct MessageEvent: Codable {
    public let type: SlackEvent.EventType
    public let channel: ChannelId
    public let user: UserId
    public let text: String
    public let channel_type: SlackEvent.ChannelType?
    public let bot_id: String?
    public let ts: String
    public let event_ts: String
}

struct Response: Codable {
    let challenge: String?

    init() {
        self.challenge = nil
    }
    init(challenge: String) {
        self.challenge = challenge
    }
}

enum SlackMessageEnqueuerError: Error {
    case jsonToStringEncodingFailure
    case teamIdMissing
}

let sqsUrl = "https://sqs.us-east-1.amazonaws.com/613751802309/gamebot.fifo"

let syncLambda: SyncCodableNIOLambda<Event, Response> = { (event, context) throws -> EventLoopFuture<Response> in
    if let challenge = event.challenge {
        log("Processed challenge \(challenge)", flush: true)
        return httpClient.eventLoopGroup.next().makeSucceededFuture(Response(challenge: challenge))
    }


    if let slackEvent = event.event {
        guard let teamId = event.team_id else {
            throw SlackMessageEnqueuerError.teamIdMissing
        }
        return try queueEvent(slackEvent, team: teamId)
    }

    log("Did not see slack event \(event)", flush: true)
    return httpClient.eventLoopGroup.next().makeSucceededFuture(Response())
}

func queueEvent(_ event: MessageEvent, team: TeamId) throws -> EventLoopFuture<Response> {
    if event.bot_id != nil {
        // ignore bot messages
        return httpClient.eventLoopGroup.next().makeSucceededFuture(Response())
    }

    let slackEvent = SlackEvent(
        type: event.type,
        channel: event.channel,
        team: team,
        user: event.user,
        text: event.text,
        channel_type: event.channel_type,
        ts: event.ts,
        event_ts: event.event_ts,
        triggerId: nil,
        responseUrl: nil)

    guard let body = String(data: try JSONEncoder().encode(slackEvent), encoding: .utf8) else {
        throw SlackMessageEnqueuerError.jsonToStringEncodingFailure
    }

    let message = SQS.SendMessageRequest(
        messageBody: body,
        messageGroupId: "g",
        queueUrl: sqsUrl)
    let future = SQS()
        .sendMessage(message)
        .map { content -> Response in
            return Response()
    }
    return future
}

public func registerHandler() {
    do {
        let sprinter = try SprinterNIO()
        sprinter.register(handler: "slackMessageEnqueuer", lambda: syncLambda)
        try sprinter.run()
    } catch {
        log(String(describing: error))
    }
}
