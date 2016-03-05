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

let MERCATOR_RADIUS = 85445659.44705395
let MAX_GOOGLE_LEVELS = 20

enum PointType: Int {
	case Home = 0
	case School
	case Work
	case Current
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

	@IBOutlet weak var mapView: MKMapView!

	var startPoint: PointType = .Current
	var destination: PointType = .Home

	private var startCoordinate: CLLocationCoordinate2D!
	private var destCoordinate: CLLocationCoordinate2D!
	private var currCoordinate: CLLocationCoordinate2D!

	private var locationManager = CLLocationManager()
	private var firstTimeGetLocation = true
	private let regionRadius: CLLocationDistance = 1000

	private var mapZoom: CGFloat = 0

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Map"
		self.mapView.delegate = self

		MyoManager.sharedInstance().clearCallbacks()

		self.locationManager.delegate = self
		self.locationManager.requestAlwaysAuthorization()
		self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if CLLocationManager.locationServicesEnabled() {
			self.locationManager.startUpdatingLocation()
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewWillDisappear(animated: Bool) {
		self.locationManager.stopUpdatingLocation()
	}

	private func centerMapOnLocation(location: CLLocation, animated: Bool) {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
		mapView.setRegion(coordinateRegion, animated: animated)
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		print("Updated Location")
		if let locValue = manager.location?.coordinate {
			self.currCoordinate = locValue
			print("locations = \(locValue.latitude) \(locValue.longitude)")
			if(self.firstTimeGetLocation){
				if self.startPoint != .Current {
					self.startCoordinate = Locations.locations[self.startPoint.rawValue].cl2D
				} else {
					self.startCoordinate = locValue
				}
				if self.destination != .Current {
					self.destCoordinate = Locations.locations[self.destination.rawValue].cl2D
				} else {
					self.destCoordinate = locValue
				}
				if self.startPoint != .Current {
					self.centerMapOnLocation(Locations.locations[self.startPoint.rawValue].cl, animated: false)
				} else {
					self.centerMapOnLocation(locValue.clLocation(), animated: false)
				}
				self.routeRequest()
				self.firstTimeGetLocation = false
			}
		}
	}

	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		let alert = UIAlertController(title: "Error", message: "Cannot get current location", preferredStyle: UIAlertControllerStyle.Alert)
		self.presentViewController(alert, animated: true) { () -> Void in
			self.navigationController?.popViewControllerAnimated(true)
		}
	}

	func routeRequest() {
		let request = MKDirectionsRequest()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.startCoordinate, addressDictionary: nil))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: self.destCoordinate, addressDictionary: nil))
		request.requestsAlternateRoutes = false
		request.transportType = .Automobile

		let direction = MKDirections(request:request)

		direction.calculateDirectionsWithCompletionHandler { [unowned self] response, error in
			guard let unwrappedResponse = response else { return }

			let startCircle = MMMapPoint(coordinate: self.startCoordinate, title: "Start")
			let destCircle = MMMapPoint(coordinate: self.destCoordinate, title: "Destination")


			self.mapView.addAnnotation(startCircle)
			self.mapView.addAnnotation(destCircle)
			for route in unwrappedResponse.routes {
				self.mapView.addOverlay(route.polyline)
				self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
			}

		}
	}

	func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
		if let polylineOverlay = overlay as? MKPolyline {
			let renderer = MKPolylineRenderer(polyline: polylineOverlay)
			renderer.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.7)
			renderer.lineWidth = 6.5
			return renderer
		}
		if let circleOverlay = overlay as? MKCircle {
			let renderer = MKCircleRenderer(circle: circleOverlay)
			if circleOverlay.coordinate == self.startCoordinate {
				renderer.fillColor = UIColor(red: 0, green: 0.7, blue: 0, alpha: 1)
			} else if circleOverlay.coordinate == self.destCoordinate {
				renderer.fillColor = UIColor(red: 0, green: 0, blue: 0.8, alpha: 1)
			}
			renderer.strokeColor = UIColor.whiteColor()
			renderer.lineWidth = 3
			return renderer
		}
		return MKOverlayRenderer()
	}

	func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
		if let title = annotation.title {
			if title == "Start" {
				let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "PointAnnotation")
				view.image = UIImage(named: "StartPoint")
				view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6)
				return view
			} else if title == "Destination" {
				let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "PointAnnotation")
				view.image = UIImage(named: "Destination")
				view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6)
				return view
			}
		}
		return nil
	}

	func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		let longitudeDelta = self.mapView.region.span.longitudeDelta
		let mapWidthInPixels = self.mapView.bounds.size.width
		let zoomScale = CGFloat(longitudeDelta * MERCATOR_RADIUS * M_PI) / (180.0 * mapWidthInPixels)
		var zoomer = CGFloat(MAX_GOOGLE_LEVELS) - log2( zoomScale );
		if zoomer < 0 {zoomer = 0}
		self.mapZoom = zoomer
		print("<MapView> Zoom changed: \(zoomer)")
	}
}