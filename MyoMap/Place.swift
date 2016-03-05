//
//  Place.swift
//  MyoMap
//
//  Created by Teakay on 2016-03-05.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import Foundation
import MapKit

class Place: NSObject, MKAnnotation {
	let title: String?
	let coordinate: CLLocationCoordinate2D
	let rating: Float
	
	init(title: String, lat: Double, lng: Double, rating: Float){
		self.title = title
		self.rating = rating
		self.coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lng)
		super.init()
	}
	
}