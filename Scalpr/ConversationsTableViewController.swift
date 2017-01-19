//
//  ConversationsTableViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 12/6/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import UIKit
import MBProgressHUD
import Whisper


class ConversationsTableViewController: UITableViewController {
    
    // MARK: Global Variable
    var conversations = [Conversation]()
    let convoHelper = ConversationHelper()
    let loginHelper = LoginHelper()
    var userID: Int64 = 0
    var selectedConvo = Conversation()
    var isWhisperShowing = false
    var refreshConversationsTimer: Timer? = nil


    override func viewDidLoad() {
        super.viewDidLoad()
        
        userID = (loginHelper?.getLoggedInUser().ID)!
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem?.title = "Delete"
        
        loadConversations()
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        if editing{
            navigationItem.leftBarButtonItem?.title = "Done"
            self.stopUpdateConvosTimer()
        }else{
            navigationItem.leftBarButtonItem?.title = "Delete"
            self.startUpdateConvosTimer()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if conversations.count > 0{
            conversations.removeAll()
            loadConversations()
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        hideConnectingNotification()
        stopUpdateConvosTimer()
    }
    
    func loadConversations(){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading Conversations"

        
        let _ = convoHelper.getUserConversationsRequest(userID: userID) { responseObject, error in
            
            loadingNotification.hide(animated: true)
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let array = responseObject as? NSArray{
                    let tempConversations = self.convoHelper.parseConversationsFromNSArray(array: array)
                    if(tempConversations.count > 0){
                        self.conversations = tempConversations
                        self.tableView.reloadData()
                        
                        self.startUpdateConvosTimer()

                    }else{
                        self.showAlert(title: "No Conversations", text: "You don't have any active conversations")
                    }
                }else{
                    self.retryAlert()
                }
            }else{
                self.retryAlert()
            }
            return
        }

    }
    
    func refreshConversations(){
        conversations.removeAll()
        
        let _ = convoHelper.getUserConversationsRequest(userID: userID) { responseObject, error in
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let array = responseObject as? NSArray{
                    self.hideConnectingNotification()
                    let tempConversations = self.convoHelper.parseConversationsFromNSArray(array: array)
                    if(tempConversations.count > 0){
                        self.conversations = tempConversations
                        self.tableView.reloadData()
                        
                    }else{
                        self.showAlert(title: "No Conversations", text: "You don't have any active conversations")
                    }
                }else{
                    self.showConnectingNotification()
                }
            }else{
                self.showConnectingNotification()
            }
            return
        }
    }

    
    func showConnectingNotification(){
        if isWhisperShowing == false{
            var connectingWhisper = Whisper.Message(title: "Reconnecting...", backgroundColor: UIColor.red)
            connectingWhisper.images = [UIImage(named: "no_connection")!]
            if navigationController != nil{
                Whisper.show(whisper: connectingWhisper, to: navigationController!, action: .present)
                isWhisperShowing = true
            }
        }
    }
    
    func hideConnectingNotification(){
        // Hide a message
        if navigationController != nil{
            Whisper.hide(whisperFrom: navigationController!)
            isWhisperShowing = false
        }
    }
    
    func startUpdateConvosTimer(){
        if self.refreshConversationsTimer != nil{
            if (self.refreshConversationsTimer?.isValid)!{
                self.refreshConversationsTimer?.invalidate()
            }
        }
        self.refreshConversationsTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            self?.refreshConversations()
        }
        
    }
    
    func stopUpdateConvosTimer(){
        if self.refreshConversationsTimer != nil{
            self.refreshConversationsTimer?.invalidate()
            self.convoHelper.cancelAllRequests()
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
        
        if conversation.isLastMessageRead {
            cell.labelYourName.font = UIFont.systemFont(ofSize: 18)
            cell.labelLastMessage.font = UIFont.systemFont(ofSize: 15)
            cell.labelLastMessageTimestamp.font = UIFont.systemFont(ofSize: 12)
        }else{
            cell.labelYourName.font = UIFont.boldSystemFont(ofSize: 18)
            cell.labelLastMessage.font = UIFont.boldSystemFont(ofSize: 15)
            cell.labelLastMessageTimestamp.font = UIFont.boldSystemFont(ofSize: 12)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a"
        
        if conversation.lastMessage.ID == 0 {
            cell.labelLastMessageTimestamp.text = dateFormatter.string(for: conversation.creationTimeStamp)
        }else{
            cell.labelLastMessageTimestamp.text = dateFormatter.string(for: conversation.lastMessage.timestamp)
        }
        
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
    
    func retryAlert(){
        let refreshAlert = UIAlertController(title: "Unable to load conversations", message: "Would you like to retry?", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action: UIAlertAction!) in
            self.loadConversations()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }



}
