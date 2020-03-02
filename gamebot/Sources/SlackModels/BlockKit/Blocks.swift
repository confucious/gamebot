//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/11/20.
//

import Foundation

/// Supported Block structs: Section, Divider
/// Will build as needed: Actions, Context, File, Image, Input
public protocol Block { }

public struct Blocks: Encodable {
    let blocks: [Block]

    public init(_ blocks: [Block]) {
        self.blocks = blocks
    }

    public init(_ blocks: Block...) {
        self.blocks = blocks
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try blocks.forEach { (item) in
            let block = EncodableBlock(item: item)
            try container.encode(block)
        }
    }

    enum EncodableBlock: Encodable {
        case section(Section)
        case divider(Divider)
        //    case actions
        //    case context
        //    case file
        //    case image
        //    case input

        public init(item: Block) {
            switch item {
            case let section as Section:
                self = .section(section)
            case let divider as Divider:
                self = .divider(divider)
            default:
                fatalError("Unknown item \(item) for EncodableBlock init")
            }
        }

        public func encode(to encoder: Encoder) throws {
            switch self {
            case let .section(section): try section.encode(to: encoder)
            case let .divider(divider): try divider.encode(to: encoder)
            }
        }
    }
}
