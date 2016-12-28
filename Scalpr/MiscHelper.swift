//
//  MiscHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 10/2/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift

class MiscHelper {
    
    init(){}
    
    static func UIColorFromRGB(rgbValue: UInt) -> UIColor {
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    static func textFieldIsNull(field: UITextField) ->Bool {
        return trimString(string: (field.text)!) == ""
    }
    
    static func trimString(string: String)-> String{
        return string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
    static func isValidEmail(value:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: value)
    }
    
    static func isValidPhoneNumber(value: String) -> Bool {
        let PHONE_REGEX = "^[+]?[0-9]{6,20}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let result =  phoneTest.evaluate(with: value)
        return result
    }
    
    static func dateToString(date: Date, format: String)-> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        let UTC = dateFormatter.string(from: date)
        
        return utcToLocal(date: UTC, format: format)
    }
    
    static func formatMessageTimeBreakDate(date: Date)-> String{
        let isToday = Calendar.autoupdatingCurrent.isDateInToday(date)
        if isToday {
            return dateToString(date: date, format: "h:mm a")
        }else{
            return dateToString(date: date, format: "EEE MMM d").uppercased() + " AT " + dateToString(date: date, format: "h:mm a")
        }
    }
    
    static func utcToLocal(date: String, format: String)-> String{
        
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone!  // original string in GMT
        let date = formatter.date(from: date)
        
        formatter.timeZone = NSTimeZone.local        // go back to user's timezone
        return formatter.string(from: date!)
    }
    
    static func formatPrice(price: Double)-> String{
        
        if price < 1000{
            return "$" + String(Int(round(price)))
        }else{
            return "$" + formatPoints(num: price)
        }
        
    }
    
    static func formatPoints(num: Double) ->String{
        let thousandNum = num/1000
        let millionNum = num/1000000
        if num >= 1000 && num < 1000000{
            if(floor(thousandNum) == thousandNum){
                return("\(Int(thousandNum))k")
            }
            return("\(roundToPlaces(num: thousandNum, places: 1))k")
        }
        if num > 1000000{
            if(floor(millionNum) == millionNum){
                return("\(Int(thousandNum))k")
            }
            return ("\(roundToPlaces(num: millionNum, places: 1))M")
        }
        else{
            if(floor(num) == num){
                return ("\(Int(num))")
            }
            return ("\(num)")
        }
        
    }
    
    private static func roundToPlaces(num: Double, places:Int) -> Double {
        let divisor: Double = pow(10.0, Double(places))
        return round(num * divisor) / divisor
    }
    
    func getMinimumAppVersion(completionHandler: @escaping (Double?, NSError?) -> ()){
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/minimum_app_version_ios.php", method: .post).response { response in
            
            let x = response.error as NSError?
            if x == nil{
                let data = response.data
                let response = Double(String(data: data!, encoding: .utf8)!)
                completionHandler(response, nil)
            }else{
                completionHandler(nil, response.error as NSError?)
            }
        }
        
    }

    static func getSecurityHeader()-> HTTPHeaders{
        let pw = "WheresTheClosestKanyeTicketAt?"
        let key = "$c@lPrK3Y1236547"
        var encryptedData: String? = nil
        
        do {
            let aes = try AES(key: key, iv: "", blockMode: .ECB, padding: PKCS7())
            encryptedData = try aes.encrypt(pw.utf8.map({$0})).toBase64()!
        }catch{
            
        }
        
        if encryptedData != nil{
            return ["ScalprVerification": encryptedData!]
        }else{
            return ["":""]
        }

    }
    
}
