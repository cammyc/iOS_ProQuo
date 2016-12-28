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
    
    func wipeDB(){
        let moc = managedObjectContext
        
        var array = [cdAttractionMO]()
        
        let attractionFetch: NSFetchRequest<cdAttractionMO> = NSFetchRequest(entityName: "Attraction")
        
        do {
            array = try moc.fetch(attractionFetch as! NSFetchRequest<NSFetchRequestResult>) as! [cdAttractionMO]
            
            for managedObject in array
            {
                let managedObjectData:NSManagedObject = managedObject as NSManagedObject
                managedObjectContext.delete(managedObjectData)
            }
        } catch {
            fatalError("Failed to fetch attractions: \(error)")
        }
    }
    
    
    func saveAttraction(attraction: Attraction){
        let cdAttraction = cdAttractionMO(context: managedObjectContext)
        
        
        cdAttraction.id = NSInteger(attraction.ID)
        cdAttraction.creatorID = NSInteger(attraction.creatorID)
        cdAttraction.name = attraction.name
        cdAttraction.venueName = attraction.venueName
        cdAttraction.attractionDescription = attraction.description
        cdAttraction.ticketPrice = attraction.ticketPrice
        cdAttraction.numTickets = attraction.numTickets
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
