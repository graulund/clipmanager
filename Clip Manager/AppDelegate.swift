//
//  AppDelegate.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 24/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSLog("Starting SoundManager: %@", SoundManager.defaultManager)
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}
}
