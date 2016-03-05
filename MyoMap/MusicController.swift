//
//  MusicController.swift
//  MyoMap
//
//  Created by Teakay on 2016-03-05.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import Foundation
import MediaPlayer

class MusicController {
	let mp = MPMusicPlayerController.systemMusicPlayer()
	
	func play() {
		mp.play()
	}
	
	func pause() {
		mp.pause()
	}
	
	func next() {
		mp.skipToNextItem()
	}
	
	func getState() -> MPMusicPlaybackState {
		return mp.playbackState
	}
	
	func addRandomSong() {
		mp.shuffleMode = .Songs
		mp.repeatMode = .All
		let songQuery = MPMediaQuery.songsQuery()
		mp.setQueueWithQuery(songQuery)
		mp.play()
	}
}