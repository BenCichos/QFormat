//
//  UInt32+Extension.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation

extension UInt32 {
    init(_ str: String) {
        self.init(Character(str).asciiValue.unsafelyUnwrapped)
    }
}
