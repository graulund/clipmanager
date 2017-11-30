//
//  ClipCollectionViewItem.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 28/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa

let DEFAULT_DEVICE_LABEL = "Default device"
let ALMOST_DONE_SECONDS: TimeInterval = 10.0

let progressColor = NSColor(white: 1.0, alpha: 1.0)
let almostDoneColor = NSColor(red: 1.0, green: 0.933333, blue: 0.4, alpha: 1.0)

class ClipCollectionViewItem: NSCollectionViewItem, SoundManagerProgressDelegate {
	@IBOutlet weak var numberField: NSTextField!
	@IBOutlet weak var progressField: NSTextField!
	@IBOutlet weak var audioPopUpButton: NSPopUpButton!
	@IBOutlet weak var progressBox: NSBox!
	@IBOutlet weak var progressBoxWidth: NSLayoutConstraint!
	
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
				let secsLeft = max(0.0, theClip.sound.duration - theClip.sound.currentTime)
				progressField.stringValue = "-\(self.secondsToLength(seconds: Int(round(secsLeft))))"
				
				if secsLeft <= ALMOST_DONE_SECONDS {
					progressBox.fillColor = almostDoneColor
				}
				
				else {
					progressBox.fillColor = progressColor
				}
				
				let newWidth = theClip.sound.currentTime / theClip.sound.duration * Double(view.frame.width)
				progressBoxWidth.constant = CGFloat(newWidth)
				progressBox.isHidden = false
			}
			
			else {
				progressField.stringValue = ""
				progressBox.isHidden = true
			}
		}
			
		else {
			textField?.stringValue = ""
			progressField.stringValue = ""
			audioPopUpButton.isEnabled = false
			progressBox.isHidden = true
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
					audioPopUpButton.setTitle(value)
					return
				}
			}
			
			SoundManager.defaultManager.setDeviceForIndex(currentIndex, deviceUid: nil)
			audioPopUpButton.setTitle(DEFAULT_DEVICE_LABEL)
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
		let optData = try? Data(contentsOf: url)
		//let optSound = NSSound(contentsOf: url, byReference: false)
		
		guard let data = optData else {
			return
		}
		
		let optSound = NSSound(data: data)
		
		if let sound = optSound, let i = index {
			print("Set the sound", sound.duration)
			let clip = Clip(url: url, sound: sound)
			SoundManager.defaultManager.setClipForIndex(i, clip: clip)
		}
			
		else {
			print("No sound :(")
		}
	}
	
	func onClipProgress() {
		updateDataView()
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
