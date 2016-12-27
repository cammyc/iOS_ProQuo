//
//  ViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 10/12/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import MBProgressHUD

class UpdateAccountViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: Helpers
    let loginHelper: LoginHelper = LoginHelper()!
    
    // MARK: Input Fields
    @IBOutlet weak var tfFirstName: UITextField!
    @IBOutlet weak var tfLastName: UITextField!
    @IBOutlet weak var tfPhone: UITextField!
    @IBOutlet weak var tfEmail: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfPasswordConfirm: UITextField!
    
    // MARK: Button Outlets
    @IBOutlet weak var bUpdate: UIButton!
    @IBOutlet weak var bChangePassword: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        bUpdate.isEnabled = false
        bChangePassword.isEnabled = false

        initializeTextFields()
        loadData()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func loadData(){
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading Profile Details"
        
        
        loginHelper.getAccountDetails(userID: (loginHelper.getLoggedInUser().ID)){ responseObject, error in
            
            if responseObject != nil {
                
                if responseObject == "0" {
                    self.showErrorAlert()
                }else{
                    if let u = self.loginHelper.getUserDetailsFromJson(json: responseObject!) as? User{
                        self.tfFirstName.text = u.firstName
                        self.tfLastName.text = u.lastName
                        self.tfEmail.text = u.email
                        self.tfPhone.text = u.phoneNumber
                        
                        self.bUpdate.isEnabled = self.validateUpdateAccount()
                        self.bChangePassword.isEnabled = self.validateChangePassword()
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
    
    // MARK: Text Field Validation
    
    func initializeTextFields(){
        tfFirstName.delegate = self
        tfLastName.delegate = self
        tfEmail.delegate = self
        tfPhone.delegate = self
        tfPassword.delegate = self
        tfPasswordConfirm.delegate = self
    }
    
    // MARK: Validation Actions
    
    func changePasswordNullCheck() -> Bool{
        
        if MiscHelper.textFieldIsNull(field: tfPassword){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfPasswordConfirm){
            return false
        }
        
        return true
        
    }
    
    func updateAccountNullCheck() -> Bool{
        if MiscHelper.textFieldIsNull(field: tfFirstName){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfLastName){
            return false
        }
        
        if MiscHelper.textFieldIsNull(field: tfEmail) && MiscHelper.textFieldIsNull(field: tfPhone){ //One is allowed to be null
            return false
        }
        
        
        return true
        
    }
    
    func validateChangePasswordFormat()->Bool{
        let password: String = tfPassword.text!
        let passwordConfirm: String = tfPasswordConfirm.text!

        if password.characters.count < 5 {
            self.view.makeToast("Password must be at least 5 characters", duration: 2.0, position: .bottom)
            bChangePassword.isEnabled = false
            return false
        }
        
        if password != passwordConfirm {
            self.view.makeToast("Passwords must match", duration: 2.0, position: .bottom)
            bChangePassword.isEnabled = false
            return false
        }
        
        bChangePassword.isEnabled = true
        
        return true
    }
    
    func ValidateUpdateAccountFormat() -> Bool {
        let email: String = tfEmail.text!
        let phone: String = tfPhone.text!
        
        if !MiscHelper.isValidEmail(value: email) && !MiscHelper.textFieldIsNull(field: tfEmail){
            self.view.makeToast("Invalid Email", duration: 2.0, position: .bottom)
            bUpdate.isEnabled = false
            return false
        }
        
        if !MiscHelper.isValidPhoneNumber(value: phone) && !MiscHelper.textFieldIsNull(field: tfPhone) {
            self.view.makeToast("Invalid Phone #", duration: 2.0, position: .bottom)
            bUpdate.isEnabled = false
            return false
        }
        
        bUpdate.isEnabled = true
        
        return true
        
    }
    
    func validateChangePassword() -> Bool{
        if changePasswordNullCheck(){
            return validateChangePasswordFormat()
        }else{
            bChangePassword.isEnabled = false
            return false
        }
    }
    
    func validateUpdateAccount() -> Bool{
        if updateAccountNullCheck(){
            return ValidateUpdateAccountFormat()
        }else{
            self.view.makeToast("First name, last name, and at least one method of contact required.", duration: 2, position: .bottom)
            bUpdate.isEnabled = false
            return false
        }
    }
    
    // MARK: Text Field Delegate Methods
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        bUpdate.isEnabled = validateUpdateAccount()
        bChangePassword.isEnabled = validateChangePassword()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        switch textField {
        case tfPassword:
            tfPasswordConfirm.becomeFirstResponder()
            break
        default:
            break
            
        }
        
        return true
    }

    // MARK: Button Actions
    @IBAction func bUpdateAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if validateUpdateAccount(){
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = "Updating Profile"
            
            let user = loginHelper.getLoggedInUser()
            
            user.firstName = tfFirstName.text!
            user.lastName = tfLastName.text!
            user.phoneNumber = tfPhone.text!
            user.email = tfEmail.text!
            
            
            self.loginHelper.updateUserContactInfo(user: user){ responseObject, error in
                
                loadingNotification.hide(animated: true)
                
                if responseObject != nil {
                    
                    let response = Int(responseObject! as String)
                    
                    if response == 1{
                        let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                        loginResponseNotification.mode = MBProgressHUDMode.customView
                        loginResponseNotification.label.text = "Profile Updated"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                        
                        
                        self.loginHelper.saveLoggedInUser(user: user)
                    }else if response == -1{
                        let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                        loginResponseNotification.mode = MBProgressHUDMode.customView
                        loginResponseNotification.label.text = "Email is already in use"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)


                    }else if response == -2{
                        let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                        loginResponseNotification.mode = MBProgressHUDMode.customView
                        loginResponseNotification.label.text = "Phone number is already in use"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)


                    }
                    
                }else if error != nil {
                    self.view.makeToast("Unable to update profile. Please try again.", duration: 2, position: .bottom)
                }
                
                return
            }
        }
    }
    
    @IBAction func bChangePasswordAction(_ sender: UIButton) {
        self.view.endEditing(true)
        if validateChangePassword(){
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = "Updating Profile"
            
            let user = loginHelper.getLoggedInUser()
            
            user.password = tfPassword.text!
            
            
            self.loginHelper.updateUserDetails(user: user){ responseObject, error in
                
                loadingNotification.hide(animated: true)
                
                if responseObject != nil {
                    
                    let response = Int(responseObject! as String)
                    
                    let loginResponseNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                    loginResponseNotification.mode = MBProgressHUDMode.customView
                    
                    if response == 0{
                        self.view.makeToast("Unable to change password. Please try again.", duration: 2, position: .bottom)
                    }else{
                        loginResponseNotification.label.text = "Password Updated"
                        loginResponseNotification.hide(animated: true, afterDelay: 2)
                        
                        
                        self.loginHelper.saveLoggedInUser(user: user)
                    }
                    
                }else if error != nil {
                    self.view.makeToast("Unable to change password. Please try again.", duration: 2, position: .bottom)
                }
                
                return
            }

        }
    }
    
    
    
    // MARK: Misc. Functions
    
    func showErrorAlert(){
        let refreshAlert = UIAlertController(title: "Unable to Load Profile", message: "Please try again.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }

}
