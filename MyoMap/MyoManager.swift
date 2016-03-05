//
//  MyoManager.swift
//  MyoMap
//
//  Created by Peter Chen on 2016-03-04.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import Foundation

class MyoManager: NSObject {
	// Singleton
	static var instance: MyoManager!

	class func sharedInstance() -> MyoManager {
		self.instance = (self.instance ?? MyoManager())
		return self.instance
	}

	var connectedMyos: [TLMMyo] = []
	var currentMyo: TLMMyo? {
		return self.connectedMyos.last
	}

	var didConnectedDeviceCallback: (()->())?
	var didDisconnectedDeviceCallback: (()->())?
	var didSyncArmCallback: ((TLMArm, TLMArmXDirection)->())?
	var didUnsyncArmCallback: (()->())?
	var didUnlockDeviceCallback: (()->())?
	var didLockDeviceCallback: (()->())?
	var	didReceiveOrientationCallback: ((TLMEulerAngles)->())?
	var didReceiveAccelerometerCallback: ((TLMVector3)->())?
	var didReceivePoseChangeCallback: ((TLMPose)->())?

	// Initialization
	override init() {
		super.init()
		let center = NSNotificationCenter.defaultCenter()
		center.addObserver(self, selector: Selector("didConnectedDevice:"), name: TLMHubDidConnectDeviceNotification, object: nil)
		center.addObserver(self, selector: Selector("didDisconnectedDevice:"), name: TLMHubDidDisconnectDeviceNotification, object: nil)
		center.addObserver(self, selector: Selector("didSyncArm:"), name: TLMMyoDidReceiveArmSyncEventNotification, object: nil)
		center.addObserver(self, selector: Selector("didUnsyncArm:"), name: TLMMyoDidReceiveArmUnsyncEventNotification, object: nil)
		center.addObserver(self, selector: Selector("didUnlockDevice:"), name: TLMMyoDidReceiveUnlockEventNotification, object: nil)
		center.addObserver(self, selector: Selector("didLockDevice:"), name: TLMMyoDidReceiveLockEventNotification, object: nil)
		center.addObserver(self, selector: Selector("didReceiveOrientationEvent:"), name: TLMMyoDidReceiveOrientationEventNotification, object: nil)
		center.addObserver(self, selector: Selector("didReceiveAccelerometerEvent:"), name: TLMMyoDidReceiveAccelerometerEventNotification, object: nil)
		center.addObserver(self, selector: Selector("didReceivePoseChangeEvent:"), name: TLMMyoDidReceivePoseChangedNotification, object: nil)
	}

	func openMyoSettings(presentController pController: UIViewController) {
		let controller = TLMSettingsViewController.settingsInNavigationController()
		// Present the settings view controller modally.
		pController.presentViewController(controller, animated: true, completion: nil)
	}

	@objc private func didConnectedDevice(notification: NSNotification) {
		if let myo = notification.userInfo?[kTLMKeyMyo] as? TLMMyo {
			NSLog("<MyoManager> Connected to Myo: \(myo.name)")
			
			self.connectedMyos.append(myo)
			if let cb = self.didConnectedDeviceCallback {
				cb()
			}
		}
	}

	@objc private func didDisconnectedDevice(notification: NSNotification) {
		if let myo = notification.userInfo?[kTLMKeyMyo] as? TLMMyo {
			NSLog("<MyoManager> Disconnected from Myo: \(myo.name)")
			if let index = self.connectedMyos.indexOf(myo) {
				self.connectedMyos.removeAtIndex(index)
			}
			if let cb = self.didConnectedDeviceCallback {
				cb()
			}
		}
	}

	@objc private func didSyncArm(notification: NSNotification) {
		if let event = notification.userInfo?[kTLMKeyArmSyncEvent] as? TLMArmSyncEvent {
			let armString = event.arm == .Left ? "Left" : "Right"
			var armDirString = ""
			switch event.xDirection {
			case .TowardElbow:
				armDirString = "TowardElbow"
			case .TowardWrist:
				armDirString = "TowardWrist"
			case .Unknown:
				armDirString = "Unknown"
			}
			if let myo = event.myo {
				myo.unlockWithType(.Hold)
			}
			NSLog("<MyoManager> Arm Synced: \(armString) - \(armDirString)")
			if let cb = self.didSyncArmCallback {
				cb(event.arm, event.xDirection)
			}
		}
	}

	@objc private func didUnsyncArm(notification: NSNotification) {
		if let event = notification.userInfo?[kTLMKeyArmUnsyncEvent] as? TLMArmUnsyncEvent {
			NSLog("<MyoManager> Arm UNsynced on \(event.myo?.name ?? "Unknown") ")
			if let cb = self.didUnsyncArmCallback {
				cb()
			}
		}
	}

	@objc private func didUnlockDevice(notification: NSNotification) {
		if let event = notification.userInfo?[kTLMKeyUnlockEvent] as? TLMUnlockEvent {
			NSLog("<MyoManager> Myo Unlocked on \(event.myo?.name ?? "Unknown") ")
			if let cb = self.didUnlockDeviceCallback {
				cb()
			}
		}
	}

	@objc private func didLockDevice(notification: NSNotification) {
		if let event = notification.userInfo?[kTLMKeyLockEvent] as? TLMLockEvent {
			NSLog("<MyoManager> Myo Locked on \(event.myo?.name ?? "Unknown") ")
			if let cb = self.didLockDeviceCallback {
				cb()
			}
		}
	}

	@objc private func didReceiveOrientationEvent(notification: NSNotification) {
		if let event = notification.userInfo?[kTLMKeyOrientationEvent] as? TLMOrientationEvent {
			if let cb = self.didReceiveOrientationCallback {
				cb(TLMEulerAngles(quaternion: event.quaternion))
			}
		}
	}

	@objc private func didReceiveAccelerometerEvent(notification: NSNotification) {
		if let event = notification.userInfo?[kTLMKeyAccelerometerEvent] as? TLMAccelerometerEvent {
			if let cb = self.didReceiveAccelerometerCallback {
				cb(event.vector)
			}
		}
	}

	@objc private func didReceivePoseChangeEvent(notification: NSNotification) {
		if let event = notification.userInfo?[kTLMKeyPose] as? TLMPose {
			var poseString = ""
			switch event.type {
			case .Unknown:
				poseString = "Unknown"
			case .DoubleTap:
				poseString = "DoubleTap"
			case .FingersSpread:
				poseString = "FingersSpread"
			case .Fist:
				poseString = "Fist"
			case .Rest:
				poseString = "Rest"
			case .WaveIn:
				poseString = "WaveIn"
			case .WaveOut:
				poseString = "WaveOut"
			}
			NSLog("<MyoManager> Pose detected: \(poseString)")
			if let cb = self.didReceivePoseChangeCallback {
				cb(event)
			}
		}
	}
}