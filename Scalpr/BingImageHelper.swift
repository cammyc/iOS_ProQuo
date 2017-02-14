//
//  BingImageHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 9/30/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation
import Alamofire

class BingImageHelper{
    
    init(){
    }
    
    func getImageThumbURLs(array: NSArray)->[String]{
        var thumbURLs = [String]()
        
        for i in 0 ..< array.count{
            let item = array[i] as! NSDictionary
            thumbURLs.append(item["thumbnailUrl"] as! String)
        }
        return thumbURLs
    }
    
    func getSearchImages(query: String, completionHandler: @escaping (NSArray?, NSError?) -> ()){

        let url = NSURLComponents()
        url.scheme = "https"
        url.host = "api.cognitive.microsoft.com"
        url.path = "/bing/v5.0/images/search"
        
        var urlString = url.url?.absoluteString
        urlString?.append("?q=" + query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
        urlString?.append("&count=10")
        urlString?.append("&offset=0")
        urlString?.append("&mkt=en-us")
        urlString?.append("&safeSearch=Moderate")
        
        let header = ["Ocp-Apim-Subscription-Key":"af466a4301e4434aab69bbc02176a9e9"]
        
        Alamofire.request(urlString!, method: .post, headers: header).responseJSON { response in
            switch response.result {
            case .success (let value):
                let responses = value as! NSDictionary
                let array = responses["value"] as? NSArray
                completionHandler(array as NSArray?, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError?)
            }
        }

        
    }
    
}
