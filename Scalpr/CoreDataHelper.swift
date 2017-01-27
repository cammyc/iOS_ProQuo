//
//  SQLiteHelper.swift
//  Scalpr
//
//  Created by Cam Connor on 10/8/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import CoreData

class CoreDataHelper : NSObject {
    
    var managedObjectContext: NSManagedObjectContext
    static var attractionChanged = false
    
    override init() {
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = Bundle.main.url(forResource: "CoreDataModels", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc
        DispatchQueue.global().async() {
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            let docURL = urls[urls.endIndex-1]
            /* The directory the application uses to store the Core Data store file.
             This code uses a file named "DataModel.sqlite" in the application's documents directory.
             */
            let storeURL = docURL.appendingPathComponent("DataModel.sqlite")
            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption: true,                           NSInferMappingModelAutomaticallyOption: true])
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }
    
    func wipeAttractionsFromDB(){
        let moc = managedObjectContext
        
        let attractionFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Attraction")
        let delete = NSBatchDeleteRequest(fetchRequest: attractionFetch)
        
        do {
            try moc.execute(delete)
        } catch {
            fatalError("Failed to fetch attractions: \(error)")
        }
    }
    
    func wipeMessagesFromDB(){
        let moc = managedObjectContext
        
        let messageFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        let delete = NSBatchDeleteRequest(fetchRequest: messageFetch)

        do {
            try moc.execute(delete)
        } catch {
            fatalError("Failed to fetch attractions: \(error)")
        }
    }
    
    func wipeConversationFromDB(convoID: Int64){
        let moc = managedObjectContext
        
        let messageFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
        messageFetch.predicate = NSPredicate(format: "conversationID == %i", convoID)
        
        do {
            try moc.execute(messageFetch)
        } catch {
            fatalError("Failed to fetch attractions: \(error)")
        }
    }
    
    func saveMessage(message: Message){
        let cdMessage = cdMessageMO(context: managedObjectContext)
        
        cdMessage.id = message.ID
        cdMessage.conversationID = message.conversationID
        cdMessage.senderID = message.senderID
        cdMessage.text = message.text
        cdMessage.timestamp = message.timestamp
        
        do {
            try managedObjectContext.save()
            //print ("saved " + attraction.name)
        } catch {
            fatalError("Failure to save context: \(error)")
        }

    }
    
    func getAllMessagesFromConversation(conversationID: Int64)->NSArray{
        let moc = managedObjectContext
        
        var array = [cdMessageMO]()
        
        let messageFetch: NSFetchRequest<cdMessageMO> = NSFetchRequest(entityName: "Message")
        
        messageFetch.predicate = NSPredicate(format: "conversationID == %i", conversationID)
        
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: true)
        let sortDescriptors = [sortDescriptor]
        messageFetch.sortDescriptors = sortDescriptors

        do {
            array = try moc.fetch(messageFetch)
        } catch {
            fatalError("Failed to fetch attractions: \(error)")
        }
        
        return array as NSArray
    }
    
    
    func saveAttraction(attraction: Attraction){
        let cdAttraction = cdAttractionMO(context: managedObjectContext)
        
        
        cdAttraction.id = attraction.ID
        cdAttraction.creatorID = attraction.creatorID
        cdAttraction.name = attraction.name
        cdAttraction.venueName = attraction.venueName
        cdAttraction.attractionDescription = attraction.description
        cdAttraction.ticketPrice = attraction.ticketPrice
        cdAttraction.numTickets = Int64(attraction.numTickets)
        cdAttraction.imageURL = attraction.imageURL
        cdAttraction.lat = attraction.lat
        cdAttraction.lon = attraction.lon
        cdAttraction.date = attraction.date
        
        //cdAttraction.timeStamp = attraction.timeStamp
        
        //cdAttraction.setValue(attraction.ID, forKey: "id")
        //cdAttraction.setValue(attraction.name, forKey: "name")
        
        do {
            try managedObjectContext.save()
            //print ("saved " + attraction.name)
        } catch {
            fatalError("Failure to save context: \(error)")
        }
    }
    
    func getAttractions()->NSArray{
        
        let moc = managedObjectContext
        
        var array = [cdAttractionMO]()
        
        let attractionFetch: NSFetchRequest<cdAttractionMO> = NSFetchRequest(entityName: "Attraction")
        
        do {
            array = try moc.fetch(attractionFetch as! NSFetchRequest<NSFetchRequestResult>) as! [cdAttractionMO]
        } catch {
            fatalError("Failed to fetch attractions: \(error)")
        }
        
        return array as NSArray
    }
    
    func getAttractions(query: String)->NSArray{
        
        let moc = managedObjectContext
        
        var array = [cdAttractionMO]()
        
        let attractionFetch: NSFetchRequest<cdAttractionMO> = NSFetchRequest(entityName: "Attraction")
        attractionFetch.predicate = NSPredicate(format: "name contains [cd] %@ OR venueName contains [cd] %@", argumentArray: [query, query])
        
        do {
            array = try moc.fetch(attractionFetch as! NSFetchRequest<NSFetchRequestResult>) as! [cdAttractionMO]
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
        return array as NSArray
    }
    
    func getAttractionByID(ID: Int)->cdAttractionMO?{
        let moc = managedObjectContext
        
        var attraction: cdAttractionMO? = nil
        
        let attractionFetch: NSFetchRequest<cdAttractionMO> = NSFetchRequest(entityName: "Attraction")
        
        let id = ID
        
        attractionFetch.predicate = NSPredicate(format: "id == %i", id)
        
        do {
            let array = try moc.fetch(attractionFetch as! NSFetchRequest<NSFetchRequestResult>) as! [cdAttractionMO]
            
            if array.count > 0{
                attraction = array[0]
            }
            
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
        return attraction
    }
    
    func getCommaSeperatedAttractionIDString()->String{
        var commaSeperatedString = ""
        
        
        let moc = managedObjectContext
        
        var array = [cdAttractionMO]()
        
        let attractionFetch: NSFetchRequest<cdAttractionMO> = NSFetchRequest(entityName: "Attraction")
        
        do {
            array = try moc.fetch(attractionFetch as! NSFetchRequest<NSFetchRequestResult>) as! [cdAttractionMO]
            
            if array.count == 0{
                commaSeperatedString = "ID != 0"
            }else{
                for i in 0 ..< array.count{
                    let comma = (i != (array.count - 1)) ? "," : ""
                    commaSeperatedString += "ID != " + String(array[i].id) + comma
                }
            }
            
        } catch {
            fatalError("Failed to fetch employees: \(error)")
        }
        
        return commaSeperatedString
    }
}
