//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/26/20.
//

import Foundation

public enum Text: Encodable {
    case markDown(String)
    case plainText(String)

    private enum CodingKeys: String, CodingKey {
        case type, text
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .markDown(text):
            try container.encode("mrkdwn", forKey: .type)
            try container.encode(text, forKey: .text)
        case let .plainText(text):
            try container.encode("plain_text", forKey: .type)
            try container.encode(text, forKey: .text)
        }
    }
}

public struct PlainText: Encodable {
    let type = "plain_text"
    let text: String
}
