//
//  File.swift
//  
//
//  Created by Jerry Hsu on 1/10/20.
//

import Foundation
import SlackModels

public struct GameState {
    public enum State: Equatable {
        case setup
        case waitingForClues
        case validatingClues([UserId])
        case waitingForGuess
        case validatingGuess(String)
        case gameOver
    }

    public struct Clue: Codable, Equatable {
        public let word: String
        public var duplicate: Bool

        public static func ==(lhs: Clue, rhs: Clue) -> Bool {
            lhs.word.lowercased() == rhs.word.lowercased()
        }
    }

    public var state: State
    public var round: Int
    public var score: Int
    var players: [UserId]
    var guesserIndex: Int
    var clues: [UserId:Clue]
    var targetWord: String

    public static var wordGetter: () -> String = {
        return ["just", "one", "word"].randomElement()!
    }

    public init() {
        self.state = .setup
        self.round = 1
        self.score = 0
        self.players = []
        self.guesserIndex = 0
        self.clues = [:]
        self.targetWord = ""
    }

    @discardableResult
    public mutating func addToGame(userId: UserId) -> Bool {
        if !players.contains(userId) {
            players.append(userId)
            return true
        } else {
            return false
        }
    }

    @discardableResult
    public mutating func removeFromGame(userId: UserId) -> Bool {
        if let index = players.firstIndex(of: userId) {
            players.remove(at: index)
            clues[userId] = nil
            if guesserIndex < index {
                incrementGuesserIndex(amount: -1)
                checkIfAllCluesEntered()
            } else if guesserIndex == index && state == .waitingForGuess {
                setupNewTargetWord()
            } else {
                checkIfAllCluesEntered()
            }
            return true
        } else {
            return false
        }
    }

    mutating func incrementGuesserIndex(amount: Int = 1) {
        guesserIndex = (guesserIndex + amount) % players.count
    }

    public func readyToStart() throws {
        guard state == .setup || state == .gameOver else {
            throw StateError.invalidState(state)
        }
        guard players.count >= 3 else {
            throw StateError.notEnoughPlayers
        }
    }

    public mutating func reset(includingPlayers: Bool = false) {
        state = .setup
        round = 1
        score = 0
        guesserIndex = 0
        clues = [:]
        targetWord = ""
        if includingPlayers {
            players = []
        }
    }

    public mutating func beginGame() throws {
        if state == .gameOver {
            reset()
        }
        try readyToStart()
        players.shuffle()
        setupNewTargetWord()
    }

    mutating func setupNewTargetWord() {
        targetWord = GameState.wordGetter()
        clues = [:]
        state = .waitingForClues
    }

    mutating func checkIfAllCluesEntered() {
        guard state == .waitingForClues else {
            return
        }
        if clues.count >= players.count - 1 {
            try! advanceToGuess()
        }
    }

    public mutating func advanceToGuess(user userId: UserId? = nil) throws {
        guard state == .waitingForClues else {
            throw StateError.invalidState(state)
        }
        if let userId = userId {
            guard players.contains(userId) else {
                throw StateError.userNotPlaying(userId)
            }
        }
        let players = clues.keys.shuffled()
        state = .validatingClues(players)
        for (index, player) in players[0 ..< players.count - 1].enumerated() {
            let clue = clues[player]
            for player2 in players[index ..< players.count] {
                let clue2 = clues[player2]
                if clue == clue2 {
                    clues[player]?.duplicate = true
                    clues[player2]?.duplicate = true
                }
            }
        }
    }

    public mutating func acceptClue(clue: String, from userId: UserId) throws {
        guard state == .waitingForClues else {
            throw StateError.invalidState(state)
        }
        guard let index = players.firstIndex(of: userId) else {
            throw StateError.userNotPlaying(userId)
        }
        guard index != guesserIndex else {
            throw StateError.notClueGiver
        }
        clues[userId] = Clue(word: clue, duplicate: false)
        checkIfAllCluesEntered()
    }

    public mutating func markClue(from userId: UserId, duplicate: Bool) throws {
        guard case .validatingClues = state else {
            throw StateError.invalidState(state)
        }
        clues[userId]?.duplicate = duplicate
    }

    public mutating func finalizeClues() throws {
        guard case .validatingClues = state else {
            throw StateError.invalidState(state)
        }
        state = .waitingForGuess
    }

    public mutating func acceptGuess(guess: String?, from userId: UserId) throws {
        guard state == .waitingForGuess else {
            throw StateError.invalidState(state)
        }
        guard let index = players.firstIndex(of: userId) else {
            throw StateError.userNotPlaying(userId)
        }
        guard index == guesserIndex else {
            throw StateError.notGuesser
        }
        if let guess = guess {
            state = .validatingGuess(guess)
            if guess.lowercased() == targetWord.lowercased() {
                try scoreGuess(correct: true)
            }
        } else {
            advance(numberOfRounds: 1)
        }
    }

    public mutating func scoreGuess(correct: Bool) throws {
        guard case .validatingGuess = state else {
            throw StateError.invalidState(state)
        }
        if correct {
            score += 1
            advance(numberOfRounds: 1)
        } else if round == 13 {
            score -= 1
            advance(numberOfRounds: 1)
        } else {
            advance(numberOfRounds: 2)
        }
    }

    mutating func advance(numberOfRounds: Int) {
        round += numberOfRounds
        if round > 13 {
            state = .gameOver
        } else {
            incrementGuesserIndex()
            setupNewTargetWord()
        }
    }
}
