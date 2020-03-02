//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/26/20.
//

import Foundation

public struct Divider: Encodable, Block {
    let type = "divider"
    let blockId: BlockId?

    public init(blockId: BlockId? = nil) {
        self.blockId = blockId
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case blockId = "block_id"
    }
}
