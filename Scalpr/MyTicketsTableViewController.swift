//
//  MyTicketsTableViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 10/10/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import MBProgressHUD

class MyTicketsTableViewController: UITableViewController{
    
    // MARK: Menu Buttons
    @IBOutlet weak var bHome: UIBarButtonItem!
    
    
    // MARK: Helpers
    let attractionHelper = AttractionHelper()
    let loginHelper = LoginHelper()
    var userAttractions = [Attraction]()
    var currentIndexPath:IndexPath? = nil
    
    var attractionOldDate = Date()
    
    var editedAttraction: Attraction? = nil
    
    var sections: [String] = []
    var items = Array<Array<Attraction>>()
    
    
    // MARK: ViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()

        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem?.title = "Delete"

    }
    
    func loadData(){
        sections = []
        items = Array<Array<Attraction>>()
        
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading Your Tickets"
        
        
        _ = attractionHelper.getUserAttractions(userID: (loginHelper?.getLoggedInUser().ID)!){ responseObject, error in
            
            if responseObject != nil {
                if (responseObject as? NSArray) != nil{
                    self.userAttractions = self.attractionHelper.getAttractionsFromNSArray(array: responseObject as! NSArray!)!
                    
                    if self.userAttractions.count > 0 {
                        
                        var lastDate:Date = self.userAttractions[0].date
                        var counter = 0
                        
                        self.sections.append(MiscHelper.dateToString(date: lastDate, format: "MM/dd/yyyy"))
                        self.items.append(Array<Attraction>())
                        
                        for at in self.userAttractions{
                            if lastDate != at.date{
                                lastDate = at.date
                                self.sections.append(MiscHelper.dateToString(date: lastDate, format: "MM/dd/yyyy"))
                                self.items.append(Array<Attraction>())
                                counter += 1
                            }
                            self.items[counter].append(at)
                        }
                        
                        self.tableView.reloadData()
                    }else{
                        self.showAlertMaybeClose(title: "No Active Tickets", text: "You don't have any active tickets.")
                    }
                }else{
                    self.showErrorAlert()
                }
                
            }else if error != nil {
                self.showErrorAlert()
            }
            
            loadingNotification.hide(animated: true)
            return
        }
    }
    
    func showErrorAlert(){
        let refreshAlert = UIAlertController(title: "Unable to Load Posts", message: "We were unable to load your posts. Please check your internet connection and try again.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }
    
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        if editing{
            navigationItem.rightBarButtonItem?.title = "Done"
        }else{
            navigationItem.rightBarButtonItem?.title = "Delete"
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return self.sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sections[section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.items[section].count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketCell", for: indexPath) as! MyTicketTableViewCell

        let attraction = self.items[indexPath.section][indexPath.row]

        return updateCell(attraction: attraction, cell: cell)
    }
    
    func updateCell(attraction: Attraction, cell: MyTicketTableViewCell)->MyTicketTableViewCell{
        let url = URL(string: attraction.imageURL)
        let color: UInt = (attraction.postType == 1) ? 0x2ecc71 : 0x3498db

        
        cell.ivImage.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { image, error,cacheType, imageURL in
                if image != nil {
                    //cell.ivImage.image = ImageHelper.circleImageBordered(image: image!, rgb: color, borderWidth: 12)
                    
                    if attraction.postType == 2 {
                        cell.ivImage.image = ImageHelper.circleImageBordered(image: image!, rgb: 0x3498db, borderWidth: 12)
                    }else{
                        cell.ivImage.image = ImageHelper.circleImage(image: image!)
                    }

                }
            }
        )
        
        cell.contentView.isUserInteractionEnabled = false
        
        cell.attractionName.text = attraction.name
        cell.attractionName.text = attraction.name
        cell.venueName.text = attraction.venueName
        
        let price = String(format: attraction.ticketPrice == floor(attraction.ticketPrice) ? "%.0f" : "%.2f", attraction.ticketPrice)
        let requestOrSell = (attraction.postType == 1) ? "Being Sold" : "Requested"

        cell.priceAndNumTickets.text = "$" + price + " - " + String(attraction.numTickets) + " Tickets " + requestOrSell
        cell.priceAndNumTickets.textColor = MiscHelper.UIColorFromRGB(rgbValue: color)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.currentIndexPath = indexPath
        
        let alert = UIAlertController(
            title: "Edit Post",
            message: "What would you like to change?",
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Details", style: UIAlertActionStyle.default, handler: { (test) -> Void in
            alert.dismiss(animated: true)
            self.performSegue(withIdentifier: "segueEditAttraction", sender: alert)
        }))
            
        alert.addAction(UIAlertAction(title: "Location", style: UIAlertActionStyle.default, handler: { (test) -> Void in
            alert.dismiss(animated: true)
            self.performSegue(withIdentifier: "seagueEditAttractionLocation", sender: alert)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (test) -> Void in
            alert.dismiss(animated: true)
        }))
        
        self.present(alert,animated: true,completion: nil)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueEditAttraction"{
            attractionOldDate = self.items[(currentIndexPath?.section)!][(currentIndexPath?.row)!].date
            let postTicketViewController = (segue.destination as! PostTicketViewController)
            postTicketViewController.editAttraction = self.items[(currentIndexPath?.section)!][(currentIndexPath?.row)!]
        }else if segue.identifier == "seagueEditAttractionLocation"{
            let setTicketLocationViewController = (segue.destination as! SetTicketLocationViewController)
            setTicketLocationViewController.editAttraction = self.items[(currentIndexPath?.section)!][(currentIndexPath?.row)!]
        }
    }
    
    @IBAction func unwindToMyTicketsVC(segue:UIStoryboardSegue) {
        if segue.identifier == "unwindToMyTicketsFromPost"{
            if editedAttraction != nil{
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                loadingNotification.label.text = "Updating Post"

                attractionHelper.updateAttractionDetails(attraction: editedAttraction!){ responseObject, error in
                    
                    loadingNotification.hide(animated: false)

                    
                    if responseObject != nil {
                        let response = Int(responseObject!)
                        
                        if response == 1{
                            
                            self.items[(self.currentIndexPath?.section)!][(self.currentIndexPath?.row)!] = self.editedAttraction!//I think the attraction is already changed in the other view, swift must pass the adress
                            
                            
                            let successNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                            successNotification.mode = MBProgressHUDMode.text
                            successNotification.label.text = "Successfully Updated Post"
                            successNotification.hide(animated: true, afterDelay: 2)
                            CoreDataHelper.attractionChanged = true
                            
                            
                            if self.items[(self.currentIndexPath?.section)!][(self.currentIndexPath?.row)!].date != self.attractionOldDate{
                                self.loadData()
                            }else{
                                self.tableView.reloadRows(at: [self.currentIndexPath!], with: UITableViewRowAnimation.left)
                            }
                        }else{
                            self.view.makeToast("Unable to update post details. Please try again.", duration: 2.0, position: .bottom)
                        }
                    }else if error != nil{
                        self.view.makeToast("Unable to update post details. Please try again.", duration: 2.0, position: .bottom)
                    }
                    self.editedAttraction = nil

                    return
                }

            }
        }else if segue.identifier == "unwindToMyTicketsFromSetLocation"{
            if self.editedAttraction != nil {
                self.items[(currentIndexPath?.section)!][(currentIndexPath?.row)!] = self.editedAttraction!
                
                self.tableView.reloadRows(at: [currentIndexPath!], with: UITableViewRowAnimation.left)
                
                let successNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                successNotification.mode = MBProgressHUDMode.text
                successNotification.label.text = "Updated Post Location"
                successNotification.hide(animated: true, afterDelay: 2)
                CoreDataHelper.attractionChanged = true
                
                self.editedAttraction = nil
            }
        }
    }

    

    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.currentIndexPath = indexPath
            // Delete the row from the data source
            
            let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            loadingNotification.mode = MBProgressHUDMode.indeterminate
            loadingNotification.label.text = "Deleting Post"
            
            attractionHelper.deleteAttraction(attraction: self.items[(currentIndexPath?.section)!][(currentIndexPath?.row)!]){ responseObject, error in
                
                loadingNotification.hide(animated: false)
                
                
                if responseObject != nil {
                    let response = Int(responseObject!)
                    
                    if response == 1{
                        
                        self.items[(self.currentIndexPath?.section)!].remove(at: (self.currentIndexPath?.row)!)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        
                        let successNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                        successNotification.mode = MBProgressHUDMode.text
                        successNotification.label.text = "Successfully Deleted Post"
                        successNotification.hide(animated: true, afterDelay: 2)
                        CoreDataHelper.attractionChanged = true
                    }else{
                        self.view.makeToast("Unable to delete post. Please try again.", duration: 2.0, position: .bottom)
                    }
                }else if error != nil{
                    self.view.makeToast("Unable to delete post. Please try again.", duration: 2.0, position: .bottom)
                }
                return
            }
        }
    }
    
    func showAlertMaybeClose(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Refresh", style: .default, handler: { (action: UIAlertAction!) in
            self.loadData()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Ok, Leave", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
