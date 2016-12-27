//
//  AttractionHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 9/28/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift

class AttractionHelper {
    
    init(){
    }
    
    func getInitialAttractions(northLat: Double, southLat: Double, eastLon: Double, westLon: Double, completionHandler: @escaping (AnyObject?, NSError?) -> ()){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: Date())
        
        let parameters: Parameters = ["latBoundLeft": northLat, "latBoundRight": southLat, "lonBoundLeft": eastLon, "lonBoundRight": westLon, "currentDate": date]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_attractions.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).responseJSON { response in
            switch response.result {
            case .success (let value):
                completionHandler(value as AnyObject?, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError?)
            }
        }
        
    }
    
    func getNewAttractions(northLat: Double, southLat: Double, eastLon: Double, westLon: Double, commaString: String, searchQuery: String, completionHandler: @escaping (AnyObject?, NSError?) -> ())->DataRequest{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: Date())
        
        let parameters: Parameters = ["latBoundLeft": northLat, "latBoundRight": southLat, "lonBoundLeft": eastLon, "lonBoundRight": westLon, "currentDate": date, "oldIDs": commaString, "searchViewQuery": searchQuery]
        
        let request = Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_new_attractions.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader())
            
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
    
    func getUserAttractions(userID: Int64, completionHandler: @escaping (AnyObject?, NSError?) -> ())->DataRequest{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: Date())
        
        let parameters: Parameters = ["userID": userID, "currentDate": date]
        
        let request = Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_user_attractions.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader())
        
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
    
    func getAttractionsFromNSArray(array: NSArray!) -> [Attraction]?{
        var attractions = [Attraction]()
        
        if array != nil{
            for i in 0 ..< array.count{
                let attraction:NSDictionary = array[i] as! NSDictionary
                
                let a : Attraction = Attraction()
                let id = attraction["attractionID"] as! NSNumber
                a.ID = id.int64Value
                a.creatorID = (attraction["creatorID"] as! NSNumber).int64Value
                a.venueName = attraction["venueName"] as! String
                a.name = attraction["name"] as! String
                a.ticketPrice = attraction["ticketPrice"] as! Double
                a.numTickets = attraction["numTickets"] as! Int
                a.description = attraction["description"] as! String
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateObj = dateFormatter.date(from: attraction["date"] as! String)
                
                a.date = dateObj!
                a.imageURL = attraction["imageURL"] as! String
                a.lat = Double(attraction["lat"] as! String)!
                a.lon = Double(attraction["lon"] as! String)!
                
                attractions.append(a)
                
            }

        }
        
        
        return attractions

    }
    
    func postAttraction(attraction: Attraction, completionHandler: @escaping (String?, NSError?) -> ()){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        
        let parameters: Parameters = ["creatorID" : attraction.creatorID, "venueName" : attraction.venueName, "attractionName": attraction.name, "ticketPrice": attraction.ticketPrice, "numberOfTickets" : attraction.numTickets, "description" : attraction.description, "date" : dateFormatter.string(from: attraction.date), "imageURL" :attraction.imageURL, "lat" : attraction.lat, "lon" : attraction.lon]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/post_attraction.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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
    
    func updateAttractionDetails(attraction: Attraction, completionHandler: @escaping (String?, NSError?) -> ()){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        
        let parameters: Parameters = ["creatorID" : attraction.creatorID, "attractionID": attraction.ID, "venueName" : attraction.venueName, "attractionName": attraction.name, "ticketPrice": attraction.ticketPrice, "numberOfTickets" : attraction.numTickets, "description" : attraction.description, "date" : dateFormatter.string(from: attraction.date), "imageURL" :attraction.imageURL]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/update_attraction_details.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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
    
    func updateAttractionLocation(attraction: Attraction, completionHandler: @escaping (String?, NSError?) -> ()){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        
        let parameters: Parameters = ["creatorID" : attraction.creatorID, "attractionID": attraction.ID, "lat" : attraction.lat, "lon" :attraction.lon]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/update_attraction_location.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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
    
    func deleteAttraction(attraction: Attraction, completionHandler: @escaping (String?, NSError?) -> ()){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        
        let parameters: Parameters = ["creatorID" : attraction.creatorID, "attractionID": attraction.ID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/delete_attraction.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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
    
    func cdAttractionToReg(attr: cdAttractionMO)->Attraction{
        let attraction = Attraction()
        attraction.ID = Int64(attr.id)
        attraction.creatorID = Int64(attr.creatorID)
        attraction.name = attr.name!
        attraction.venueName = attr.venueName!
        attraction.ticketPrice = attr.ticketPrice
        attraction.numTickets = attr.numTickets
        attraction.date = attr.date!
        attraction.description = attr.description
        attraction.imageURL = attr.imageURL!
        attraction.lat = attr.lat
        attraction.lon = attr.lon
        
        return attraction
    }

    
}
