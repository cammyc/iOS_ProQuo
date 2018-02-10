//
//  CreateAccountViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 4/29/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import MBProgressHUD

class CreateAccountViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: bgVideo
    var player: AVPlayer?
    var videoPaused = false
    
    // MARK: fields
    @IBOutlet weak var tfFirstName: UITextField!
    @IBOutlet weak var tfLastName: UITextField!
    @IBOutlet weak var tfEmailPhone: UITextField!
    @IBOutlet weak var tfEmailPhoneConfirm: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfPasswordConfirm: UITextField!
    
    @IBOutlet weak var bCreateAccount: UIButton!

    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tfFirstName.delegate = self
        tfLastName.delegate = self
        tfEmailPhone.delegate = self
        tfEmailPhoneConfirm.delegate = self
        tfPassword.delegate = self
        tfPasswordConfirm.delegate = self
        
        initVideoBG()
        makeFieldsLookPretty()
    }
    
    // MARK: Video
    
    func initVideoBG(){
        // Do any additional setup after loading the view.
        let videoURL: NSURL = Bundle.main.url(forResource: "videobg", withExtension: "mp4")! as NSURL
        
        player = AVPlayer(url: videoURL as URL)
        player?.actionAtItemEnd = .none
        player?.isMuted = true
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        playerLayer.zPosition = -1
        
        playerLayer.frame = view.frame
        
        view.layer.addSublayer(playerLayer)
        
        player?.play()
        
        //loop video
        NotificationCenter.default.addObserver(self, selector: #selector(CreateAccountOrLoginViewController.loopVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func loopVideo() {
        player?.seek(to: kCMTimeZero)
        player?.play()
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
    
    
    // MARK: Form styling

    
    func makeFieldsLookPretty(){
        updatedTextField(textField: tfEmailPhone)
        updatedTextField(textField: tfEmailPhoneConfirm)
        updatedTextField(textField: tfPassword)
        updatedTextField(textField: tfPasswordConfirm)
        updatedTextField(textField: tfFirstName)
        updatedTextField(textField: tfLastName)
        bCreateAccount.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        
    }
    
    func updatedTextField(textField: UITextField){
        textField.layer.cornerRadius = 5.0
        textField.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(10,0,0)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        switch textField {
        case tfFirstName:
            tfLastName.becomeFirstResponder()
            break
        case tfLastName:
            tfEmailPhone.becomeFirstResponder()
            break
        case tfEmailPhone:
            tfEmailPhoneConfirm.becomeFirstResponder()
            break
        case tfEmailPhoneConfirm:
            tfPassword.becomeFirstResponder()
            break
        case tfPassword:
            tfPasswordConfirm.becomeFirstResponder()
            break
        case tfPasswordConfirm:
            tfPassword.endEditing(true)
            break
        default:
            break
            
        }
        
        return true
    }

    

    // MARK: Form Validation
    
    func validateCreateAccount() -> Bool{
        if createAccountNullCheck(){
            return ValidateCreateAccountFormat()
        }else{
            //self.view.makeToast("Please complete all required fields", duration: 2.0, position: .bottom) //causes spamming of this notification
            return false
        }
    }
    
    func createAccountNullCheck() -> Bool{
        if MiscHelper.textFieldIsNull(field: tfFirstName){
            self.view.makeToast("Please fill out all required fields.", duration: 2.0, position: .center)
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfLastName){
            self.view.makeToast("Please fill out all required fields.", duration: 2.0, position: .center)
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfEmailPhone){
            self.view.makeToast("Please fill out all required fields.", duration: 2.0, position: .center)
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfEmailPhoneConfirm){
            self.view.makeToast("Please fill out all required fields.", duration: 2.0, position: .center)
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfPassword){
            self.view.makeToast("Please fill out all required fields.", duration: 2.0, position: .center)
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfPasswordConfirm){
            self.view.makeToast("Please fill out all required fields.", duration: 2.0, position: .center)
            return false
        }
        
        return true
        
    }
    
    func ValidateCreateAccountFormat() -> Bool {
        let emailPhone: String = tfEmailPhone.text!
        let emailPhoneConfirm: String = tfEmailPhoneConfirm.text!
        let password: String = tfPassword.text!
        let passwordConfirm: String = tfPasswordConfirm.text!
        
        if !MiscHelper.isValidEmail(value: emailPhone) && !MiscHelper.isValidPhoneNumber(value: emailPhone){
            self.view.makeToast("Invalid Email or Phone #", duration: 2.0, position: .center)
            return false
        }
        
        if emailPhone != emailPhoneConfirm {
            self.view.makeToast("Email/Phone #'s must match", duration: 2.0, position: .center)
            return false
        }
        
        if password.characters.count < 5 {
            self.view.makeToast("Password must be at least 5 characters", duration: 2.0, position: .center)
            return false
        }
        
        if password != passwordConfirm {
            self.view.makeToast("Passwords must match", duration: 2.0, position: .center)
            return false
        }
        
        return true
        
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
    
    
    @IBAction func bCreateAccountAction(_ sender: Any) {
        
        if validateCreateAccount() {
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = "Creating Account"
            
            let loginHelper = LoginHelper()
            
            loginHelper?.createAccountRequest(firstName: tfFirstName.text!, lastName: tfLastName.text!, emailPhone: tfEmailPhone.text!, password: tfPassword.text!){ responseObject, error in
                
                loadingNotification.hide(animated: true)
                
                if responseObject != nil {
                    
                    let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                    loginResponseNotification.mode = MBProgressHUDMode.customView
                    
                    if let response = Int64(responseObject!){
                        if response == 0{
                            loginResponseNotification.label.text = "Connection Error, Please Try Again"
                            loginResponseNotification.hide(animated: true, afterDelay: 2)
                        }else if response == -1{
                            loginResponseNotification.label.text = "Email or Phone# Already Taken"
                            loginResponseNotification.hide(animated: true, afterDelay: 2)
                        }else{
                            loginResponseNotification.label.text = "Connection Error, Please Try Again"
                            loginResponseNotification.hide(animated: true, afterDelay: 2)
                        }
                    }else{
                        loginResponseNotification.label.text = "Account Created"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                        
                        
                        let user = loginHelper?.getUserDetailsFromJson(json: responseObject!)
                        let _ = loginHelper?.saveLoggedInUser(user: user as! User)
                        self.loginSuccessfullTasks(userID: (user as! User).ID) //needs to go after save user
                        
                        
                        self.performSegue(withIdentifier: "go_home_from_login", sender: nil)
                        
                    }
                    
                    
                }else if error != nil {
                    self.view.makeToast("Unable to create account. Please try again", duration: 3.0, position: .bottom)
                }
                
                return
            }
        }

        
    }
    
}
