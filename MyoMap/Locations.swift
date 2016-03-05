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

	func transform(original: CLLocationCoordinate2D) -> (CLLocation) {
		let c = CLLocation(latitude: original.latitude, longitude: original.longitude)
		return c
	}
	
}