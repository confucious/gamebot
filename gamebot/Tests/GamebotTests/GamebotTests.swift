import XCTest
@testable import GamebotLib
import Codenames
import SlackModels

final class GamebotTests: XCTestCase {
    func testActionMapIsInReverseOrder() {
        let bot = CodenamesBot(state: GameState(), wordListGetter: { return [] })
        let commands = bot.parser.commandMap.map { $0.0 }
        let sortedCommands = Array(commands.sorted().reversed())
        XCTAssertEqual(commands, sortedCommands, "Commands should be in reverse sorted order.")
    }

    func testActionGetAction() {
        let bot = CodenamesBot(state: GameState(), wordListGetter: { return [] })
        XCTAssertEqual(bot.parser.getCommand(from: message("HELP"))!.action, .help)
        XCTAssertEqual(bot.parser.getCommand(from: message("s"))!.action, .showStatus)
        XCTAssertEqual(bot.parser.getCommand(from: message("guess Clue"))!.action, .guess)
        XCTAssertEqual(bot.parser.getCommand(from: message("guess Clue"))!.remainder, "Clue")
        XCTAssertEqual(bot.parser.getCommand(from: message("make me a sandwich"))!.action, .unknownCommand)
    }

    func testPrintButtonJson() throws {
        let bot = TestBot()
        let blocks = bot.buttonBlock()
        print(String(data: try JSONEncoder().encode(blocks), encoding: .utf8)!)
    }
}

private func message(_ message: String, from user: UserId = "") -> Input {
    return Input(type: .message(message), user: user)
}
