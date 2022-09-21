//
//  WindowController.swift
//  QFormat
//
//  Created by Benjamin Cichos on 06.08.22.
//

import AppKit
import Cocoa

class WindowController: NSWindowController {
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        (NSApplication.shared.delegate as! AppDelegate).window = self.window
    }
    
}
