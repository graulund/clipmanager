//
//  SoundManager.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 26/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

let MIDI_MESSAGE_NOTE_ON = 9
let MIDI_MESSAGE_NOTE_OFF = 8

import Cocoa
import CoreAudio
import CoreMIDI
import AMCoreAudio

let clipIndices: Dictionary<Int, Int> = [
	36: 0,
	37: 1,
	38: 2,
	39: 3,
	40: 4,
	41: 5,
	42: 6,
	43: 7
]

let indexNotes: Dictionary<Int, Int> = [
	0: 36,
	1: 37,
	2: 38,
	3: 39,
	4: 40,
	5: 41,
	6: 42,
	7: 43
]

func CheckError(_ error: OSStatus, _ operation: String) {
	guard error != noErr else {
		return
	}
	
	var result: String = ""
	var char = Int(error.bigEndian)
	
	for _ in 0..<4 {
		guard isprint(Int32(char&255)) == 1 else {
			result = "\(error)"
			break
		}
		result.append(String(UnicodeScalar(char&255)!))
		char = char/256
	}
	
	print("Error: \(operation) (\(result))")
	
	exit(1)
}

class SoundManager: NSObject, NSSoundDelegate {
	static let defaultManager = SoundManager()
	
	var outPort = MIDIPortRef()
	var outEndpoint = MIDIEndpointRef()
	
	var clips = Dictionary<Int, Clip>()
	private var timers = Dictionary<Int, Timer>()
	private var progressDelegates = Dictionary<Int, SoundManagerProgressDelegate>()
	
	var delegate: SoundManagerDelegate?
	
	override init() {
		super.init()
		setupMIDI()
		
		let devices = AudioDevice.allOutputDevices()
		
		NSLog("Devices: %@", devices)
		
		for device in devices {
			if let uid = device.uid {
				print(uid)
			}
		}
	}
	
	func setClipForIndex(_ index: Int, clip: Clip) {
		stopClipForIndex(index)
		clip.sound.delegate = self
		NSLog("Set sound %@ to index %d, duration %f", clip.sound, index, clip.sound.duration)
		clips[index] = clip
		clipsChanged()
	}
	
	func setDeviceForIndex(_ index: Int, deviceUid: String?) {
		if let clip = clips[index] {
			if let uid = deviceUid {
				clip.sound.playbackDeviceIdentifier = NSSound.PlaybackDeviceIdentifier(uid)
			}
			
			else {
				clip.sound.playbackDeviceIdentifier = nil
			}
		}
	}
	
	private func clipsChanged() {
		if let delg = delegate {
			DispatchQueue.main.async {
				delg.onClipsChanged()
			}
		}
	}

	private func setSoundTimerForIndex(_ index: Int) {
		if let timer = timers[index] {
			timer.invalidate()
		}
		
		let timer = Timer(timeInterval: 0.05, target: self, selector: #selector(timerTick), userInfo: NSNumber(value: Int32(index)), repeats: true)
		timers[index] = timer
		RunLoop.main.add(timer, forMode: .commonModes)
	}
	
	@objc func timerTick(_ timer: Timer) {
		if let index = timer.userInfo as? NSNumber {
			if clips[index.intValue] != nil {
				notifyProgressForIndex(index.intValue)
			}
		}
	}
	
	func sound(_ sound: NSSound, didFinishPlaying flag: Bool) {
		if let index = findIndexForSound(sound) {
			killSoundTimerForIndex(index)
			updateActivityIndicatorForIndex(index)
		}
	}
	
	private func killSoundTimerForIndex(_ index: Int) {
		if let timer = timers[index] {
			timer.invalidate()
			timers[index] = nil
		}
		
		if let clip = clips[index] {
			clip.playing = false
			notifyProgressForIndex(index)
		}
	}
	
	func findIndexForSound(_ sound: NSSound) -> Int? {
		for (index, thisClip) in clips {
			if (thisClip.sound == sound) {
				return index
			}
		}
		
		return nil
	}
	
	func getClipForIndex(_ index: Int) -> Clip? {
		return clips[index]
	}
	
	func playClipForIndex(_ index: Int) {
		if let clip = clips[index] {
			setSoundTimerForIndex(index)
			clip.sound.play()
			clip.playing = true
			notifyProgressForIndex(index)
		}
	}
	
	func stopClipForIndex(_ index: Int) {
		if let clip = clips[index] {
			clip.sound.stop()
			killSoundTimerForIndex(index)
		}
	}
	
	func toggleClipForIndex(_ index: Int) {
		if timers[index] != nil {
			stopClipForIndex(index)
		}
		
		else {
			playClipForIndex(index)
		}
	}
	
	func notifyProgressForIndex(_ index: Int) {
		if let delegate = progressDelegates[index] {
			DispatchQueue.main.async {
				delegate.onClipProgress()
			}
		}
	}
	
	func setProgressDelegateForIndex(_ index: Int, delegate: SoundManagerProgressDelegate) {
		progressDelegates[index] = delegate
	}
	
	func clipIndexForNote(_ note: Int) -> Int? {
		return clipIndices[note]
	}
	
	func onNoteDown(note: Int) {
		let optIndex = clipIndexForNote(note)
		
		if let index = optIndex {
			NSLog("Toggling clip index %d", index)
			toggleClipForIndex(index)
		}
	}
	
	func onNoteUp(note: Int) {
		let optIndex = clipIndexForNote(note)
		
		if let index = optIndex {
			NSLog("Stopped holding down key for index %d", index)
			updateActivityIndicatorForIndex(index)
		}
	}
	
	func setIndexActivityIndicator(index: Int, on: Bool) {
		if let note = indexNotes[index] {
			if outPort != 0 && outEndpoint != 0 {
				let status = on ? 0x90 : 0x80
				let dataToSend: [UInt8] = [UInt8(status), UInt8(note), UInt8(1)]
				
				var packetList = MIDIPacketList()
				var packet = MIDIPacketListInit(&packetList)
				packet = MIDIPacketListAdd(&packetList, 1024, packet, 0, 3, dataToSend)
				
				NSLog("Trying to send MIDI packet list %@", dataToSend)
				CheckError(MIDISend(outPort, outEndpoint, &packetList), "Couldn't send MIDI packet list")
			}
		}
	}
	
	func updateActivityIndicatorForIndex(_ index: Int) {
		setIndexActivityIndicator(index: index, on: timers[index] != nil)
	}
	
	private func setupMIDI() {
		let MIDINotifyCallback: MIDINotifyProc = { message, refCon in
			// TODO: Reload if messageId == 1
			print("MIDI notify, messageID=\(message.pointee.messageID.rawValue)")
		}
		
		let MIDIReadCallback: MIDIReadProc = { pktlist, refCon, connRefCon in
			var packet = pktlist.pointee.packet
			
			for _ in 0..<Int(pktlist.pointee.numPackets) {
				let midiStatus = packet.data.0
				let midiCommand = midiStatus >> 4
				
				if midiCommand == MIDI_MESSAGE_NOTE_ON || midiCommand == MIDI_MESSAGE_NOTE_OFF {
					let note = packet.data.1 & 0x7f
					let velocity = packet.data.2 & 0x7f
					print("\(midiCommand) \(note) \(velocity)")
					
					// Voodoo to retrieve the reference to the sound manager object back in here...
					let me = Unmanaged<SoundManager>.fromOpaque(refCon!).takeUnretainedValue()
					
					if midiCommand == MIDI_MESSAGE_NOTE_ON {
						me.onNoteDown(note: Int(note))
					}
					
					else {
						me.onNoteUp(note: Int(note))
					}
				}
				
				packet = MIDIPacketNext(&packet).pointee
			}
		}
		
		var client = MIDIClientRef()
		var inPort = MIDIPortRef()
		
		// Voodoo to send the reference to the sound manager in there...
		let passedSelf = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
		
		CheckError(
			MIDIClientCreate("Clip Manager" as CFString, MIDINotifyCallback, nil, &client),
			"Couldn't create MIDI client"
		)
		
		CheckError(
			MIDIInputPortCreate(client, "Clip Manager input port" as CFString, MIDIReadCallback, passedSelf, &inPort),
			"Couldn't create MIDI input port"
		)
		CheckError(
			MIDIOutputPortCreate(client, "Clip Manager output port" as CFString, &outPort),
			"Couldn't create output port"
		)
		
		let sourceCount = MIDIGetNumberOfSources()
		print("\(sourceCount) sources")
		
		for i in 0..<sourceCount {
			let src = MIDIGetSource(i)
			var endpointName: Unmanaged<CFString>?
			
			CheckError(
				MIDIObjectGetStringProperty(src, kMIDIPropertyName, &endpointName),
				"Couldn't get endpoint name"
			)
			
			print("  source \(i): \(endpointName!.takeRetainedValue() as String)")
			
			CheckError(
				MIDIPortConnectSource(inPort, src, nil),
				"Couldn't connect MIDI port"
			)
		}
		
		let destCount = MIDIGetNumberOfDestinations()
		print("\(destCount) destinations")
		
		for i in 0..<destCount {
			let dest = MIDIGetDestination(i)
			var endpointName: Unmanaged<CFString>?
			
			CheckError(
				MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &endpointName),
				"Couldn't get endpoint name"
			)
			
			print("  dest \(i): \(endpointName!.takeRetainedValue() as String)")
			outEndpoint = dest
		}
	}
	
	func outputDeviceIds() -> [String] {
		let devices = AudioDevice.allOutputDevices()
		
		var list = [String]()
		
		for device in devices {
			if let uid = device.uid {
				list.append(uid)
			}
		}
		
		return list
	}
}
