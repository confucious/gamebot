//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/7/19.
//

import Foundation

public extension Array {
    mutating func replace(index: Index, update: (Element) -> (Element)) {
        self[index] = update(self[index])
    }
}

public struct DefaultingDictionary<K: Hashable, V> {
    var dict = [K:V]()
    let defaultValue: V

    public init(defaultValue: V) {
        self.defaultValue = defaultValue
    }

    public subscript(index: K) -> V {
        get {
            return dict[index, default: defaultValue]
        }

        set {
            dict[index] = newValue
        }
    }
}

public extension Optional {
    func `do`(_ block: (Wrapped) throws -> ()) rethrows {
        if let item = self {
            try block(item)
        }
    }
}
