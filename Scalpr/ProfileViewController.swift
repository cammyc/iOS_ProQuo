//
//  ProfileViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 5/23/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit
import MBProgressHUD
import Kingfisher

class ProfileViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    
    // MARK: UI Fields
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var gradientContainer: UIView!
    
    @IBOutlet weak var bEditProfile: UIButton!
  
    @IBOutlet weak var tfFirstName: UITextField!
    @IBOutlet weak var tfLastName: UITextField!
    @IBOutlet weak var dtfEmail: DesignableUITextField!
    @IBOutlet weak var dtfPhone: DesignableUITextField!
    @IBOutlet weak var bCreditCard: UIButton!
    @IBOutlet weak var bConnectFB: UIButton!
    @IBOutlet weak var bConnectGoogle: UIButton!
    
    // MARK: Variables
    let loginHelper:LoginHelper = LoginHelper()!
    
    var user:User = User()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        makeFieldsLookPretty()
        loadData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    // MARK: Load User
    func loadData(){
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading Profile Details"
        
        
        loginHelper.getAccountDetails(userID: (loginHelper.getLoggedInUser().ID)){ responseObject, error in
            
            if responseObject != nil {
                
                if responseObject == "0" || responseObject == "-1" {
                    self.showErrorAlert()
                }else{
                    if let u = self.loginHelper.getUserDetailsFromJson(json: responseObject!) as? User{
                        self.user = u
                        self.showUserData(u: u)
                    }else{
                        self.showErrorAlert()
                    }
                }
                
            }else if error != nil{
                self.showErrorAlert()
            }
            
            loadingNotification.hide(animated: true)
            return
        }
    }
    
    func showUserData(u: User){
        self.tfFirstName.text = u.firstName
        self.tfLastName.text = u.lastName
        self.dtfEmail.text = u.email
        self.dtfPhone.text = u.phoneNumber
        
        if !u.profPicURL.isEmpty{
            KingfisherManager.shared.retrieveImage(with: Foundation.URL(string: u.profPicURL)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                if image != nil{
                    self.profilePic.image = ImageHelper.circleImageBordered(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: self.profilePic.frame.height, height: self.profilePic.frame.height)), rgb: 0xFFFFFF, borderWidth: 5)
                }
            })
        }
        
        if !u.facebookID.isEmpty {
            bConnectFB.setTitle("Connected", for: .normal)
        }
        
        if !u.googleID.isEmpty {
            bConnectGoogle.setTitle("Connected", for: .normal)
        }

    }
    
    
    // MARK: FieldUI

    func makeFieldsLookPretty(){
        
        //profilePic init
        profilePic.layer.masksToBounds = false
        profilePic.layer.shadowColor = UIColor.black.cgColor
        profilePic.layer.shadowOpacity = 0.5
        profilePic.layer.shadowOffset = CGSize(width: -1, height: 1)
        profilePic.layer.shadowRadius = profilePic.frame.height/2
        
        profilePic.layer.shadowPath = UIBezierPath(rect: profilePic.bounds).cgPath
        profilePic.layer.shouldRasterize = true
        
        profilePic.image = ImageHelper.circleImageBordered(image: profilePic.image!, rgb: 0xFFFFFF, borderWidth: 7)
        
        //change profilePic
        bEditProfile.layer.cornerRadius = 20
        bEditProfile.layer.borderWidth = 1
        bEditProfile.layer.borderColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71).cgColor
        
        
        updateNameTextField(textField: tfFirstName)
        updateNameTextField(textField: tfLastName)
    
        
        updateDesignTextFields(textField: dtfEmail)
        updateDesignTextFields(textField: dtfPhone)
        
        //make card a button
        updateButtons(button: bCreditCard)
        
        bConnectGoogle.titleLabel?.textAlignment = .center
        bConnectFB.titleLabel?.textAlignment = .center

//
//        var imageView = UIImageView();
//        var image = UIImage(named: "profile_email");
//        //set frame
//        imageView.image = image;
//        tfEmail.leftView = imageView;
//        tfEmail.leftViewMode = UITextFieldViewMode.always
    }
    
    func updateNameTextField(textField: UITextField){
        textField.layer.cornerRadius = 7.5
        textField.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        textField.layer.borderColor = UIColor.white.cgColor
        textField.layer.borderWidth = 2.0
//        textField.layer.sublayerTransform = CATransform3DMakeTranslation(10,0,0)
        
    }
    
    func updateDesignTextFields(textField: DesignableUITextField){
        textField.layer.cornerRadius = 7.5
        textField.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: 0xCCCCCC).withAlphaComponent(0.5)
//        textField.layer.sublayerTransform = CATransform3DMakeTranslation(8,0,0)
//        textField.layer.borderColor = UIColor.white.cgColor
//        textField.layer.borderWidth = 2.0
    }
    
    func updateButtons(button: UIButton){
        button.layer.cornerRadius = 7.5
        button.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: 0xCCCCCC).withAlphaComponent(0.5)
//        if let size = button.imageView?.image?.size {
//            button.imageView?.frame = CGRect(x: 0.0, y: 0.0, width: size.width + 10.0, height: size.height)
//        }
//        button.imageView?.contentMode = UIViewContentMode.center
        button.imageEdgeInsets = UIEdgeInsetsMake(0, 11, 0, 0)
        button.titleEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 0)
        button.setTitleColor(MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), for: UIControlState.highlighted)

//        button.showsTouchWhenHighlighted = true
    }

    func setGradientBackground() {
        let colorTop =  MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71).cgColor
        let colorBottom = MiscHelper.UIColorFromRGB(rgbValue: 0xffffff).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = gradientContainer.bounds
        
//        gradientContainer.layer.addSublayer(gradientLayer)
        gradientContainer.layer.insertSublayer(gradientLayer, at: 0)
//        gradient
//        gradientContainer.layer.addS
    }
    
    
    // MARK: Button Click functions
    
    @IBAction func bUploadProfilePicAction(_ sender: Any) {
    }
    
    @IBAction func bAddCreditCardAction(_ sender: Any) {
    }
    
    
    @IBAction func bConnectFacebookAction(_ sender: Any) {
        
        //if profile page isn't loaded it exits so user cant be nil so no need to check
        if user.facebookID.isEmpty{
        }
        
        
        
    }
    
    @IBAction func bConnectGoogleAction(_ sender: Any) {
        
        if user.googleID.isEmpty{
            GIDSignIn.sharedInstance().signIn()
        }
        
    }
    

    // MARK: Google Functions
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            let notification = MBProgressHUD.showAdded(to: self.view, animated: true)
            notification.mode = MBProgressHUDMode.indeterminate
            notification.label.text = "Connecting Google Account"

            loginHelper.connectGoogleAccount(userID: self.user.ID, googleID: user.userID, displayPicURL: user.profile.imageURL(withDimension: 400).absoluteString){ responseObject, error in
                
                notification.hide(animated: true)
                
                if let response = Int64(responseObject!){
                    
                    if response == 1 {
                        self.user.googleID = user.userID
                        self.bConnectGoogle.setTitle("Connected", for: .normal)
                    }else if response == -1{
                        self.showCustomAlert(customTitle: "Already Connected", customMessage: "This Google account is already connected to another account. To use it logout then log in with your Google account.")
                        
                        GIDSignIn.sharedInstance().signOut()
                    }else{
                        self.showCustomAlert(customTitle: "Network Error", customMessage: "Unable to connect account. Please try again.")
                    }
                    
                }else{
                    self.showCustomAlert(customTitle: "Network Error", customMessage: "Unable to connect account. Please try again.")
                }
                
                return
            }
        }else{
            self.showCustomAlert(customTitle: "Google Sign In Error", customMessage: "Unable to sign in with Google. Please try again.")
        }
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
//        self.sign(signIn, present: viewController)
        self.present(viewController, animated: true, completion: nil)

    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    // MARK: Misc. Functions
    func showErrorAlert(){
        let refreshAlert = UIAlertController(title: "Unable to Load Profile", message: "Please try again.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }
    
    func showCustomAlert(customTitle: String, customMessage: String){
        let refreshAlert = UIAlertController(title: customTitle, message: customMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }
}
