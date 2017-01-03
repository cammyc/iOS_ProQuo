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
    
    @NSManaged var id: NSInteger
    @NSManaged var conversationID: NSInteger
    @NSManaged var senderID: NSInteger
    @NSManaged var text: String?
    @NSManaged var timestamp: Date?
    
}
