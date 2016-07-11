//
//  AppDelegate.swift
//  TutorOverlay main file
//
//  Created by Bert Freudenberg on 15.06.16.
//  Copyright © 2016 Bert Freudenberg. All rights reserved.
//

import Cocoa

var overlayView: OverlayView?;

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        window.styleMask = NSBorderlessWindowMask
        window.opaque = false
        window.movableByWindowBackground = false
        window.backgroundColor = NSColor.clearColor()
        window.level = Int(CGWindowLevelForKey(CGWindowLevelKey.ScreenSaverWindowLevelKey) + 1)
        window.hasShadow = false
        if let screen = NSScreen.mainScreen() {
            window.setFrame(screen.frame, display: true)
        }
        overlayView = window.contentView as? OverlayView;
        start_listening()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

