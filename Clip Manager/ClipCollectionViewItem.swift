//
//  ClipCollectionViewItem.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 28/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa
import AVFoundation
import AMCoreAudio

let DEFAULT_DEVICE_LABEL = "Default device"
let ALMOST_DONE_SECONDS: TimeInterval = 10.0

let progressColor = NSColor(white: 1.0, alpha: 1.0)
let almostDoneColor = NSColor(red: 1.0, green: 0.933333, blue: 0.4, alpha: 1.0)
let deviceColor = NSColor(red: 0.25, green: 0.25, blue: 1.0, alpha: 1.0)

class ClipCollectionViewItem: NSCollectionViewItem, NSDraggingDestination, SoundManagerProgressDelegate, EventSubscriber {
	@IBOutlet weak var numberField: NSTextField!
	@IBOutlet weak var progressField: NSTextField!
	@IBOutlet weak var audioPopUpButton: NSPopUpButton!
	@IBOutlet weak var progressBox: NSBox!
	@IBOutlet weak var progressBoxWidth: NSLayoutConstraint!

	var clip: Clip? {
		didSet {
			guard isViewLoaded else { return }
			DispatchQueue.main.async {
				self.updateDataView()
			}
		}
	}

	var index: Int? {
		didSet {
			guard isViewLoaded else { return }
			DispatchQueue.main.async {
				if let view = self.view as? ClipCollectionViewItemView {
					view.index = self.index
				}

				self.updateDataView()
			}
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do view setup here.
		view.wantsLayer = true

		// Register audio hardware change events
		NotificationCenter.defaultCenter.subscribe(self, eventType: AudioHardwareEvent.self)
	}

	override func viewWillAppear() {
		super.viewWillAppear()
		updateDataView()
	}

	override func viewWillDisappear() {
		// Unregister events when view disappears
		NotificationCenter.defaultCenter.unsubscribe(self, eventType: AudioHardwareEvent.self)
	}

	func updateDataView() {
		if let currentIndex = index {
			numberField.stringValue = String(describing: 1 + currentIndex)
		}

		audioPopUpButton.removeAllItems()
		audioPopUpButton.addItem(withTitle: DEFAULT_DEVICE_LABEL)
		audioPopUpButton.addItems(withTitles: SoundManager.default.outputDeviceIds())

		if let theClip = clip {
			let rawClipString = "\(theClip.name) \(self.secondsToLength(seconds: Int(round(theClip.sound.duration))))"

			let clipString = NSMutableAttributedString(string: rawClipString)
			clipString.addAttribute(NSAttributedStringKey.foregroundColor, value: NSColor.controlShadowColor, range: NSMakeRange(theClip.name.unicodeScalars.count, rawClipString.unicodeScalars.count - theClip.name.unicodeScalars.count))

			textField?.attributedStringValue = clipString

			let customDeviceString = NSMutableAttributedString(attributedString: clipString)
			customDeviceString.addAttribute(NSAttributedStringKey.foregroundColor, value: deviceColor, range: NSMakeRange(0, theClip.name.unicodeScalars.count))

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

			if #available(OSX 10.13, *) {
				audioPopUpButton.isEnabled = true

				if let deviceUid = theClip.sound.currentDevice {
					if deviceUid == "AQDefaultOutput" {
						audioPopUpButton.selectItem(withTitle: DEFAULT_DEVICE_LABEL)
						textField?.attributedStringValue = clipString
					}

					else {
						audioPopUpButton.selectItem(withTitle: deviceUid)
						textField?.attributedStringValue = customDeviceString
					}
				}

				else {
					audioPopUpButton.selectItem(withTitle: DEFAULT_DEVICE_LABEL)
					textField?.attributedStringValue = clipString
				}
			}

			else {
				audioPopUpButton.isEnabled = false
			}
		}

		else {
			textField?.stringValue = ""
			progressField.stringValue = ""
			audioPopUpButton.isEnabled = false
			progressBox.isHidden = true
		}
	}

	@IBAction func audioPopUpClick(_ sender: Any) {
		if let currentIndex = index {
			if let value = audioPopUpButton.titleOfSelectedItem {
				if value != DEFAULT_DEVICE_LABEL {
					SoundManager.default.setDeviceForIndex(currentIndex, deviceUid: value)
					updateDataView()
					return
				}
			}

			SoundManager.default.setDeviceForIndex(currentIndex, deviceUid: nil)
			updateDataView()
		}
	}

	@IBAction func fileSelectClick(_ sender: Any) {
		if let index = self.index {
			if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
				appDelegate.openAudioFileForIndex(index)
			}
		}
	}

	func onClipProgress() {
		updateDataView()
	}

	// Events

	func eventReceiver(_ event: Event) {
		if let evt = event as? AudioHardwareEvent {
			switch evt {
			case .deviceListChanged(_, _):
				NSLog("Device list changed")
				DispatchQueue.main.async {
					if let index = self.index {
						SoundManager.default.resetDeviceIfGoneForIndex(index)
					}
					self.updateDataView()
				}
			default:
				NSLog("Received an audio hardware event")
			}
		}
	}

	// Time tools
	// TODO: Move elsewhere

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
