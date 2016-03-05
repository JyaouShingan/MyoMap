//
//  Utils.swift
//  MyoMap
//
//  Created by Peter Chen on 2016-03-04.
//  Copyright © 2016 Peter Chen. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension UIPickerView {
	func setFocused(focus focus: Bool) {
		if focus {
			self.layer.cornerRadius = 15
			self.layer.borderWidth = 2
			self.layer.borderColor = UIColor.redColor().CGColor
		} else {
			self.layer.cornerRadius = 0
			self.layer.borderWidth = 0
			self.layer.borderColor = UIColor.clearColor().CGColor
		}
	}
}

extension CLLocationCoordinate2D {
	func clLocation() -> CLLocation {
		return CLLocation(latitude: self.latitude, longitude: self.longitude)
	}
}