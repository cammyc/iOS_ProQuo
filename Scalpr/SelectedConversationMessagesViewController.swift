//
//  SelectedConversationMessagesViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 12/19/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import UIKit
import MBProgressHUD
import Kingfisher
import JSQMessagesViewController
import Whisper


class SelectedConversationMessagesViewController: JSQMessagesViewController {
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    
    let convoHelper = ConversationHelper()
    let loginHelper = LoginHelper();
    let coreDataHelper = CoreDataHelper()
    
    var conversation = Conversation()
    var messagesRaw = [Message]()
    var messages = [JSQMessage]()
    var myUserID: Int64 = 0
    var myName: String = ""
    var yourName: String = ""
    var avatarImage: UIImage? = nil
    weak var newMessageTimer: Timer?
    weak var updateLastReadMessageTimer: Timer?
    var isWhisperShowing = false
    var taskWasCanceled = false;
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.inputToolbar.contentView?.leftBarButtonItem = nil
        // No avatars
        //collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
                
        
        myUserID = (loginHelper?.getLoggedInUser().ID)!
        myName = (myUserID == conversation.buyerID) ? conversation.buyerName : conversation.sellerName
        yourName = (myUserID == conversation.buyerID) ? conversation.sellerName : conversation.buyerName
        
        senderId = String(myUserID)//JSQ defined var
        senderDisplayName = myName//JSQ defined
        
        
        self.navigationItem.title = yourName
//        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
//        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
//        activityIndicator.startAnimating()
//        self.view.addSubview(activityIndicator)
        
        if Foundation.URL(string: conversation.attractionImageURL) != nil{
            KingfisherManager.shared.retrieveImage(with: Foundation.URL(string: conversation.attractionImageURL)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                if image != nil{
                    self.avatarImage = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 50, height: 50)))
                }else{
                    self.collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
                }
            })
        }
        
        let dbMessages = coreDataHelper.getAllMessagesFromConversation(conversationID: conversation.ID) as! [cdMessageMO]
        
        if dbMessages.count > 0 {
            for i in 0 ..< dbMessages.count{
                let m = dbMessages[i]
                if (m.senderID as NSNumber).int64Value == self.myUserID{
                    self.addMessage(withId: String(m.senderID), name: self.myName, text: m.text!, timestamp: m.timestamp!)
                }else{
                    self.addMessage(withId: String(m.senderID), name: self.yourName, text: m.text!, timestamp: m.timestamp!)
                }
            }
            self.collectionView?.reloadData()
            
//            let height1 = self.navigationController?.navigationBar.frame.height
//            let height2 = self.inputToolbar.frame.height
//            if let h:CGFloat = height1 {
//                self.collectionView?.contentInset = UIEdgeInsetsMake(h*1.5, 0, height2, 0)
//            }
            //above isn't needed here for some reason...
            
            self.finishReceivingMessage()
            
            getNewMessages() //will start timer and has no delay
            //any messages in db should be read in server db so new messages will not repeat
            //need to implement session tokens on each device because right now using the app on multiple devices at the same time will be a disaster
            //multiple missed messages and your own message will only appear on device it's sent on
            
        }else{
            loadInitialMessages()
        }
        

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopNewMessageTimer()
        stopUpdateLastMessageTimer()
        hideConnectingNotification()
    }

    
    func loadInitialMessages(){
        let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.indeterminate
        loadingNotification.label.text = "Loading Messages"
        
        
        let _ = convoHelper.getInitialConversationMessagesRequest(conversationID: conversation.ID) { responseObject, error in
            
            loadingNotification.hide(animated: true)
            
            if responseObject != nil {
                // use responseObject and error here
                
                if let array = responseObject as? NSArray{
                    let tempMessages = self.convoHelper.parseMessagesFromNSArray(array: array)
                    if(tempMessages.count > 0){
                        self.updateLastReadMessage(messageID: tempMessages[tempMessages.count-1].ID, startNewMessageTimer: true)
                        self.messagesRaw = tempMessages
                        for i in 0 ..< self.messagesRaw.count{
                            let m = self.messagesRaw[i]
                            self.coreDataHelper.saveMessage(message: m)

                            if m.senderID == self.myUserID{
                                self.addMessage(withId: String(m.senderID), name: self.myName, text: m.text, timestamp: m.timestamp)
                            }else{
                                self.addMessage(withId: String(m.senderID), name: self.yourName, text: m.text, timestamp: m.timestamp)
                            }
                        }
                        self.collectionView?.reloadData()

                        let height1 = self.navigationController?.navigationBar.frame.height
                        let height2 = self.inputToolbar.frame.height
                        if let h:CGFloat = height1 {
                            self.collectionView?.contentInset = UIEdgeInsetsMake(h*1.5, 0, height2, 0)
                        }
                        
                        self.finishReceivingMessage()
                        
                    }
                }else{
                    //give option to try again
                    self.showAlertAndTryAgain(title: "Unable to load messages", text: "We were unable to retrieve your messages. Please check your internet connection and try again.")
                }
            }else{
                self.showAlertAndTryAgain(title: "Unable to load messages", text: "We were unable to retrieve your messages. Please check your internet connection and try again.")
            }
            return
        }
        
    }
    
    func updateLastReadMessage(messageID: Int64, startNewMessageTimer: Bool){//startnewmessagetimer
            self.convoHelper.updateLastReadMessageRequest(messageID: messageID, conversationID: self.conversation.ID, userID: self.myUserID){ responseObject, error in
                
                if error == nil{
                    if responseObject != "0" {
                        self.stopUpdateLastMessageTimer()//this will stop the timer started from startUpdateLastReadMessageIfError
                        if startNewMessageTimer{
                            self.startNewMessageTimer()//this will start the normal newMessage timer
                        }
                    }else{
                        self.stopNewMessageTimer()
                        self.stopUpdateLastMessageTimer()
                        self.startUpdateLastReadMessageTimerIfError(messageID: messageID)
                    }
                }else{//if last message not updated keep calling itself until it is updated so no duplicates and stop requesting new messages
                    self.stopNewMessageTimer()
                    self.stopUpdateLastMessageTimer()
                    self.startUpdateLastReadMessageTimerIfError(messageID: messageID)
                }
                return
            }
    }
    
    func startUpdateLastReadMessageTimerIfError(messageID: Int64){
        self.updateLastReadMessageTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.updateLastReadMessage(messageID: messageID, startNewMessageTimer: true)//startNewMessageTimer because this is only called if stopped
        }
    }
    
    func stopUpdateLastMessageTimer() {
        if updateLastReadMessageTimer != nil {
            self.updateLastReadMessageTimer?.invalidate()
            self.convoHelper.cancelAllRequests()
            taskWasCanceled = true;
        }
    }
    
    func startNewMessageTimer() {
        self.newMessageTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.getNewMessages()
        }
    }
    
    func initialStartNewMessageTimer(){
        if newMessageTimer == nil{
            startNewMessageTimer()
        }
    }
    
    func getNewMessages(){
        _ = convoHelper.getNewConversationMessagesRequest(conversationID: self.conversation.ID, userID: self.myUserID) { responseObject, error in
            
            if responseObject != nil {
                self.hideConnectingNotification()
                // use responseObject and error here
                
                if let array = responseObject as? NSArray{
                    let tempMessages = self.convoHelper.parseMessagesFromNSArray(array: array)
                    if(tempMessages.count > 0){
                        self.stopNewMessageTimer()//stop new messages while updating last read message
                        self.updateLastReadMessage(messageID: tempMessages[tempMessages.count-1].ID, startNewMessageTimer: true)//new message timer is started once last read message is updated
                        for i in 0 ..< tempMessages.count{
                            let m = tempMessages[i]
                            self.coreDataHelper.saveMessage(message: m)

                            if m.senderID == self.myUserID{
                                self.addMessage(withId: String(m.senderID), name: self.myName, text: m.text, timestamp: m.timestamp)
                            }else{
                                self.addMessage(withId: String(m.senderID), name: self.yourName, text: m.text, timestamp: m.timestamp)
                            }
                        }
                        //self.collectionView?.reloadItems(at: <#T##[IndexPath]#>)
                        
//                        let height1 = self.navigationController?.navigationBar.frame.height
//                        let height2 = self.inputToolbar.frame.height
//                        if let h:CGFloat = height1 {
//                            self.collectionView?.contentInset = UIEdgeInsetsMake(h*1.5, 0, height2, 0)
//                        }
                        
                        self.finishReceivingMessage()
                        
                    }else{
                        self.initialStartNewMessageTimer()
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
        if !taskWasCanceled{
            if isWhisperShowing == false{
                var connectingWhisper = Whisper.Message(title: "Reconnecting...", backgroundColor: UIColor.red)
                connectingWhisper.images = [UIImage(named: "no_connection")!]
                if navigationController != nil{
                    Whisper.show(whisper: connectingWhisper, to: navigationController!, action: .present)
                    isWhisperShowing = true
                }
            }
        }else{
            taskWasCanceled = false
        }
    }
    
    func hideConnectingNotification(){
        // Hide a message
        if navigationController != nil{
            Whisper.hide(whisperFrom: navigationController!)
            isWhisperShowing = false
        }
    }
    
    func stopNewMessageTimer() {
        if newMessageTimer != nil {
            self.newMessageTimer?.invalidate()
            self.convoHelper.cancelAllRequests()
            taskWasCanceled = true
        }
    }
    
    // MARK: JSQ Overrides

    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }

    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
        let message = messages[indexPath.item] // 1
        if message.senderId == senderId { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        return cell
    }

    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = messages[indexPath.item]
        let i = indexPath.item
        if i > 0 {
            let lastMessage = messages[indexPath.item - 1]
            let timeDiff = Calendar.autoupdatingCurrent.dateComponents([.minute], from: lastMessage.date, to: message.date)
            
            if timeDiff.minute! > 30{
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
//                paragraph.firstLineHeadIndent = collectionView.collectionViewLayout.messageBubbleLeftRightMargin
                let attributes = [NSParagraphStyleAttributeName: paragraph]
                
                return NSAttributedString(string: MiscHelper.formatMessageTimeBreakDate(date: message.date), attributes: attributes)
            }else{
                return nil
            }

        }else{
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
//            paragraph.firstLineHeadIndent = collectionView.collectionViewLayout.messageBubbleLeftRightMargin
            let attributes = [NSParagraphStyleAttributeName: paragraph]
            
            return NSAttributedString(string: "Conversation created: " + MiscHelper.formatMessageTimeBreakDate(date: self.conversation.creationTimeStamp), attributes: attributes)
        }
    
    }

    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.item]
        
        let i = indexPath.item
        if i > 0 {
            let lastMessage = messages[indexPath.item - 1]
            let timeDiff = Calendar.autoupdatingCurrent.dateComponents([.minute], from: lastMessage.date, to: message.date)
            
            if timeDiff.minute! > 30{
                return 20
            }else{
                return 0
            }
            
        }else{
            return 20
        }
        
    }
    
//
//
//    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellBottomLabelAt indexPath: IndexPath) -> NSAttributedString? {
//        let message = messages[indexPath.item]
//        if message.senderId != senderId() {
//            return NSAttributedString(string: "hi")
//        }else{
//            return NSAttributedString(string: "his")
//        }
//        //return nil
//    }
//
//    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellBottomLabelAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(20)
//    }
//
//    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellBottomLabelAt indexPath: IndexPath) -> NSAttributedString? {
//        let message = messages[indexPath.item]
//        if message.senderId != senderId {
//            let paragraph = NSMutableParagraphStyle()
//            paragraph.alignment = .left
//            paragraph.firstLineHeadIndent = collectionView.collectionViewLayout.messageBubbleLeftRightMargin
//
//            let attributes = [NSParagraphStyleAttributeName: paragraph]
//            let date = MiscHelper.dateToString(date: message.date, format: "h:mm")
//            return NSAttributedString(string: date, attributes: attributes)
//        }
//        return nil
//    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView?, avatarImageDataForItemAt indexPath: IndexPath?) -> JSQMessageAvatarImageDataSource? {
        let message = messages[(indexPath?.item)!]
        if message.senderId != senderId {
            return JSQMessagesAvatarImage(avatarImage: avatarImage, highlightedImage: avatarImage, placeholderImage: avatarImage!)
        }

        return nil
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71))
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        
        //sendlogic here
        stopNewMessageTimer()
        self.addMessage(withId: senderId, name: senderDisplayName, text: text, timestamp: date)
        self.finishSendingMessage(animated: true)
        convoHelper.sendConversationMessageRequest(conversationID: conversation.ID, senderID: myUserID, message: text){ responseObject, error in
            
            self.startNewMessageTimer()//start message timer again
            
            if error == nil{
                if responseObject != "-1" && responseObject != "" {
                    let date = Date.init()
                    
                    let m = Message()
                    m.ID = Int64(responseObject!)!
                    m.senderID = self.myUserID
                    m.conversationID = self.conversation.ID
                    m.text = text
                    m.timestamp = date
                    self.coreDataHelper.saveMessage(message: m)
                    //sent message isn't showing timebreak initially if after 30 minutes - only does once convo refreshed
                }else{
                    
                    self.messages.removeLast()
                    self.collectionView.reloadData()
                    
                    let notification = MBProgressHUD.showAdded(to: self.view, animated: true)
                    notification.mode = .text
                    notification.label.text = "Unable to send message"
                    notification.hide(animated: true, afterDelay: 3.0)
                }
            }else{
                self.messages.removeLast()
                self.collectionView.reloadData()
                
                let notification = MBProgressHUD.showAdded(to: self.view, animated: true)
                notification.mode = .text
                notification.label.text = "Unable to send message"
                notification.hide(animated: true, afterDelay: 3.0)

            }
            
            return
        }
    }
        

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func showAlertAndTryAgain(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Retry", style: .default, handler: { (action: UIAlertAction!) in
            self.loadInitialMessages()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }
    
    func showWhisper(message: String, color: UIColor){
        if self.navigationController != nil{
            let connectingWhisper = Whisper.Message(title: message, backgroundColor: color)
            Whisper.show(whisper: connectingWhisper, to: self.navigationController!, action: .show)
        }
    }
    
    private func addMessage(withId id: String, name: String, text: String, timestamp: Date) {
        let message = JSQMessage(senderId: id, senderDisplayName: name, date: timestamp, text: text)
        messages.append(message!)
    }

}
