//
//  LoginHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 10/4/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation
import Alamofire
import FBSDKLoginKit
import FacebookCore
import FacebookLogin
import SwiftKeychainWrapper


class LoginHelper{
    
    static var userLoggedin: Bool = false
    
    init?(){}
    
    func LoginRequest(emailPhone: String, password: String, completionHandler: @escaping (String?, NSError?) -> ()){
        let parameters: Parameters = ["emailPhone": emailPhone, "password": password]
        
//        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = 10
//        configuration.timeoutIntervalForResource = 10
//        let manager = Alamofire.SessionManager(configuration: configuration)
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/login_check.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
        }
    }
    
    func createAccountRequest(firstName: String, lastName: String, emailPhone: String, password: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date:String = dateFormatter.string(from: Date())
        
        let parameters: Parameters = ["firstname": firstName, "lastname": lastName, "emailPhone": emailPhone, "password": password, "currentDate": date]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/create_account.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }
    
    func facebookCreateAccountLoginRequest(firstName: String, lastName: String, email: String, facebookID: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["firstName": firstName, "lastName": lastName, "email": email, "facebookID": facebookID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/facebook_create_account_and_login.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }
    
    func googleCreateAccountLoginRequest(firstName: String, lastName: String, email: String, displayPicURL: String, googleID: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["firstName": firstName, "lastName": lastName, "email": email, "displayPicURL": displayPicURL, "googleID": googleID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/google_create_account_and_login.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }
    
    func updateUserContactInfo(user: User, completionHandler: @escaping (String?, NSError?) -> ()){
        
        
        let parameters: Parameters = ["userID": user.ID, "firstName": user.firstName, "lastName": user.lastName, "phoneNumber": user.phoneNumber, "email": user.email]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/update_user_contact_info.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as? NSError)
            }
            
        }
    }
    
    func updateUserDetails(user: User, completionHandler: @escaping (String?, NSError?) -> ()){
        
        
        let parameters: Parameters = ["userID": user.ID, "password": user.password]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/update_user_details.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }

    
    func getAccountDetails(userID: Int64, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["userID": userID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_user_details.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }
    
    func getUserContactDetails(userID: Int64, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["userID": userID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_user_contact_info.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }
    
    func updateIOSDeviceToken(userID: Int64, deviceToken: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["userID": userID, "deviceToken": deviceToken]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/update_IOSDeviceToken.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }
    
    func removeIOSDeviceToken(deviceToken: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["deviceToken": deviceToken]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/remove_IOSDeviceToken.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }

    func removeAccessToken(accessToken: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["accessToken": accessToken]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/remove_access_token.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }
    
    func connectGoogleAccount(userID: Int64, googleID: String, displayPicURL: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["userID": userID, "googleID": googleID, "displayPicURL": displayPicURL]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/google_connect_account.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let utf8Text = String(data: data!, encoding: .utf8)
                completionHandler(utf8Text, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
            
        }
    }

    
    func getUserDetailsFromJson(json: String)->Any?{
        let u = User()
        
        do {
            let parsedData = try JSONSerialization.jsonObject(with: (json.data(using: .utf8))!, options: .allowFragments) as! [String:Any]
            
            if let id = parsedData["userID"] as? NSNumber{
                u.ID = id.int64Value
            }
            
            if let firstName = parsedData["firstName"] as? String {
                u.firstName = firstName
            }
            
            if let lastName = parsedData["lastName"] as? String{
                u.lastName = lastName
            }
            
            if let email = parsedData["email"] as? String{
                u.email = email
            }
            
            if let phone = parsedData["phoneNumber"] as? String{
                u.phoneNumber = phone
            }
            
            if let accessToken = parsedData["accessToken"] as? String{
                u.accessToken = accessToken
            }
            
            if let profPicURL = parsedData["displayPicURL"] as? String{
                u.profPicURL = profPicURL
            }
            
            if let facebookID = parsedData["facebookID"] as? String{
                u.facebookID = facebookID
            }
            
            if let googleID = parsedData["googleID"] as? String{
                u.googleID = googleID
            }
            
        } catch let error as NSError {
            print(error)
            return nil
        }

        
        return u
    }

    
    func saveLoggedInUser(user: User)-> Bool{
        let preferences = UserDefaults.standard
        let userID = NSNumber(value: user.ID)
        
        preferences.set(userID, forKey: "userID")
        preferences.set(user.firstName, forKey: "firstName")
        preferences.set(user.lastName, forKey: "lastName")
        preferences.set(user.email, forKey: "email")
        preferences.set(user.phoneNumber, forKey: "phoneNumber")
        preferences.set(user.password, forKey: "password")
        let saveSuccessful: Bool = KeychainWrapper.standard.set(user.accessToken, forKey: "accessToken")

        print("save successful: " + String(saveSuccessful))
        return preferences.synchronize()
    }
    
    func getLoggedInUser()->User{
        let preferences = UserDefaults.standard

        let user: User = User()
        
        if preferences.object(forKey: "userID") != nil{
            let id = preferences.object(forKey: "userID") as! NSNumber
            user.ID = id.int64Value
            user.firstName = preferences.object(forKey: "firstName") as! String
            user.lastName = preferences.object(forKey: "lastName") as! String
            user.email = preferences.object(forKey: "email") as! String
            user.phoneNumber = preferences.object(forKey: "phoneNumber") as! String
            user.password = preferences.object(forKey: "password") as! String
            if let retrievedString = KeychainWrapper.standard.string(forKey: "accessToken") {
                user.accessToken = retrievedString
            }

        }
    
        return user
    }
    
    func logout()-> Bool{
        
        let user:User = User()
        let preferences = UserDefaults.standard
        
        preferences.set(NSNumber(value: user.ID), forKey: "userID")
        preferences.set(user.firstName, forKey: "firstName")
        preferences.set(user.lastName, forKey: "lastName")
        preferences.set(user.email, forKey: "email")
        preferences.set(user.phoneNumber, forKey: "phoneNumber")
        preferences.set(user.password, forKey: "password")
        KeychainWrapper.standard.remove(key: "accessToken")
       // preferences.set(nil, forKey: "deviceNotificationToken") no need to do this because it never changes...
        
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
        
        //  Save to disk
        return preferences.synchronize()
    }
    
    
    
}
