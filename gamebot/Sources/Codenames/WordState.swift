//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/14/19.
//

import Foundation

public struct WordState: Codable {
    var index: Int
    var words: [String]

    public init() {
        index = 0
        words = WordList.words.shuffled()
    }

    // Returns next 25 words starting from index.
    // If there are not enough words left to get 25,
    // resets and reshuffles the word list.
    public mutating func getNextBatch() -> [String] {
        if index + 25 >= words.count {
            index = 0
            words = WordList.words.shuffled()
        }
        index += 25
        return Array(words[(index - 25) ..< index])
    }
}
