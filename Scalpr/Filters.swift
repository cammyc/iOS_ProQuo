//
//  Filters.swift
//  Scalpr
//
//  Created by Cameron Connor on 3/24/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import Foundation

class Filters {
    
    var startDate: Date
    var endDate: Date
    var showRequested: Bool
    var showSelling: Bool
    var minPrice: Int
    var maxPrice: Int
    var numTickets: Int
    
    
    init(){
        startDate = Date()
        endDate = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        showRequested = true
        showSelling = true
        minPrice = 0
        maxPrice = 1000
        numTickets = -1 //-1 is any
    }
    
    func startDateToString()->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: startDate)
    }
    
    func endDateToString()->String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: endDate)
    }
    
}
