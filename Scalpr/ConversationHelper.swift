//
//  ConversationHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 12/7/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift

class ConversationHelper {
    
    var timer:Timer? = nil
    
    init(){
    }
    
    func cancelAllRequests(){
        Alamofire.SessionManager.default.session.getAllTasks { tasks in
            tasks.forEach { $0.cancel() }
        }
    }
    
    func getUserConversationsRequest(userID: Int64, completionHandler: @escaping (AnyObject?, NSError?) -> ()){
        
        let parameters: Parameters = ["userID": userID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_user_conversations.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).responseJSON { response in
            switch response.result {
            case .success (let value):
                completionHandler(value as AnyObject?, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError?)
            }
        }
        
    }
    
    func getInitialConversationMessagesRequest(conversationID: Int64, completionHandler: @escaping (AnyObject?, NSError?) -> ()){
        
        let parameters: Parameters = ["conversationID": conversationID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_conversation_messages.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).responseJSON { response in
            switch response.result {
            case .success (let value):
                completionHandler(value as AnyObject?, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError?)
            }
        }
        
    }
    
    func getNewConversationMessagesRequest(conversationID: Int64, userID: Int64, completionHandler: @escaping (AnyObject?, NSError?) -> ()){
        
        let parameters: Parameters = ["conversationID": conversationID, "userID": userID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/get_new_conversation_messages.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).responseJSON { response in
            switch response.result {
            case .success (let value):
                completionHandler(value as AnyObject?, nil)
            case .failure(let error):
                completionHandler(nil, error as NSError?)
            }
        }
        
    }

    
    func sendConversationMessageRequest(conversationID: Int64, senderID: Int64, message: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["conversationID": conversationID, "senderID": senderID, "message": message]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/send_conversation_message.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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
    
    func updateLastReadMessageRequest(messageID: Int64, conversationID: Int64, userID: Int64, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["messageID": messageID, "conversationID": conversationID, "userID": userID]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/update_user_last_read_message_for_conversation.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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
    
    func updateIOSDeviceToken(userID: Int64, deviceToken: String, completionHandler: @escaping (String?, NSError?) -> ()){
        
        let parameters: Parameters = ["userID": userID, "deviceToken": deviceToken]
        
        Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/update_IOSDeviceToken.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
            
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


    func backgroundCheckForNewMessageRequest(userID: Int64, completionHandler: @escaping (String?, NSError?) -> ()?){
        
        let preferences = UserDefaults.standard
        let deviceToken = preferences.object(forKey: "deviceNotificationToken") as? String
        if deviceToken != nil{
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String{
                let parameters: Parameters = ["userID": userID, "appType": 2, "appVersion": Double(version)!, "deviceToken": deviceToken!]
                
                Alamofire.request("https://scalpr-143904.appspot.com/scalpr_ws/ios_check_new_conversation_messages.php", method: .post, parameters: parameters, headers: MiscHelper.getSecurityHeader()).response { response in
                    
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
        }
        
    }
    
    func deleteConversation
    
//    func startBackgroundMessageCheckTimer(){
//        if timer == nil {
//            timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) {
//                timer in
//                
//                DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
//                    let convoHelper = ConversationHelper()
//                    
//                    convoHelper.backgroundCheckForNewMessageRequest(userID: (LoginHelper()?.getLoggedInUser().ID)!){
//                        responseObject, error in
//                        return
//                    }
//                    
//                }
//            }
//        }
//        
//
//    }
//    
//    func stopBackgroundMessageCheckTimer(){
//        if timer != nil{
//            timer?.invalidate()
//            timer = nil
//        }
//    }

    
    func parseConversationsFromNSArray(array: NSArray!) -> [Conversation]{
        var conversations = [Conversation]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd H:m:s"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone!  // original string in GMT/UTC
        
        if array != nil{
            for i in 0 ..< array.count{
                let conversation:NSDictionary = array[i] as! NSDictionary
                
                let convo : Conversation = Conversation()
                let id = conversation["conversationID"] as! NSNumber
                convo.ID = id.int64Value
                convo.attractionID = (conversation["attractionID"] as! NSNumber).int64Value
                convo.buyerID = (conversation["buyerID"] as! NSNumber).int64Value
                convo.sellerID = (conversation["sellerID"] as! NSNumber).int64Value
                convo.buyerName = conversation["buyerName"] as! String
                convo.sellerName = conversation["sellerName"] as! String
                convo.title = conversation["title"] as! String
                
                let message:NSDictionary = conversation["lastMessage"] as! NSDictionary
                
                if let messageID = message["messageID"] as? NSNumber{
                    let m : Message = Message()
                    m.ID = messageID.int64Value
                    m.conversationID = (message["conversationID"] as! NSNumber).int64Value
                    m.senderID = (message["senderID"] as! NSNumber).int64Value
                    m.text = message["message"] as! String
                    m.timestamp = dateFormatter.date(from: message["timestamp"] as! String)!
                    
                    convo.lastMessage = m
                }
                
                convo.attractionImageURL = conversation["attractionImageURL"] as! String
                convo.creationTimeStamp = dateFormatter.date(from: conversation["creationTimestamp"] as! String)!
                convo.isLastMessageRead = (conversation["isLastMessageRead"] as! Int == 0) ? false : true
                
                conversations.append(convo)
                
            }
            
        }

        
        return conversations
    }
    
    func parseMessagesFromNSArray(array: NSArray!) -> [Message]{
        var messages = [Message]()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd H:m:s"
        dateFormatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone!  // original string in GMT/UTC

        
        if array != nil{
            for i in 0 ..< array.count{
                let message:NSDictionary = array[i] as! NSDictionary
                
                let m : Message = Message()
                m.ID = (message["messageID"] as! NSNumber).int64Value
                m.conversationID = (message["conversationID"] as! NSNumber).int64Value
                m.senderID = (message["senderID"] as! NSNumber).int64Value
                m.text = message["message"] as! String
                m.timestamp = dateFormatter.date(from: message["timestamp"] as! String)!
                
                messages.insert(m, at: 0)
                
            }
            
        }
        
        
        return messages
    }

}
