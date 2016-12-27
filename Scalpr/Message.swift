//
//  Message.swift
//  Scalpr
//
//  Created by Cam Connor on 12/6/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import Foundation

class Message {
    
    var ID: Int64
    var conversationID: Int64
    var senderID: Int64
    var text: String
    var timestamp: Date
    
    init() {
        ID = 0
        conversationID = 0
        senderID = 0
        text = ""
        timestamp = Date.init()
    }
    
}
