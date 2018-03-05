//
//  WindowController.swift
//  Clip Manager
//
//  Created by Andreas Ullits Graulund     Web og Apps on 05/03/2018.
//  Copyright © 2018 Andreas Graulund. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

	func windowShouldClose(_ sender: NSWindow) -> Bool {
		if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
			return appDelegate.confirmBeforeLeavingUnsaved(title: "Closing Clip Manager")
		}

		return true
	}
}
