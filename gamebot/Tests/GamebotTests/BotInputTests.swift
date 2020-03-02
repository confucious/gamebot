import XCTest
@testable import GamebotLib
import Codenames
import SlackModels

final class BotInputTests: XCTestCase {
    var wordListGetter: (() -> [String])!
    override func setUp() {
        wordListGetter = {
            ["A2", "B", "C", "D", "E",
            "F", "G", "H", "I", "J",
            "K", "L", "M", "N", "O",
            "P", "Q", "R", "S", "T",
            "U", "V", "W", "X", "Y"]
        }
        GameState.wordSideShuffler = {
            Array(repeating: .red, count: 9)
                + Array(repeating: .blue, count: 8)
                + Array(repeating: .neutral, count: 7)
                + [.assassin]
        }
    }

//    func testBeginGame() {
//        let bot = CodenamesBot(state: GameState(), wordListGetter: wordListGetter)
//        XCTAssertEqual(bot.command("join", from: "a"), [.message("You have joined the red team.", recipient: "a")])
//        XCTAssertEqual(bot.command("join", from: "b"), [.message("You have joined the blue team.", recipient: "b")])
//        XCTAssertEqual(bot.command("join", from: "c"), [.message("You have joined the red team.", recipient: "c")])
//        XCTAssertEqual(bot.command("join", from: "d"), [.message("You have joined the blue team.", recipient: "d")])
//        XCTAssertEqual(bot.command("become spymaster", from: "a"), [.message("You are now spymaster for the red team.", recipient: "a")])
//        XCTAssertEqual(bot.command("become spymaster", from: "b"), [.message("You are now spymaster for the blue team.", recipient: "b")])
//        let expectedPublic = """
//        :cn-unknown:`A` :cn-unknown:`B` :cn-unknown:`C` :cn-unknown:`D` :cn-unknown:`E`
//        :cn-unknown:`F` :cn-unknown:`G` :cn-unknown:`H` :cn-unknown:`I` :cn-unknown:`J`
//        :cn-unknown:`K` :cn-unknown:`L` :cn-unknown:`M` :cn-unknown:`N` :cn-unknown:`O`
//        :cn-unknown:`P` :cn-unknown:`Q` :cn-unknown:`R` :cn-unknown:`S` :cn-unknown:`T`
//        :cn-unknown:`U` :cn-unknown:`V` :cn-unknown:`W` :cn-unknown:`X` :cn-unknown:`Y`
//        """
//        let expectedSpyMaster = """
//        :cn-red:`A` :cn-red:`B` :cn-red:`C` :cn-red:`D` :cn-red:`E`
//        :cn-red:`F` :cn-red:`G` :cn-red:`H` :cn-red:`I` :cn-blue:`J`
//        :cn-blue:`K` :cn-blue:`L` :cn-blue:`M` :cn-blue:`N` :cn-blue:`O`
//        :cn-blue:`P` :cn-blue:`Q` :cn-neutral:`R` :cn-neutral:`S` :cn-neutral:`T`
//        :cn-neutral:`U` :cn-neutral:`V` :cn-neutral:`W` :cn-neutral:`X` :cn-kill:`Y`
//        """
//        let actual = bot.command("begin game", from: "a")
//        let expected: [GamebotLib.ResponseAction] = [
//            .message(expectedPublic, recipient: nil),
//            .ephemeralMessage(expectedSpyMaster, recipient: "a"),
//            .ephemeralMessage(expectedSpyMaster, recipient: "b")
//        ]
//        zip(actual, expected).forEach {
//            XCTAssertEqual($0, $1)
//        }
//    }
}

extension CodenamesBot {
    func command(_ input: String, from user: UserId) -> [ResponseAction] {
        return self.process(command: parser.getCommand(from: message(input, from: user))!).responses
    }
}

private func message(_ message: String, from user: UserId = "") -> Input {
    return Input(type: .message(message), user: user)
}

