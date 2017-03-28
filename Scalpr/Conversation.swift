//
//  Conversation.swift
//  Scalpr
//
//  Created by Cam Connor on 12/6/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import Foundation

class Conversation {
    
    var ID: Int64
    var attractionID: Int64
    var buyerID: Int64
    var sellerID: Int64
    var buyerName: String
    var sellerName: String
    var title: String
    var attractionImageURL: String
    var lastMessage: Message
    var messages: [Message]
    var creationTimeStamp: Date
    var isLastMessageRead: Bool
    var postType: Int64
    
    init() {
        ID = 0
        attractionID = 0
        buyerID = 0
        sellerID = 0
        buyerName = ""
        sellerName = ""
        title = ""
        attractionImageURL = ""
        lastMessage = Message()
        messages = [Message]()
        creationTimeStamp = Date.init()
        isLastMessageRead = false
        postType = 0
    }
    
}
