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
    
    func getSGVenuesFromNSArray(array: NSArray!) -> [SGVenue]{
        var venues = [SGVenue]()
        
        if array != nil{
            for i in 0 ..< array.count{
                
                let venue:NSDictionary = array[i] as! NSDictionary
                
                let v:SGVenue = SGVenue()
//                let id = attraction["attractionID"] as! NSNumber
//                a.ID = id.int64Value
//                a.creatorID = (attraction["creatorID"] as! NSNumber).int64Value
//                a.venueName = attraction["venueName"] as! String
//                a.name = attraction["name"] as! String
//                a.ticketPrice = attraction["ticketPrice"] as! Double
//                a.numTickets = attraction["numTickets"] as! Int
//                a.description = attraction["description"] as! String
//                a.postType = (attraction["postType"] as! NSNumber).int64Value
//
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "yyyy-MM-dd"
//                let dateObj = dateFormatter.date(from: attraction["date"] as! String)
//
//                a.date = dateObj!
//                a.imageURL = attraction["imageURL"] as! String
//                a.lat = Double(attraction["lat"] as! String)!
//                a.lon = Double(attraction["lon"] as! String)!
                
                venues.append(v)
                
            }
            
        }
        return venues
        
    }
}
