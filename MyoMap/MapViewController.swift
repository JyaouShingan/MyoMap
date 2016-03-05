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

	private var locationManager = CLLocationManager()
	private var currentLoc: CLLocationCoordinate2D?
	private var firstTimeFocus = true
	private let regionRadius: CLLocationDistance = 1000

	private var mapZoom: CGFloat = 0

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Map"
		self.mapView.delegate = self

		self.locationManager.requestWhenInUseAuthorization()
		MyoManager.sharedInstance().clearCallbacks()

		if CLLocationManager.locationServicesEnabled() {
			self.locationManager.delegate = self
			self.locationManager.desiredAccuracy =	kCLLocationAccuracyNearestTenMeters
			self.locationManager.startUpdatingLocation()
		}

	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.currentLoc = Locations.locations[self.startPoint.rawValue].cl2D
		self.centerMapOnLocation(Locations.locations[self.startPoint.rawValue].cl, animated: false)
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.routeRequest()
	}

	private func centerMapOnLocation(location: CLLocation, animated: Bool) {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
		mapView.setRegion(coordinateRegion, animated: animated)
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let locValue = manager.location?.coordinate {
			self.currentLoc = locValue
			print("locations = \(locValue.latitude) \(locValue.longitude)")
			if(self.firstTimeFocus){
				let c = locValue.clLocation()
				self.centerMapOnLocation(c, animated: true)
				self.firstTimeFocus = false

			}
		}
	}

	func routeRequest() {
		let request = MKDirectionsRequest()
		request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.currentLoc!, addressDictionary: nil))
		request.destination = MKMapItem(placemark: MKPlacemark(coordinate: Locations.wemesh2D, addressDictionary: nil))
		request.requestsAlternateRoutes = false
		request.transportType = .Automobile

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
		renderer.strokeColor = UIColor(red: 0, green: 0, blue: 1, alpha: 0.7)
		renderer.lineWidth = 6.5
		return renderer
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