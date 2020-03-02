//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/7/19.
//

import Foundation
import SlackModels

public extension GameState {
    enum StateError: Error, Equatable {
        case invalidState(State)
        case userNotPlaying(UserId)
        case notEnoughPlayers
        case needSpyMaster
        case playerIsNotSpyMaster
        case playerIsNotGuesser
        case wrongTurn
        case mustGuessOneWord
        case spyMasterCannotPass
        case unknownWord(String)
        case wordAlreadyGuessed(String)
    }
}
