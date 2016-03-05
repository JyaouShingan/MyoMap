//
//  ViewController.swift
//  MyoMap
//
//  Created by Peter Chen on 2016-03-04.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

	@IBOutlet weak var myoSettings: UIButton!
	var myoManager: MyoManager!
	var locationManager = CLLocationManager()
	var locValue: CLLocationCoordinate2D?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.locationManager.requestAlwaysAuthorization()
		self.locationManager.requestWhenInUseAuthorization()
		if CLLocationManager.locationServicesEnabled() {
			self.locationManager.delegate = self
			self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
			self.locationManager.startUpdatingLocation()
		}
		self.myoManager = MyoManager()
		// Do any additional setup after loading the view, typically from a nib.
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		locValue = manager.location!.coordinate
		//print("locations = \(locValue!.latitude) \(locValue!.longitude)")
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	@IBAction func openMyoSettings(sender: UIButton) {
		self.myoManager.openMyoSettings(presentController: self)
	}
}

