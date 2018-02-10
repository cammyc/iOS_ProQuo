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
import FacebookCore
import FBSDKLoginKit
import FacebookLogin
import Stripe
import IQKeyboardManagerSwift
import KCFloatingActionButton
import GoogleSignIn

class ProfileViewController: UIViewController, GIDSignInUIDelegate, GIDSignInDelegate, STPAddCardViewControllerDelegate{
    
    
    // MARK: UI Fields
    @IBOutlet weak var profilePic: UIImageView!
    @IBOutlet weak var gradientContainer: UIView!
    
    @IBOutlet weak var bEditProfile: UIButton!
  
    @IBOutlet weak var tfFirstName: UITextField!
    @IBOutlet weak var tfLastName: UITextField!
    @IBOutlet weak var dtfEmail: DesignableUITextField!
    @IBOutlet weak var dtfPhone: DesignableUITextField!

    @IBOutlet weak var bAddPaymentOption: UIButton!
    @IBOutlet weak var bAddReceivalOption: UIButton!
    
    @IBOutlet weak var bConnectFB: UIButton!
    @IBOutlet weak var bConnectGoogle: UIButton!
    let settingsVC = SettingsViewController()
    
    @IBOutlet weak var fabSave: KCFloatingActionButton!
    
    var ADD_CARD_CODE = 0
    let ADD_PAYMENT_METHOD = 1
    let ADD_RECEIVAL_METHOD = 2
    let UPDATE_PAYMENT_METHOD = 3
    let UPDATE_RECEIVAL_METHOD = 4

    
    // MARK: Variables
    let loginHelper:LoginHelper = LoginHelper()!
    
    var user:User = User()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        fabSave.sticky = true
        
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

        if u.stripeAccount.isInitialized {
            if !u.stripeAccount.paymentPreview.isEmpty{
                if u.stripeAccount.paymentType == "card"{
                    bAddPaymentOption.setTitle("Payment: xxxx xxxx xxxx " + u.stripeAccount.paymentPreview, for: .normal)
                }else{
                    
                }
            }
            
            if !u.stripeAccount.receivalPreview.isEmpty{
                if u.stripeAccount.receivalType == "card"{
                    bAddReceivalOption.setTitle("Receival: xxxx xxxx xxxx " + u.stripeAccount.receivalPreview, for: .normal)
                }
            }
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
        updateButtons(button: bAddPaymentOption)
        updateButtons(button: bAddReceivalOption)
        
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
//        textField.layer.cornerRadius = 7.5
//        textField.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: 0xCCCCCC).withAlphaComponent(0.5)
//        textField.layer.sublayerTransform = CATransform3DMakeTranslation(8,0,0)
//        textField.layer.borderColor = UIColor.white.cgColor
//        textField.layer.borderWidth = 2.0
    }
    
    func updateButtons(button: UIButton){
//        button.layer.cornerRadius = 7.5
//        button.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: 0xCCCCCC).withAlphaComponent(0.5)
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
    
    
    @IBAction func bAddReceivalAction(_ sender: Any) {
        if user.email.isEmpty {
            //require email - haven't coded it to updated email yet
            //add dob field to profile?
        }
        
        if user.stripeAccount.isInitialized {
            if !user.stripeAccount.paymentPreview.isEmpty{
                let updateOrDelete = UIAlertController(title: "Update or Delete", message: "Would you like to update or delete your receival method?", preferredStyle: UIAlertControllerStyle.alert)
                
                updateOrDelete.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action: UIAlertAction!) in
                    //                    ADD_CARD_CODE = UPDATE_PAYMENT_METHOD
                    //                    self.updateDebitCreditCard()
                }))
                
                updateOrDelete.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
                    
                }))
                
                updateOrDelete.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    
                }))
                
                self.present(updateOrDelete,animated: true,completion: nil)
                
                
                return
            }
        }

        
        ADD_CARD_CODE = ADD_RECEIVAL_METHOD;
        
        let locale = Locale.current
        
        if locale.regionCode == "US" {
            
            let bankOrCardAlert = UIAlertController(title: "Card or Account", message: "Would you like to add a debit card or bank account?", preferredStyle: UIAlertControllerStyle.alert)
            
            bankOrCardAlert.addAction(UIAlertAction(title: "Debit Card", style: .default, handler: { (action: UIAlertAction!) in
                self.addDebitCreditCard()
            }))
            
            bankOrCardAlert.addAction(UIAlertAction(title: "Bank Account", style: .default, handler: { (action: UIAlertAction!) in
                
            }))
            
            bankOrCardAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                
            }))
            
            
            self.present(bankOrCardAlert,animated: true,completion: nil)
            
            
        }else{
            //            STPAPIClient.shared().createToken(withBankAccount: <#T##STPBankAccountParams#>, completion: <#T##STPTokenCompletionBlock?##STPTokenCompletionBlock?##(STPToken?, Error?) -> Void#>)
        }

    }
  
    
    @IBAction func bAddPaymentAction(_ sender: Any) {
        
        if user.email.isEmpty {
            //require email - haven't coded it to updated email yet
            //add dob field to profile?
        }
        
        if user.stripeAccount.isInitialized {
            if !user.stripeAccount.paymentPreview.isEmpty{
                let updateOrDelete = UIAlertController(title: "Update or Delete", message: "Would you like to update or delete your payment method?", preferredStyle: UIAlertControllerStyle.alert)
                
                updateOrDelete.addAction(UIAlertAction(title: "Update", style: .default, handler: { (action: UIAlertAction!) in
//                    ADD_CARD_CODE = UPDATE_PAYMENT_METHOD
//                    self.updateDebitCreditCard()
                }))
                
                updateOrDelete.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (action: UIAlertAction!) in
                    
                    let confirmDialog = UIAlertController(title: "Confirm", message: "Are you sure you want to delete this payment method?", preferredStyle: UIAlertControllerStyle.alert)
                    
                    confirmDialog.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                        
                    }))
                    
                    confirmDialog.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    
                    self.present(confirmDialog, animated: true, completion: nil)
                    
                }))
                
                updateOrDelete.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                    
                }))
                
                self.present(updateOrDelete,animated: true,completion: nil)


                return
            }
        }
        
        ADD_CARD_CODE = ADD_PAYMENT_METHOD
        self.addDebitCreditCard()
    }
    
    func addDebitCreditCard(){
        let paymentConfig = STPPaymentConfiguration.init();
        paymentConfig.requiredBillingAddressFields = STPBillingAddressFields.full;
        paymentConfig.publishableKey = "pk_test_EUXTG75yVL1mFS57Q7b0Svkz"
        //        let theme = STPTheme.defaultTheme();
        
        let addCardViewController = STPAddCardViewController(configuration: paymentConfig, theme: STPTheme.default())
        addCardViewController.delegate = self
        
        addCardViewController.managedAccountCurrency = "usd"
        
        // STPAddCardViewController must be shown inside a UINavigationController.
        let navigationController = UINavigationController(rootViewController: addCardViewController)
        self.present(navigationController, animated: true, completion: nil)
        IQKeyboardManager.sharedManager().enable = false
        
        /*
         NEED TO EITHER CREATE OWN FIELDS AND GENERATE TWO TOKENS OR HAVE TWO FIELDS ON PROFILE AND HAVE PAYMENTA ACCOUNT AND RECEIVING ACCOUNT
 
        */
        
    }
    
    func addCardViewControllerDidCancel(_ addCardViewController: STPAddCardViewController) {
        IQKeyboardManager.sharedManager().enable = true
        self.dismiss(animated: true, completion: nil)
    }
    
    
    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: @escaping STPErrorBlock) {
        //ACCEPT TERMS OF SERVICE HERE FIRST

        
        IQKeyboardManager.sharedManager().enable = true
        let tokenID: String = token.tokenId
        let country:String = (token.card?.addressCountry!)!
        let city:String = (token.card?.addressCity!)!
        let addressLine:String = (token.card?.addressLine1!)!
        let postalCode:String = (token.card?.addressZip!)!
        let provinceState:String = (token.card?.addressState!)!
        
        let stripeHelper = StripeAPIHelper()

        
        if ADD_CARD_CODE == ADD_PAYMENT_METHOD {
        
            let cardID:String = (token.card?.cardId)!
            stripeHelper?.createStripeAccountWithPaymentMethod(tokenID: tokenID, country: country, city: city, addressLine: addressLine, postalCode: postalCode, provinceState: provinceState, cardID: cardID){ responseObject, error in
                
                if responseObject != nil {
                    print(responseObject)
                  
                }else{
                    print(error.debugDescription)
                }
                
                return
            }
        } else if ADD_CARD_CODE == ADD_RECEIVAL_METHOD {
            stripeHelper?.createStripeAccountWithReceivalMethod(tokenID: tokenID, country: country, city: city, addressLine: addressLine, postalCode: postalCode, provinceState: provinceState, receivalType: "card"){ responseObject, error in
                
                if responseObject != nil {
                    print(responseObject)
                    
                }else{
                    print(error.debugDescription)
                }
                
                return
            }
        }
        
        /* Send Details to server */
        self.dismiss(animated: true, completion: nil)
    }
    
    
//    func addCardViewController(_ addCardViewController: STPAddCardViewController, didCreateToken token: STPToken, completion: STPErrorBlock) {
//        print(token.tokenId)
////        self.submitTokenToBackend(token, completion: { (error: Error?) in
////            if let error = error {
////                completion(error)
////            } else {
////                self.dismiss(animated: true, completion: {
////                    self.showReceiptPage()
////                    completion(nil)
////                })
////            }
////        })
//    }
//  
    
    @IBAction func bConnectFacebookAction(_ sender: Any) {
        
        //if profile page isn't loaded it exits so user cant be nil so no need to check
        if user.facebookID.isEmpty{
            let login:FBSDKLoginManager = FBSDKLoginManager()
            login.logIn(withReadPermissions: ["email", "public_profile"], from: self) { (result, error) -> Void in
                if (error != nil){
                    // Process error
                    self.fbSignInErrorAlert()
                }else{
                    
                    let fbloginresult : FBSDKLoginManagerLoginResult = result!
                    
                    if fbloginresult.isCancelled {
                        return
                    }
                    
                    if((FBSDKAccessToken.current()) != nil){
                        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email"]).start(completionHandler: { (connection, result, error) -> Void in
                            if (error == nil){
                                
                                //everything works
                                
                                let notification = MBProgressHUD.showAdded(to: self.view, animated: true)
                                notification.mode = MBProgressHUDMode.indeterminate
                                notification.label.text = "Connecting Facebook Account"
                                
                                let fbDetails = result as! NSDictionary
                                
                                let fbID = fbDetails["id"] as? String


                                self.loginHelper.connectFacebookAccount(facebookID: fbID!){ responseObject, error in
                                    
                                    notification.hide(animated: true)
                                    
                                    if let response = Int64(responseObject!){
                                        
                                        if response == 1 {
                                            self.user.facebookID = fbID!
                                            self.bConnectFB.setTitle("Connected", for: .normal)
                                        }else if response == -1{
                                            self.showCustomAlert(customTitle: "Already Connected", customMessage: "This Facebook account is already connected to another account. To use it logout then log in with your Facebook account.")
                                            
                                            FBSDKLoginManager().logOut()
                                        }else{
                                            self.networkErrorAlert()                                        }
                                        
                                    }else{
                                        self.networkErrorAlert()
                                    }
                                    
                                    return
                                }

                            }else{
                                self.fbSignInErrorAlert()
                            }
                        })
                    }
                }
            }
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

            loginHelper.connectGoogleAccount(googleID: user.userID, displayPicURL: user.profile.imageURL(withDimension: 400).absoluteString){ responseObject, error in
                
                notification.hide(animated: true)
                
                if let response = Int64(responseObject!){
                    
                    if response == 1 {
                        self.user.googleID = user.userID
                        self.bConnectGoogle.setTitle("Connected", for: .normal)
                    }else if response == -1{
                        self.showCustomAlert(customTitle: "Already Connected", customMessage: "This Google account is already connected to another account. To use it logout then log in with your Google account.")
                        
                        GIDSignIn.sharedInstance().signOut()
                    }else{
                        self.networkErrorAlert()
                    }
                    
                }else{
                    self.networkErrorAlert()
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
    
    func fbSignInErrorAlert(){
        self.showCustomAlert(customTitle: "Facebook Sign In Error", customMessage: "Unable to sign in with Facebook. Please try again.")
    }
    
    func networkErrorAlert(){
        self.showCustomAlert(customTitle: "Network Error", customMessage: "Unable to connect account. Please try again.")
    }
}
