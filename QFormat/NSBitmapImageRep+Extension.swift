//
//  NSBitmapImageRep+Extension.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation
import AppKit

extension NSBitmapImageRep {
    var png: Data? { representation(using: .png, properties: [:]) }
    var jpeg: Data? { representation(using: .jpeg, properties: [:])}
}
