//
//  StripeAPIHelper.swift
//  Scalpr
//
//  Created by Cameron Connor on 7/11/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import Foundation
import Alamofire

class StripeAPIHelper {
    
    init?(){}
    
    func createStripeAccountWithPaymentMethod(tokenID: String, country: String, city: String, addressLine: String, postalCode: String, provinceState:String, cardID: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["tokenID": tokenID, "country": country, "city": city, "addressLine": addressLine, "postalCode": postalCode, "provinceState": provinceState, "cardID": cardID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/stripe/create_account_with_payment_method.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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
    
    func createStripeAccountWithReceivalMethod(tokenID: String, country: String, city: String, addressLine: String, postalCode: String, provinceState:String, receivalType: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["tokenID": tokenID, "country": country, "city": city, "addressLine": addressLine, "postalCode": postalCode, "provinceState": provinceState, "receivalType": receivalType]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/stripe/create_account_with_receival_method.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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


    
}
