//
//  SGVenue.swift
//  Scalpr
//
//  Created by Cameron Connor on 2/11/18.
//  Copyright © 2018 ProQuo. All rights reserved.
//

import Foundation

class SGVenue {
    
    var ID: Int64
    var slug: String
    var lat: Double
    var lon: Double
    var postalCode:Int
    var url:String
    var country:String
    var displayLocation: String
    var score: Double
    var city: String
    var name: String
    var state: String
    var numUpcomingEvents: Int
    var nameV2: String
    var timezone: String
    var popularity: Double
    var extendedAddress: String
    var address: String
    var events: [SGEvent]
    
    
    init() {
        ID = 0;
        slug = ""
        name = ""
        lat = 0.0
        lon = 0.0
        postalCode = 0
        url = ""
        country = ""
        displayLocation = ""
        score = 0.0
        city = ""
        name = ""
        state = ""
        numUpcomingEvents = 0
        nameV2 = ""
        timezone = ""
        popularity = 0.0
        extendedAddress = ""
        address = ""
        events = []
    }
    
}
