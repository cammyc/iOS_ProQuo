//
//  LocationHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 10/6/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation
import CoreLocation

class LocationHelper {
    
    init?(){}
    
    func updateLastLocation(location: CLLocation)-> Bool{
        let preferences = UserDefaults.standard
        
        preferences.set(location.coordinate.latitude, forKey: "userLat")
        preferences.set(location.coordinate.longitude , forKey: "userLon")
        
        //  Save to disk
        return preferences.synchronize()

    }
    
    func getLastLocation()-> Any?{
        let preferences = UserDefaults.standard
        
        let lat = preferences.object(forKey: "userLat") as? Double
        let lon = preferences.object(forKey: "userLon") as? Double
        
        if lat == nil || lon == nil{
            return nil
        }else{
            return CLLocation(latitude: lat! , longitude: lon! )
        }
        
    }
    
    
    
}
