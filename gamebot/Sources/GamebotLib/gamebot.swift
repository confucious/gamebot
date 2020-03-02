import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import LambdaSwiftSprinter
import LambdaSwiftSprinterNioPlugin
import NIO
import NIOFoundationCompat
import SlackModels

typealias Response = [String:String]
let emptyResponse: Response = [:]

let syncLambda: SyncCodableNIOLambda<SQSEvents, Response> = { (events, context) throws -> EventLoopFuture<Response> in
    for event in events.records {
        let slackEvent: SlackEvent
        do {
            slackEvent = try event.body.decodeJson()
        } catch {
            log("Unable to decode \(event.body). Error: \(error). Skipping.")
            continue
        }

        guard let channel = slackEvent.channel else {
            continue
        }

        // Get gameState for channel
        let cache = ChannelCache(teamId: slackEvent.team, channelId: channel)
        var channelState: ChannelState = try cache.get(from: "gameState")
            ?? ChannelState(teamId: slackEvent.team, channelId: channel, sequenceNumber: "0", gameState: .none)

        // If sequence number is invalid, skip.
        guard channelState.sequenceNumber < event.attributes.sequenceNumber else {
            log("Skipping previously seen sequence number \(event.attributes.sequenceNumber)")
            continue
        }

        // Process and then store gameState with updated sequence number.
        let result = process(slackEvent, with: channelState.gameState)
        channelState.gameState = result.gameState
        channelState.sequenceNumber = event.attributes.sequenceNumber
        try cache.set(channelState, into: "gameState")
        try sendResponses(result.responses, teamId: slackEvent.team, channel: channelState.channelId)
    }

    return httpClient.eventLoopGroup.next().makeSucceededFuture(emptyResponse)
}

public func registerHandler() {
    do {
        let sprinter = try SprinterNIO()
        sprinter.register(handler: "gamebot", lambda: syncLambda)
        try sprinter.run()
    } catch {
        log(String(describing: error), flush: true)
    }
}

extension String {
    func decodeJson<T: Decodable>() throws -> T {
        guard let data = self.data(using: .utf8) else {
            throw CacheError.utf8EncodingError("", self)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
