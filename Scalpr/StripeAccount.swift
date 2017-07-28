//
//  StripeAccount.swift
//  Scalpr
//
//  Created by Cameron Connor on 7/28/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import Foundation

class StripeAccount{
    
    var connectID: String
    var customerID: String
    var sourceID: String
    var paymentID: String
    var paymentType: String
    var receivalType: String
    var paymentPreview: String
    var receivalPreview: String
    var isInitialized: Bool
    
    init(){
        connectID = ""
        customerID = ""
        sourceID = ""
        paymentID = ""
        paymentType = ""
        receivalType = ""
        paymentPreview = ""
        receivalPreview = ""
        isInitialized = false
    }
}
