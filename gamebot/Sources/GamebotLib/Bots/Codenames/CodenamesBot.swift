//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/14/19.
//

import Foundation
import Codenames
import SlackModels

public class CodenamesBot {
    public enum Action {
        case help
        case beginGame
        case endGame
        case rotateSpyMasters
        case resetEverything
        case join
        case leave
        case shuffleTeams
        case becomeSpyMaster
        case showStatus
        case giveClue
        case guess
        case pass
        case forcePass
        case allowSpyMaster
        case avoidSpyMaster
        case echoPrivately
        case unknownCommand
    }


    // Keep actionMap in reverse sorted order because matching relies on checking prefixes.
    let parser = Parser<Action>(
        commandMap: [
            ("status", .showStatus),
            ("start game", .beginGame),
            ("shuffle-teams", .shuffleTeams),
            ("shuffle teams", .shuffleTeams),
            ("s", .showStatus),
            ("rotate spymasters", .rotateSpyMasters),
            ("reset everything", .resetEverything),
            ("pass", .pass),
            ("leave", .leave),
            ("join", .join),
            ("help", .help),
            ("h", .help),
            ("guess", .guess),
            ("give-clue", .giveClue),
            ("give clue", .giveClue),
            ("force pass", .forcePass),
            ("end game", .endGame),
            ("begin-game", .beginGame),
            ("begin game", .beginGame),
            ("become-spymaster", .becomeSpyMaster),
            ("become spymaster", .becomeSpyMaster),
            ("avoid spymaster", .avoidSpyMaster),
            ("allow spymaster", .allowSpyMaster),
        ],
        buttonMap: [
            "echoPrivately" : .echoPrivately,
            "status" : .showStatus,
        ],
        unknownCommand: .unknownCommand)

    var state: GameState
    let wordListGetter: () throws -> [String]

    static func cacheWordListGetter(teamId: TeamId, channelId: ChannelId) -> (() throws -> [String]) {
        return {
            let cache = ChannelCache(teamId: teamId, channelId: channelId)
            var wordState: WordState = try cache.get(from: "wordState") ?? WordState()
            let result = wordState.getNextBatch()
            try cache.set(wordState, into: "wordState")
            return result
        }
    }

    public init(state: GameState, wordListGetter: @escaping () throws -> [String]) {
        self.state = state
        self.wordListGetter = wordListGetter
    }

    func process(command: Command<Action>) -> ProcessResult {
        let responses: [ResponseAction]
        switch command.action {
        case .help:
            responses = [.ephemeralMessage(help, recipient: command.user)]
        case .beginGame:
            responses = beginGame(user: command.user)
        case .join:
            responses = join(user: command.user)
        case .leave:
            responses = leave(user: command.user)
        case .becomeSpyMaster:
            responses = becomeSpyMaster(user: command.user)
        case .giveClue:
            responses = giveClue(user: command.user, remainder: command.remainder)
        case .showStatus:
            responses = showStatus(user: command.user, remainder: command.remainder)
        case .guess:
            responses = guess(user: command.user, remainder: command.remainder)
        case .shuffleTeams:
            responses = shuffleTeams(user: command.user)
        case .pass:
            responses = pass(user: command.user)
        case .forcePass:
            responses = forcePass(user: command.user)
        case .endGame:
            responses = endGame(user: command.user)
        case .rotateSpyMasters:
            responses = rotateSpyMasters(user: command.user)
        case .allowSpyMaster:
            responses = allowSpyMaster(user: command.user)
        case .avoidSpyMaster:
            responses = avoidSpyMaster(user: command.user)
        case .echoPrivately:
            responses = [.ephemeralMessage(command.remainder, recipient: command.user)]
        case .unknownCommand:
            responses = [.ephemeralMessage("Unknown command `\(command.remainder)`. `help` to see available commands.", recipient: command.user)]
        default:
            responses = [.ephemeralMessage("Not ready yet", recipient: command.user)]
        }
        return ProcessResult(gameState: .codenames(state), responses: responses)
    }

    func beginGame(user: UserId) -> [ResponseAction] {
        do {
            try state.readyToStart()
            let words = try wordListGetter()
            try state.beginGame(words: words, wordShuffler: GameState.columnMinimizingShuffle)
            return [
                .message("Begins the game.", recipient: user)
                ]
                + displayBoardToChannel(state: state)
                + showSpyMasterStatus(side: .red)
                + showSpyMasterStatus(side: .blue)
        } catch GameState.StateError.invalidState {
            return [.ephemeralMessage("Cannot start game at this time. Finish the current game.", recipient: user)]
        } catch GameState.StateError.needSpyMaster {
            return [.ephemeralMessage("Cannot start game. Need a spymaster for each team.", recipient: user)]
        } catch GameState.StateError.notEnoughPlayers {
            return [.ephemeralMessage("Cannot start game. Need at least one guesser on each team.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func join(user: UserId) -> [ResponseAction] {
        let side = state.addToGame(userId: user)
        return [.message("Joins the \(side) team.", recipient: user)]
    }

    func leave(user: UserId) -> [ResponseAction] {
        if state.removeFromGame(userId: user) {
            return [.message("Leaves the game.", recipient: user)]
        } else {
            return [.ephemeralMessage("You are not playing.", recipient: user)]
        }
    }

    func becomeSpyMaster(user: UserId) -> [ResponseAction] {
        do {
            let side = try state.setSpymaster(to: user)
            return [.message("Is now spymaster for the \(side) team.", recipient: user)]
        } catch GameState.StateError.userNotPlaying {
            return [.ephemeralMessage("Please join the game first.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func rotateSpyMasters(user: UserId) -> [ResponseAction] {
        do {
            try state.rotateSpymasters()
            return [.message("Rotated spymasters.\n" + display(state: state, components: [.teams]), recipient: user)]
        } catch GameState.StateError.invalidState {
            return [.ephemeralMessage("Cannot rotate spymasters right now.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func allowSpyMaster(user: UserId) -> [ResponseAction] {
        do {
            try state.setAvoidSpyMaster(for: user, avoid: false)
            return [.message("Is no longer avoiding being SpyMaster.", recipient: user)]
        } catch GameState.StateError.userNotPlaying {
            return [.ephemeralMessage("Please join the game first.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func avoidSpyMaster(user: UserId) -> [ResponseAction] {
        do {
            try state.setAvoidSpyMaster(for: user, avoid: true)
            return [.message("Is now avoiding being SpyMaster.", recipient: user)]
        } catch GameState.StateError.userNotPlaying {
            return [.ephemeralMessage("Please join the game first.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func showStatus(user: UserId, remainder: String) -> [ResponseAction] {
        switch state.state {
        case .setup:
            if remainder.lowercased() == "public" {
                return [.message("Requested `status public`.\n\n" + display(state: state, components: [.teams, .pendingAction(statusButton: true)]), recipient: user)]
            } else {
                return [.ephemeralMessage(display(state: state, components: [.teams, .pendingAction(statusButton: false)]), recipient: user)]
            }
        case .gameOver:
            return [.ephemeralMessage(display(state: state, components: [.clues, .remainingWords, .board(spyMasterView: true), .pendingAction(statusButton: false)]), recipient: user)]
        case .waitingForClue,
             .waitingForGuesses:
            let spyMaster = state.isSpyMaster(user)
            return [
                .ephemeralMessage(
                    display(
                        state: state,
                        components: [
                            .teams,
                            .clues,
                            .remainingWords,
                            .board(spyMasterView: spyMaster),
                            .pendingAction(statusButton: false)
                    ]),
                    recipient: user)
            ]
        }
    }

    enum DisplayComponent {
        case teams
        case clues
        case remainingWords
        case board(spyMasterView: Bool)
        case pendingAction(statusButton: Bool)
    }

    func display(state: GameState, components: [DisplayComponent]) -> String {
        return components.map { component -> String in
            switch component {
            case .teams: return teams(state: state)
            case .clues: return givenClues(state: state)
            case .remainingWords: return remainingWords(state: state)
            case .board(let spyMasterView): return board(state: state, spyMasterView: spyMasterView)
            case .pendingAction: return pendingAction(state: state)
            }
        }
        .joined(separator: "\n\n")
    }

    func displayBlocks(state: GameState, components: [DisplayComponent]) -> Blocks {
        return Blocks(components.map { component -> Section in
            switch component {
            case .teams:
                return Section(text: teams(state: state))
            case .clues:
                return givenCluesAsFields(state: state)
            case .remainingWords:
                return Section(text: remainingWords(state: state))
            case .board(let spyMasterView):
                return Section(text: board(state: state, spyMasterView: spyMasterView))
            case .pendingAction(let statusButton):
                if statusButton {
                    if case .gameOver = state.state {
                        return Section(text: pendingAction(state: state),
                                       accessory: Button(text: "Final State",
                                                         actionId: "echoPrivately",
                                                         value: display(state: state,
                                                                        components: [
                                                                            .teams,
                                                                            .clues,
                                                                            .remainingWords,
                                                                            .board(spyMasterView: true),
                                                                            .pendingAction(statusButton: false)
                                                         ]),
                                                         style: .primary))
                    } else {
                        return Section(text: pendingAction(state: state),
                                       accessory: Button(text: "Status", actionId: "status", style: .primary))
                    }
                } else {
                    return Section(text: pendingAction(state: state))
                }
            }
        })
    }

    func pendingAction(state: GameState) -> String {
        switch state.state {
        case .setup:
            return "Waiting for game to start."
        case let .gameOver(winningSide: winningSide, winningPlayers: winningPlayers, losingPlayers: _):
            let winners = winningPlayers.mentionForms().joined(separator: ", ")
            return "*GAME OVER!* Team \(winningSide) wins!. Congratulations to \(winners)."
        case let .waitingForClue(side: side):
            if let spyMaster = state.spyMaster(for: side) {
                return "SpyMaster \(spyMaster.mentionForm()) should give a clue to the \(side) team."
            } else {
                return "The \(side) team needs to give a clue, but does not currently have a SpyMaster."
            }
        case let .waitingForGuesses(side: side, clue: clue, cluedGuesses: numberClued, guessesTaken: numberGuessed):
            let guessers = state.guessers(for: side).mentionForms().joined(separator: ", ")
            let displayPlayers = "Players on the \(side) team (\(guessers)) should guess a word."
            let displayClue = "\"\(clue)\" for \(numberClued.clueDisplayValue())"
            if numberClued == 0 || numberClued == 99 {
                return "\(displayPlayers) The clue is \(displayClue)."
            } else {
                let numberRemaining = numberGuessed < numberClued
                    ? "\(numberClued - numberGuessed) (+1)"
                    : "1 extra guess"
                return "\(displayPlayers) They have \(numberRemaining) left for \(displayClue)."
            }
        }
    }

    func showSpyMasterStatus(side: GameState.Side) -> [ResponseAction] {
        if let spyMaster = state.spyMaster(for: side) {
            return [.ephemeralMessage(board(state: state, spyMasterView: true), recipient: spyMaster)]
        } else {
            return []
        }
    }

    private func displayBoardToChannel(state: GameState) -> [ResponseAction] {
        return [
            .message(
                display(
                    state: state,
                    components: [
                        .clues,
                        .remainingWords,
                        .board(spyMasterView: false)
                ]),
                recipient: nil),
            .messageBlock(
                displayBlocks(
                    state: state,
                    components: [
                        .pendingAction(statusButton: true)
                ]),
                message: pendingAction(state: state),
                recipient: nil)
        ]
    }

    func giveClue(user: UserId, remainder: String) -> [ResponseAction] {
        let components = remainder.components(separatedBy: " ")
        guard components.count == 2 else {
            return [.ephemeralMessage("Expected a clue followed by a number or unlimited.", recipient: user)]
        }
        let count: Int
        if components[1].lowercased() == "unlimited" {
            count = 99
        } else if let clueCount = Int(components[1]),
            clueCount >= 0 {
            count = clueCount < 10 ? clueCount : 99
        } else {
            return [.ephemeralMessage("Expected a clue followed by a number or unlimited.", recipient: user)]
        }
        let clue = components[0]
        do {
            try state.acceptClue(clue: clue, count: count, from: user)
        } catch GameState.StateError.invalidState {
            return [.ephemeralMessage("Can not give a clue at this time.", recipient: user)]
        } catch GameState.StateError.userNotPlaying {
            return [.ephemeralMessage("Please join the game first.", recipient: user)]
        } catch GameState.StateError.wrongTurn {
            return [.ephemeralMessage("It isn't your team's turn.", recipient: user)]
        } catch GameState.StateError.playerIsNotSpyMaster {
            return [.ephemeralMessage("You are not the spymaster.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
        return [
            .message("Gave clue `\(clue)` for `\(count.clueDisplayValue())`", recipient: user)
            ]
            + displayBoardToChannel(state: state)
    }

    func guess(user: UserId, remainder: String) -> [ResponseAction] {
        let guess = remainder.uppercased()
        do {
            let (result, wordSide) = try state.acceptGuess(guess: guess, from: user)
            let guessResult = "Guessed `\(guess)`. It was \(wordSide)."
            let notifySpyMaster: [ResponseAction] = result == .wrong
                ? showSpyMasterStatus(side: wordSide)
                : []
            return [
                .message(guessResult, recipient: user)
                ]
                + displayBoardToChannel(state: state)
                + notifySpyMaster
        } catch GameState.StateError.invalidState {
            return [.ephemeralMessage("Can not guess at this time.", recipient: user)]
        } catch GameState.StateError.userNotPlaying {
            return [.ephemeralMessage("Please join the game first.", recipient: user)]
        } catch GameState.StateError.wrongTurn {
            return [.ephemeralMessage("It isn't your team's turn.", recipient: user)]
        } catch GameState.StateError.playerIsNotGuesser {
            return [.ephemeralMessage("You are not a guesser.", recipient: user)]
        } catch GameState.StateError.wordAlreadyGuessed {
            return [.ephemeralMessage("`\(guess)` was already guessed.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func pass(user: UserId) -> [ResponseAction] {
        do {
            let side = try state.passTurn(from: user)
            return [
                .message("Passes.", recipient: user)
                ]
                + displayBoardToChannel(state: state)
                + showSpyMasterStatus(side: side)
        } catch GameState.StateError.invalidState {
            return [.ephemeralMessage("Can not pass at this time.", recipient: user)]
        } catch GameState.StateError.userNotPlaying {
            return [.ephemeralMessage("Please join the game first.", recipient: user)]
        } catch GameState.StateError.wrongTurn {
            return [.ephemeralMessage("It isn't your team's turn.", recipient: user)]
        } catch GameState.StateError.playerIsNotGuesser {
            return [.ephemeralMessage("You are not a guesser.", recipient: user)]
        } catch GameState.StateError.mustGuessOneWord {
            return [.message("Tried to pass, but you must guess at least one word first.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func forcePass(user: UserId) -> [ResponseAction] {
        do {
            let side = try state.passTurn(from: user, force: true)
            return [
                .message("Force passes to the other team.", recipient: user)
                ]
                + displayBoardToChannel(state: state)
                + showSpyMasterStatus(side: side)
        } catch GameState.StateError.invalidState {
            return [.ephemeralMessage("Can not pass at this time.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
    }

    func shuffleTeams(user: UserId) -> [ResponseAction] {
        do {
            try state.shuffleTeams()
        } catch GameState.StateError.invalidState {
            return [.ephemeralMessage("Cannot shuffle teams at this time.", recipient: user)]
        } catch {
            return unexpectedError(error, user: user)
        }
        return [
            .ephemeralMessage(display(state: state, components: [.teams]), recipient: user)
        ]
    }

    func endGame(user: UserId) -> [ResponseAction] {
        state.reset()
        return [.message("Ended the game.", recipient: user)]
    }

    func unexpectedError(_ error: Error, user: UserId) -> [ResponseAction] {
        return [.ephemeralMessage("Unexpected error. \(error)", recipient: user)]
    }

    let help = """
Codenames module of gamebot
 - `status`, `s` : Show current game status. Add `public` to broadcast to channel. This will @mention all players.
 - `join` : Join team or swap teams.
 - `leave` : Leave the game.
 - `become spymaster` : Become spymaster of your team.
 - `rotate spymasters` : Assign the next player on the team as spymaster. This will happen automatically if you `begin game` at the end of a previous game.
 - `shuffle teams` : Randomly assign teams and spymasters. Use `status public` to broadcast to the channel when you see a combination you like.
 - `begin game` : Start a new game.
 - `give clue <clue> <number>` : Give a clue as spymaster.
 - `guess <word>` : Guess a word as a guesser.
 - `pass` : Pass your turn.
 - `force pass` : Force the turn to end.
 - `end game` : Force the game to end.
 - `avoid|allow spymaster` : Control if you can be shuffled into spymaster.
 - `reset everything` : End game and remove all players. (Not ready yet)
"""
}

extension UserId {
    func mentionForm() -> String {
        "<@\(id)>"
    }
}

extension Array where Element == UserId {
    func mentionForms() -> [String] {
        self.map { $0.mentionForm() }
    }
}

extension Int {
    func clueDisplayValue() -> String {
        if self == 99 {
            return "unlimited"
        } else {
            return "\(self)"
        }
    }
}
