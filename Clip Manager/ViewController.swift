//
//  ViewController.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 24/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

	@IBOutlet weak var filenameField: NSTextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func browseFile(_ sender: Any) {
		let dialog = NSOpenPanel();
		
		dialog.title                   = "Choose an audio file";
		dialog.showsResizeIndicator    = true;
		dialog.showsHiddenFiles        = false;
		dialog.canChooseDirectories    = false;
		dialog.canCreateDirectories    = true;
		dialog.allowsMultipleSelection = false;
		dialog.allowedFileTypes        = ["mp3", "wav", "aiff", "aac", "m4a", "caf"];
		
		if (dialog.runModal() == NSApplication.ModalResponse.OK) {
			let optResult = dialog.url // Pathname of the file
			
			if let result = optResult {
				let path = result.path
				filenameField.stringValue = path
				self.playSound(url: result)
			}
		} else {
			// User clicked on "Cancel"
			return
		}
	}
	
	func playSound(url: URL) {
		let optData = try? Data(contentsOf: url)
		
		guard let data = optData else {
			print("AaaaaaaaaA")
			return
		}
		
		//let sound = NSSound(named: NSSound.Name("Blow"))
		let optSound = NSSound(data: data)
		
		if let sound = optSound {
			print("Set the sound", sound.duration)
			SoundManager.defaultManager.setSoundForIndex(1, sound: sound)
		}
			
		else {
			print("No sound :(")
		}
	}
	
}

