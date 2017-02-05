//
//  User.swift
//  Scalpr
//
//  Created by Cam Connor on 10/4/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation

class User {
    var ID: Int64
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String
    var password: String
    var accessToken: String
    
    init(){
        ID = 0
        firstName = ""
        lastName = ""
        email = ""
        phoneNumber = ""
        password = ""
        accessToken = ""
    }
}
