//
//  CreateAccountOrLoginViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 4/28/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import FacebookLogin
import FacebookCore
import FBSDKLoginKit
import SafariServices
import MBProgressHUD
import GoogleSignIn

class CreateAccountOrLoginViewController: UIViewController, LoginButtonDelegate, UITextFieldDelegate, GIDSignInUIDelegate, GIDSignInDelegate {
    
    // MARK: bgVideo
    var player: AVPlayer?
    var videoPaused = false
    
    // MARK: fields
    @IBOutlet weak var tfEmailPhone: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var bLogin: UIButton!
    @IBOutlet weak var ivLogo: UIImageView!
    @IBOutlet weak var bSignUp: UIButton!
    @IBOutlet weak var bCancel: UIButton!
    
    // MARK: fb and Google Sign In
    @IBOutlet weak var googleSignIn: GIDSignInButton!
    @IBOutlet weak var fbSignIn: UIView!
    
    let loginHelper:LoginHelper = LoginHelper()!
    
    // MARK: Data Variables
    let facebookUser = User()
    let googleUser = User()
    var fbUserID: String? = nil
    var googleUserID: String? = nil
    var googleDisplayPicURL: String? = nil
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tfEmailPhone.delegate = self
        tfPassword.delegate = self

        initVideoBG()
        
        makeFieldsLookPretty();
        
        googleInitialization()
        facebookInitialization()
        
        if self.navigationController != nil{
            bCancel.isHidden = true
            self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.navigationController?.navigationBar.shadowImage = UIImage()
            self.navigationController?.navigationBar.isTranslucent = true
            self.navigationController?.view.backgroundColor = .clear
        }
    }
    
    // MARK: Video
    
    func initVideoBG(){
        // Do any additional setup after loading the view.
        let videoURL: NSURL = Bundle.main.url(forResource: "videobg", withExtension: "mp4")! as NSURL
        
        player = AVPlayer(url: videoURL as URL)
        player?.actionAtItemEnd = .none
        player?.isMuted = true
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.zPosition = -1
        
        playerLayer.frame = view.frame
        
        view.layer.addSublayer(playerLayer)
        
        player?.play()
        
        //loop video
        NotificationCenter.default.addObserver(self, selector: #selector(CreateAccountOrLoginViewController.loopVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
//        let bgView = UIView(frame: self.view.bounds)
//        bgView.backgroundColor = UIColor.red
//        
//        self.view.insertSubview(bgView, belowSubview: self.tfEmailPhone)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        player?.pause()
        videoPaused = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if videoPaused {
            player?.play()
            videoPaused = false
        }
    }
    
    
    func loopVideo() {
        player?.seek(to: kCMTimeZero)
        player?.play()
    }

    
    // MARK: Form Styling
    
    func makeFieldsLookPretty(){
        updatedTextField(textField: tfEmailPhone)
        updatedTextField(textField: tfPassword)
        updateLoginButton(button: bLogin)
        bSignUp.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        
    }
    
    func updatedTextField(textField: UITextField){
        textField.layer.cornerRadius = 5.0
        textField.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(10,0,0)

    }
    
    func updateLoginButton(button: UIButton){
        button.layer.cornerRadius = 5.0
        button.layer.borderWidth = 2.0
        button.layer.borderColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71).cgColor
    }
    
    
    // MARKL Form Validation
    
    func signInNullCheck() -> Bool{
        
        if MiscHelper.textFieldIsNull(field: tfEmailPhone){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfPassword){
            return false
        }
        
        return true
        
    }

    
    func validateSignIn() -> Bool{
        if signInNullCheck(){
            return validateSignInFormat()
        }else{
            return false
        }
    }
    
    func validateSignInFormat()->Bool{
        let text: String = tfEmailPhone.text!
        let pw: String = tfPassword.text!
        if (MiscHelper.isValidEmail(value: text) || MiscHelper.isValidPhoneNumber(value: text)) && (pw.characters.count) >= 5{
            return true
        }else{
            return false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        switch textField {
        case tfEmailPhone:
            tfPassword.becomeFirstResponder()
            break
        case tfPassword:
            //tfPassword.resignFirstResponder()
            tfPassword.endEditing(true)

            break
        default:
            break
            
        }
        
        return true
    }
    
    // MARK: Login Button
    
    
    @IBAction func bLoginAction(_ sender: Any) {
        if validateSignIn(){
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = "Logging In"
            
            self.loginHelper.LoginRequest(emailPhone: tfEmailPhone.text!, password: tfPassword.text!){ responseObject, error in
                
                loadingNotification.hide(animated: false)
                
                
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
                            let _ = self.loginHelper.saveLoggedInUser(user: user as! User)
                            self.loginSuccessfullTasks(userID: (user as! User).ID)//needs to go after save user
                            
                        }
                        
                        self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                    }
                }else if error != nil{
                    self.view.makeToast("Unable to login. Please try again.", duration: 2, position: .bottom)
                }
                
                
                return
            }
            
        }else{
            self.view.makeToast("Please enter valid login info.", duration: 2, position: .center)

        }
    }


    
    // MARK: Google
    
    func googleInitialization(){
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        googleSignIn.style = .wide
    }
    
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if (error == nil) {
            // Perform any operations on signed in user here.
            
            self.googleUserID = user.userID!
            self.googleUser.firstName = user.profile.givenName!
            self.googleUser.lastName = user.profile.familyName!
            self.googleUser.email = user.profile.email!
            self.googleDisplayPicURL = user.profile.imageURL(withDimension: 400).absoluteString
            
            
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
                            let _ = self.loginHelper.saveLoggedInUser(user: self.googleUser)
                            self.loginSuccessfullTasks(userID: self.googleUser.ID) //needs to go after saveuser
                            
                            
                            self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                        }
                        //not sure what happens here
                        break
                    }
                }else{
                    //user logged in parse date
                    MiscHelper.showWhisper(message: "Google login successful.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), navController: self.navigationController)
                    
                    let user = self.loginHelper.getUserDetailsFromJson(json: responseObject!)
                    let _ = self.loginHelper.saveLoggedInUser(user: user as! User)
                    self.loginSuccessfullTasks(userID: (user as! User).ID) //needs to go after saveuser
                    
                    
                    self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                }
                
                
                return
            }
            // ...
        } else {
            MiscHelper.showWhisper(message: "Unable to login with Google.", color: UIColor.red, navController: self.navigationController)
        }
        
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
    }
    
    // MARK: Facebook
    
    func facebookInitialization(){
        let loginButton = LoginButton(readPermissions: [.publicProfile, .email])
        
        loginButton.frame.size.width = fbSignIn.frame.width
        loginButton.frame.size.height = fbSignIn.frame.height
        fbSignIn.addSubview(loginButton)
        
        loginButton.delegate = self
    }
    
    // Facebook Delegate Methods
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        print("logged out")
        
    }
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        
        switch result {
        case .success(_, _, _):
            returnUserData()
            break;
        case .cancelled:
            MiscHelper.showWhisper(message: "Facebook login canceled.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x3b5998), navController: self.navigationController)
            break;
        case .failed(_):
            MiscHelper.showWhisper(message: "Unable to login with Facebook.", color: UIColor.red, navController: self.navigationController)
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
                    FBSDKLoginManager().logOut()
                    self.showAlert(title: "Email Taken", text: "There is already an account that uses your Facebook email address. Please change the email on that account then try again. If you did not create the account using your email please contact us.")
                    break
                case -3:
                    self.requestFacebookEmail()
                    break
                default:
                    if response > 0 {
                        MiscHelper.showWhisper(message: "Facebook login successful.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), navController: self.navigationController)
                        
                        self.facebookUser.ID = response
                        let _ = self.loginHelper.saveLoggedInUser(user: self.facebookUser)
                        self.loginSuccessfullTasks(userID: self.facebookUser.ID) //needs to go after save user
                        
                        
                        self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                    }
                    //not sure what happens here
                    break
                }
            }else{
                //user logged in parse date
                MiscHelper.showWhisper(message: "Facebook login successful.", color: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71), navController: self.navigationController)
                
                let user = self.loginHelper.getUserDetailsFromJson(json: responseObject!)
                let _ = self.loginHelper.saveLoggedInUser(user: user as! User)
                self.loginSuccessfullTasks(userID: (user as! User).ID)//needs to go after saveuser
                
                
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
    
    func loginSuccessfullTasks(userID: Int64){
        let preferences = UserDefaults.standard
        
        let deviceToken = preferences.string(forKey: "deviceNotificationToken")
        
        if deviceToken != nil{
            LoginHelper()?.updateIOSDeviceToken(userID: userID, deviceToken: deviceToken!){ responseObject, error in
                if responseObject == "1"{
                }else{
                    //print(responseObject!)
                }
                return
            }
        }
        
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Unwind Seague
    
    @IBAction func unwindToLogin(segue:UIStoryboardSegue) {
    
    
    }
    

    // MARK: Misc
    
    @IBAction func bForgotPasswordAction(_ sender: Any) {
        let svc = SFSafariViewController(url: NSURL(string: "http://belivetickets.com/forgotPassword.html") as! URL)
        present(svc, animated: true, completion: nil)
    }
    

    func showAlert(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            //self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }


}
