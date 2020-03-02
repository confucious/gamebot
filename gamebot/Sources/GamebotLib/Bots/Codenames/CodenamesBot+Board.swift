//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/15/19.
//

import Foundation
import Codenames
import SlackModels

extension CodenamesBot {
    enum Icon {
        static let red = ":cn-red:"
        static let blue = ":cn-blue:"
        static let neutral = ":cn-neutral:"
        static let assassin = ":cn-kill:"
        static let assassinPicked = ":cn-kill-picked:"
        static let redPicked = ":cn-red-picked:"
        static let bluePicked = ":cn-blue-picked:"
        static let neutralPicked = ":cn-neutral-picked:"
        static let unknown = ":cn-unknown:"
    }

    private func team(state: GameState, side: GameState.Side) -> String {
        return [
            "Team \(side):",
            "*SpyMaster*:",
            spyMaster(state: state, side: side),
            "*Guessers*:",
            guessers(state: state, side: side)
        ].joined(separator: " ")
    }

    func spyMaster(state: GameState, side: GameState.Side) -> String {
        return state.spyMaster(for: side).flatMap { $0.mentionForm() } ?? "_Unassigned_"
    }

    func guessers(state: GameState, side: GameState.Side) -> String {
        let guessers = state.guessers(for: side)
        return guessers.count == 0
            ? "_None_"
            : guessers.mentionForms().joined(separator: ", ")
    }

    func teams(state: GameState) -> String {
        return [
            team(state: state, side: .red),
            team(state: state, side: .blue)
        ].joined(separator: "\n")
    }

    private func remaining(count: Int, normalIcon: String, pickedIcon: String) -> String {
        if count == 0 {
            return "\(pickedIcon) all picked"
        } else {
            return Array(repeating: normalIcon, count: count).joined() + " \(count)"
        }
    }

    func remainingWords(state: GameState) -> String {
        let remainingCounts = state.remainingCounts()
        return [
            remaining(count: remainingCounts[.red], normalIcon: Icon.red, pickedIcon: Icon.redPicked),
            remaining(count: remainingCounts[.blue], normalIcon: Icon.blue, pickedIcon: Icon.bluePicked),
            remaining(count: remainingCounts[.neutral], normalIcon: Icon.neutral, pickedIcon: Icon.neutralPicked),
            remaining(count: remainingCounts[.assassin], normalIcon: Icon.assassin, pickedIcon: Icon.assassinPicked)
            ].joined(separator: ", ")
    }

    func board(state: GameState, spyMasterView: Bool) -> String {
        let maxLengths = state.words.enumerated()
            .map { ($0, $1.word.count) }
            .reduce(into: [0, 0, 0, 0, 0]) { (result, indexedCount) in
                let (index, count) = indexedCount
                let bucket = index % 5
                result[bucket] = max(result[bucket], count)
        }
        return state.words.enumerated()
            .map { (index, word) -> String in
                let icon: String
                if word.guessed {
                    switch word.side {
                    case .red: icon = Icon.redPicked
                    case .blue: icon = Icon.bluePicked
                    case .neutral: icon = Icon.neutralPicked
                    case .assassin: icon = Icon.assassinPicked
                    }
                } else if spyMasterView {
                    switch word.side {
                    case .red: icon = Icon.red
                    case .blue: icon = Icon.blue
                    case .neutral: icon = Icon.neutral
                    case .assassin: icon = Icon.assassin
                    }
                } else {
                    icon = Icon.unknown
                }
                return icon
                    + "`"
                    + word.word
                    + String(repeating: " ", count: maxLengths[index % 5] - word.word.count)
                    + "`"
        }
        .chunked(by: 5).map { $0.joined(separator: " ") }
        .joined(separator: "\n")
    }

    private func teamClues(
        _ clues: DefaultingDictionary<GameState.Side, [GameState.Clue]>,
        side: GameState.Side) -> String? {
        let sideClues = clues[side]
        if sideClues.isEmpty {
            return nil
        }
        let formatted = sideClues.enumerated().map { (index, clue) -> String in
            "\(index + 1): \"\(clue.word)\" for \(clue.displayCount)"
        }
        return (["\(side) clues:"] + formatted).joined(separator: "\n")
    }

    func givenClues(state: GameState) -> String {
        let clues = state.givenClues()
        return [teamClues(clues, side: .red), teamClues(clues, side: .blue)].compactMap { $0 }.joined(separator: "\n\n")
    }

    func givenCluesAsFields(state: GameState) -> Section {
        let clues = state.givenClues()
        let displayClues = [teamClues(clues, side: .red), teamClues(clues, side: .blue)].compactMap { $0 }
        return Section(fields: displayClues.map { .markDown($0) })
    }

    func status(state: GameState, spyMasterView: Bool) -> String {
        let components = [
            teams(state: state),
            "",
            givenClues(state: state),
            "",
            remainingWords(state: state),
            board(state: state, spyMasterView: spyMasterView)
        ]
        return components.joined(separator: "\n")
    }
}

extension Array {
    func chunked(by chunkSize: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: chunkSize).map {
            Array(self[$0 ..< Swift.min($0 + chunkSize, self.count)])
        }
    }
}
