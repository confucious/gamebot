import XCTest
import Codenames

final class GameStateTests: XCTestCase {
    var state: GameState!
    let words = ["A", "B", "C", "D", "E",
                 "F", "G", "H", "I", "J",
                 "K", "L", "M", "N", "O",
                 "P", "Q", "R", "S", "T",
                 "U", "V", "W", "X", "Y"]
    var board: [GameState.Word]!

    override func setUp() {
        state = GameState()
        let sides: [GameState.Side] =
            Array(repeating: .red, count: 9)
                + Array(repeating: .blue, count: 8)
                + Array(repeating: .neutral, count: 7)
                + Array(repeating: .assassin, count: 1)
        board = zip(words, sides).map { (word, side) -> GameState.Word in
            .init(word: word, side: side)
        }
    }


    func testInitialState() {
        XCTAssertEqual(state.state, .setup)
    }

    func testAddToGame() {
        state.addToGame(userId: "playerA")
        XCTAssertEqual(state.guessers(for: .red), ["playerA"])
        state.addToGame(userId: "playerB")
        XCTAssertEqual(state.guessers(for: .red), ["playerA"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerB"])
        state.addToGame(userId: "playerA")
        XCTAssertEqual(state.guessers(for: .red), [])
        XCTAssertEqual(state.guessers(for: .blue), ["playerA", "playerB"])
        state.addToGame(userId: "playerC")
        state.addToGame(userId: "playerD")
        XCTAssertEqual(state.guessers(for: .red), ["playerC", "playerD"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerA", "playerB"])
    }

    func testRemoveFromGame() {
        state.addToGame(userId: "playerA")
        state.addToGame(userId: "playerB")
        XCTAssertEqual(state.guessers(for: .red), ["playerA"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerB"])
        state.removeFromGame(userId: "playerA")
        XCTAssertEqual(state.guessers(for: .red), [])
        XCTAssertEqual(state.guessers(for: .blue), ["playerB"])
    }

    func testSetSpyMasters() {
        state.addToGame(userId: "playerA")
        state.addToGame(userId: "playerB")
        state.addToGame(userId: "playerC")
        state.addToGame(userId: "playerD")
        XCTAssertEqual(state.guessers(for: .red), ["playerA", "playerC"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerB", "playerD"])

        try! state.setSpymaster(to: "playerA")
        XCTAssertEqual(state.spyMaster(for: .red), "playerA")
        XCTAssertEqual(state.spyMaster(for: .blue), nil)
        XCTAssertEqual(state.guessers(for: .red), ["playerC"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerB", "playerD"])

        try! state.setSpymaster(to: "playerB")
        XCTAssertEqual(state.spyMaster(for: .red), "playerA")
        XCTAssertEqual(state.spyMaster(for: .blue), "playerB")
        XCTAssertEqual(state.guessers(for: .red), ["playerC"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerD"])
    }

    func testSetSpyMastersThenChangeSpyMaster() {
        testSetSpyMasters()

        try! state.setSpymaster(to: "playerC")
        XCTAssertEqual(state.spyMaster(for: .red), "playerC")
        XCTAssertEqual(state.spyMaster(for: .blue), "playerB")
        XCTAssertEqual(state.guessers(for: .red), ["playerA"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerD"])
    }

    func testSetSpyMasterThenChangeSides() {
        state.addToGame(userId: "playerA")
        state.addToGame(userId: "playerB")
        state.addToGame(userId: "playerC")
        state.addToGame(userId: "playerD")

        try! state.setSpymaster(to: "playerA")
        XCTAssertEqual(state.spyMaster(for: .red), "playerA")
        XCTAssertEqual(state.spyMaster(for: .blue), nil)
        XCTAssertEqual(state.guessers(for: .red), ["playerC"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerB", "playerD"])

        state.addToGame(userId: "playerA")
        XCTAssertEqual(state.spyMaster(for: .red), nil)
        XCTAssertEqual(state.spyMaster(for: .blue), nil)
        XCTAssertEqual(state.guessers(for: .red), ["playerC"])
        XCTAssertEqual(state.guessers(for: .blue), ["playerA", "playerB", "playerD"])
    }

    func testBeginGame() {
        testSetSpyMasters()

        try! state.beginGame(words: words)
        if case let .waitingForClue(side) = state.state {
            let remainingCounts = state.remainingCounts()
            XCTAssertEqual(remainingCounts[.assassin], 1)
            XCTAssertEqual(remainingCounts[.neutral], 7)
            XCTAssertEqual(remainingCounts[side], 9)
            XCTAssertEqual(remainingCounts[side.otherSide], 8)
        } else {
            XCTFail("state was not waitingForClue \(state.state)")
        }
    }

    func testCannotStartGameWithoutSpyMasters() {
        XCTAssertThrowsError(GameState.StateError.needSpyMaster) {
            try state.beginGame(words: words)
        }
        state.addToGame(userId: "playerA")
        try! state.setSpymaster(to: "playerA")
        XCTAssertThrowsError(GameState.StateError.needSpyMaster) {
            try state.beginGame(words: words)
        }
    }

    func testCannotStartGameWithoutAtLeastOneGuesserPerTeam() {
        state.addToGame(userId: "playerA")
        state.addToGame(userId: "playerB")
        try! state.setSpymaster(to: "playerA")
        try! state.setSpymaster(to: "playerB")
        XCTAssertThrowsError(GameState.StateError.notEnoughPlayers) {
            try state.beginGame(words: words)
        }

        state.addToGame(userId: "playerC")
        XCTAssertThrowsError(GameState.StateError.notEnoughPlayers) {
            try state.beginGame(words: words)
        }
    }

    func testShuffleTeams() {
        state.addToGame(userId: "playerA")
        state.addToGame(userId: "playerB")
        state.addToGame(userId: "playerC")
        state.addToGame(userId: "playerD")
        try! state.shuffleTeams()
        XCTAssertNotNil(state.spyMaster(for: .red), "Red team should have spymaster")
        XCTAssertNotNil(state.spyMaster(for: .blue), "Blue team should have spymaster")
        XCTAssert(state.guessers(for: .red).count > 0, "Red team should have guessers")
        XCTAssert(state.guessers(for: .blue).count > 0, "Blue team should have guessers")
    }

    func testCannotShuffleWhilePlaying() {
        state.state = .waitingForClue(side: .red)
        XCTAssertThrowsError(GameState.StateError.invalidState(.waitingForClue(side: .red))) {
            try state.shuffleTeams()
        }
        state.state = .waitingForGuesses(side: .red, clue: "", cluedGuesses: 1, guessesTaken: 0)
        XCTAssertThrowsError(GameState.StateError.invalidState(.waitingForGuesses(side: .red, clue: "", cluedGuesses: 1, guessesTaken: 0))) {
            try state.shuffleTeams()
        }
    }

    func testShuffleDuringGameOverResetsGame() {
        state.addToGame(userId: "playerA")
        state.addToGame(userId: "playerB")
        state.addToGame(userId: "playerC")
        state.addToGame(userId: "playerD")
        state.state = .gameOver(winningSide: .red, winningPlayers: [], losingPlayers: [])
        try! state.shuffleTeams()
        XCTAssertEqual(state.state, .setup)
        XCTAssertNotNil(state.spyMaster(for: .red), "Red team should have spymaster")
        XCTAssertNotNil(state.spyMaster(for: .blue), "Blue team should have spymaster")
        XCTAssert(state.guessers(for: .red).count > 0, "Red team should have guessers")
        XCTAssert(state.guessers(for: .blue).count > 0, "Blue team should have guessers")
    }

    func startGame() {
        testSetSpyMasters()
        state.words = board
        state.state = .waitingForClue(side: .red)

    }

    func testGiveClue(count: Int) {
        startGame()
        try! state.acceptClue(clue: "1", count: count, from: "playerA")
        XCTAssertEqual(state.state, .waitingForGuesses(side: .red, clue: "1", cluedGuesses: count, guessesTaken: 0))
        XCTAssertEqual(state.clues[0].word, "1")
        XCTAssertEqual(state.clues[0].side, .red)
        XCTAssertEqual(state.clues[0].count, count)
    }

    func testGiveClue() {
        testGiveClue(count: 3)
    }

    func testWrongTurnClue() {
        startGame()
        XCTAssertThrowsError(GameState.StateError.wrongTurn) {
            try state.acceptClue(clue: "1", count: 1, from: "playerB")
        }
    }

    func testOnlySpyMasterCanGiveClue() {
        startGame()
        XCTAssertThrowsError(GameState.StateError.playerIsNotSpyMaster) {
            try state.acceptClue(clue: "1", count: 1, from: "playerC")
        }
    }

    func testGive3CorrectGuesses() {
        testGiveClue()
        try! state.acceptGuess(guess: "a", from: "playerC")
        XCTAssertEqual(state.state, .waitingForGuesses(side: .red, clue: "1", cluedGuesses: 3, guessesTaken: 1))
        try! state.acceptGuess(guess: "b", from: "playerC")
        XCTAssertEqual(state.state, .waitingForGuesses(side: .red, clue: "1", cluedGuesses: 3, guessesTaken: 2))
        try! state.acceptGuess(guess: "c", from: "playerC")
        XCTAssertEqual(state.state, .waitingForGuesses(side: .red, clue: "1", cluedGuesses: 3, guessesTaken: 3))
    }

    func testGive3CorrectGuessesAndPass() {
        testGive3CorrectGuesses()
        try! state.passTurn(from: "playerC")
        XCTAssertEqual(state.state, .waitingForClue(side: .blue))
    }

    func testGive4CorrectGuesses() {
        testGive3CorrectGuesses()
        try! state.acceptGuess(guess: "d", from: "playerC")
        XCTAssertEqual(state.state, .waitingForClue(side: .blue))
    }

    func testGiveWrongGuess() {
        testGiveClue()
        try! state.acceptGuess(guess: "j", from: "playerC")
        XCTAssertEqual(state.state, .waitingForClue(side: .blue))
    }

    func testGiveAssassinGuess() {
        testGiveClue()
        try! state.acceptGuess(guess: "y", from: "playerC")
        XCTAssertEqual(state.state,
                       .gameOver(winningSide: .blue,
                                 winningPlayers: ["playerB", "playerD"],
                                 losingPlayers: ["playerA", "playerC"]))
    }

    func testGuessAllCorrect() {
        testGiveClue(count: 9)
        try! state.acceptGuess(guess: "a", from: "playerC")
        try! state.acceptGuess(guess: "b", from: "playerC")
        try! state.acceptGuess(guess: "c", from: "playerC")
        try! state.acceptGuess(guess: "d", from: "playerC")
        try! state.acceptGuess(guess: "e", from: "playerC")
        try! state.acceptGuess(guess: "f", from: "playerC")
        try! state.acceptGuess(guess: "g", from: "playerC")
        try! state.acceptGuess(guess: "h", from: "playerC")
        try! state.acceptGuess(guess: "i", from: "playerC")
        XCTAssertEqual(state.state,
                       .gameOver(winningSide: .red,
                                 winningPlayers: ["playerA", "playerC"],
                                 losingPlayers: ["playerB", "playerD"]))
    }

    func testGuessFinalOpponent() {
        testGiveClue(count: 7)
        try! state.acceptGuess(guess: "a", from: "playerC")
        try! state.acceptGuess(guess: "b", from: "playerC")
        try! state.acceptGuess(guess: "c", from: "playerC")
        try! state.acceptGuess(guess: "d", from: "playerC")
        try! state.acceptGuess(guess: "e", from: "playerC")
        try! state.acceptGuess(guess: "f", from: "playerC")
        try! state.acceptGuess(guess: "g", from: "playerC")
        try! state.acceptGuess(guess: "h", from: "playerC")
        XCTAssertEqual(state.state,
                       .waitingForClue(side: .blue))
        try! state.acceptClue(clue: "2", count: 1, from: "playerB")
        try! state.acceptGuess(guess: "i", from: "playerD")
        XCTAssertEqual(state.state,
                       .gameOver(winningSide: .red,
                                 winningPlayers: ["playerA", "playerC"],
                                 losingPlayers: ["playerB", "playerD"]))
    }

    func testGuessAlreadyGuessedWord() {
        testGiveClue()
        try! state.acceptGuess(guess: "a", from: "playerC")
        XCTAssertThrowsError(GameState.StateError.wordAlreadyGuessed("a")) {
            try state.acceptGuess(guess: "a", from: "playerC")
        }
    }

    func testWrongTurnGuess() {
        testGiveClue()
        XCTAssertThrowsError(GameState.StateError.wrongTurn) {
            try state.acceptGuess(guess: "d", from: "playerD")
        }
    }

    func testOnlyGuessersCanGuess() {
        testGiveClue()
        XCTAssertThrowsError(GameState.StateError.playerIsNotGuesser) {
            try state.acceptGuess(guess: "a", from: "playerA")
        }
    }

    func testUnknownWordGuessed() {
        testGiveClue()
        XCTAssertThrowsError(GameState.StateError.unknownWord("z")) {
            try state.acceptGuess(guess: "z", from: "playerC")
        }
    }

    func testPassTurn() {
        testGiveClue()
        try! state.acceptGuess(guess: "a", from: "playerC")
        try! state.passTurn(from: "playerC")
        XCTAssertEqual(state.state, .waitingForClue(side: .blue))
    }

    func testCannotPassTurn() {
        testGiveClue()
        XCTAssertThrowsError(GameState.StateError.mustGuessOneWord) {
            try state.passTurn(from: "playerC")
        }
    }

    func testWrongTeamPassTurn() {
        testGiveClue()
        XCTAssertThrowsError(GameState.StateError.wrongTurn) {
            try state.passTurn(from: "playerD")
        }
    }

    func testOnlyGuesserCanPass() {
        testGiveClue()
        XCTAssertThrowsError(GameState.StateError.playerIsNotGuesser) {
            try state.passTurn(from: "playerA")
        }
    }

    func testForcedPassTurn() {
        testGiveClue()
        try! state.passTurn(from: "playerA", force: true)
        XCTAssertEqual(state.state, .waitingForClue(side: .blue))
        try! state.passTurn(from: "playerC", force: true)
        XCTAssertEqual(state.state, .waitingForClue(side: .red))
    }

    func testIllegalActionsBeforeGameStart() {
        XCTAssertThrowsError(GameState.StateError.invalidState(.setup)) {
            try state.acceptClue(clue: "1", count: 1, from: "playerA")
        }
        XCTAssertThrowsError(GameState.StateError.invalidState(.setup)) {
            try state.acceptGuess(guess: "a", from: "playerA")
        }
        XCTAssertThrowsError(GameState.StateError.invalidState(.setup)) {
            try state.passTurn(from: "playerA")
        }
        XCTAssertThrowsError(GameState.StateError.invalidState(.setup)) {
            try state.passTurn(from: "playerA")
        }
    }
}

func XCTAssertThrowsError<T: Error & Equatable>(_ expectedError: T, message: String = "", file: StaticString = #file, line: UInt = #line, block: () throws -> ()) {
    do {
        try block()
    } catch {
        guard let actualError = error as? T else {
            XCTFail("\(message): error \(error) could not be typecasted to expected type.", file: file, line: line)
            return
        }
        XCTAssertEqual(actualError, expectedError, message, file: file, line: line)
    }
}
