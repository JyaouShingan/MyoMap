//
//  ViewController.swift
//  MyoMap
//
//  Created by Peter Chen on 2016-03-04.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import UIKit

enum HomeControllerSelectionState {
	case Disconnected
	case StartPoint
	case Destination
	case Finished
}

enum HomeControllerPitchState {
	case High
	case Level
	case Low
}

class HomeController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

	@IBOutlet weak var myoSettings: UIButton!
	@IBOutlet weak var myoStatusLabel: UILabel!
	@IBOutlet weak var confirmationLabel: UILabel!
	@IBOutlet weak var startPointPKView: UIPickerView!
	@IBOutlet weak var destinationPointPKView: UIPickerView!
	@IBOutlet weak var startPointLabel: UILabel!
	@IBOutlet weak var destinationLabel: UILabel!

	var myoManager: MyoManager!
	var mp = MusicController()
	private var myoConnected: Bool = false
	private var currentSelectingView: UIPickerView?

	private var selectionState: HomeControllerSelectionState = .Disconnected {
		didSet {
			UIView.animateWithDuration(0.5) {
				switch self.selectionState {
				case .Disconnected:
					self.disableAllViews()
					self.startPointPKView.setFocused(focus: false)
					self.destinationPointPKView.setFocused(focus: false)
				case .StartPoint:
					self.disableAllViews()
					self.startPointLabel.enabled = true
					self.startPointPKView.showsSelectionIndicator = true
					self.startPointPKView.userInteractionEnabled = true
					self.startPointPKView.setFocused(focus: true)
					self.destinationPointPKView.setFocused(focus: false)
					self.currentSelectingView = self.startPointPKView
				case .Destination:
					self.disableAllViews()
					self.destinationLabel.enabled = true
					self.destinationPointPKView.showsSelectionIndicator = true
					self.destinationPointPKView.userInteractionEnabled = true
					self.destinationPointPKView.setFocused(focus: true)
					self.startPointPKView.setFocused(focus: false)
					self.currentSelectingView = self.destinationPointPKView
				case .Finished:
					self.disableAllViews()
					self.startPointPKView.setFocused(focus: false)
					self.destinationPointPKView.setFocused(focus: false)
					self.confirmationLabel.text = "Start from \(self.pickerViewSelections[self.startPointPKView.selectedRowInComponent(0)]) to \(self.pickerViewSelections[self.destinationPointPKView.selectedRowInComponent(0)]), right?"
				}
			}
		}
	}
	private var currentPitchState: HomeControllerPitchState = .Level {
		didSet {
			switch self.currentPitchState {
			case .High:
				if let index = currentSelectingView?.selectedRowInComponent(0) {
					currentSelectingView?.selectRow(max(0, min(self.pickerViewSelections.count - 1, index - 1)), inComponent: 0, animated: true)
				}
			case .Level:
				() // Do nothing
			case .Low:
				if let index = currentSelectingView?.selectedRowInComponent(0) {
					currentSelectingView?.selectRow(max(0, min(self.pickerViewSelections.count - 1, index + 1)), inComponent: 0, animated: true)
				}
			}
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "MyoMap"
		self.myoStatusLabel.text = "Disconnected"
		self.myoStatusLabel.textColor = UIColor.redColor()

		self.myoManager = MyoManager.sharedInstance()
		self.startPointPKView.dataSource = self
		self.startPointPKView.delegate = self
		self.destinationPointPKView.dataSource = self
		self.destinationPointPKView.delegate = self

		self.disableAllViews()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.selectionState = self.myoConnected ? .StartPoint : .Disconnected
		self.myoManager.didReceivePoseChangeCallback = {[weak self] (pose: TLMPose) -> () in
			if let wSelf = self {
				if pose.type == .Fist {
					switch wSelf.selectionState {
					case .Disconnected:
						() // Do Nothing
					case .StartPoint:
						wSelf.selectionState = .Destination
					case .Destination:
						wSelf.selectionState = .Finished
					case .Finished:
						wSelf.performSegueWithIdentifier("ToMap", sender: self)
						self!.mp.pause()
					}
				} else if pose.type == .WaveIn {
					switch wSelf.selectionState {
					case .Disconnected:
						() // Do Nothing
					case .StartPoint:
						() // Do Nothing
					case .Destination:
						wSelf.selectionState = .StartPoint
					case .Finished:
						wSelf.selectionState = .Destination
						//TODO: Segue stuff, enter map
					}
				} else if pose.type == .DoubleTap {
					switch wSelf.selectionState {
					case .Disconnected:
						self!.mp.pause() // stop music if there is
					case .StartPoint:
						self!.mp.pause() // stop music if there is
					case .Destination:
						self!.mp.pause() // stop music if there is
					case .Finished:
						() // do nothing
						//TODO: Segue stuff, enter map
					}
				}
			}
		}
		self.myoManager.didReceiveOrientationCallback = {[weak self] (angle: TLMEulerAngles) -> () in
			if let wSelf = self {
				if angle.pitch.degrees >= 25 {
					if wSelf.currentPitchState != .High {
						wSelf.currentPitchState = .High
					}
				} else if angle.pitch.degrees <= -25 {
					if wSelf.currentPitchState != .Low {
						wSelf.currentPitchState = .Low
					}
				} else {
					if wSelf.currentPitchState != .Level {
						wSelf.currentPitchState = .Level
					}
				}
			}
		}
		self.myoManager.didConnectedDeviceCallback = {[weak self] in
			if let wSelf = self {
				wSelf.myoStatusLabel.text = "Unsync: \(wSelf.myoManager.currentMyo?.name ?? "Unknown")"
				wSelf.myoStatusLabel.textColor = UIColor.darkGrayColor()
			}
		}
		self.myoManager.didDisconnectedDeviceCallback = {[weak self] in
			if let wSelf = self {
				wSelf.myoStatusLabel.text = "Disconnected"
				wSelf.myoStatusLabel.textColor = UIColor.redColor()
				wSelf.selectionState = .Disconnected
				wSelf.myoConnected = false
			}
		}
		self.myoManager.didSyncArmCallback = {[weak self] (_ , _) -> () in
			if let wSelf = self {
				wSelf.myoStatusLabel.text = "Synced: \(wSelf.myoManager.currentMyo?.name ?? "Unknown")"
				wSelf.myoStatusLabel.textColor = UIColor(red: 0, green: 0.6, blue: 0, alpha: 1)
				wSelf.selectionState = .StartPoint
				wSelf.myoConnected = true
				self!.mp.play()
			}
		}
		self.myoManager.didUnsyncArmCallback = {[weak self] in
			if let wSelf = self {
				wSelf.myoStatusLabel.text = "Unsync: \(wSelf.myoManager.currentMyo?.name ?? "Unknown")"
				wSelf.myoStatusLabel.textColor = UIColor.darkGrayColor()
				wSelf.selectionState = .Disconnected
				wSelf.myoConnected = false
			}
		}
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func openMyoSettings(sender: UIButton) {
		self.myoManager.openMyoSettings(presentController: self)
	}

	@IBAction func simulateFist(sender: UIButton) {
		switch self.selectionState {
		case .Disconnected:
			() // Do Nothing
		case .StartPoint:
			self.selectionState = .Destination
		case .Destination:
			self.selectionState = .Finished
		case .Finished:
			self.performSegueWithIdentifier("ToMap", sender: self)
		}
	}

	// MARK: UIPickerView delegate & datasource
	let pickerViewSelections = [
		"Home",
		"School",
		"Work",
		"Current"
	]

	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return self.pickerViewSelections.count
	}

	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return self.pickerViewSelections[row]
	}

	// MARK: Segues

	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let identifier = segue.identifier {
			if identifier == "ToMap" {
				if let dest = segue.destinationViewController as? MapViewController {
					let startPointIndex = self.startPointPKView.selectedRowInComponent(0)
					let destinatinoIndex = self.destinationPointPKView.selectedRowInComponent(0)
					dest.startPoint = PointType(rawValue: startPointIndex)!
					dest.destination = PointType(rawValue: destinatinoIndex)!
				}
			}
		}
	}

	// MARK: Utils

	private func disableAllViews() {
		self.startPointLabel.enabled = false
		self.startPointPKView.showsSelectionIndicator = false
		self.startPointPKView.userInteractionEnabled = false
		self.destinationLabel.enabled = false
		self.destinationPointPKView.showsSelectionIndicator = false
		self.destinationPointPKView.userInteractionEnabled = false
		self.currentSelectingView = nil
		self.confirmationLabel.text = ""
	}
}

