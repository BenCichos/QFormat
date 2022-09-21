//
//  NSTextField+Extension.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation
import AppKit

class InfoTextField : NSTextField {
    
    convenience init(_ stringValue: String, _ alignment: NSTextAlignment) {
        self.init()
        self.stringValue = stringValue
        self.alignment = alignment
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        configure()
    }
    
    private func configure() {
        self.isBezeled = false
        self.isEditable = false
        self.isBordered = false
        self.backgroundColor = .clear
        self.font = .systemFont(ofSize: 12)
    }
}

