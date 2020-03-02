//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/11/20.
//

import Foundation

public protocol SectionAccessory { }

public struct Section: Encodable, Block {
    let type = "section"
    let text: Text?
    let blockId: BlockId?
    let fields: [Text]?
    let accessory: SectionAccessory?

    public init(text: String, blockId: BlockId? = nil, accessory: SectionAccessory? = nil) {
        self.text = .markDown(text)
        self.blockId = blockId
        self.fields = nil
        self.accessory = accessory
    }

    public init(text: Text, blockId: BlockId? = nil, accessory: SectionAccessory? = nil) {
        self.text = text
        self.blockId = blockId
        self.fields = nil
        self.accessory = accessory
    }

    public init(text: Text? = nil, fields: [Text], blockId: BlockId? = nil, accessory: SectionAccessory? = nil) {
        self.text = text
        self.fields = fields
        self.blockId = blockId
        self.accessory = accessory
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case text
        case blockId = "block_id"
        case fields
        case accessory
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try text.do { try container.encode($0, forKey: .text) }
        try blockId.do { try container.encode($0, forKey: .blockId) }
        try fields.do { try container.encode($0, forKey: .fields) }
        try accessory.do { try container.encode(EncodableSectionAccessory(item: $0), forKey: .accessory) }
    }
}

enum EncodableSectionAccessory: Encodable {
    case button(Button)
    case plainTextInput(PlainTextInput)

    init(item: SectionAccessory) {
        switch item {
        case let button as Button:
            self = .button(button)
        case let input as PlainTextInput:
            self = .plainTextInput(input)
        default:
            fatalError("Unknown item type \(item) for SectionAccessory")
        }
    }

    func encode(to encoder: Encoder) throws {
        switch self {
        case let .button(button): try button.encode(to: encoder)
        case let .plainTextInput(input): try input.encode(to: encoder)
        }
    }
}
