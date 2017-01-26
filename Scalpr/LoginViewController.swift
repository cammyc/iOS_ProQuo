//
//  LoginViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 10/2/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import MBProgressHUD
import FacebookLogin
import FacebookCore
import FBSDKLoginKit

class LoginViewController: UIViewController, LoginButtonDelegate, UITextFieldDelegate, GIDSignInUIDelegate, GIDSignInDelegate {
    
    // MARK: Text Field Initialization
    @IBOutlet weak var tfEmailPhoneLogin: UITextField!
    @IBOutlet weak var tfPasswordLogin: UITextField!
    @IBOutlet weak var tfFirstNameCC: UITextField!
    @IBOutlet weak var tfLastNameCC: UITextField!
    @IBOutlet weak var tfEmailPhoneCC: UITextField!
    @IBOutlet weak var tfConfirmEmailPhoneCC: UITextField!
    @IBOutlet weak var tfPasswordCC: UITextField!
    @IBOutlet weak var tfPasswordConfirmCC: UITextField!
    
    // MARK: Button Initialization
    @IBOutlet weak var bSignIn: UIButton!
    @IBOutlet weak var bCreateAccount: UIButton!
    @IBOutlet weak var facebookView: UIView!
    
    // MARK: Misc Initialization
    @IBOutlet weak var menuButton: UIBarButtonItem!
    var loadingNotification: MBProgressHUD? = nil
    var googleNotification: MBProgressHUD? = nil

    let loginHelper:LoginHelper = LoginHelper()!
    let facebookUser = User()
    let googleUser = User()
    var fbUserID: String? = nil
    var googleUserID: String? = nil
    var googleDisplayPicURL: String? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        facebookInitialization()
        
        googleInitialization()
        
        initializeTextFields()

        bSignIn.isEnabled = false
        bCreateAccount.isEnabled = false
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PostTicketViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    

    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    // MARK: Google
    
    func googleInitialization(){
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            // Perform any operations on signed in user here.
            
            self.googleUserID = user.userID!
            self.googleUser.firstName = user.profile.givenName!
            self.googleUser.lastName = user.profile.familyName!
            self.googleUser.email = user.profile.email!
            self.googleDisplayPicURL = user.profile.imageURL(withDimension: 200).absoluteString
            
            
            let notification = MBProgressHUD.showAdded(to: self.view, animated: true)
            notification.mode = MBProgressHUDMode.indeterminate
            notification.label.text = "Logging in with Google"
            
            
            loginHelper.googleCreateAccountLoginRequest(firstName: googleUser.firstName, lastName: googleUser.lastName, email: googleUser.email, displayPicURL: googleDisplayPicURL!, googleID: googleUserID!){ responseObject, error in
                
                notification.hide(animated: true)
                
                if let response = Int64(responseObject!){
                    switch response{
                    case 0:
                        MiscHelper.showWhisper(message: "Network error. Please try again.", color: UIColor.red, navController: self.navigationController)
                        break
                    case -1:
                        MiscHelper.showWhisper(message: "Network error. Please try again.", color: UIColor.red, navController: self.navigationController)
                        break
                    case -2:
                        self.showAlert(title: "Email Taken", text: "There is already an account that uses your Google email address. Please change the email on that account then try again. If you did not create the account using your email please contact us.")
                        break
                    default:
                        if response > 0 {
                            MiscHelper.showWhisper(message: "Google login successful.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), navController: self.navigationController)
                            
                            self.googleUser.ID = response
                            self.loginSuccessfullTasks(userID: self.googleUser.ID)
                            let _ = self.loginHelper.saveLoggedInUser(user: self.googleUser)
                            
                            self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                        }
                        //not sure what happens here
                        break
                    }
                }else{
                    //user logged in parse date
                    MiscHelper.showWhisper(message: "Google login successful.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), navController: self.navigationController)
                    
                    let user = self.loginHelper.getUserDetailsFromJson(json: responseObject!)
                    self.loginSuccessfullTasks(userID: (user as! User).ID)
                    let _ = self.loginHelper.saveLoggedInUser(user: user as! User)
                    
                    self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                }

                
                return
            }
            // ...
        } else {
            print("\(error.localizedDescription)")
        }
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    // MARK: Facebook
    
    func facebookInitialization(){
        let loginButton = LoginButton(readPermissions: [.publicProfile, .email])

        loginButton.frame.size.width = facebookView.frame.width
        facebookView.addSubview(loginButton)
        
//        if let accessToken = AccessToken.current {
//            print("logged in")
//        }
        
        loginButton.delegate = self
    }
    
    // Facebook Delegate Methods
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("logged out")

    }
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        
        switch result {
            case .success(let _, let _, let _):
                returnUserData()
                break;
            case .cancelled:
                
                break;
            case .failed(let error):
                print(error)
                break;
            
        
        }
    }
    
    func returnUserData()
    {
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email"])
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                // Process error
                print("Error: \(error)")
            }
            else
            {
                let fbDetails = result as! NSDictionary

                self.fbUserID = fbDetails["id"] as? String
                self.facebookUser.firstName = fbDetails["first_name"] as! String
                self.facebookUser.lastName = fbDetails["last_name"] as! String

                if let userEmail = fbDetails["email"] as? String{
                    self.facebookUser.email = userEmail
                }
                
                self.faceBookLoginRequest()
                //print("User Email is: \(userEmail)")
            }
        })
    }
    
    func faceBookLoginRequest(){
        let notification = MBProgressHUD.showAdded(to: self.view, animated: true)
        notification.mode = MBProgressHUDMode.indeterminate
        notification.label.text = "Logging in with Facebook"
        
        let _ = loginHelper.facebookCreateAccountLoginRequest(firstName: facebookUser.firstName, lastName: facebookUser.lastName, email: facebookUser.email, facebookID: self.fbUserID!){ responseObject, error in
            
            notification.hide(animated: true)
            
            if let response = Int64(responseObject!){
                switch response{
                case 0:
                    MiscHelper.showWhisper(message: "Network error. Please try again.", color: UIColor.red, navController: self.navigationController)
                    break
                case -1:
                    MiscHelper.showWhisper(message: "Network error. Please try again.", color: UIColor.red, navController: self.navigationController)
                    break
                case -2:
                    self.showAlert(title: "Email Taken", text: "There is already an account that uses your Facebook email address. Please change the email on that account then try again. If you did not create the account using your email please contact us.")
                    break
                case -3:
                    self.requestFacebookEmail()
                    break
                default:
                    if response > 0 {
                        MiscHelper.showWhisper(message: "Facebook login successful.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), navController: self.navigationController)
                        
                        self.facebookUser.ID = response
                        self.loginSuccessfullTasks(userID: self.facebookUser.ID)
                        let _ = self.loginHelper.saveLoggedInUser(user: self.facebookUser)
                        
                        self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                    }
                    //not sure what happens here
                    break
                }
            }else{
                //user logged in parse date
                MiscHelper.showWhisper(message: "Facebook login successful.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), navController: self.navigationController)
                
                let user = self.loginHelper.getUserDetailsFromJson(json: responseObject!)
                self.loginSuccessfullTasks(userID: (user as! User).ID)
                let _ = self.loginHelper.saveLoggedInUser(user: user as! User)
            
                self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
            }
        
            return
        }
    }
    
    func requestFacebookEmail(){
        //1. Create the alert controller.
        let alert = UIAlertController(title: "Enter Email", message: "Facebook didn't give us an email for your account.Please enter your email below.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            FBSDKLoginManager().logOut()
        }))
        
        let saveAction = UIAlertAction(title:"Ok", style: .default, handler: { (action) -> Void in
            let textField = alert.textFields![0] // Force unwrapping because we know it exists.
            self.facebookUser.email = (textField.text)!
            
            self.faceBookLoginRequest()
        })
        
        alert.addAction(saveAction)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholderText = "email@domain.com"
            
            let text = ((textField.text)!).trimmingCharacters(in: .whitespaces)
            saveAction.isEnabled = MiscHelper.isValidEmail(value: text)
            
            NotificationCenter.default.addObserver(forName: NSNotification.Name.UITextFieldTextDidChange, object: textField, queue: OperationQueue.main) { (notification) in
                let text = ((textField.text)!).trimmingCharacters(in: .whitespaces)
                saveAction.isEnabled = MiscHelper.isValidEmail(value: text)
            }
        }
    
        
        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    // MARK: Validate Action
    
    func initializeTextFields(){
        tfEmailPhoneLogin.delegate = self
        tfPasswordLogin.delegate = self
        tfFirstNameCC.delegate = self
        tfLastNameCC.delegate = self
        tfEmailPhoneCC.delegate = self
        tfConfirmEmailPhoneCC.delegate = self
        tfPasswordCC.delegate = self
        tfPasswordConfirmCC.delegate = self
    }
    
    func signInNullCheck() -> Bool{
        
        if MiscHelper.textFieldIsNull(field: tfEmailPhoneLogin){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfPasswordLogin){
            return false
        }
        
       return true
        
    }
    
    func createAccountNullCheck() -> Bool{
        if MiscHelper.textFieldIsNull(field: tfFirstNameCC){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfLastNameCC){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfEmailPhoneCC){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfConfirmEmailPhoneCC){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfPasswordCC){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfPasswordConfirmCC){
            return false
        }
        
         return true
        
    }
    
    
    
    func validateSignInFormat()->Bool{
        let text: String = tfEmailPhoneLogin.text!
        let pw: String = tfPasswordLogin.text!
        if (MiscHelper.isValidEmail(value: text) || MiscHelper.isValidPhoneNumber(value: text)) && (pw.characters.count) >= 5{
            bSignIn.isEnabled = true
            return true
        }else{
            bSignIn.isEnabled = false
            return false
        }
    }
    
    func ValidateCreateAccountFormat() -> Bool {
        let emailPhone: String = tfEmailPhoneCC.text!
        let emailPhoneConfirm: String = tfConfirmEmailPhoneCC.text!
        let password: String = tfPasswordCC.text!
        let passwordConfirm: String = tfPasswordConfirmCC.text!
        
        if !MiscHelper.isValidEmail(value: emailPhone) && !MiscHelper.isValidPhoneNumber(value: emailPhone){
            self.view.makeToast("Invalid Email or Phone #", duration: 2.0, position: .bottom)
            bCreateAccount.isEnabled = false
            return false
        }
        
        if emailPhone != emailPhoneConfirm {
            self.view.makeToast("Email/Phone #'s must match", duration: 2.0, position: .bottom)
            bCreateAccount.isEnabled = false
            return false
        }
        
        if password.characters.count < 5 {
            self.view.makeToast("Password must be at least 5 characters", duration: 2.0, position: .bottom)
            bCreateAccount.isEnabled = false
            return false
        }
        
        if password != passwordConfirm {
            self.view.makeToast("Passwords must match", duration: 2.0, position: .bottom)
            bCreateAccount.isEnabled = false
            return false
        }
        
        bCreateAccount.isEnabled = true
        
        return true

    }
    
    func validateSignIn() -> Bool{
        if signInNullCheck(){
            return validateSignInFormat()
        }else{
            bSignIn.isEnabled = false
            return false
        }
    }
    
    func validateCreateAccount() -> Bool{
        if createAccountNullCheck(){
            return ValidateCreateAccountFormat()
        }else{
            //self.view.makeToast("Please complete all required fields", duration: 2.0, position: .bottom) //causes spamming of this notification
            bCreateAccount.isEnabled = false
            return false
        }
    }
    
    // MARK: Button Action
    @IBAction func bSignInAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if validateSignIn(){
            loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.label.text = "Logging In"
            
            self.loginHelper.LoginRequest(emailPhone: tfEmailPhoneLogin.text!, password: tfPasswordLogin.text!){ responseObject, error in
                
                self.loadingNotification?.hide(animated: false)
                
                

                
                if responseObject != nil {
                    if responseObject == "0"{
                        let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                        loginResponseNotification.mode = MBProgressHUDMode.customView
                        loginResponseNotification.label.text = "Invalid Username or Password"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                    }else{
                        let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                        loginResponseNotification.mode = MBProgressHUDMode.customView
                        loginResponseNotification.label.text = "Login Successfull"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                        
                        
                        if let x = Int64(responseObject!){
                            let user:User = User()
                            user.ID = x
                            let _ = self.loginHelper.saveLoggedInUser(user: user)
                            self.loginSuccessfullTasks(userID: x)

                        }else{
                            let user = self.loginHelper.getUserDetailsFromJson(json: responseObject!)
                            self.loginSuccessfullTasks(userID: (user as! User).ID)
                            let _ = self.loginHelper.saveLoggedInUser(user: user as! User)
                        }
                        
                        self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                    }
                }else if error != nil{
                    self.view.makeToast("Unable to login. Please try again.", duration: 2, position: .bottom)
                }
                
                
                return
            }

        }
    }
    
    
    @IBAction func bCancelLogin(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
    }
    
    @IBAction func bCreateAccountAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if validateCreateAccount() {
            loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification?.mode = MBProgressHUDMode.indeterminate
            loadingNotification?.label.text = "Creating Account"
            
            self.loginHelper.createAccountRequest(firstName: tfFirstNameCC.text!, lastName: tfLastNameCC.text!, emailPhone: tfEmailPhoneCC.text!, password: tfPasswordCC.text!){ responseObject, error in
                
                self.loadingNotification?.hide(animated: true)
                
                if responseObject != nil {
                
                    let response = Int64(responseObject! as String)
                    
                    let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                    loginResponseNotification.mode = MBProgressHUDMode.customView

                    if response == 0{
                        loginResponseNotification.label.text = "Server Error, Please Check Your Internet Connection."
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                    }else if response == -1{
                        loginResponseNotification.label.text = "Email or Phone# Already Taken"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                    }else{
                        loginResponseNotification.label.text = "Account Created"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                        
                        let user: User = User()
                        user.ID = response!
                        user.firstName = self.tfFirstNameCC.text!
                        user.lastName = self.tfLastNameCC.text!
                        
                        if MiscHelper.isValidEmail(value: self.tfEmailPhoneCC.text!){
                            user.email = self.tfEmailPhoneCC.text!
                        }else{
                            user.phoneNumber = self.tfEmailPhoneCC.text!
                        }
                        
                        user.password = self.tfPasswordCC.text!
                        
                        let _ = self.loginHelper.saveLoggedInUser(user: user)
                        
                        self.loginSuccessfullTasks(userID: user.ID)

                        self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                    }
                    
                }else if error != nil {
                    self.view.makeToast("Unable to create account. Please try again.", duration: 3.0, position: .bottom)
                }
                
                return
            }
        }
    }
    
    // MARK: Text Field Data Functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        switch textField {
        case tfEmailPhoneLogin:
            tfPasswordLogin.becomeFirstResponder()
            break
        case tfFirstNameCC:
            tfLastNameCC.becomeFirstResponder()
            break
        case tfLastNameCC:
            tfEmailPhoneCC.becomeFirstResponder()
            break
        case tfEmailPhoneCC:
            tfConfirmEmailPhoneCC.becomeFirstResponder()
            let _ = validateCreateAccount()
            break
        case tfConfirmEmailPhoneCC:
            tfPasswordCC.becomeFirstResponder()
            let _ = validateCreateAccount()
            break
        case tfPasswordCC:
            tfPasswordConfirmCC.becomeFirstResponder()
            let _ = validateCreateAccount()
            break
        case tfPasswordConfirmCC:
            let _ = validateCreateAccount()
            break
        default:
            break
            
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let _ = validateSignIn()
        let _ = validateCreateAccount()
    }
    
    func loginSuccessfullTasks(userID: Int64){
        let preferences = UserDefaults.standard
        
        let deviceToken = preferences.string(forKey: "deviceNotificationToken")
        
        if deviceToken != nil{
            ConversationHelper().updateIOSDeviceToken(userID: userID, deviceToken: deviceToken!){ responseObject, error in
                if responseObject == "1"{
                }else{
                    //print(responseObject!)
                }
                return
            }
        }
        
    }
    
    func showAlert(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            //self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
