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
import Whisper
import UserNotifications
import DLRadioButton
//import ARNTransitionAnimator
import Presentr


protocol FilterDelegate {
    
    func sliderFocused()
    
    func sliderUnfocused()
    
    func updateFilters(updatedFilter: Filters)
}

protocol TutorialDelegate{
    func checkVersionAndTerms()
}


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
    var requestNotification = false;
    var selectedMarker:GMSMarker? = nil
    let fabPostTicket = KCFloatingActionButton()
    let fabGoToMyLocation = KCFloatingActionButton()
    let fabAttractionList = KCFloatingActionButton()
    var firstLocationUpdate = true
    var attemptedInitialTickets = false
    
    var postSelectedFromList: cdAttractionMO? = nil
    var idleFromAttractionListContactSeller = false

    var blurView: UIVisualEffectView? = nil
    
    var postFilters = Filters()
    var geekMarkers = [GMSMarker]()
    
//    // MARK: Music Player
//    private var animator : ARNTransitionAnimator?
//    private var tempAnimator : ARNTransitionAnimator?
//
//    fileprivate var modalVC : ModalViewController!
    
    @IBOutlet weak var menuFilterButton: UIBarButtonItem!
    
//    let myNotification = Notification.Name(rawValue:"MyNotification"

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initiateOptions()
        
        let preferences = UserDefaults.standard
        
        if preferences.object(forKey: "viewedTutorial") == nil{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let controller = storyboard.instantiateViewController(withIdentifier: "TutorialPageViewController") as? TutorialPageViewController
            controller?.tutorialDelegate = self
            let presenter = Presentr(presentationType: .popup)
            
            preferences.set(true, forKey: "viewedTutorial")
            preferences.synchronize()
            
            customPresentViewController(presenter, viewController: controller!, animated: true, completion: nil)
        }
        
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
        fabPostTicket.paddingY =  fabPostTicket.paddingY
        self.view.addSubview(fabPostTicket)
        
        let icon2 = UIImage(named: "list_icon_green")
        fabAttractionList.buttonImage = ImageHelper.ResizeImage(image: icon2!, size: CGSize(width: (icon2?.size.width)!/2, height: (icon2?.size.height)!/2))
        fabAttractionList.buttonColor = MiscHelper.UIColorFromRGB(rgbValue: 0xFFFFFF)
        fabAttractionList.fabDelegate = self
        fabAttractionList.friendlyTap = false
        fabAttractionList.paddingY = fabAttractionList.frame.height + 25
        self.view.addSubview(fabAttractionList)

        
        let icon1 = UIImage(named: "My_Location")
        fabGoToMyLocation.buttonImage = ImageHelper.ResizeImage(image: icon1!, size: CGSize(width: (icon1?.size.width)!/2, height: (icon1?.size.height)!/2))
        fabGoToMyLocation.buttonColor = MiscHelper.UIColorFromRGB(rgbValue: 0xFFFFFF)
        fabGoToMyLocation.fabDelegate = self
        fabGoToMyLocation.friendlyTap = false
        fabGoToMyLocation.paddingY =  fabAttractionList.paddingY + fabGoToMyLocation.frame.height + 12.5
        self.view.addSubview(fabGoToMyLocation)
        
    }

    
//    func setupAnimator() {
//
//
//            let animation = MusicPlayerTransitionAnimation(rootVC: self, modalVC: self.modalVC)
//            animation.completion = { [weak self] isPresenting in
//                if isPresenting {
//                    guard let _self = self else { return }
//                    let modalGestureHandler = TransitionGestureHandler(targetVC: _self, direction: .bottom)
//                    modalGestureHandler.registerGesture(_self.modalVC.view)
//                    modalGestureHandler.panCompletionThreshold = 15.0
//                    _self.animator?.registerInteractiveTransitioning(.dismiss, gestureHandler: modalGestureHandler)
//                    //self?.animator?.unregisgterInteractiveTransitioning()
//                } else {
//                    self?.setupAnimator()
//                }
//            }
//
////            let gestureHandler = TransitionGestureHandler(targetVC: self, direction: .top)
////            gestureHandler.registerGesture(self.optionsView)
////            gestureHandler.panCompletionThreshold = 15.0
////
////            self.animator = ARNTransitionAnimator(duration: 0.5, animation: animation)
////            self.animator?.registerInteractiveTransitioning(.present, gestureHandler: gestureHandler)
//
//            self.modalVC.transitioningDelegate = self.animator
//            self.modalVC.delegate = self
//
//
//
//    }
    
//    func registerAnimator(){
//        let modalGestureHandler = TransitionGestureHandler(targetVC: self, direction: .bottom)
//        modalGestureHandler.registerGesture(modalVC.view)
//        modalGestureHandler.panCompletionThreshold = 15.0
//        self.animator?.registerInteractiveTransitioning(.dismiss, gestureHandler: modalGestureHandler)
//    }
//
//    func unRegisterAnimator(){
//        animator?.unregisgterInteractiveTransitioning()
//    }

    
    @IBAction func tappedOptions(_ sender: Any) {
//        self.present(self.modalVC, animated: true, completion: nil)
    }
    
    @IBAction func tappedFiltersAction(_ sender: Any) {
//        self.present(self.modalVC, animated: true, completion: nil)
    }
    
    func initiateOptions(){
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        self.modalVC = storyboard.instantiateViewController(withIdentifier: "ModalViewController") as? ModalViewController
//        self.modalVC.modalPresentationStyle = .overFullScreen
//
//        let color = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 0.3)
//       // self.miniPlayerButton.setBackgroundImage(self.generateImageWithColor(color), for: .highlighted)
//
//        self.setupAnimator()
    }
    
//    func setSwitchButton () {
//        
//        switchControl.backgroundColor = UIColor.red;
//        switchControl.layer.cornerRadius = 16.0;
//        
//        switchControl.setOn(false, animated: false)
//        switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .valueChanged)
//        }
//    
//    
//    func switchValueDidChange(sender:UISwitch!)
//    {
//        
//        let preferences = UserDefaults.standard
//        
//        if preferences.object(forKey: "hasToggled") == nil{
//            
//            let explanation = "Now you can view tickets being sold and tickets that are being requested! When toggled on, instead of the map showing you tickets being sold by sellers it will show you the tickets that have been requested by buyers."
//            
//            let alert = UIAlertController(title: "View Requested Tickets!",message: explanation,
//                        preferredStyle: UIAlertControllerStyle.alert)
//            
//            
//            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//
//            preferences.set(true, forKey: "hasToggled")
//        }
//        
//        
//        if sender.isOn {
//            print("on")
//            //showrequests
//        } else{
//            print("off")
//            //showsell
//        }
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if requestNotification {
            requestNotificationsAlert()
            requestNotification = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if CoreDataHelper.attractionChanged {
            getInitialTickets()
            CoreDataHelper.attractionChanged = false
        }
    }

    
//
//    func catchNotification(notification:Notification) -> Void {
//        print("Catch notification")
//        
//        guard let userInfo = notification.userInfo,
//            let message  = userInfo["message"] as? String,
//            let date     = userInfo["date"]    as? Date else {
//                print("No userInfo found in notification")
//                return
//        }
//        
//        let alert = UIAlertController(title: "Notification!",
//                                      message:"\(message) received at \(date)",
//            preferredStyle: UIAlertControllerStyle.alert)
//        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
//        self.present(alert, animated: true, completion: nil)
//    }
    
    
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
        }else if fab == fabAttractionList{
            self.performSegue(withIdentifier: "segue_attraction_list", sender: nil)
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
            message: "An update is required to continue using BeLive. Please close the app and update it in the app store.",
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
            message: "You must agree to BeLive's Terms of Service to continue using the app.",
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "View Terms", style: .default, handler: { (test) -> Void in
            UIApplication.shared.open(NSURL(string: "http://www.belivetickets.com/help/policies/terms_of_service.html")! as URL, options: [:])
            self.termsAlert()
        }))
        
        alert.addAction(UIAlertAction(title: "I Agree", style: .default, handler: { (test) -> Void in
            let preferences = UserDefaults.standard
            preferences.set(true, forKey: "acceptedTerms")
            preferences.synchronize()
            if CLLocationManager.authorizationStatus() == .denied{
                self.enableLocInSettings()
            }
            
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
                    let _ = self.showMarker(attraction: attraction)
                }
                searchActive = true
                
//                let count = attractions.count
//                self.optionsButton.setTitle(String(count) + " Posts Found • Filters", for: UIControlState.normal)
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
                let _ = self.showMarker(attraction: attraction)
            }
            
            getNewTickets()
            
            searchActive = false
            
            let count = attractions.count
//            self.optionsButton.setTitle(String(count) + " Posts Found • Filters", for: UIControlState.normal)
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        //unBlurView()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        unBlurView()//always call first incase blur wasn't removed
        //setBlurView(parent: searchBar)
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
    
    // MARK: Seat Feek Functions
    
    func getSeatGeekVenues(){
    
        let seatGeekHelper:SeatGeekHelper = SeatGeekHelper()!
        let lat = Double(self.mapView.camera.target.latitude)
        let lon = Double(self.mapView.camera.target.longitude)
        let bounds = GMSCoordinateBounds(region:self.mapView.projection.visibleRegion())
        let center = self.mapView.camera.target
        let ne = bounds.northEast
        let range = round(Double(GMSGeometryDistance(ne, center)) * 0.000621371)
        
        seatGeekHelper.getLocalVenues(lat: lat, lon: lon, range: range){ responseObject, error in
            if error == nil {
                for marker in self.geekMarkers {
                    marker.map = nil
                }
                
                self.geekMarkers.removeAll()
                let x = responseObject as! NSDictionary
                //                print(x)
                if let venues = x["venues"] as? NSArray{
                    for i in 0 ..< venues.count{
                        
                        let venue:NSDictionary = venues[i] as! NSDictionary
                        let numEvents = venue["num_upcoming_events"] as! Int
                        if numEvents > 0 {
                            let loc = venue["location"] as! NSDictionary
                            let lat = loc["lat"] as? Double
                            let lon = loc["lon"] as? Double
                            
                            let marker = GMSMarker()
                            marker.tracksInfoWindowChanges = true
                            marker.position = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
                            marker.title = venue["title"] as? String
                            marker.userData = venue
                            marker.icon = self.textToImage(drawText: venue["name"] as! NSString, inImage: UIImage(named: "ic_seatgeek_venue")!, atPoint: CGPoint(x: 0, y: 0))
                            marker.map = self.mapView
                            self.geekMarkers.append(marker)
                            //create object for easier reuse then make new infowindow
                        }
                    }
                }
                
            }else{
                
            }
            return
        }
    }
    
    func showVenueModal(venue: NSDictionary){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let controller = storyboard.instantiateViewController(withIdentifier: "selectedVenue") as? SelectedVenueViewController
        controller?.venue = venue
        let presenter = Presentr(presentationType: .popup)
        
        customPresentViewController(presenter, viewController: controller!, animated: true, completion: nil)
    }
    
    func textToImage(drawText: NSString, inImage: UIImage, atPoint: CGPoint) -> UIImage{
        
        // Setup the font specific variables
        var textColor = UIColor.black
        var textFont = UIFont(name: "Helvetica Bold", size: 10)!
        
        // Setup the image context using the passed image
        let scale = UIScreen.main.scale
        let textFontAttributes = [
            NSAttributedStringKey.font: textFont,
            NSAttributedStringKey.foregroundColor: textColor
            ] as [NSAttributedStringKey : Any]
        
        let textSize = drawText.size(withAttributes: textFontAttributes)
        
        let frameWidth = textSize.width
        let frameHeight =  inImage.size.height + textSize.height + 10
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: frameWidth, height: frameHeight), false, scale)
        
        // Setup the font attributes that will be later used to dictate how the text should be drawn
       

        // Put the image into a rectangle as large as the original image
        inImage.draw(in: CGRect(x: (frameWidth/2) - (inImage.size.width/2), y: 0, width: inImage.size.width, height: inImage.size.height))
        
        // Create a point within the space that is as bit as the image
        var rect = CGRect(x: 0, y: inImage.size.height, width: frameWidth, height: frameHeight)
        // Draw the text into an image
        drawText.draw(in: rect, withAttributes: textFontAttributes)
        
        // Create a new image out of the images we have created
        var newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        // End the context now that we have the image we need
        UIGraphicsEndImageContext()
        
        //Pass the image back up to the caller
        return newImage!
        
    }
    
    // MARK: Get Ticket Functions
    func getInitialTickets(){
        self.coreDataHelper.wipeAttractionsFromDB()

        mapView.clear()
        let bound = GMSCoordinateBounds(region: mapView.projection.visibleRegion())
        let northEast = bound.northEast
        let southWest = bound.southWest
        
        
        loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification?.mode = MBProgressHUDMode.indeterminate
        loadingNotification?.label.text = "Retrieving Tickets"
        
        getSeatGeekVenues()

        attractionHelper.getInitialAttractions(filters: postFilters, northLat: northEast.latitude, southLat: southWest.latitude, eastLon: northEast.longitude, westLon: southWest.longitude) { responseObject, error in
            
            self.attemptedInitialTickets = true
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let attractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as? NSArray){

                    for i in 0 ..< attractions.count{
                        
                        let attraction = attractions[i]
                        
                        self.coreDataHelper.saveAttraction(attraction: attraction)
                        
                        let _ = self.showMarker(attraction: attraction)
                        
                    }
                    
//                    if attractions.count > 0 {
//                        let count = self.coreDataHelper.getAttractions().count
//                        self.optionsButton.setTitle(String(count) + " Posts Found • Filters", for: UIControlState.normal)
//                    }
                    
                }
            }else if error != nil {

                if error?.code == -1009 || (error?.code)! == NSURLErrorTimedOut{//error that appears if no connection, not sure what NSURLError to use for -1009
                    self.view.makeToast("Unable to retreive posts. Move the map to try again.", duration: 3.0, position: .bottom)
                }else{
                    self.view.makeToast("Unable to retreive posts. Move the map to try again.", duration: 3.0, position: .bottom)
                }
            }
            
            
            
            self.loadingNotification?.hide(animated: true)
            
            return
        }
    }
    
    func getNewTickets(){
        if !attemptedInitialTickets {
            return //don't get new tickets if initial aren't loaded - really should get rid of initial function...
        }
        
        let oldIDs = self.coreDataHelper.getCommaSeperatedAttractionIDString()
        
        let bound = GMSCoordinateBounds(region: self.mapView.projection.visibleRegion())
        let northEast = bound.northEast
        let southWest = bound.southWest
        
        getSeatGeekVenues()
        
        currentDataRequest = attractionHelper.getNewAttractions(filters: postFilters, northLat: northEast.latitude, southLat: southWest.latitude, eastLon: northEast.longitude, westLon: southWest.longitude, commaString: oldIDs, searchQuery: searchBar.text!){ responseObject, error in
            
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let attractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as? NSArray){
                
                    for i in 0 ..< attractions.count{
                        
                        let attraction = attractions[i]
                        
                        self.coreDataHelper.saveAttraction(attraction: attraction)
                        
                        let _ = self.showMarker(attraction: attraction)
                        
                    }
                    
//                    if attractions.count > 0 {
//                        let count = self.coreDataHelper.getAttractions().count
//                        self.optionsButton.setTitle(String(count) + " Posts Found • Filters", for: UIControlState.normal)
//                    }
                }
            } else if error != nil {
                if error?.code == -1009 || (error?.code)! == NSURLErrorTimedOut{//error that appears if no connection, not sure what NSURLError to use for -1009
                    self.view.makeToast("Unable to retreive posts. Move the map to try again.", duration: 3.0, position: .bottom)
                }
            }
            
            self.loadingNotification?.hide(animated: true)
            
            return
        }
        
    }
    
    func getNewTicketsFromFilter(){
        self.coreDataHelper.wipeAttractionsFromDB()
        mapView.clear()
        
        let oldIDs = self.coreDataHelper.getCommaSeperatedAttractionIDString()
        
        let bound = GMSCoordinateBounds(region: self.mapView.projection.visibleRegion())
        let northEast = bound.northEast
        let southWest = bound.southWest
        
        self.loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        self.loadingNotification?.mode = MBProgressHUDMode.indeterminate
        self.loadingNotification?.label.text = "Retrieving Tickets"
        
        getSeatGeekVenues()
        
        currentDataRequest = attractionHelper.getNewAttractions(filters: postFilters, northLat: northEast.latitude, southLat: southWest.latitude, eastLon: northEast.longitude, westLon: southWest.longitude, commaString: oldIDs, searchQuery: searchBar.text!){ responseObject, error in
            
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let attractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as? NSArray){
                    
                    for i in 0 ..< attractions.count{
                        
                        let attraction = attractions[i]
                        
                        self.coreDataHelper.saveAttraction(attraction: attraction)
                        
                        let _ = self.showMarker(attraction: attraction)
                        
                    }
                    
//                    let count = self.coreDataHelper.getAttractions().count
//                    self.optionsButton.setTitle(String(count) + " Posts Found • Filters", for: UIControlState.normal)
//
                }
            } else if error != nil {
                if error?.code == -1009 || (error?.code)! == NSURLErrorTimedOut{//error that appears if no connection, not sure what NSURLError to use for -1009
                    self.view.makeToast("Unable to retreive posts. Move the map to try again.", duration: 3.0, position: .bottom)
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
        
        let query = searchBar.text!
        
        getSeatGeekVenues()
        
        currentDataRequest = attractionHelper.getNewAttractions(filters: postFilters, northLat: northEast.latitude, southLat: southWest.latitude, eastLon: northEast.longitude, westLon: southWest.longitude, commaString: oldIDs, searchQuery: query){ responseObject, error in
            
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let attractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as? NSArray){
                    
                    for i in 0 ..< attractions.count{
                        
                        let attraction = attractions[i]
                        self.coreDataHelper.saveAttraction(attraction: attraction)
                        _ = self.showMarker(attraction: attraction)
                    }
                    
                    if attractions.count > 0{
                        self.centerMapOnLocation(location: CLLocation(latitude: attractions[0].lat, longitude: attractions[0].lon), withAnimation: true)
//                        let count = self.coreDataHelper.getAttractions(query: query).count
//                        self.optionsButton.setTitle(String(count) + " Posts Found • Filters", for: UIControlState.normal)
                    }else{
                        self.view.makeToast("No tickets found. Try another area.", duration: 3.0, position: .bottom)
                    }
                }
            } else if error != nil {
                if error?.code == -1009 || (error?.code)! == NSURLErrorTimedOut{//error that appears if no connection, not sure what NSURLError to use for -1009
                    self.view.makeToast("Unable to retreive posts. Move the map to try again.", duration: 3.0, position: .bottom)
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
        getNewTickets()
//        if self.mapView.camera.zoom >= 12.0{
//            getNewTickets()
//        }else{
//            if lastZoom != self.mapView.camera.zoom && userLocation != nil{
//                self.view.makeToast("Please zoom in to load posts", duration: 1.0, position: .bottom)
//                lastZoom = self.mapView.camera.zoom
//            }
//        }
        
        if idleFromTap {
            mapView.selectedMarker = selectedMarker
            idleFromTap = false
        }else if idleFromAttractionListContactSeller{
            let user = loginHelper.getLoggedInUser()
            if user.ID != 0{
                self.contactSeller(attraction: attractionHelper.cdAttractionToReg(attr: postSelectedFromList!))
            }else{
                //MiscHelper.showWhisper(message: "You must be logged in to contact the seller", color: .red, navController: self.navigationController)
                self.showOkAlert(title: "Please Login", text: "You must be logged in to contact the seller.")
            }
            idleFromAttractionListContactSeller = false //reset
        }
        
        
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {

        if let venue =  marker.userData as? NSDictionary{
            showVenueModal(venue: venue)
            return false
        }else{
            centerInfoWindow(mapView: mapView, marker: marker)
            return true
        }
        
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
            infoWindow.date.text = MiscHelper.dateToString(date: cdAttraction.date!, format: "MMM dd, yyyy")
            
            let color: UInt = (cdAttraction.postType == 1) ? 0x2ecc71 : 0x3498db
            infoWindow.date.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: color)
            
            infoWindow.attractionName.text = cdAttraction.name
            infoWindow.venueName.text = cdAttraction.venueName
            infoWindow.numTickets.text = String(cdAttraction.numTickets)
            infoWindow.ticketPrice.text = currencyFormatter.string(for: cdAttraction.ticketPrice)! + "/Ticket"
            infoWindow.attractionDescription.text = cdAttraction.attractionDescription
            
            infoWindow.contact.textColor = MiscHelper.UIColorFromRGB(rgbValue: color)

            
            if loggedInID != Int64(cdAttraction.creatorID){
                let requestOrSell = (cdAttraction.postType == 1) ? "CONTACT SELLER" : "CONTACT REQUESTER"

                infoWindow.contact.text = requestOrSell
            }else{
                infoWindow.contact.text = "THIS IS YOUR POST"
            }
            
            let url = URL(string: cdAttraction.imageURL!)

            infoWindow.image.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { image, error,cacheType, imageURL in
                    if image != nil {
                        infoWindow.image.image = ImageHelper.circleImage(image: image!)
                    }
                }
            )

        
            
        }else if let attraction = marker.userData as? Attraction{
            infoWindow.date.text = MiscHelper.dateToString(date: attraction.date, format: "MMM dd, yyyy")
            
            let color: UInt = (attraction.postType == 1) ? 0x2ecc71 : 0x3498db
            infoWindow.date.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: color)
            
            infoWindow.attractionName.text = attraction.name
            infoWindow.venueName.text = attraction.venueName
            infoWindow.numTickets.text = String(attraction.numTickets)
            infoWindow.ticketPrice.text = currencyFormatter.string(for: attraction.ticketPrice)! + "/Ticket"
            infoWindow.attractionDescription.text = attraction.description
            
            infoWindow.contact.textColor = MiscHelper.UIColorFromRGB(rgbValue: color)

            if loggedInID != attraction.creatorID {
                let requestOrSell = (attraction.postType == 1) ? "CONTACT SELLER" : "CONTACT REQUESTER"

                infoWindow.contact.text = requestOrSell
            }else{
                infoWindow.contact.text = "THIS IS YOUR POST"
            }
            
            
            let url = URL(string: attraction.imageURL)
            
            infoWindow.image.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { image, error,cacheType, imageURL in
                    if image != nil {
                        infoWindow.image.image = ImageHelper.circleImage(image: image!)
                    }
                }
            )

            //above only works because kingfisher is used for the marker icon so the image is cached already. If I ever stop using kingfisher I will have to cache manually

        }
        
        if let venue =  marker.userData as? NSDictionary{
            return nil
        }else{
            return infoWindow
        }
        
        
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
//                contactSeller(attraction: attraction)
//                MiscHelper.showWhisper(message: "You must be logged in to contact the seller", color: .red, navController: self.navigationController)
                let text = (attraction.postType == 1) ? "seller." : "requester."
                
                  self.showOkAlert(title: "Please Login", text: "You must be logged in to contact the " + text)

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
                let text = (attraction.postType == 1) ? "seller." : "requester."

                MiscHelper.showWhisper(message: "You must be logged in to contact the " + text, color: .red, navController: self.navigationController)
            }

        }
    }
    
    func contactSeller(attraction: Attraction){
        
        let text = (attraction.postType == 1) ? "seller?" : "requester?"

        
        let alert = UIAlertController(
            title: "Contact Seller",
            message: "Would you like to contact the " + text,
            preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.default, handler: { (test) -> Void in
            
            let convoHelper = ConversationHelper()

            let notification = MBProgressHUD.showAdded(to: self.view, animated: true)
            notification.mode = MBProgressHUDMode.indeterminate
            notification.label.text = "Creating Conversation"
            
            convoHelper.createConversation(attractionID: attraction.ID, buyerID: self.loginHelper.getLoggedInUser().ID, attractionName: attraction.name){ responseObject, error in
                
                notification.hide(animated: true)
                
                if responseObject != nil {
                    if responseObject != "-1" {
                        self.performSegue(withIdentifier: "segue_create_convo", sender: nil)
                    }else{
                        self.showWhisper(message: "Unable to create conversation. Check network connection.", color: UIColor.red)
                    }
                }else{
                    self.showWhisper(message: "Unable to create conversation. Check network connection.", color: UIColor.red)
                }
                
                return
            }

        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (test) -> Void in
            alert.dismiss(animated: true)
        }))

        
        self.present(alert,animated: true,completion: nil)

        
        
//        loginHelper.getAccountDetails(userID: attraction.creatorID){ responseObject, error in
//            
//            if responseObject != nil {
//                
//                if responseObject == "0" {
//                    self.showNotification(text: "Unable to retrieve seller info. Please try again.", delay: 2)
//                }else{
//                    if let u = self.loginHelper.getUserDetailsFromJson(json: responseObject!) as? User{
////                        if u.email != "" && u.phoneNumber == ""{
////                            self.sendEmail(recipientEmail: u.email, attraction: attraction)
////                        }else if u.phoneNumber != "" && u.email == ""{
////                            self.sendText(recipientPhone: u.phoneNumber, attraction: attraction)
////                        }else{
////                            let alert = UIAlertController(
////                                title: "Text or Email",
////                                message: "Would you like to contact the seller through Email or Text?",
////                                preferredStyle: .alert)
////                            
////                            alert.addAction(UIAlertAction(title: "Text", style: UIAlertActionStyle.default, handler: { (test) -> Void in
////                                alert.dismiss(animated: true)
////                                self.sendText(recipientPhone: u.phoneNumber, attraction: attraction)
////                            }))
////                            
////                            alert.addAction(UIAlertAction(title: "Email", style: UIAlertActionStyle.default, handler: { (test) -> Void in
////                                alert.dismiss(animated: true)
////                                self.sendEmail(recipientEmail: u.email, attraction: attraction)
////                            }))
////                            
////                            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (test) -> Void in
////                                alert.dismiss(animated: true)
////                            }))
////
////                            
////                            self.present(alert,animated: true,completion: nil)
////                            
//
////                        }
//                    }else{
//                        self.showNotification(text: "Unable to retrieve seller info. Please try again.", delay: 2)
//                    }
//                }
//                
//            }else if error != nil{
//                self.showNotification(text: "Unable to retrieve seller info. Please try again.", delay: 2)
//            }
//            
//            loadingNotification.hide(animated: true)
//            return
//        }
        
        
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
        
        if CLLocationManager.authorizationStatus() == .denied{
            enableLocInSettings()
        }else if CLLocationManager.authorizationStatus() != .authorizedWhenInUse{
            self.locationManager.requestWhenInUseAuthorization()

        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.locationServicesEnabled() && status == .authorizedWhenInUse{
            mapView.isMyLocationEnabled = true
            
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            //locationManager.requestLocation()
            locationManager.startUpdatingLocation()
            
            if userLocation == nil{
                attemptedInitialTickets = true //so that when location updates new tickets appear
                self.view.makeToast("Retrieving Your Location...", duration: 2.0, position: .bottom)
            }
        }
    }
    
    func enableLocInSettings(){
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(url as URL, options: [:], completionHandler: nil)
            }
        }
        
        let refreshAlert = UIAlertController(title: "Location required", message: "Your location is required to use this app. Please enable location services in the app settings.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(openAction)
        present(refreshAlert, animated: true, completion: nil)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationNotification?.hide(animated: true)
        
        if let location = locations.first {
            
            if location.horizontalAccuracy < 20{
                
                let animate = (userLocation == nil) ? false : true
                
                let _ = locationHelper.updateLastLocation(location: location)
                refreshMapAndGetNewTickets(location: location, withAnimation: animate, center: firstLocationUpdate)
                firstLocationUpdate = false
        
                locationManager.stopUpdatingLocation()
                
                print("location stop")

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
    
    func requestNotificationsAlert(){ //TEST ON PHONE TO MAKE SURE DEVICE TOKEN IS REGISTERED
        
        let preferences = UserDefaults.standard
        let hasRequestedNotifications = preferences.object(forKey: "hasRequestedNotifications")
        
        if hasRequestedNotifications == nil{
            
            let notificationType = UIApplication.shared.currentUserNotificationSettings!.types
            
            if notificationType == [] {
        
                let alert = UIAlertController(title: "Notifications", message:"Would you like to receive a notification when contacted by a buyer?",
                                              preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (test) -> Void in
                    // iOS 10 support
                    if #available(iOS 10, *) {
                        UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in
                            
                            if granted == false {
                                let alert = UIAlertController(title: "Declined Notifications", message:"It appears you have previously declined notifications from this app. Please go to Settings->Notifications, find BeLive and re-enable notifications to receive updates when messaged.",preferredStyle: UIAlertControllerStyle.alert)
                                
                                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (test) -> Void in
                                    
                                }))
                                
                                self.present(alert, animated: true, completion: nil)
                            }
                            
                        }
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                        // iOS 9 support
                    else if #available(iOS 9, *) {
                        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                        // iOS 8 support
                    else if #available(iOS 8, *) {
                        UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                        // iOS 7 support
                    else {
                        UIApplication.shared.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
                    }
                    
                    preferences.set(true, forKey: "hasRequestedNotifications")
                    preferences.synchronize()
                    
                }))
                
                alert.addAction(UIAlertAction(title: "No", style: .default, handler: { (test) -> Void in
                    
                }))
                
                alert.addAction(UIAlertAction(title: "Never", style: .cancel, handler: { (test) -> Void in
                    preferences.set(false, forKey: "hasRequestedNotifications")
                    preferences.synchronize()
                }))
                
                self.present(alert, animated: true, completion: nil)
            }
        }

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        
        if segue.identifier == "segue_attraction_list"{
            let attractionListTableViewController = (segue.destination as! AttractionListTableViewController)
            attractionListTableViewController.attractions = coreDataHelper.getAttractionsByDate() as! [cdAttractionMO]
        }
//        else if segue.identifier == "login_to_post_ticket"{
//            let modal = segue.destination as! ModalViewController
//        }
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
            
            requestNotification = true;
            
            
            if newAttraction != nil{
                let marker = showMarker(attraction: self.newAttraction!)
                mapView.selectedMarker = marker
                _ = CLLocation(latitude: (self.newAttraction?.lat)!, longitude: (self.newAttraction?.lon)!)
                centerInfoWindow(mapView: self.mapView, marker: marker)
            }
        }else if segue.identifier == "segue_go_to_post"{
            if postSelectedFromList != nil{
                mapView.animate(to: GMSCameraPosition.camera(withLatitude: (postSelectedFromList?.lat)!, longitude: (postSelectedFromList?.lon)!, zoom: 15.5))
            }
        }else if segue.identifier == "segue_contact_seller_from_list"{
            if postSelectedFromList != nil{
                let zoomTo:Float = (self.mapView.camera.zoom == 15.5) ? 15.4 : 15.5
                mapView.animate(to: GMSCameraPosition.camera(withLatitude: (postSelectedFromList?.lat)!, longitude: (postSelectedFromList?.lon)!, zoom: zoomTo))
                idleFromAttractionListContactSeller = true
            }
        }
    }

    
    func showMarker(attraction: Attraction)->GMSMarker{
        let marker = GMSMarker()
        marker.tracksInfoWindowChanges = true
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
                    
                    if attraction.postType == 2 {
                        marker.icon = ImageHelper.circleImageBordered(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 55, height: 55)), rgb: 0x3498db, borderWidth: 4)
                    }else{
                        marker.icon = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 55, height: 55)))
                    }
                    
                    
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
                
                
                if attraction.postType == 2 {
                    marker.icon = ImageHelper.circleImageBordered(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 55, height: 55)), rgb: 0x3498db, borderWidth: 4)
                }else{
                    marker.icon = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 55, height: 55)))
                }


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
    
    func showWhisper(message: String, color: UIColor){
        if self.navigationController != nil{
            let connectingWhisper = Whisper.Message(title: message, backgroundColor: color)
            Whisper.show(whisper: connectingWhisper, to: self.navigationController!, action: .show)
        }
    }
    
    func sendEmail(recipientEmail: String, attraction: Attraction) {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = NumberFormatter.Style.currency
        // localize to your grouping and decimal separator
        currencyFormatter.locale = NSLocale.current

        let subject = "BeLive - " + attraction.name + " at " + attraction.venueName
        let message = "Hey, I saw your " + attraction.name + " at " + attraction.venueName + " tickets on BeLive for " + currencyFormatter.string(for: attraction.ticketPrice)! + "/Ticket.\n\nAre they still for sale?"
        
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
            let message = "Hey, I saw your " + attraction.name + " at " + attraction.venueName + " tickets on BeLive for " + currencyFormatter.string(for: attraction.ticketPrice)! + "/Ticket. Are they still for sale?"
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

    func showOkAlert(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            self.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }


}


extension HomeViewController : FilterDelegate {
    internal func sliderFocused() {
//        unRegisterAnimator()
    }

    internal func sliderUnfocused() {
//        registerAnimator()
    }
    
    internal func updateFilters(updatedFilter: Filters){
        self.postFilters = updatedFilter
        self.getNewTicketsFromFilter()
        //refreshMapWithNewParams()
    }
}

extension HomeViewController : TutorialDelegate {
    
    internal func checkVersionAndTerms(){
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

    }
}



