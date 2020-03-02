//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/26/20.
//

import Foundation

public struct Button: Encodable, SectionAccessory {
    public enum Style: String, Encodable {
        case primary
        case danger
    }
    let type = "button"
    let text: PlainText
    let actionId: ActionId
    let value: String?
    let style: Style?
    // let confirm: Confirm

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case actionId = "action_id"
        case value
        case style
    }

    public init(text: String, actionId: ActionId, value: String? = nil, style: Style? = nil) {
        self.text = .init(text: text)
        self.actionId = actionId
        self.value = value
        self.style = style
    }
}

public struct PlainTextInput: Encodable, SectionAccessory {
    let type = "plain_text_input"
    let actionId: ActionId
    let placeholder: PlainText?
    let initialValue: String?
    let multiline: Bool?
    let minLength: Int?
    let maxLength: Int?

    private enum CodingKeys: String, CodingKey {
        case type
        case actionId = "action_id"
        case placeholder
        case initialValue = "initial_value"
        case multiline
        case minLength = "min_length"
        case maxLength = "max_length"
    }
}
