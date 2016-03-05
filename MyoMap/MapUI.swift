//
//  MapUI.swift
//  MyoMap
//
//  Created by Teakay on 2016-03-05.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit

class MapUI: UIViewController, CLLocationManagerDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	
	var locationManager = CLLocationManager()
	var locValue: CLLocationCoordinate2D?
	var loc = Locations()
	var firstTimeFocus = true
	let regionRadius: CLLocationDistance = 1000
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.locationManager.requestAlwaysAuthorization()
		self.locationManager.requestWhenInUseAuthorization()
		
		if CLLocationManager.locationServicesEnabled() {
			self.locationManager.delegate = self
			self.locationManager.desiredAccuracy =	kCLLocationAccuracyNearestTenMeters
			self.locationManager.startUpdatingLocation()
		}
		
	}

	func centerMapOnLocation(location: CLLocation) {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
		mapView.setRegion(coordinateRegion, animated: true)
	}
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		locValue = manager.location!.coordinate
		print("locations = \(locValue!.latitude) \(locValue!.longitude)")
		if(firstTimeFocus){
			let c = loc.transform(locValue!)
			centerMapOnLocation(c)
			firstTimeFocus = false
		}
	}
	
}