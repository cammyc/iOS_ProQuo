//
//  SelectedConversationTableViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 12/7/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import UIKit
import MBProgressHUD

class SelectedConversationTableViewController: UITableViewController {
    
    // MARK: Global Variables/Helpers
    let convoHelper = ConversationHelper()
    let loginHelper = LoginHelper();
    
    var conversation = Conversation()
    var messages = [Message]()
    var userID: Int64 = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        userID = (loginHelper?.getLoggedInUser().ID)!
        
        self.tableView.rowHeight = UITableViewAutomaticDimension;
        self.tableView.estimatedRowHeight = 40.0;
    
        loadMessages()
    }
    
    func loadMessages(){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading Messages"
        
        
        let request = convoHelper.getInitialConversationMessagesRequest(conversationID: conversation.ID) { responseObject, error in
            
            loadingNotification.hide(animated: true)
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let array = responseObject as? NSArray{
                    let tempMessages = self.convoHelper.parseMessagesFromNSArray(array: array)
                    if(tempMessages.count > 0){
                        self.messages = tempMessages
                        self.tableView.reloadData()
                        self.tableView.scrollToRow(at: NSIndexPath(row: self.messages.count - 1, section: 0) as IndexPath, at: .bottom, animated: false)
                        
                    }else{
                        self.showAlert(title: "No Conversation", text: "You don't have any active conversations")
                    }
                }else{
                    self.showAlert(title: "Unable to load conversations", text: "We were unable to retrieve your conversations. Please check your internet connection and try again.")
                }
            }else{
                self.showAlert(title: "Unable to load conversations", text: "We were unable to retrieve your conversations. Please check your internet connection and try again.")
            }
            return
        }
        
        
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let message = messages[indexPath.row]
        
        if message.senderID != userID {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "my_message", for: indexPath) as! MyMessageTableViewCell
            cell.myMessage.text = message.text
            //cell.myMessage.numberOfLines = 0
//            cell.myMessage.layoutIfNeeded()
//            cell.setNeedsLayout()
//            cell.layoutIfNeeded()
        
            
            cell.myMessage.layer.cornerRadius = 20
//            cell.myMessage.setNeedsLayout()
//            cell.myMessage.layoutIfNeeded()
            cell.setNeedsLayout()
            cell.layoutIfNeeded()
            
            return cell
            
        }else{
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "your_message", for: indexPath) as! YourMessageTableViewCell
            cell.yourMessage.text = message.text
            //cell.yourMessage.numberOfLines = 0
//            cell.yourMessage.sizeToFit()
//            cell.setNeedsLayout()
//            cell.layoutIfNeeded()
            
            cell.yourMessage.layer.cornerRadius = 20


            
            return cell
        }

        
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
    
    func showAlert(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }

}
