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

struct Locations{
	static let homeLoc = CLLocation(latitude: 43.4797601, longitude: -80.5281519)
	static let home2D = CLLocationCoordinate2D(latitude: 43.4797601, longitude: -80.5281519)

	static let schoolLoc = CLLocation(latitude: 43.4776419, longitude: -80.5303093)
	static let school2D = CLLocationCoordinate2D(latitude: 43.4776419, longitude: -80.5303093)

	static let wemeshLoc = CLLocation(latitude: 43.4563305, longitude: -80.4943874)
	static let wemesh2D = CLLocationCoordinate2D(latitude: 43.4563305, longitude:-80.4943874)


	static let locations: [(cl: CLLocation ,cl2D: CLLocationCoordinate2D)] =
	[(homeLoc,   home2D)  ,
	 (schoolLoc, school2D),
	 (wemeshLoc, wemesh2D)]

}