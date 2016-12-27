//
//  LoginViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 10/2/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import MBProgressHUD

class LoginViewController: UIViewController, UITextFieldDelegate {
    
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
    
    // MARK: Misc Initialization
    @IBOutlet weak var menuButton: UIBarButtonItem!
    var loadingNotification: MBProgressHUD? = nil
    let loginHelper:LoginHelper = LoginHelper()!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if self.revealViewController() != nil {
            menuButton.target = self.revealViewController()
            menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
            self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
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
    
    // MARK: Validate Action
    
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
            loadingNotification?.labelText = "Logging In"
            
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
                            self.loginHelper.saveLoggedInUser(user: user)
                        }else{
                            let user = self.loginHelper.getUserDetailsFromJson(json: responseObject!)
                            self.loginHelper.saveLoggedInUser(user: user as! User)
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
            loadingNotification?.labelText = "Creating Account"
            
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
                        
                        self.loginHelper.saveLoggedInUser(user: user)
                        
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
            validateCreateAccount()
            break
        case tfConfirmEmailPhoneCC:
            tfPasswordCC.becomeFirstResponder()
            validateCreateAccount()
            break
        case tfPasswordCC:
            tfPasswordConfirmCC.becomeFirstResponder()
            validateCreateAccount()
            break
        case tfPasswordConfirmCC:
            validateCreateAccount()
            break
        default:
            break
            
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        validateSignIn()
        validateCreateAccount()
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
