
//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/30/19.
//

import Foundation
import SlackModels

struct SQSEvents: Codable {
    let records: [SQSEvent]

    enum CodingKeys: String, CodingKey {
        case records = "Records"
    }
}

/// String representing 128-bit Int.
// It will strictly increase so we only need to test for ordering.
public class SequenceNumber: TypedId, Comparable {
    public static func < (lhs: SequenceNumber, rhs: SequenceNumber) -> Bool {
        return lhs.id.count < rhs.id.count
        || (lhs.id.count == rhs.id.count && lhs.id < rhs.id)
    }
}

struct SQSEvent: Codable {

    struct Attributes: Codable {
        let approximateReceiveCount: String
        let sentTimestamp: String
        let sequenceNumber: SequenceNumber
        let messageGroupId: String
        let senderId: String
        let messageDeduplicationId: String
        let approxmiateFirstReceiveTimestamp: String

        enum CodingKeys: String, CodingKey {
            case approximateReceiveCount = "ApproximateReceiveCount"
            case sentTimestamp = "SentTimestamp"
            case sequenceNumber = "SequenceNumber"
            case messageGroupId = "MessageGroupId"
            case senderId = "SenderId"
            case messageDeduplicationId = "MessageDeduplicationId"
            case approxmiateFirstReceiveTimestamp = "ApproximateFirstReceiveTimestamp"
        }
    }

    let messageId: String
    let receiptHandle: String
    let body: String
    let attributes: Attributes
    // let messageAttributes: MessageAttributes
    let md5OfBody: String
    let eventSource: String
    let eventSourceARN: String
    let awsRegion: String
}
