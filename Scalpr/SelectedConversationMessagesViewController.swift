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
    var connectingNotification: MBProgressHUD? = nil
    

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
            
            startNewMessageTimer()//after loading db messages load new messages
            //any messages in db should be read in server db so new messages will not repeat
            //need to implement session tokens on each device because right now using the app on multiple devices at the same time will be a disaster
            //multiple missed messages and your own message will only appear on device it's sent on
            
        }else{
            loadInitialMessages()
        }
        

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        stopNewMessageTimer()
        stopUpdateLastMessageTimer()
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
                    self.showAlert(title: "Unable to load messages", text: "We were unable to retrieve your messages. Please check your internet connection and try again.")
                }
            }else{
                self.showAlert(title: "Unable to load messages", text: "We were unable to retrieve your messages. Please check your internet connection and try again.")
            }
            return
        }
        
    }
    
    func updateLastReadMessage(messageID: Int64, startNewMessageTimer: Bool){//startnewmessagetimer
            self.convoHelper.updateLastReadMessageRequest(messageID: messageID, conversationID: self.conversation.ID, userID: self.myUserID){ responseObject, error in
                
                if error == nil{
                    if responseObject != "0" {
                        if startNewMessageTimer{
                            self.startNewMessageTimer()
                        }
                    }else{
                        self.stopNewMessageTimer()
                        self.startUpdateLastReadMessageTimerIfError(messageID: messageID)
                    }
                }else{//if last message not updated keep calling itself until it is updated so no duplicates and stop requesting new messages
                    self.stopNewMessageTimer()
                    self.startUpdateLastReadMessageTimerIfError(messageID: messageID)
                }
                return
            }
    }
    
    func startUpdateLastReadMessageTimerIfError(messageID: Int64){
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { [weak self] _ in
            self?.updateLastReadMessage(messageID: messageID, startNewMessageTimer: true)//startNewMessageTimer because this is only called if stopped
        }
    }
    
    func stopUpdateLastMessageTimer() {
        self.newMessageTimer?.invalidate()
    }
    
    func startNewMessageTimer() {
        self.newMessageTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.getNewMessages()
        }
    }
    
    func getNewMessages(){
        let request = convoHelper.getNewConversationMessagesRequest(conversationID: self.conversation.ID, userID: self.myUserID) { responseObject, error in
            
            if responseObject != nil {
                self.hideConnectingNotification()
                // use responseObject and error here
                
                if let array = responseObject as? NSArray{
                    let tempMessages = self.convoHelper.parseMessagesFromNSArray(array: array)
                    if(tempMessages.count > 0){
                        self.updateLastReadMessage(messageID: tempMessages[tempMessages.count-1].ID, startNewMessageTimer: false)//false because timer already started
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
        if self.connectingNotification == nil {
            self.connectingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
            self.connectingNotification?.mode = MBProgressHUDMode.indeterminate
            self.connectingNotification?.label.text = "Connecting..."
        }else{
            self.connectingNotification?.show(animated: true)
        }
    }
    
    func hideConnectingNotification(){
        if self.connectingNotification != nil {
            self.connectingNotification?.hide(animated: true)
        }
    }
    
    func stopNewMessageTimer() {
        self.newMessageTimer?.invalidate()
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
        convoHelper.sendConversationMessageRequest(conversationID: conversation.ID, senderID: myUserID, message: text){ responseObject, error in
            
            if error == nil{
                if responseObject != "-1" {
                    let date = Date.init()
                    
                    self.addMessage(withId: senderId, name: senderDisplayName, text: text, timestamp: date)
                    //sent message isn't showing timebreak initially if after 30 minutes - only does once convo refreshed
                    
                    self.finishSendingMessage()
                }else{
                    self.showAlert(title: "Unable to send message", text: "Please check your internet connection and try again.")
                }
            }else{
                self.showAlert(title: "Unable to send message", text: "Please check your internet connection and try again.")
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
    
    func showAlert(title: String, text: String){
        let refreshAlert = UIAlertController(title: title, message: text, preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }
    
    private func addMessage(withId id: String, name: String, text: String, timestamp: Date) {
        let message = JSQMessage(senderId: id, senderDisplayName: name, date: timestamp, text: text)
        messages.append(message!)
    }

}
