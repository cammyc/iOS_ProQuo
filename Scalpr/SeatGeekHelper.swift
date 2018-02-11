//
//  SeatGeekHelper.swift
//  Scalpr
//
//  Created by Cameron Connor on 2/9/18.
//  Copyright © 2018 ProQuo. All rights reserved.
//

import Foundation
import Alamofire
class SeatGeekHelper{
    
    let clientID:String = "Njc3NDMwMnwxNDkxNTQ4NzQyLjE3";
    init?(){}
    
    func getLocalVenues(lat: Double, lon: Double, range: Double, completionHandler: @escaping (AnyObject?, NSError?) -> ())->DataRequest{
        var numResults = 50
        var updatedRange = range
        if range > 30 {
            numResults = 10
        }else if updatedRange < 10 {
            updatedRange = 10
        }
        
        let url:String = "https://api.seatgeek.com/2/venues?lat="+String(lat)+"&lon="+String(lon)+"&range="+String(updatedRange)+"mi&per_page="+String(numResults)+"&client_id="+clientID
        
        let request = Alamofire.request(url, method: .get)
        request.responseJSON { response in
            switch response.result {
            case .success (let value):
                completionHandler(value as AnyObject?, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError?)
            }
        }
        return request
    }
    
    func getVenueEvents(venueID: Int, completionHandler: @escaping (AnyObject?, NSError?) -> ())->DataRequest{
        
        let url:String = "https://api.seatgeek.com/2/events?venue.id="+String(venueID)+"&client_id="+String(clientID)
        
        let request = Alamofire.request(url, method: .get)
        request.responseJSON { response in
            switch response.result {
            case .success (let value):
                completionHandler(value as AnyObject?, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError?)
            }
        }
        return request
    }
}
