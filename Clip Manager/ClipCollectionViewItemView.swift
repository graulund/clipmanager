//
//  ClipCollectionViewItemView.swift
//  Clip Manager
//
//  Created by Andreas Ullits Graulund     Web og Apps on 05/03/2018.
//  Copyright © 2018 Andreas Graulund. All rights reserved.
//

import Cocoa

let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingFileURLsOnly: true]

class ClipCollectionViewItemView: NSView {
	var index: Int?

	var isReceivingDrag = false {
		didSet {
			needsDisplay = true
		}
	}

	override func draw(_ dirtyRect: NSRect) {
		super.draw(dirtyRect)

		if isReceivingDrag {
			NSColor.selectedControlColor.set()
		}

		else {
			NSColor.windowBackgroundColor.set()
		}

		let path = NSBezierPath(rect: bounds)
		path.lineWidth = 6.0
		path.stroke()
	}

	override func awakeFromNib() {
		registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: kUTTypeFileURL as String)])
	}

	override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
		return shouldAllowDrag(info: sender)
	}

	override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
		let pasteboard = sender.draggingPasteboard()

		if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: filteringOptions) as? [URL] {
			if urls.count == 1 {
				if let index = self.index {
					// TODO: Filter by file type
					SoundManager.default.setClipByURLForIndex(index, url: urls[0])
					return true
				}
			}
		}

		return false
	}

	override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
		let allow = shouldAllowDrag(info: sender)
		isReceivingDrag = allow
		return allow ? .copy : NSDragOperation()
	}

	override func draggingExited(_ sender: NSDraggingInfo?) {
		isReceivingDrag = false
	}

	override func draggingEnded(_ sender: NSDraggingInfo?) {
		isReceivingDrag = false
	}

	func shouldAllowDrag(info: NSDraggingInfo) -> Bool {
		let pasteboard = info.draggingPasteboard()
		return pasteboard.canReadObject(forClasses: [NSURL.self], options: filteringOptions)
	}
}
