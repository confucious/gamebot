//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/10/20.
//

import Foundation
import SlackModels

public extension GameState {
    enum StateError: Error, Equatable {
        case invalidState(State)
        case userNotPlaying(UserId)
        case notEnoughPlayers
        case notClueGiver
        case notGuesser
    }
}
