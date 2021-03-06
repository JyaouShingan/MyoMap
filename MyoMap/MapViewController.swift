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

enum MapMode {
	case Explore
	case Navigation
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var mapTypeSC: UISegmentedControl!
	@IBOutlet weak var modeLabel: UILabel!

	var startPoint: PointType = .Current
	var destination: PointType = .Home

	private var startCoordinate: CLLocationCoordinate2D!
	private var destCoordinate: CLLocationCoordinate2D!
	private var currCoordinate: CLLocationCoordinate2D!

	private var myoManager = MyoManager.sharedInstance()
	private var locationManager = CLLocationManager()
	private var firstTimeGetLocation = true
	private let regionRadius: CLLocationDistance = 1000
	private let mp = MusicController()
	private var nearby = false

	private var mapZoom: CGFloat = 0

	private var mode: MapMode = .Explore {
		didSet {
			if self.mode == .Explore {
				self.modeLabel.text = "Mode: Explore"
				if self.updateTimer == nil {
					let camera = MKMapCamera(lookingAtCenterCoordinate: self.mapView.camera.centerCoordinate, fromDistance: 2000, pitch: 0, heading: 0)
					self.mapView.setCamera(camera, animated: true)
					self.needCenterAngle = true
					self.updateTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("updateMapCamera"), userInfo: nil, repeats: true)
				}
			} else {
				self.modeLabel.text = "Mode: Navigation"
				self.updateTimer?.invalidate()
				self.updateTimer = nil
				self.mapView.camera.pitch = 40
				self.mapView.camera.altitude = 2000
			}
		}
	}
	private var mapType: MKMapType = .Standard
	private let mapTypes: [MKMapType] = [.Standard, .Satellite, .Hybrid]

	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Map"
		self.mapView.delegate = self

		self.myoManager.clearCallbacks()

		self.locationManager.delegate = self
		self.locationManager.requestAlwaysAuthorization()
		self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters

		self.view.sendSubviewToBack(self.mapView)
		self.mapView.showsUserLocation = true

		self.setupMyoCallbacks()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if CLLocationManager.locationServicesEnabled() {
			self.locationManager.startUpdatingHeading()
			self.locationManager.startUpdatingLocation()
		}
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewWillDisappear(animated: Bool) {
		self.locationManager.stopUpdatingLocation()
		self.locationManager.stopUpdatingHeading()
	}

	private func centerMapOnLocation(location: CLLocation, animated: Bool) {
		let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 2.0, regionRadius * 2.0)
		mapView.setRegion(coordinateRegion, animated: animated)
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
				self.mode = .Explore
			} else if self.mode == .Navigation {
				let camera = MKMapCamera(lookingAtCenterCoordinate: locValue, fromDistance: 2000, pitch: 40, heading: locationManager.heading?.trueHeading ?? 0)
				self.mapView.setCamera(camera, animated: true)
			}
		}
	}

	func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
		NSLog("Updated Heading")
		if self.mode == .Navigation {
			let camera = MKMapCamera(lookingAtCenterCoordinate: self.locationManager.location!.coordinate, fromDistance: 2000, pitch: 40, heading: newHeading.trueHeading)
			self.mapView.setCamera(camera, animated: true)
		}
	}

	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		let alert = UIAlertController(title: "Error", message: "Cannot get current location", preferredStyle: UIAlertControllerStyle.Alert)
		alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
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
			guard let unwrappedResponse = response else {
				print("error occured")
				return
			}

			let startCircle = MMMapPoint(coordinate: self.startCoordinate, title: "StartPoint")
			let destCircle = MMMapPoint(coordinate: self.destCoordinate, title: "Destination")


			self.mapView.addAnnotation(startCircle)
			self.mapView.addAnnotation(destCircle)
			for route in unwrappedResponse.routes {
				self.mapView.addOverlay(route.polyline)
				self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
			}
		}
	}
	
	func nearbyRequest() {
		let request = MKLocalSearchRequest()
		request.naturalLanguageQuery = "Restaurants"
		request.region = mapView.region
		
		let search = MKLocalSearch(request:request)
		
		search.startWithCompletionHandler { response, error in
			guard let unwrappedResponse = response else {
				print("error occured")
				return
			}
			
			self.nearby = true

			for instance in unwrappedResponse.mapItems {
				let temp = MMMapPoint(coordinate: instance.placemark.coordinate, title: instance.name)
				self.mapView.addAnnotation(temp)
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
			if title == "StartPoint" && self.nearby == false {
				let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "PointAnnotation")
				view.image = UIImage(named: "StartPoint")
				view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6)
				return view
			} else if title == "Destination" && self.nearby == false {
				let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "PointAnnotation")
				view.image = UIImage(named: "Destination")
				view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.6, 0.6)
				return view
			} else if title != "Current Location"{
				let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "PointAnnotation")
				view.image = UIImage(named: "restaurant")
				view.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4)
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

	// MARK: Explore Mode Camera

	private var centerAngle: TLMEulerAngles = TLMEulerAngles()
	private var currAngle: TLMEulerAngles = TLMEulerAngles()
	private let YAW_THRESHOLD = 10.0
	private let PITCH_THRESHOLD = 10.0
	private let ROLL_THRESHOLD = 15.0

	private var needCenterAngle: Bool = true

	private var updateTimer: NSTimer?

	private func processOrientation(angle: TLMEulerAngles) {
		if self.needCenterAngle {
			self.centerAngle = angle
			self.needCenterAngle = false
		}
		self.currAngle = angle
	}

	@objc private func updateMapCamera() {
		// YAW
		let camera = self.mapView.camera
		var yawDiff = self.currAngle.yaw.degrees - self.centerAngle.yaw.degrees
		if abs(yawDiff) > 180 {
			yawDiff += (yawDiff > 0 ? -360 : 360)
		}
		if abs(yawDiff) > self.YAW_THRESHOLD {
			let newLongitude = max(-180, min(180, camera.centerCoordinate.longitude - camera.altitude * (yawDiff > 0 ? yawDiff - 10 : yawDiff + 10) * 0.00000001))
			camera.centerCoordinate.longitude = newLongitude
		}
		// PITCH
		var pitchDiff = self.currAngle.pitch.degrees - self.centerAngle.pitch.degrees
		if abs(pitchDiff) > 180 {
			pitchDiff += (pitchDiff > 0 ? -360 : 360)
		}
		if abs(pitchDiff) > self.PITCH_THRESHOLD {
			let newLatitude = max(-90, min(90, camera.centerCoordinate.latitude + camera.altitude * (pitchDiff > 0 ? pitchDiff - 10 : pitchDiff + 10) * 0.00000001))
			camera.centerCoordinate.latitude = newLatitude
		}
		
		// ROLL
		let rollDiff = self.currAngle.roll.degrees - self.centerAngle.roll.degrees
		if abs(rollDiff) > self.ROLL_THRESHOLD {
			camera.altitude *= (1 + (rollDiff - 15)/500)
		}
		self.mapView.setCamera(camera, animated: true)
		print("YawDiff:  \(yawDiff)")
		print("PitchDiff:\(pitchDiff)")
		print("RollDiff: \(rollDiff)")
	}

	// MARK: Setups

	private func setupMyoCallbacks() {
		self.myoManager.didDisconnectedDeviceCallback = {[weak self] in
			if let wSelf = self {
				let alert = UIAlertController(title: "Error", message: "Lost connection to MyoBand", preferredStyle: .Alert)
				alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
				wSelf.presentViewController(alert, animated: true, completion: { () -> Void in
					wSelf.navigationController?.popViewControllerAnimated(true)
				})
			}
		}
		self.myoManager.didUnsyncArmCallback = { [weak self] in
			if let wSelf = self {
				let alert = UIAlertController(title: "Error", message: "MyoBand lost sync with arm", preferredStyle: .Alert)
				alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
				wSelf.presentViewController(alert, animated: true, completion: { () -> Void in
					wSelf.navigationController?.popViewControllerAnimated(true)
				})
			}
		}
		self.myoManager.didReceivePoseChangeCallback = {[weak self] (pose: TLMPose) -> () in
			if let wSelf = self {
				if wSelf.mode == .Explore {
					switch pose.type {
					case .WaveIn:
						let index = max(0, min(2 ,wSelf.mapTypeSC.selectedSegmentIndex - 1))
						wSelf.mapTypeSC.selectedSegmentIndex = index
						wSelf.mapType = wSelf.mapTypes[index]
						wSelf.mapView.mapType = wSelf.mapTypes[index]
					case .WaveOut:
						let index = max(0, min(2 ,wSelf.mapTypeSC.selectedSegmentIndex + 1))
						wSelf.mapTypeSC.selectedSegmentIndex = index
						wSelf.mapType = wSelf.mapTypes[index]
						wSelf.mapView.mapType = wSelf.mapTypes[index]
					case .DoubleTap:
						switch wSelf.nearby {
						case false:
							wSelf.nearbyRequest()
						case true:
							for element in wSelf.mapView.annotations {
								if element.title! != "StartPoint" &&
								   element.title! != "Destination" {
									wSelf.mapView.removeAnnotation(element)
								}
							}
							wSelf.nearby = false
						}
					case .FingersSpread:
						wSelf.mode = .Navigation
					default:
						()
					}
				} else {
					switch pose.type {
					case .WaveOut:
						wSelf.mp.next()
						wSelf.mp.play()
					case .WaveIn:
						let tempState = self!.mp.getState()
						switch tempState {
						case .Paused:
							wSelf.mp.play()
						case .Playing:
							wSelf.mp.pause()
						case .Stopped:
							wSelf.mp.addRandomSong()
						default:
							()
						}
					case .DoubleTap:
						wSelf.mode = .Explore
					default:
						()
					}
				}
			}
		}
		self.myoManager.didReceiveOrientationCallback = {[weak self] (angle: TLMEulerAngles) -> () in
			if let wSelf = self {
				if wSelf.mode == .Explore {
					wSelf.processOrientation(angle)
				}
			}
		}
	}
}