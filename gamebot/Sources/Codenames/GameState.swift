//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/7/19.
//

import Foundation
import SlackModels

public struct GameState: Codable {
    public enum State: Equatable {
        case setup
        case waitingForClue(side: Side)
        case waitingForGuesses(side: Side, clue: String, cluedGuesses: Int, guessesTaken: Int)
        case gameOver(winningSide: Side, winningPlayers: [UserId], losingPlayers: [UserId])

        var validToStart: Bool {
            switch self {
            case .setup, .gameOver: return true
            default: return false
            }
        }
    }

    public enum Side: String, Codable {
        case red
        case blue
        case neutral
        case assassin

        public var otherSide: Side {
            switch self {
            case .red: return .blue
            case .blue: return .red
            default:
                fatalError("No other side for \(self)")
            }
        }
    }

    public enum Role: String, Codable {
        case spyMaster
        case guesser
    }

    public struct Word: Codable {
        public let word: String
        public let side: Side
        public var guessed: Bool

        public init(word: String, side: Side, guessed: Bool = false) {
            self.word = word
            self.side = side
            self.guessed = guessed
        }

        func updating(guessed: Bool) -> Word {
            return Word(word: word, side: side, guessed: guessed)
        }
    }

    public struct Clue: Codable {
        public let word: String
        public let side: Side
        public let count: Int
        public var displayCount: String {
            if count > 9 {
                return "unlimited"
            } else {
                return "\(count)"
            }
        }
    }

    public struct Player: Codable, Equatable {
        var side: Side
        var role: Role
        var avoidSpymaster: Bool
        let id: UserId

        func updating(side: Side? = nil, role: Role? = nil, avoidSpymaster: Bool? = nil) -> Player {
            return Player(side: side ?? self.side,
                          role: role ?? self.role,
                          avoidSpymaster: avoidSpymaster ?? self.avoidSpymaster,
                          id: id)
        }
    }

    public var state: State
    public var words: [Word]
    var players: [Player]
    public var clues: [Clue]
    public static var wordSideShuffler: () -> [Side] = {
        let sideArray = [Side.assassin]
            + Array(repeating: Side.neutral, count: 7)
            + Array(repeating: Side.red, count: 8)
            + Array(repeating: Side.blue, count: 8)
            + ((Int.random(in: 0...1) == 0) ? [Side.red] : [Side.blue])
        return sideArray.shuffled()
    }

    public init() {
        self.state = .setup
        self.words = []
        self.players = []
        self.clues = []
    }

    public func remainingCounts() -> DefaultingDictionary<Side, Int> {
        words.reduce(into: DefaultingDictionary(defaultValue: 0)) { (result, word) in
            result[word.side] += word.guessed ? 0 : 1
        }
    }

    public func givenClues() -> DefaultingDictionary<Side, [Clue]> {
        clues.reduce(into: DefaultingDictionary(defaultValue: [])) { (result, clue) in
            result[clue.side].append(clue)
        }
    }

    public func players(for side: Side) -> [Player] {
        players.filter { (player) -> Bool in
            player.side == side
        }
    }

    public func side(for user: UserId) -> Side? {
        return players.first(where: playerHasId(user))?.side
    }

    public func spyMaster(for side: Side) -> UserId? {
        players(for: side).first { (player) -> Bool in
            player.role == .spyMaster
        }
        .flatMap { $0.id }
    }

    public func guessers(for side: Side) -> [UserId] {
        players(for: side).filter { (player) -> Bool in
            player.role == .guesser
        }
        .map { $0.id }
    }

    public func isSpyMaster(_ user: UserId) -> Bool {
        players.first(where: playerHasId(user))?.role == .spyMaster
    }

    func playerHasId(_ user: UserId) -> ((Player) -> (Bool)) {
        return { $0.id == user }
    }
    func playerHasRole(_ role: Role, side: Side? = nil) -> ((Player) -> (Bool)) {
        if let side = side {
            return { $0.role == role && $0.side == side }
        } else {
            return { $0.role == role }
        }
    }

    public mutating func reset(includingPlayers: Bool = false) {
        state = .setup
        words = []
        clues = []
        if includingPlayers {
            players = []
        }
    }

    public mutating func rotateSpymasters() throws {
        if case .gameOver = state {
            reset()
        }
        guard state == .setup else {
            throw StateError.invalidState(state)
        }

        if let redSpymaster = getNextSpymaster(for: .red) {
            try setSpymaster(to: redSpymaster)
        }
        if let blueSpymaster = getNextSpymaster(for: .blue) {
            try setSpymaster(to: blueSpymaster)
        }
    }

    private func getNextSpymaster(for side: Side) -> UserId? {
        let sidePlayers = players(for: side)
        var allowingSpymasterPlayers = sidePlayers.filter { $0.avoidSpymaster == false }
        if allowingSpymasterPlayers.isEmpty {
            allowingSpymasterPlayers = sidePlayers
        }
        if let spyMasterIndex = allowingSpymasterPlayers.firstIndex(where: { $0.role == .spyMaster }) {
            let newIndex = (spyMasterIndex + 1) % allowingSpymasterPlayers.count
            return allowingSpymasterPlayers[newIndex].id
        } else {
            return allowingSpymasterPlayers.first?.id
        }
    }

    public mutating func shuffleTeams() throws {
        if case .gameOver = state {
            reset()
        }
        guard state == .setup else {
            throw StateError.invalidState(state)
        }
        let allowingSpymasterPlayers = players.filter { $0.avoidSpymaster == false }
        let avoidingSpymasterPlayers = players.filter { $0.avoidSpymaster == true }
        players = allowingSpymasterPlayers.shuffled() + avoidingSpymasterPlayers.shuffled()
        players = players.enumerated()
            .map { (index, player) in
                Player(
                    side: index % 2 == 0 ? .red : .blue,
                    role: index < 2 ? .spyMaster : .guesser,
                    avoidSpymaster: player.avoidSpymaster,
                    id: player.id)
        }
    }

    @discardableResult
    public mutating func setSpymaster(to userId: UserId) throws -> Side {
        guard let playerIndex = players.firstIndex(where: playerHasId(userId)) else {
            throw StateError.userNotPlaying(userId)
        }

        let side = players[playerIndex].side
        if let spyMasterIndex = players.firstIndex(where: playerHasRole(.spyMaster, side: side)) {
            players.replace(index: spyMasterIndex) { $0.updating(role: .guesser) }
        }

        players.replace(index: playerIndex) { $0.updating(role: .spyMaster) }
        return players[playerIndex].side
    }

    public mutating func setAvoidSpyMaster(for userId: UserId, avoid: Bool) throws {
        guard let playerIndex = players.firstIndex(where: playerHasId(userId)) else {
            throw StateError.userNotPlaying(userId)
        }

        players.replace(index: playerIndex) { $0.updating(avoidSpymaster: avoid) }
    }

    @discardableResult
    public mutating func addToGame(userId: UserId) -> Side {
        if let playerIndex = players.firstIndex(where: playerHasId(userId)) {
            players.replace(index: playerIndex) {
                $0.updating(side: $0.side == .red ? .blue : .red, role: .guesser)
            }
            return players[playerIndex].side
        } else {
            if guessers(for: .red).count > guessers(for: .blue).count {
                players.append(Player(side: .blue, role: .guesser, avoidSpymaster: false, id: userId))
                return .blue
            } else {
                players.append(Player(side: .red, role: .guesser, avoidSpymaster: false, id: userId))
                return .red
            }
        }
    }

    @discardableResult
    public mutating func removeFromGame(userId: UserId) -> Bool {
        if let playerIndex = players.firstIndex(where: playerHasId(userId)) {
            players.remove(at: playerIndex)
            return true
        } else {
            return false
        }
    }

    // words are assumed to be pre-shuffled
    mutating func initializeBoard(words: [String]) {
        self.words = zip(words, GameState.wordSideShuffler())
            .map { (word, side) in
                Word(word: word, side: side, guessed: false)
        }
    }

    public func readyToStart() throws {
        guard state.validToStart else {
            throw StateError.invalidState(state)
        }
        guard spyMaster(for: .red) != nil,
            spyMaster(for: .blue) != nil
            else {
                throw StateError.needSpyMaster
        }
        guard guessers(for: .red).count > 0,
            guessers(for: .blue).count > 0
            else {
                throw StateError.notEnoughPlayers
        }
    }

    func identity<T>(input: T) -> T {
        return input
    }

    public static func columnMinimizingShuffle(words: [String]) -> [String] {
        // order words by length to minimize column widths.
        let wordsOrderedByLength = words.sorted { (a, b) -> Bool in
            a.count < b.count
        }
        let shuffledColumns = [
            wordsOrderedByLength[0 ..< 5].shuffled(),
            wordsOrderedByLength[5 ..< 10].shuffled(),
            wordsOrderedByLength[10 ..< 15].shuffled(),
            wordsOrderedByLength[15 ..< 20].shuffled(),
            wordsOrderedByLength[20 ..< 25].shuffled()
        ].shuffled()
        return (0 ..< 5).flatMap { row in
            (0 ..< 5).map { column in
                shuffledColumns[column][row]
            }
        }
    }

    public mutating func beginGame(words: [String], wordShuffler: ([String]) -> [String] = { $0 }) throws {
        if case .gameOver = state {
            reset()
            try rotateSpymasters()
        }
        try readyToStart()
        initializeBoard(words: wordShuffler(words))
        let counts = remainingCounts()
        if counts[.red] > counts[.blue] {
            state = .waitingForClue(side: .red)
        } else {
            state = .waitingForClue(side: .blue)
        }
    }

    public mutating func acceptClue(clue: String, count: Int, from userId: UserId) throws {
        guard case .waitingForClue = state else {
            throw StateError.invalidState(state)
        }
        guard let player = players.first(where: playerHasId(userId)) else {
            throw StateError.userNotPlaying(userId)
        }
        guard state == .waitingForClue(side: player.side) else {
            throw StateError.wrongTurn
        }
        guard player.role == .spyMaster else {
            throw StateError.playerIsNotSpyMaster
        }
        clues.append(Clue(word: clue, side: player.side, count: count))
        state = .waitingForGuesses(side: player.side, clue: clue, cluedGuesses: count, guessesTaken: 0)
    }

    func gameOver(winningSide: Side) -> State {
        return .gameOver(winningSide: winningSide,
        winningPlayers: players(for: winningSide).map { $0.id },
        losingPlayers: players(for: winningSide.otherSide).map { $0.id })
    }

    public enum GuessResult {
        case correct
        case wrong
        case gameOver
    }

    @discardableResult
    public mutating func acceptGuess(guess: String, from userId: UserId) throws -> (GuessResult, Side) {
        guard case .waitingForGuesses = state else {
            throw StateError.invalidState(state)
        }
        guard let player = players.first(where: playerHasId(userId)) else {
            throw StateError.userNotPlaying(userId)
        }
        guard case let .waitingForGuesses(side, clue, cluedGuesses, guessesTaken) = state,
            side == player.side
            else {
                throw StateError.wrongTurn
        }
        guard player.role == .guesser else {
            throw StateError.playerIsNotGuesser
        }
        let testWord = guess.uppercased()
        guard let wordIndex = words.firstIndex(where: { (word) -> Bool in
            word.word.uppercased() == testWord.uppercased()
        }) else {
            throw StateError.unknownWord(guess)
        }
        let word = words[wordIndex]
        guard word.guessed == false else {
            throw StateError.wordAlreadyGuessed(guess)
        }
        words.replace(index: wordIndex) { $0.updating(guessed: true) }
        if word.side == .assassin {
            state = gameOver(winningSide: side.otherSide)
            return (.gameOver, word.side)
        } else if word.side != side {
            if remainingCounts()[side.otherSide] == 0 {
                state = gameOver(winningSide: side.otherSide)
                return (.gameOver, word.side)
            } else {
                state = .waitingForClue(side: side.otherSide)
                return (.wrong, word.side)
            }
        } else {
            if remainingCounts()[side] == 0 {
                state = gameOver(winningSide: side)
                return (.gameOver, word.side)
            } else if cluedGuesses != 0 && guessesTaken >= cluedGuesses {
                state = .waitingForClue(side: side.otherSide)
                return (.correct, word.side)
            } else {
                state = .waitingForGuesses(
                    side: side,
                    clue: clue,
                    cluedGuesses: cluedGuesses,
                    guessesTaken: guessesTaken + 1)
                return (.correct, word.side)
            }
        }
    }

    @discardableResult
    public mutating func passTurn(from userId: UserId, force: Bool = false) throws -> Side {
        if force {
            switch state {
            case let .waitingForClue(side: side),
                 let .waitingForGuesses(side: side, _, _, _):
                state = .waitingForClue(side: side.otherSide)
                return side.otherSide
            default:
                throw StateError.invalidState(state)
            }
        }
        guard case .waitingForGuesses = state else {
            throw StateError.invalidState(state)
        }
        guard let player = players.first(where: playerHasId(userId)) else {
            throw StateError.userNotPlaying(userId)
        }
        guard case let .waitingForGuesses(side, _, _, guessesTaken) = state,
            side == player.side
            else {
                throw StateError.wrongTurn
        }
        guard player.role == .guesser else {
            throw StateError.playerIsNotGuesser
        }
        guard guessesTaken > 0 else {
            throw StateError.mustGuessOneWord
        }
        state = .waitingForClue(side: side.otherSide)
        return side.otherSide
    }
}
