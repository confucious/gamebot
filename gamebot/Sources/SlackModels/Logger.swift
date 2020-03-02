//
//  File.swift
//  
//
//  Created by Jerry Hsu on 12/31/19.
//

import Foundation

public func log(_ object: Any, flush: Bool = false) {
    fputs("\(object)\n", stderr)
    if flush {
        fflush(stderr)
    }
}
