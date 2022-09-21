//
//  RoundedButton.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Foundation
import AppKit

class RoundedButton: NSButton {
    @IBInspectable var backgroundColor : NSColor  = .controlAccentColor
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
            
        self.wantsLayer = true
        var color: NSColor
        
        if self.isHighlighted {
            color = .black
        } else {
            color = backgroundColor
        }
        
        self.layer?.backgroundColor = color.cgColor
        self.layer?.cornerRadius = 10
        self.isBordered = false
        self.bezelStyle = .roundRect
        self.isEnabled = true
        
        let attributedString = NSAttributedString(string: self.title, attributes: [
            .foregroundColor : NSColor.white
        ])
        
        self.attributedTitle = attributedString
    }
}


