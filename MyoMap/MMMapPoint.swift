//
//  MMMapPoint.swift
//  MyoMap
//
//  Created by Peter Chen on 2016-03-05.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import Foundation
import MapKit

class MMMapPoint: NSObject, MKAnnotation {
	var title: String?
	var subtitle: String?
	var coordinate: CLLocationCoordinate2D

	init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
		self.coordinate = coordinate
		self.title = title
		self.subtitle = subtitle
	}
}