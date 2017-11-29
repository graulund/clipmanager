//
//  Clip.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 28/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa

class Clip: NSObject {
	var name: String
	var url: URL
	var sound: NSSound
	
	var playing = false
	
	init(url: URL, sound: NSSound) {
		self.name = url.lastPathComponent
		self.url = url
		self.sound = sound
	}
}
