//
//  ViewController.swift
//  Clip Manager
//
//  Created by Andreas Graulund on 24/11/2017.
//  Copyright © 2017 Andreas Graulund. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, SoundManagerDelegate {

	@IBOutlet weak var collectionView: NSCollectionView!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Stay on top of clips
		SoundManager.default.delegate = self
	}

	// This method will be called everytime window is resized
	override func viewWillLayout() {
		super.viewWillLayout()

		// When we're invalidating the collection view layout
		// it will call `collectionView(_:layout:sizeForItemAt:)` method
		collectionView.collectionViewLayout?.invalidateLayout()
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	func numberOfSections(in collectionView: NSCollectionView) -> Int {
		return 1
	}

	func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
		return SoundManager.default.numClips
	}

	func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
		let item = collectionView.makeItem(
			withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ClipCollectionViewItem"),
			for: indexPath
		)
		guard let collectionViewItem = item as? ClipCollectionViewItem else { return item }

		SoundManager.default.removeProgressDelegate(collectionViewItem)

		let index = indexPath[indexPath.endIndex - 1]
		let clip = SoundManager.default.getClipForIndex(index)

		if collectionViewItem.index != index {
			collectionViewItem.index = index
			SoundManager.default.setProgressDelegateForIndex(index, delegate: collectionViewItem)
		}

		if collectionViewItem.clip !== clip {
			collectionViewItem.clip = clip
		}

		return item
	}

	func collectionView(
		_ collectionView: NSCollectionView,
		layout collectionViewLayout: NSCollectionViewLayout,
		sizeForItemAt indexPath: IndexPath
	) -> NSSize {
		// Here we're telling that we want our cell width to
		// be equal to our collection view width
		// and height equals to 70
		return CGSize(width: collectionView.bounds.width, height: 70)
	}

	func onClipsChanged() {
		self.collectionView.reloadData()
	}

	func onDirtyStatusChanged() {
		self.view.window?.isDocumentEdited = SoundManager.default.listIsDirty
	}
}

