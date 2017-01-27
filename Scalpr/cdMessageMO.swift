//
//  cdMessageMO.swift
//  Scalpr
//
//  Created by Cameron Connor on 1/2/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class cdMessageMO: NSManagedObject{
    
    @NSManaged var id: Int64
    @NSManaged var conversationID: Int64
    @NSManaged var senderID: Int64
    @NSManaged var text: String?
    @NSManaged var timestamp: Date?
    
}
