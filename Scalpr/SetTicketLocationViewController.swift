//
//  SetTicketLocationViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 10/6/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import GoogleMaps
import MBProgressHUD


class SetTicketLocationViewController: UIViewController, GMSMapViewDelegate{
    
    
    @IBOutlet weak var mapView: GMSMapView!
    let loginHelper: LoginHelper = LoginHelper()!
    let locationHelper: LocationHelper = LocationHelper()!
    let attractionHelper: AttractionHelper = AttractionHelper()
    
    let marker: GMSMarker = GMSMarker()
    var loadingNotification: MBProgressHUD? = nil
    
    var attraction : Attraction = Attraction()
    
    var editAttraction : Attraction? = nil
    
    var success : Bool = false
    
    // MARK: Buttons
    @IBOutlet weak var bCancel: UIButton!
    @IBOutlet weak var bPost: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.mapView.delegate = self
        marker.title = "Ticket Post Location"

        if editAttraction != nil {
            let atPosition2D = CLLocationCoordinate2D(latitude: (editAttraction?.lat)!, longitude: (editAttraction?.lon)!)
            centerMapOnLocation(location: CLLocation(latitude: (editAttraction?.lat)!, longitude: (editAttraction?.lon)!), withAnimation: false)
            marker.position = atPosition2D
            marker.map = self.mapView
            self.mapView.isMyLocationEnabled = true
            bPost.setTitle("Update Location", for: .normal)
        }else if let location = locationHelper.getLastLocation() as? CLLocation{
            self.mapView.isMyLocationEnabled = true
            centerMapOnLocation(location: location, withAnimation: false)
            marker.position = self.mapView.camera.target
            marker.map = self.mapView
        }

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func centerMapOnLocation(location: CLLocation, withAnimation: Bool) {
        
        if withAnimation{
            self.mapView.animate(to: GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15.0))
        }else{
            self.mapView.camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 15.0)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "unwindToHome"{
            let homeViewController = (segue.destination as! HomeViewController)
            homeViewController.newAttraction = self.attraction
        }else if segue.identifier == "unwindToMyTicketsFromSetLocation"{
            if sender as! UIButton == bPost{
                let myTicketsViewController = (segue.destination as! MyTicketsTableViewController)
                myTicketsViewController.editedAttraction = self.editAttraction
            }
        }
        
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        marker.position = position.target
    }
    
    @IBAction func bCancel(_ sender: UIButton) {
        if editAttraction != nil {
            self.performSegue(withIdentifier: "unwindToMyTicketsFromSetLocation", sender: sender)
        }else{
            self.performSegue(withIdentifier: "unwindToPostTicket", sender: sender)
        }
    }
    
    
    @IBAction func bPostTicket(_ sender: UIButton) {
        
        if editAttraction == nil {
            self.attraction.lat = marker.position.latitude
            self.attraction.lon = marker.position.longitude
            self.attraction.creatorID = loginHelper.getLoggedInUser().ID
            
            loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.label.text = "Posting Ticket"

            
            attractionHelper.postAttraction(attraction: self.attraction){ responseObject, error in
                
                self.loadingNotification?.hide(animated: false)
                
                if responseObject != nil {
                
                    let response = Int((responseObject)!)
                    
                    if response == 0{
                        self.view.makeToast("Unable to post ticket. Please try again.", duration: 2.0, position: .bottom)
                    }else{
                        self.success = true
                        
                        self.performSegue(withIdentifier: "unwindToHome", sender: sender)
                    }
                }else{
                    self.view.makeToast("Unable to post ticket. Please try again.", duration: 2.0, position: .bottom)
                }
                
                return
            }
        }else{
            self.editAttraction?.lat = marker.position.latitude
            self.editAttraction?.lon = marker.position.longitude
            
            loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.label.text = "Updating Post"
            
            
            attractionHelper.updateAttractionLocation(attraction: self.editAttraction!){ responseObject, error in
                
                self.loadingNotification?.hide(animated: false)
                
                if responseObject != nil {
                    
                    let response = Int((responseObject)!)
                    
                    if response == 1{
                        self.success = true
                        CoreDataHelper.attractionChanged = true //tells home to refresh when loaded again
                        self.performSegue(withIdentifier: "unwindToMyTicketsFromSetLocation", sender: sender)
                    }else{
                        self.view.makeToast("Unable to update ticket location. Please try again.", duration: 2.0, position: .bottom)
                    }
                }else{
                    self.view.makeToast("Unable to update ticket location. Please try again.", duration: 2.0, position: .bottom)
                }
                
                return
            }
        }
    }

    
}
