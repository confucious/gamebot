//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/26/20.
//

import Foundation
import XCTest
@testable import GamebotLib
import SlackModels

final class SlackBlockTests: XCTestCase {
    func testEncodeSectionWithButtonAccessory() throws {
        let item: [SlackBlockItem] = [
            SlackBlock.Section(text: .markDown("This is a button"),
                               accessory: SlackBlock.Button(text: "Do something", actionId: "asdf"))
        ]
        let blocks = item.map(SlackBlock.init)
        let encoded = try JSONEncoder().encode(blocks)
        let json = String(data: encoded, encoding: .utf8)!
        print(json)
    }
}
