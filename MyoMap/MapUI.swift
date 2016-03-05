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
			RouteRequest()
		}
	}
	
	func RouteRequest() {
		let request = MKDirectionsRequest()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: locValue!, addressDictionary: nil))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: loc.wemesh2D, addressDictionary: nil))
		request.requestsAlternateRoutes = true
		request.transportType = .Any
		
		let direction = MKDirections(request:request)
		
		direction.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
			guard let unwrappedResponse = response else { return }
			
			for route in unwrappedResponse.routes {
				self.mapView.addOverlay(route.polyline)
				self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
			}
		}
	}
	
	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
		renderer.strokeColor = UIColor.blueColor()
		return renderer
	}
}