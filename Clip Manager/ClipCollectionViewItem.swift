//
//  ClipCollectionViewItem.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 28/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa

let DEFAULT_DEVICE_LABEL = "Default device"

class ClipCollectionViewItem: NSCollectionViewItem {
	@IBOutlet weak var numberField: NSTextField!
	@IBOutlet weak var progressField: NSTextField!
	@IBOutlet weak var audioPopUpButton: NSPopUpButton!
	
	var clip: Clip? {
		didSet {
			guard isViewLoaded else { return }
			updateDataView()
		}
	}
	
	var index: Int? {
		didSet {
			guard isViewLoaded else { return }
			updateDataView()
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
		view.wantsLayer = true
    }
	
	override func viewWillAppear() {
		super.viewWillAppear()
		updateDataView()
	}
	
	func updateDataView() {
		if let currentIndex = index {
			numberField.stringValue = String(describing: 1 + currentIndex)
		}
		
		if let theClip = clip {
			textField?.stringValue = theClip.name
			audioPopUpButton.isEnabled = true
			
			if theClip.playing {
				let secsLeft = Int(max(0.0, theClip.sound.duration - theClip.sound.currentTime))
				progressField.stringValue = "-\(self.secondsToLength(seconds: secsLeft))"
			}
			
			else {
				progressField.stringValue = ""
			}
		}
			
		else {
			textField?.stringValue = ""
			progressField.stringValue = ""
			audioPopUpButton.isEnabled = false
		}
		
		audioPopUpButton.removeAllItems()
		audioPopUpButton.addItem(withTitle: DEFAULT_DEVICE_LABEL)
		audioPopUpButton.addItems(withTitles: SoundManager.defaultManager.outputDeviceIds())
	}
	
	@IBAction func audioPopUpClick(_ sender: Any) {
		if let currentIndex = index {
			if let value = audioPopUpButton.titleOfSelectedItem {
				if value != DEFAULT_DEVICE_LABEL {
					SoundManager.defaultManager.setDeviceForIndex(currentIndex, deviceUid: value)
					return
				}
			}
			
			SoundManager.defaultManager.setDeviceForIndex(currentIndex, deviceUid: nil)
		}
	}
	
	@IBAction func fileSelectClick(_ sender: Any) {
		let dialog = NSOpenPanel()
		
		dialog.title                   = "Choose an audio file"
		dialog.showsResizeIndicator    = true
		dialog.showsHiddenFiles        = false
		dialog.canChooseDirectories    = false
		dialog.canCreateDirectories    = true
		dialog.allowsMultipleSelection = false
		dialog.allowedFileTypes        = ["mp3", "wav", "aiff", "aac", "m4a", "caf"]
		
		if dialog.runModal() == NSApplication.ModalResponse.OK {
			let optResult = dialog.url // Pathname of the file
			
			if let result = optResult {
				self.selectSound(url: result)
			}
		}
	}
	
	func selectSound(url: URL) {
		let optSound = NSSound(contentsOf: url, byReference: false)
		
		if let sound = optSound, let i = index {
			print("Set the sound", sound.duration)
			let clip = Clip(url: url, sound: sound)
			SoundManager.defaultManager.setClipForIndex(i, clip: clip)
		}
			
		else {
			print("No sound :(")
		}
	}
	
	// Time tools
	
	func formatTime(seconds: Int) -> [String: Int] {
		var s = seconds
		let hours = s / 3600
		s = s % 3600
		let minutes = seconds / 60
		s = s % 60
		return ["hours": hours, "minutes": minutes, "seconds": s]
	}
	
	func secondsToLength(seconds: Int) -> String {
		var t = self.formatTime(seconds: seconds)
		
		if let secs = t["seconds"] {
			let minutes = t["minutes"] != nil ? t["minutes"]! : 0
			if let hours = t["hours"] {
				if hours > 0 {
					return String(format: "\(hours):%02d:%02d", minutes, secs)
				}
			}
			return String(format: "\(minutes):%02d", secs)
		}
		
		return ""
	}
}
