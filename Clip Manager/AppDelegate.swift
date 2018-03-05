//
//  AppDelegate.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 24/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa
import AppKit

let SaveResponse = NSApplication.ModalResponse.alertFirstButtonReturn
let DontSaveResponse = NSApplication.ModalResponse.alertSecondButtonReturn

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet weak var playMenu: NSMenu!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		NSLog("Starting SoundManager: %@", SoundManager.default)

		for index in 0..<SoundManager.default.numClips {
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
				SoundManager.default.toggleClipForIndex(index)
			}
		}
	}

	func openListFromFilePath(_ filePath: URL) -> [String: [String: String?]]? {
		do {
			let data = try Data(contentsOf: filePath)
			let listData = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)

			if let output = listData as? [String: [String: String?]] {
				return output
			}
		}

		catch {
			print("Unexpected error during list open: \(error)")
		}

		return nil
	}

	func saveListToFilePath(_ filePath: URL) {
		let data = SoundManager.default.exportClips()

		do {
			let output = try PropertyListSerialization.data(fromPropertyList: data as NSDictionary, format: .xml, options: 0)
			try output.write(to: filePath)

			SoundManager.default.listFilePath = filePath
			SoundManager.default.listIsDirty = false
			return
		}

		catch {
			print("Unexpected error during list save: \(error)")
		}

		let alert = NSAlert()
		alert.messageText = "Could Not Write to File"
		alert.informativeText = "Please try again."
		alert.runModal()
	}

	func confirmBeforeLeavingUnsaved(title: String) -> Bool {
		if !SoundManager.default.listIsDirty {
			return true
		}

		let alert = NSAlert()
		alert.messageText = title
		alert.informativeText = "Do you want to save your current clip list?"

		alert.addButton(withTitle: "Save")
		alert.addButton(withTitle: "Don't Save")
		alert.addButton(withTitle: "Cancel")

		let response = alert.runModal()

		if response == SaveResponse {
			saveListMenuItemClick(self)
			return true
		}

		else if response == DontSaveResponse {
			return true
		}

		return false
	}

	@IBAction func newListMenuItemClick(_ sender: Any) {
		if confirmBeforeLeavingUnsaved(title: "New List") {
			SoundManager.default.clearClips()
		}
	}

	@IBAction func openListMenuItemClick(_ sender: Any) {
		if confirmBeforeLeavingUnsaved(title: "Open List") {
			let dialog = NSOpenPanel()

			dialog.title                   = "Choose a List File"
			dialog.showsResizeIndicator    = true
			dialog.showsHiddenFiles        = false
			dialog.canChooseDirectories    = false
			dialog.canCreateDirectories    = true
			dialog.allowsMultipleSelection = false
			dialog.allowedFileTypes        = ["clips"]

			if dialog.runModal() == NSApplication.ModalResponse.OK {
				let result = dialog.url

				if let filePath = result {
					let optData = openListFromFilePath(filePath)

					if let data = optData {
						SoundManager.default.listFilePath = filePath
						SoundManager.default.importClips(data)
					}

					else {
						let alert = NSAlert()
						alert.messageText = "Invalid List File"
						alert.informativeText = "Please try again and select another file."
						alert.runModal()
					}
				}
			}
		}
	}

	@IBAction func saveListMenuItemClick(_ sender: Any) {
		if !SoundManager.default.listIsDirty {
			return
		}

		if let currentFilePath = SoundManager.default.listFilePath {
			saveListToFilePath(currentFilePath)
		}

		else {
			saveListAsMenuItemClick(sender)
		}
	}

	@IBAction func saveListAsMenuItemClick(_ sender: Any) {
		if !SoundManager.default.listIsDirty {
			return
		}

		let dialog = NSSavePanel()

		dialog.title                   = "Save List File"
		dialog.showsResizeIndicator    = true
		dialog.showsHiddenFiles        = false
		dialog.canCreateDirectories    = true
		dialog.allowedFileTypes        = ["clips"]

		let result = dialog.runModal()

		if result == NSApplication.ModalResponse.OK {
			let result = dialog.url

			if let filePath = result {
				saveListToFilePath(filePath)
			}
		}
	}
}
