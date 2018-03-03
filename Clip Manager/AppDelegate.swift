//
//  AppDelegate.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 24/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa
import AppKit

let NUM_CLIPS = 8

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var playMenu: NSMenu!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSLog("Starting SoundManager: %@", SoundManager.defaultManager)

		for index in 0..<NUM_CLIPS {
			let number = index + 1
			let item = NSMenuItem.init(title: "Play item " + String(number), action: #selector(playItemClick), keyEquivalent: String(number))
			playMenu.addItem(item)
		}
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	@objc func playItemClick(sender: Any, forEvent event: NSEvent) {
		if let item = sender as? NSMenuItem {
			if let number = Int(item.keyEquivalent) {
				let index = number - 1
				SoundManager.defaultManager.toggleClipForIndex(index)
			}
		}
	}
}
