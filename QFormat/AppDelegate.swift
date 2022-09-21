//
//  AppDelegate.swift
//  QFormat
//
//  Created by Benjamin Cichos on 04.08.22.
//

import Cocoa
import AppKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    weak var window: NSWindow!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @IBAction func showQFormat(_ sender: NSMenuItem) {
        window.makeKeyAndOrderFront(sender)
    }
    
}

