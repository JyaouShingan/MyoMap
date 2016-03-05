//
//  Locations.swift
//  MyoMap
//
//  Created by Teakay on 2016-03-05.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class Locations{

	var wemeshLoc = CLLocation(latitude: 43.4563305, longitude:-80.4943874)
	var wemesh2D = CLLocationCoordinate2D(latitude: 43.4563305, longitude:-80.4943874)
	
	func transform(original: CLLocationCoordinate2D) -> (CLLocation) {
		let c = CLLocation(latitude: original.latitude, longitude: original.longitude)
		return c
	}
	
}