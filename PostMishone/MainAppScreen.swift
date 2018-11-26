//
//  MainAppScreen.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-10-14.
//  Copyright © 2018 Victor Liang. All rights reserved.
//
import Foundation
import UIKit
import Firebase
import MapKit
import CoreLocation
import UserNotifications

// Custom class for missions: (replacing MKAnnotation)
 class missionAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var missionPosterID: String?
    var timeStamp: Int?
    var reward: String?
    var missionID: String?
    
    init(title:String, subtitle:String, location:CLLocationCoordinate2D, posterID:String, timeStamp:Int, reward:String, missionID:String) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = location
        self.missionPosterID = posterID
        self.timeStamp = timeStamp
        self.reward = reward
        self.missionID = missionID
    }
 }

class MainAppScreen: UIViewController, UNUserNotificationCenterDelegate {
    var ref: DatabaseReference!
    var missionPostsArray = [missionAnnotation]()
    var selectedAnnotation: missionAnnotation?
    var longitude : Double = 0.0
    var latitude : Double = 0.0
    let userID = Auth.auth().currentUser!.uid
//    var tempanno: missionAnnotation?
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    let displayRegionInMeters : Double = 1600
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "MainAppScreen" // Identifier for UI Testing
        mapView.delegate = self // For showing annotation when pin is tapped
        ref = Database.database().reference() // Firebase Reference
        checkLocationServices() // Check user location settings -> initiate user map
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in})
        
        UNUserNotificationCenter.current().delegate = self
        
        ref.child("Users").child(userID).child("MissionPosts").observe(.childChanged, with: { (snapshot) in
            
            let content = UNMutableNotificationContent()
            
            //adding title, subtitle, body and badge
            content.title = "Your mission has been accepted"
            
            //getting the notification trigger
            //it will be called after 2 seconds
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            
            //getting the notification request
            let request = UNNotificationRequest(identifier: "SimplifiedIOSNotification", content: content, trigger: trigger)
            
            //adding the notification to notification center
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }, withCancel: nil)

    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // Retreive Mission Posts
        retrieveAllMissions()
        
        // Listen for user changes to missions
        listenForMissionChanges()
        
        // Listen for deleted missions
        listenForMissionDeletions()
        
    }
    
    
    func retrieveAllMissions() {
        ref?.child("PostedMissions").observe(.childAdded, with: { (snapshot) in
            print("FIREBASEobservedAdded")
            // Code to execute when a child is added under "PostedMissions"
            // MARK: missionAnnotation Creation
            // Take value from snapshot and add it to missionPostsArray
            if let dic = snapshot.value as? [String:Any], let timeStamp = dic["timeStamp"] as? Int, let latitude = dic["Latitude"] as? Double, let longitude = dic["Longitude"] as? Double, let missionName = dic["missionName"] as? String, let missionDescription = dic["missionDescription"] as? String, let posterID = dic["UserID"] as? String, let reward = dic["reward"] as? String, let missionID = dic["missionID"] as? String {
                
                let annotation = missionAnnotation(title: missionName, subtitle: missionDescription, location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), posterID: posterID, timeStamp: timeStamp, reward: reward, missionID: missionID)
                
                // Update mapview with changed missionPostsArray to reflect new mission post
                self.missionPostsArray.append(annotation)
                self.mapView.addAnnotations(self.missionPostsArray)
                
            }
        })
    }
    
    func listenForMissionChanges() {
        ref?.child("PostedMissions").observe(.childChanged, with: { (snapshot) in
            print("FIREBASEobservedChanged")
            print(snapshot)
            
            if let dic = snapshot.value as? [String:Any], let timeStamp = dic["timeStamp"] as? Int, let latitude = dic["Latitude"] as? Double, let longitude = dic["Longitude"] as? Double, let missionName = dic["missionName"] as? String, let missionDescription = dic["missionDescription"] as? String, let posterID = dic["UserID"] as? String, let reward = dic["reward"] as? String, let missionID = dic["missionID"] as? String {
                
                print("new des: \(missionDescription)")
                
                let annotation = missionAnnotation(title: missionName, subtitle: missionDescription, location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), posterID: posterID, timeStamp: timeStamp, reward: reward, missionID: missionID)
                
                let changedMission = self.missionPostsArray.filter{$0.missionID == missionID}
                let filteredMissions = self.missionPostsArray.filter{$0.missionID != missionID}
                self.mapView.removeAnnotations(changedMission)
                self.missionPostsArray = filteredMissions
                self.missionPostsArray.append(annotation)
                self.mapView.addAnnotations(self.missionPostsArray)
            }
        })
    }
    
    func listenForMissionDeletions() {
        ref?.child("PostedMissions").observe(.childRemoved, with: { (snapshot) in
            print("FIREBASEobservedRemove")
            if let dic = snapshot.value as? [String:Any], let missionID = dic["missionID"] as? String {
                
                let deletedMission = self.missionPostsArray.filter{$0.missionID == missionID}
                
                // Update mapview with changed missionPostsArray to reflect deleted mission
                self.mapView.removeAnnotations(deletedMission)
                let filteredMissions = self.missionPostsArray.filter{$0.missionID != missionID}
                self.missionPostsArray = filteredMissions
                print("DELETE")
            }
        })
    }
    
    // MARK: MAP FUNCTIONALITY
    func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center : location, latitudinalMeters : displayRegionInMeters, longitudinalMeters :  displayRegionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Make sure location services are enabled on device
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            // Set up location manager
            setupLocationManager()
            checkLocationAuthorization()
        }
        else {
            // Alert user their location service is off
            print("location service disabled")
        }
    }
    
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            // Do map stuff
            print("doing map stuff")
            mapView.showsUserLocation = true
            centerViewOnUserLocation()
            locationManager.startUpdatingLocation()
            break
        case .denied:
            // Show alert "how to turn on alert"
            print("Denied")
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            print("Denied")
            // Show alert about whats up
            break
        case .authorizedAlways:
            break
        }
    }
    
    // MARK: LONG PRESS -> Pin Mission
    @IBAction func pinMission(_ sender: UILongPressGestureRecognizer) {
        if sender.state == UIGestureRecognizer.State.ended {
            let touchLocation = sender.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation,toCoordinateFrom: mapView)
            
            longitude = locationCoordinate.longitude
            latitude = locationCoordinate.latitude
            
            self.performSegue(withIdentifier: "toDescribeMission", sender: self)
            
            print("Long pressed mission at lat: \(locationCoordinate.latitude) long: \(locationCoordinate.longitude)")
            print("Total annotations: \(mapView.annotations.count)")
        }
    }
    
    // Prepares pin coordinate information to send to describeMissionViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDescribeMission" { // Posting Mission
            let destination = segue.destination as? DescribeMissionViewController
            destination?.latitude = latitude
            destination?.longitude = longitude
        }
        if segue.identifier == "toMissionDescription" { // Viewing Mission
            let destination = segue.destination as? MissionDescriptionViewController
            destination?.missionTitle = selectedAnnotation?.title ?? ""
            destination?.subtitle = selectedAnnotation?.subtitle ?? ""
            destination?.posterID = selectedAnnotation?.missionPosterID ?? ""
            destination?.reward = selectedAnnotation?.reward ?? ""
            destination?.missionID = selectedAnnotation?.missionID ?? ""
            destination?.latitude = selectedAnnotation?.coordinate.latitude ?? 0.0
            destination?.longitude = selectedAnnotation?.coordinate.longitude ?? 0.0
        }
        if segue.identifier == "toViewMyMission" { // View Personal Posted Mission
            let destination = segue.destination as? ViewMyMission
            destination?.missionID = selectedAnnotation?.missionID ?? ""
            destination?.enteredFromMap = true
        }
        
    }
    
    

    
    
}


// MARK: Map extension
extension MainAppScreen: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.last != nil else {
            return
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Check if authorization changes, if so, check again
        checkLocationAuthorization()
    }
    
}

extension MainAppScreen: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil } // Do not touch UserLocation

        let identifier = "marker"
        var view: MKMarkerAnnotationView

        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: 5)
            view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            if let annotation = view.annotation as? missionAnnotation {
                if(annotation.missionPosterID == userID) { // Render marker color, differentiate own missions from others // TODO: helper function to classify missions
                    view.markerTintColor = UIColor.blue;
                }
            }
        }
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("info")
        if(selectedAnnotation?.missionPosterID == userID) {
            self.performSegue(withIdentifier: "toViewMyMission", sender: self)
        }
        else {
            self.performSegue(withIdentifier: "toMissionDescription", sender: self)
        }
    }
    
    
    // MARK: SELECT ANNOTATION -> Identify selected annotation
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation as? missionAnnotation {
            selectedAnnotation = annotation;
            print("selected posterID: \(String(describing: annotation.missionPosterID))")
            print("selected reward: \(String(describing: annotation.reward))")
            print("selected timeStamp: \(String(describing: annotation.timeStamp))")
        }
    }
    
    
}
