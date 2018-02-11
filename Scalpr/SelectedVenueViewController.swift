//
//  SelectedVenueViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 2/9/18.
//  Copyright © 2018 ProQuo. All rights reserved.
//

import UIKit

class SelectedVenueViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var upcomingEvents: UICollectionView!
    
    var venue:NSDictionary? = nil
    var events:NSArray = NSArray()
    let seatGeekHelper:SeatGeekHelper = SeatGeekHelper()!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.upcomingEvents.delegate = self
        self.upcomingEvents.dataSource = self
        
       }
    
    override func viewDidAppear(_ animated: Bool) {
        if let v = venue as NSDictionary! {
            venueName.text = v["name"] as? String
            seatGeekHelper.getVenueEvents(venueID: v["id"] as! Int){ responseObject, error in
                if error == nil {
                    let x = responseObject as! NSDictionary
                    if let eventData = x["events"] as? NSArray{
                        self.events = eventData
                        self.upcomingEvents.reloadData()
                    }
                }else{
                }
                return
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return events.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "eventCell", for: indexPath) as! VenueEventCollectionViewCell
        
        let event = self.events[indexPath.row] as! NSDictionary
        
        cell.eventTitle.text = event["short_title"] as? String
        if let price = (event["stats"] as! NSDictionary)["average_price"] as? Int64 {
            cell.priceLabel.text = "$" + String(describing: price)
        }else{
            cell.priceLabel.text = "NaN"
        }
        let dateString = event["datetime_local"] as! String
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = Calendar(identifier: .iso8601)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss"
        let date:Date = dateFormatter.date(from: dateString)!
        cell.dateLabel.text = MiscHelper.dateToString(date: date, format: "MMM dd, YYYY")
        
        //add start time after adding object for seatgeek data
        
        return cell
    }

}
