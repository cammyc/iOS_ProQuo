//
//  Attraction.swift
//  Scalpr
//
//  Created by Cam Connor on 9/28/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation

class Attraction {
    
    var ID: Int64
    var creatorID: Int64
    var venueName: String
    var name: String
    var ticketPrice: Double
    var numTickets: Int
    var description: String
    var date: Date
    var imageURL: String
    var lat: Double
    var lon: Double
    var timeStamp: String
    
    init() {
        ID = 0;
        creatorID = 0
        venueName = ""
        name = ""
        ticketPrice = 0
        numTickets = 0
        description = ""
        date = Date()
        imageURL = ""
        lat = 0.0
        lon = 0.0
        timeStamp = ""
    }
    
}
