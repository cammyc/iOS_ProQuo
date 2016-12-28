//
//  ConversationsTableViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 12/6/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import UIKit
import MBProgressHUD


class ConversationsTableViewController: UITableViewController {
    
    // MARK: Global Variable
    var conversations = [Conversation]()
    let convoHelper = ConversationHelper()
    let loginHelper = LoginHelper()
    var userID: Int64 = 0
    var selectedConvo = Conversation()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        userID = (loginHelper?.getLoggedInUser().ID)!
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        loadConversations()
    }
    
    func loadConversations(){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading Conversations"

        
        let request = convoHelper.getUserConversationsRequest(userID: userID) { responseObject, error in
            
            loadingNotification.hide(animated: true)
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let array = responseObject as? NSArray{
                    let tempConversations = self.convoHelper.parseConversationsFromNSArray(array: array)
                    if(tempConversations.count > 0){
                        self.conversations = tempConversations
                        self.tableView.reloadData()

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
        return conversations.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "conversationCell", for: indexPath) as! ConversationTableViewCell

        let convo = self.conversations[indexPath.row]
        
        return updateCell(conversation: convo, cell: cell)
    }
    
    func updateCell(conversation: Conversation, cell: ConversationTableViewCell)->ConversationTableViewCell{
        let url = URL(string: conversation.attractionImageURL)
        
        cell.ivAttractionImage.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: { image, error,cacheType, imageURL in
            if image != nil {
                cell.ivAttractionImage.image = ImageHelper.circleImage(image: image!)
                
            }
            }
        )
        
        cell.contentView.isUserInteractionEnabled = false
        
        if conversation.buyerID == userID {
            cell.labelYourName.text = conversation.sellerName
        }else{
            cell.labelYourName.text = conversation.buyerName
        }
        
        cell.labelLastMessage.text = conversation.lastMessage.text
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        cell.labelLastMessageTimestamp.text = dateFormatter.string(for: conversation.creationTimeStamp)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedConvo = conversations[indexPath.row]
        self.performSegue(withIdentifier: "selected_conversation_segue", sender: nil)
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

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "selected_conversation_segue"{
            let selectedConversationMessagesViewController = segue.destination as! SelectedConversationMessagesViewController
            selectedConversationMessagesViewController.conversation = self.selectedConvo
            
//            let yourName = (userID == selectedConvo.buyerID) ? selectedConvo.sellerName : selectedConvo.buyerName
//
//            let backItem = UIBarButtonItem()
//            backItem.title = yourName
//            navigationItem.backBarButtonItem = backItem // This will show in the next view controller being pushed
            
        }
        
    }
    
    
    func showAlert(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }


}
