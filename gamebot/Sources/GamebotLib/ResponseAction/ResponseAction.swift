//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/11/20.
//

import Foundation
import SlackModels

public enum ResponseAction {
    case message(String, recipient: UserId?)
    case ephemeralMessage(String, recipient: UserId)
    case messageBlock(Blocks, message: String, recipient: UserId?)
    case ephemeralMessageBlock(Blocks, message: String, recipient: UserId)
}
