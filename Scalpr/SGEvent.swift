//
//  SGEvent.swift
//  Scalpr
//
//  Created by Cameron Connor on 2/11/18.
//  Copyright © 2018 ProQuo. All rights reserved.
//

import Foundation

class SGEvent {
    var ID: Int64
    var localDateTime: String
    var status: String
    var title: String
    var url: String
    var score: Double
    var taxonomies: [Int:String]
    var type: String
    var venue: SGVenue
    var popularity: Double
    var averagePrice: Double
    var highestPrice: Double
    var lowestPrice: Double
    var listingCount: Int64
    var shortTitle: String
    var utcDateTime: String
    
    
    init(){
        localDateTime = ""
    }
}
