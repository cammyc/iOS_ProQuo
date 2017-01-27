//
//  cdAttractionMO.swift
//  Scalpr
//
//  Created by Cam Connor on 10/8/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class cdAttractionMO: NSManagedObject{
    
    @NSManaged var id: Int64
    @NSManaged var creatorID: Int64
    @NSManaged var venueName: String?
    @NSManaged var name: String?
    @NSManaged var ticketPrice: Double
    @NSManaged var numTickets: Int64
    @NSManaged var attractionDescription: String?
    @NSManaged var date: Date?
    @NSManaged var imageURL: String?
    @NSManaged var lat: Double
    @NSManaged var lon: Double
    //@NSManaged var timeStamp: String?

}
