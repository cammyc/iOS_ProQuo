//
//  ViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 9/27/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import Kingfisher
import MBProgressHUD
import MessageUI
import KCFloatingActionButton

class HomeViewController: UIViewController, CLLocationManagerDelegate, UISearchBarDelegate, KCFloatingActionButtonDelegate, GMSMapViewDelegate, SWRevealViewControllerDelegate, MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate{
    
    // MARK: Variable Initialization
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var menuButton: UIBarButtonItem!
    let locationManager = CLLocationManager()
    @IBOutlet weak var searchBar: UISearchBar!
    var userLocation: CLLocation? = nil
    var loggedInViewController: LoggedInMenuController?
    var loggedOutViewController: LoggedOutMenuController?
    //@IBOutlet weak var bAddTicket: UIImageView!
    let loginHelper: LoginHelper = LoginHelper()!
    let locationHelper: LocationHelper = LocationHelper()!
    let coreDataHelper: CoreDataHelper = CoreDataHelper()
    let attractionHelper: AttractionHelper = AttractionHelper()
    var newAttraction: Attraction? = nil
    var loadingNotification: MBProgressHUD? = nil
    var locationNotification: MBProgressHUD? = nil
    var currentDataRequest: DataRequest? = nil
    var searchActive = false
    var lastZoom: Float = 0.00
    var idleFromTap = false
    var selectedMarker:GMSMarker? = nil
    let fabPostTicket = KCFloatingActionButton()
    let fabGoToMyLocation = KCFloatingActionButton()
    var firstLocationUpdate = true

    var blurView: UIVisualEffectView? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("view did load")
        mapView.delegate = self
        mapView.settings.consumesGesturesInView = false
        
        searchBar.delegate = self
        searchBar.layer.borderWidth = 0
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            self.revealViewController().draggableBorderWidth = self.view.frame.size.width/5
            
            self.revealViewController().delegate = self
            
            //let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            if loginHelper.getLoggedInUser().ID == 0 {
                let loggedOutMenuController: LoggedOutMenuController = self.storyboard?.instantiateViewController(withIdentifier: "LoggedOutMenuController") as! LoggedOutMenuController
                self.revealViewController().setRear(loggedOutMenuController, animated: false)
            }else{
                let loggedInMenuController: LoggedInMenuController = self.storyboard?.instantiateViewController(withIdentifier: "LoggedInMenuController") as! LoggedInMenuController
                self.revealViewController().setRear(loggedInMenuController, animated: false)
            }
        }
        
        let miscHelper = MiscHelper()
        miscHelper.getMinimumAppVersion(){ responseObject, error in
            if responseObject != nil{
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    if Double(version)! < responseObject!{
                        self.neverEndingAlert()
                    }else{
                        self.terms() //not worried about terms if update is required, it will show once updated
                    }
                }else{
                    self.terms()
                }
                
            }else{
                self.terms()
            }
            
            return
        }
        
        checkLocationAuthorizationStatus()
        searchBar.delegate = self
        
        
        let icon = UIImage(named: "ic_money_white")
        fabPostTicket.buttonImage = ImageHelper.ResizeImage(image: icon!, size: CGSize(width: (icon?.size.width)!/2, height: (icon?.size.height)!/2))
        fabPostTicket.buttonColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71)
        fabPostTicket.fabDelegate = self
        fabPostTicket.friendlyTap = false
        self.view.addSubview(fabPostTicket)
        
        let icon1 = UIImage(named: "My_Location")
        fabGoToMyLocation.buttonImage = ImageHelper.ResizeImage(image: icon1!, size: CGSize(width: (icon1?.size.width)!/2, height: (icon1?.size.height)!/2))
        fabGoToMyLocation.buttonColor = MiscHelper.UIColorFromRGB(rgbValue: 0xFFFFFF)
        fabGoToMyLocation.fabDelegate = self
        fabGoToMyLocation.friendlyTap = false
        fabGoToMyLocation.paddingY = fabGoToMyLocation.frame.height + 25
        self.view.addSubview(fabGoToMyLocation)

        
    }
    
    
    func revealControllerPanGestureBegan(_ revealController: SWRevealViewController!) {
        mapView.settings.scrollGestures = false
    }
    
    func revealControllerPanGestureEnded(_ revealController: SWRevealViewController!) {
        mapView.settings.scrollGestures = true
    }
    
    func revealController(_ revealController: SWRevealViewController!, willMoveTo position: FrontViewPosition) {
        self.searchBar.resignFirstResponder()
        
        if position == FrontViewPosition.left{
            unBlurView()
            if FlagHelper.focusSearch {
                searchBar.becomeFirstResponder()
                FlagHelper.focusSearch = false
            }
        }else{
            unBlurView()//always call first incase blur wasn't removed
            setBlurView(parent:self.view)
        }
    }
    
    
    func tap(gesture: UITapGestureRecognizer) {
        self.searchBar.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if CoreDataHelper.attractionChanged {
            getInitialTickets()
            CoreDataHelper.attractionChanged = false
        }
    }
    
    func emptyKCFABSelected(_ fab: KCFloatingActionButton) {
        if fab == fabPostTicket{
            if loginHelper.getLoggedInUser().ID != 0{
                self.performSegue(withIdentifier: "seaguePostTicket", sender: fab)
            }else{
                let refreshAlert = UIAlertController(title: "Login", message: "You must be logged in to post a ticket. Would you like to login?", preferredStyle: UIAlertControllerStyle.alert)
                
                refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                    self.performSegue(withIdentifier: "login_to_post_ticket", sender: nil)
                }))
                
                refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
                    //print("Handle Cancel Logic here")
                }))
                
                present(refreshAlert, animated: true, completion: nil)
            }
        }else{
            if let location = locationHelper.getLastLocation() as? CLLocation{
                self.centerMapOnLocation(location: location, withAnimation: true)
            }else{
                self.view.makeToast("Unable to determine your location", duration: 3.0, position: .bottom)
            }
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Alerts
    
    func neverEndingAlert(){
        let alert = UIAlertController(
            title: "Update Required",
            message: "An update is required to continue using ProQuo. Please close the app and update it in the app store.",
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (test) -> Void in
            UIApplication.shared.open(NSURL(string: "itms-apps://itunes.apple.com")! as URL, options: [:])
            self.neverEndingAlert()
        }))
        
        
        self.present(alert,animated: true, completion: nil)
    }
    
    func terms(){
        let preferences = UserDefaults.standard
        
        if let acceptedTerms = preferences.object(forKey: "acceptedTerms") as? Bool{
            if !acceptedTerms {
                termsAlert()//not sure this is ever called since it can only be set as true
            }
        }else{
            termsAlert()
        }
        
    }
    
    func termsAlert(){
        let alert = UIAlertController(
            title: "Terms of Service",
            message: "You must agree to ProQuo's Terms of Service to continue using the app.",
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "View Terms", style: .default, handler: { (test) -> Void in
            UIApplication.shared.open(NSURL(string: "http://www.proquoapp.com/help/policies/terms_of_service.html")! as URL, options: [:])
            self.termsAlert()
        }))
        
        alert.addAction(UIAlertAction(title: "I Agree", style: .default, handler: { (test) -> Void in
            let preferences = UserDefaults.standard
            preferences.set(true, forKey: "acceptedTerms")
            preferences.synchronize()
        }))
        
        
        self.present(alert,animated: true, completion: nil)
    }

    
    // MARK: Variable Actions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.searchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let text = searchBar.text{
            let attractions = self.coreDataHelper.getAttractions(query: text) as! [cdAttractionMO]
            
            if attractions.count == 0 {
                getNewSearchTickets()
            }else{
                self.mapView.clear()
                
                mapView.animate(to: GMSCameraPosition.camera(withLatitude: attractions[0].lat, longitude: attractions[0].lon, zoom: self.mapView.camera.zoom))

                
                for i in 0 ..< attractions.count{
                    
                    let attraction = attractions[i]
                    self.showMarker(attraction: attraction)
                }
                searchActive = true
            }
            
            
        }
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == "" && searchActive{
            mapView.clear()
            
            let attractions = self.coreDataHelper.getAttractions() as! [cdAttractionMO]
            
            for i in 0 ..< attractions.count{
                
                let attraction = attractions[i]
                self.showMarker(attraction: attraction)
            }
            
            searchActive = false
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        unBlurView()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        unBlurView()//always call first incase blur wasn't removed
        setBlurView(parent: searchBar)
    }
    
    
    func setBlurView(parent: UIView){
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.blurView = blurEffectView
        
            self.view.insertSubview(self.blurView!, belowSubview: parent)
        }
    }
    
    func unBlurView(){
        if self.blurView != nil{
            self.blurView?.removeFromSuperview()
        }
    }
    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.text = ""
//
//        if searchActive{
//            mapView.clear()
//        
//            let attractions = self.coreDataHelper.getAttractions() as! [cdAttractionMO]
//            
//            for i in 0 ..< attractions.count{
//                
//                let attraction = attractions[i]
//                self.showMarker(attraction: attraction)
//            }
//        }
//        
//        searchBar.endEditing(true)
//        searchActive = false
//    }
    
    // MARK: Get Ticket Functions
    func getInitialTickets(){
        mapView.clear()
        let bound = GMSCoordinateBounds(region: mapView.projection.visibleRegion())
        let northEast = bound.northEast
        let southWest = bound.southWest
        
        
        loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.label.text = "Retrieving Tickets"

        attractionHelper.getInitialAttractions(northLat: northEast.latitude, southLat: southWest.latitude, eastLon: northEast.longitude, westLon: southWest.longitude) { responseObject, error in
            
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let attractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as? NSArray){
                    self.coreDataHelper.wipeDB()

                    for i in 0 ..< attractions.count{
                        
                        let attraction = attractions[i]
                        
                        self.coreDataHelper.saveAttraction(attraction: attraction)
                        
                        self.showMarker(attraction: attraction)
                        
                    }
                }
            }else if error != nil {
                if error?.code == -1009 || (error?.code)! == NSURLErrorTimedOut{//error that appears if no connection, not sure what NSURLError to use for -1009
                    self.view.makeToast("Unable to retreive posts. Please try again.", duration: 3.0, position: .bottom)
                }else{
                    self.view.makeToast("Unable to retreive posts. Please try again.", duration: 3.0, position: .bottom)
                }
            }
            
            
            
            self.loadingNotification?.hide(animated: true)
            
            return
        }
    }
    
    func getNewTickets(){
        let oldIDs = self.coreDataHelper.getCommaSeperatedAttractionIDString()
        
        let bound = GMSCoordinateBounds(region: self.mapView.projection.visibleRegion())
        let northEast = bound.northEast
        let southWest = bound.southWest
        
        currentDataRequest = attractionHelper.getNewAttractions(northLat: northEast.latitude, southLat: southWest.latitude, eastLon: northEast.longitude, westLon: southWest.longitude, commaString: oldIDs, searchQuery: searchBar.text!){ responseObject, error in
            
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let attractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as? NSArray){
                
                    for i in 0 ..< attractions.count{
                        
                        let attraction = attractions[i]
                        
                        self.coreDataHelper.saveAttraction(attraction: attraction)
                        
                        self.showMarker(attraction: attraction)
                        
                    }
                }
            } else if error != nil {
                if error?.code == -1009 || (error?.code)! == NSURLErrorTimedOut{//error that appears if no connection, not sure what NSURLError to use for -1009
                    self.view.makeToast("Unable to retreive posts. Please try again.", duration: 3.0, position: .bottom)
                }
            }
            
            self.loadingNotification?.hide(animated: true)
            
            return
        }
        
    }
    
    func getNewSearchTickets(){
        let oldIDs = self.coreDataHelper.getCommaSeperatedAttractionIDString()
        
        let bound = GMSCoordinateBounds(region: self.mapView.projection.visibleRegion())
        let northEast = bound.northEast
        let southWest = bound.southWest
        
        currentDataRequest = attractionHelper.getNewAttractions(northLat: northEast.latitude, southLat: southWest.latitude, eastLon: northEast.longitude, westLon: southWest.longitude, commaString: oldIDs, searchQuery: searchBar.text!){ responseObject, error in
            
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let attractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as? NSArray){
                    
                    for i in 0 ..< attractions.count{
                        
                        let attraction = attractions[i]
                        self.coreDataHelper.saveAttraction(attraction: attraction)
                        self.showMarker(attraction: attraction)
                    }
                    
                    if attractions.count > 0{
                        self.centerMapOnLocation(location: CLLocation(latitude: attractions[0].lat, longitude: attractions[0].lon), withAnimation: true)
                    }else{
                        self.view.makeToast("No tickets found. Try another area.", duration: 3.0, position: .bottom)
                    }
                }
            } else if error != nil {
                if error?.code == -1009 || (error?.code)! == NSURLErrorTimedOut{//error that appears if no connection, not sure what NSURLError to use for -1009
                    self.view.makeToast("Unable to retreive posts. Please try again.", duration: 3.0, position: .bottom)
                }
            }
            
            self.loadingNotification?.hide(animated: true)
            
            return
        }
        
    }
    
    // MARK: map functions
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        if currentDataRequest != nil{
            currentDataRequest?.cancel()
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap overlay: GMSOverlay) {
        self.searchBar.endEditing(true)
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if self.mapView.camera.zoom >= 12.0{
            getNewTickets()
        }else{
            if lastZoom != self.mapView.camera.zoom && userLocation != nil{
                self.view.makeToast("Please zoom in to load posts", duration: 1.0, position: .bottom)
                lastZoom = self.mapView.camera.zoom
            }
        }
        
        if idleFromTap {
            mapView.selectedMarker = selectedMarker
            idleFromTap = false
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {

        centerInfoWindow(mapView: mapView, marker: marker)
        
        return true
    }
    
    func centerInfoWindow(mapView: GMSMapView, marker: GMSMarker){
        let center = mapView.camera.target.latitude
        let southMap = GMSCoordinateBounds(region: mapView.projection.visibleRegion()).southWest.latitude
        
        let diff = (center - southMap)/2
        
        let newLat = marker.position.latitude + diff
        
        //mapView.camera = GMSCameraPosition.camera(withLatitude: newLat, longitude: marker.position.longitude, zoom: mapView.camera.zoom)
        //mapView.moveCamera()
        mapView.animate(with: GMSCameraUpdate.setTarget(CLLocationCoordinate2D(latitude: newLat, longitude: marker.position.longitude)))
        idleFromTap = true
        selectedMarker = marker
    }
    
    
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        let infoWindow = Bundle.main.loadNibNamed("InfoWindow", owner: self, options: nil)?.first as! CustomInfoWindow
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        // localize to your grouping and decimal separator
        currencyFormatter.locale = NSLocale.current
        
        let loggedInID = loginHelper.getLoggedInUser().ID
        
        if let cdAttraction = marker.userData as? cdAttractionMO{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            infoWindow.date.text = dateFormatter.string(for: cdAttraction.date)
            
            infoWindow.attractionName.text = cdAttraction.name
            infoWindow.venueName.text = cdAttraction.venueName
            infoWindow.numTickets.text = String(cdAttraction.numTickets)
            infoWindow.ticketPrice.text = currencyFormatter.string(for: cdAttraction.ticketPrice)! + "/Ticket"
            infoWindow.attractionDescription.text = cdAttraction.attractionDescription

            
            if loggedInID != Int64(cdAttraction.creatorID){
                infoWindow.contact.text = "CONTACT SELLER"
            }else{
                infoWindow.contact.text = "THIS IS YOUR POST"
            }
            
            let url = URL(string: cdAttraction.imageURL!)

            infoWindow.image.kf.setImage(with: url)
            infoWindow.image.image = ImageHelper.circleImage(image: infoWindow.image.image!)
            
        }else if let attraction = marker.userData as? Attraction{
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMM dd, yyyy"
            infoWindow.date.text = dateFormatter.string(for: attraction.date)
            
            infoWindow.attractionName.text = attraction.name
            infoWindow.venueName.text = attraction.venueName
            infoWindow.numTickets.text = String(attraction.numTickets)
            infoWindow.ticketPrice.text = currencyFormatter.string(for: attraction.ticketPrice)! + "/Ticket"
            
            infoWindow.attractionDescription.text = attraction.description

            if loggedInID != attraction.creatorID {
                infoWindow.contact.text = "CONTACT SELLER"
            }else{
                infoWindow.contact.text = "THIS IS YOUR POST"
            }
            
            
            let url = URL(string: attraction.imageURL)
            
            infoWindow.image.kf.setImage(with: url)
            if infoWindow.image.image != nil{
                infoWindow.image.image = ImageHelper.circleImage(image: infoWindow.image.image!)
            }
            //above only works because kingfisher is used for the marker icon so the image is cached already. If I ever stop using kingfisher I will have to cache manually

        }
        
        return infoWindow
    }
    
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        if let attraction = marker.userData as? Attraction{
            let user = loginHelper.getLoggedInUser()
            if user.ID != 0{
                if attraction.creatorID == user.ID{
                    self.performSegue(withIdentifier: "segueMyTicketsFromInfo", sender: marker)
                }else{
                    contactSeller(attraction: attraction)
                }
            }else{
                contactSeller(attraction: attraction)
            }
        }else if let cdAttraction = marker.userData as? cdAttractionMO{
            let attraction = attractionHelper.cdAttractionToReg(attr: cdAttraction)
            let user = loginHelper.getLoggedInUser()
            if user.ID != 0{
                if attraction.creatorID == user.ID{
                    self.performSegue(withIdentifier: "segueMyTicketsFromInfo", sender: marker)
                }else{
                    contactSeller(attraction: attraction)
                }
            }else{
                contactSeller(attraction: attraction)
            }

        }
    }
    
    func contactSeller(attraction: Attraction){
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Retrieving seller info"
        
        
        loginHelper.getAccountDetails(userID: attraction.creatorID){ responseObject, error in
            
            if responseObject != nil {
                
                if responseObject == "0" {
                    self.showNotification(text: "Unable to retrieve seller info. Please try again.", delay: 2)
                }else{
                    if let u = self.loginHelper.getUserDetailsFromJson(json: responseObject!) as? User{
                        if u.email != "" && u.phoneNumber == ""{
                            self.sendEmail(recipientEmail: u.email, attraction: attraction)
                        }else if u.phoneNumber != "" && u.email == ""{
                            self.sendText(recipientPhone: u.phoneNumber, attraction: attraction)
                        }else{
                            let alert = UIAlertController(
                                title: "Text or Email",
                                message: "Would you like to contact the seller through Email or Text?",
                                preferredStyle: .alert)
                            
                            alert.addAction(UIAlertAction(title: "Text", style: UIAlertActionStyle.default, handler: { (test) -> Void in
                                alert.dismiss(animated: true)
                                self.sendText(recipientPhone: u.phoneNumber, attraction: attraction)
                            }))
                            
                            alert.addAction(UIAlertAction(title: "Email", style: UIAlertActionStyle.default, handler: { (test) -> Void in
                                alert.dismiss(animated: true)
                                self.sendEmail(recipientEmail: u.email, attraction: attraction)
                            }))
                            
                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (test) -> Void in
                                alert.dismiss(animated: true)
                            }))

                            
                            self.present(alert,animated: true,completion: nil)
                            

                        }
                    }else{
                        self.showNotification(text: "Unable to retrieve seller info. Please try again.", delay: 2)
                    }
                }
                
            }else if error != nil{
                self.showNotification(text: "Unable to retrieve seller info. Please try again.", delay: 2)
            }
            
            loadingNotification.hide(animated: true)
            return
        }
        
        
    }
    
    // MARK: Locate User Functions
    func checkLocationAuthorizationStatus() {
        
        if let location = locationHelper.getLastLocation() as? CLLocation{
            self.centerMapOnLocation(location: location, withAnimation: false)
            refreshMapAndGetInitialTickets(location: location)
        }
        
        if CLLocationManager.locationServicesEnabled() {
            mapView.isMyLocationEnabled = true
            
            locationManager.delegate = self
            //locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()
        }
        
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse {
            // Ask for Authorisation from the User.
            //self.locationManager.requestAlwaysAuthorization()
            
            self.locationManager.requestWhenInUseAuthorization()
        }
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.locationServicesEnabled() && status == .authorizedWhenInUse{
            mapView.isMyLocationEnabled = true
            
            locationManager.delegate = self
            //locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestLocation()
            
            if userLocation == nil{
                self.view.makeToast("Retrieving Your Location...", duration: 2.0, position: .bottom)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationNotification?.hide(animated: true)
        
        if let location = locations.first {
            
            if userLocation == nil{
                locationHelper.updateLastLocation(location: location)
                refreshMapAndGetNewTickets(location: location, withAnimation: false, center: firstLocationUpdate)//center if first time called, if not leave map
                firstLocationUpdate = false
            }else{
                let distance = location.distance(from: userLocation!)
                if distance >= 10 {
                    locationHelper.updateLastLocation(location: location)
                    refreshMapAndGetNewTickets(location: location, withAnimation: true, center: firstLocationUpdate)
                    firstLocationUpdate = false
                }
            }
            
        }else{
        }
        //locationManager.stopUpdatingLocation();
    }
    
    func refreshMapAndGetInitialTickets(location: CLLocation){
        self.userLocation = location
        getInitialTickets()
    }
    
    func refreshMapAndGetNewTickets(location: CLLocation, withAnimation: Bool, center: Bool){
        self.userLocation = location
        if center{
            centerMapOnLocation(location: location, withAnimation: withAnimation)
        }
        getNewTickets()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Unable to retrieve location")
    }
    
    
    func centerMapOnLocation(location: CLLocation, withAnimation: Bool) {
        
        if withAnimation{
            mapView.animate(to: GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 13.0))
        }else{
            mapView.camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 13.0)
        }
        
    }
    
    @IBAction func unwindToHomeVC(segue:UIStoryboardSegue) {
        
        
        if segue.identifier == "go_home_from_login"{
            if self.revealViewController() != nil {
                if loginHelper.getLoggedInUser().ID == 0 {
                    let loggedOutMenuController: LoggedOutMenuController = self.storyboard?.instantiateViewController(withIdentifier: "LoggedOutMenuController") as! LoggedOutMenuController
                    self.revealViewController().setRear(loggedOutMenuController, animated: false)
                }else{
                    let loggedInMenuController: LoggedInMenuController = self.storyboard?.instantiateViewController(withIdentifier: "LoggedInMenuController") as! LoggedInMenuController
                    self.revealViewController().setRear(loggedInMenuController, animated: false)
                }
            }
        }else if segue.identifier == "unwindToHome" {
            let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loginResponseNotification.mode = MBProgressHUDMode.customView
            loginResponseNotification.label.text = "Ticket Posted!"
            loginResponseNotification.hide(animated: true, afterDelay: 3)
            
            if newAttraction != nil{
                let marker = showMarker(attraction: self.newAttraction!)
                mapView.selectedMarker = marker
                let location = CLLocation(latitude: (self.newAttraction?.lat)!, longitude: (self.newAttraction?.lon)!)
                centerInfoWindow(mapView: self.mapView, marker: marker)
            }
        }
    }

    
    func showMarker(attraction: Attraction)->GMSMarker{
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: attraction.lat, longitude: attraction.lon)
        marker.title = attraction.name
        marker.userData = attraction
//        
//        let downloader: ImageDownloader! = ImageDownloader(name: "downloadIcons")
//        
//        downloader.downloadImage(with: Foundation.URL(string: attraction.imageURL)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
//            if image != nil{
//                marker.icon = self.imgHelper.ResizeImage(image: (self.imgHelper.circleImage(image: image!)), targetSize: CGSize(width: 50, height: 50))
//            }
//            
//            marker.map = self.mapView
//        })
    
        if Foundation.URL(string: attraction.imageURL) != nil{
            KingfisherManager.shared.retrieveImage(with: Foundation.URL(string: attraction.imageURL)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                if image != nil{
                    marker.icon = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 55, height: 55)))
                }
                
                marker.map = self.mapView
            })
        }else{
            marker.map = self.mapView
        }
        
        return marker

    }
    
    func showMarker(attraction: cdAttractionMO)->GMSMarker{
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: attraction.lat, longitude: attraction.lon)
        marker.title = attraction.name
        marker.userData = attraction
        //
        //        let downloader: ImageDownloader! = ImageDownloader(name: "downloadIcons")
        //
        //        downloader.downloadImage(with: Foundation.URL(string: attraction.imageURL)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
        //            if image != nil{
        //                marker.icon = self.imgHelper.ResizeImage(image: (self.imgHelper.circleImage(image: image!)), targetSize: CGSize(width: 50, height: 50))
        //            }
        //
        //            marker.map = self.mapView
        //        })
        
        
        KingfisherManager.shared.retrieveImage(with: Foundation.URL(string: attraction.imageURL!)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
            if image != nil{
                marker.icon = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 55, height: 55)))

            }
            
            marker.map = self.mapView
        })
        
        return marker
        
    }
    
    // MARK: Functions that should be in helper classes
    
    func showNotification(text: String, delay: Int){
        let Notification = MBProgressHUD.showAdded(to: self.view, animated: true)
        Notification.mode = MBProgressHUDMode.text
        Notification.label.text = text
        Notification.show(animated: true)
        Notification.hide(animated: true, afterDelay: TimeInterval(delay))
    }
    
    func sendEmail(recipientEmail: String, attraction: Attraction) {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        // localize to your grouping and decimal separator
        currencyFormatter.locale = NSLocale.current

        let subject = "ProQuo - " + attraction.name + " at " + attraction.venueName
        let message = "Hey, I saw your " + attraction.name + " at " + attraction.venueName + " tickets on ProQuo for " + currencyFormatter.string(for: attraction.ticketPrice)! + "/Ticket.\n\nAre they still for sale?"
        
        if MFMailComposeViewController.canSendMail() {
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([recipientEmail])
            mail.setSubject(subject)
            
            mail.setMessageBody(message, isHTML: false)
            present(mail, animated: true)
        } else {
            //showSendMailErrorAlert(email: recipientEmail)
            let coded = "mailto:\(recipientEmail)?subject=\(subject)&body=\(message)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            
            if let emailURL:URL = URL(string: coded!)
            {
                if UIApplication.shared.canOpenURL(emailURL as URL)
                {
                    UIApplication.shared.open(emailURL, options: [:])
                }else{
                    showSendMailErrorAlert(email: recipientEmail)
                }
            }
            
        }
    }
    
    func sendText(recipientPhone: String, attraction: Attraction){
        if (MFMessageComposeViewController.canSendText()) {
            let currencyFormatter = NumberFormatter()
            currencyFormatter.usesGroupingSeparator = true
            currencyFormatter.numberStyle = NumberFormatter.Style.currency
            // localize to your grouping and decimal separator
            currencyFormatter.locale = NSLocale.current
            
            let controller = MFMessageComposeViewController()
            controller.messageComposeDelegate = self
            let message = "Hey, I saw your " + attraction.name + " at " + attraction.venueName + " tickets on ProQuo for " + currencyFormatter.string(for: attraction.ticketPrice)! + "/Ticket. Are they still for sale?"
            controller.body = message
            controller.recipients = [recipientPhone]
            present(controller, animated: true)
        }else{
            showSendTextErrorAlert()
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
    
    
    func showSendMailErrorAlert(email: String) {
        let refreshAlert = UIAlertController(title: "Could Not Send Email", message: "This is likely because you don't have the default 'Mail' app installed or your 'Mail' settings are configured improperly.\n\nThe sellers email \n \(email) \n has been copied to your clipboard.\n\nSorry for the inconvenience.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (test) -> Void in
            UIPasteboard.general.string = email
            self.view.makeToast("Sellers email copied to clipboard.", duration: 2.0, position: .bottom)
        }))

        present(refreshAlert, animated: true, completion: nil)
        
    }
    
    func showSendTextErrorAlert() {
        let refreshAlert = UIAlertController(title: "Could Not Send Text", message: "Your device cannot send a text.  Please check your SMS configuration and try again.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(refreshAlert, animated: true, completion: nil)
        
    }

    


}



