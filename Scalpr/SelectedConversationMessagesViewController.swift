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

class SelectedConversationMessagesViewController: JSQMessagesViewController {
    
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    
    
    let convoHelper = ConversationHelper()
    let loginHelper = LoginHelper();
    
    var conversation = Conversation()
    var messagesRaw = [Message]()
    var messages = [JSQMessage]()
    var myUserID: Int64 = 0
    var myName: String = ""
    var yourName: String = ""
    var avatarImage: UIImage? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.inputToolbar.contentView?.leftBarButtonItem = nil
        // No avatars
        //collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        
        myUserID = (loginHelper?.getLoggedInUser().ID)!
        myName = (myUserID == conversation.buyerID) ? conversation.buyerName : conversation.sellerName
        yourName = (myUserID == conversation.buyerID) ? conversation.sellerName : conversation.buyerName
        
        self.navigationItem.title = yourName

//        if let h = self.navigationController?.navigationBar.frame.height{
//            let w = self.navigationController?.navigationBar.frame.width
//            let myView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: w!, height: h))
////            let title: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 300 - (h + 10), height: h))
////            title.text = self.yourName
////            title.textColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71)
////            //title.font = UIFont.boldSystemFont(ofSize: 20.0)
////            title.backgroundColor = UIColor.clear
////            myView.addSubview(title)
//            
//            if Foundation.URL(string: conversation.attractionImageURL) != nil{
//                KingfisherManager.shared.retrieveImage(with: Foundation.URL(string: conversation.attractionImageURL)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
//                    if image != nil{
//                        
//                        let tempH = h*0.9
//                        
//                        let myImageView: UIImageView = UIImageView(image: ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: tempH, height: tempH))))
//                        self.navigationController?.navigationBar.backIndicatorImage = image
//                        myImageView.frame = CGRect(x: w! - tempH, y: 0, width: tempH, height: tempH)
//                        myImageView.layer.masksToBounds = true
//                        myImageView.layer.borderColor = UIColor.lightGray.cgColor
//                        myImageView.layer.borderWidth = 0.1
//                        myView.backgroundColor = UIColor.clear
//                        myView.addSubview(myImageView)
//                    }
//                    
//                    self.navigationItem.titleView = myView
//                })
//            }else{
//                self.navigationItem.titleView = myView
//            }
//
//        }
        
        if Foundation.URL(string: conversation.attractionImageURL) != nil{
            KingfisherManager.shared.retrieveImage(with: Foundation.URL(string: conversation.attractionImageURL)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                if image != nil{
                    self.avatarImage = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 50, height: 50)))
                }
            })
        }

        
        
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
                        self.messagesRaw = tempMessages
                        for i in 0 ..< self.messagesRaw.count{
                            let m = self.messagesRaw[i]
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
                    self.showAlert(title: "Unable to load messages", text: "We were unable to retrieve your messages. Please check your internet connection and try again.")
                }
            }else{
                self.showAlert(title: "Unable to load messages", text: "We were unable to retrieve your messages. Please check your internet connection and try again.")
            }
            return
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
        if message.senderId == senderId() { // 2
            return outgoingBubbleImageView
        } else { // 3
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        
        if message.senderId == senderId() {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
//            cell.cellTopLabel?.text = MiscHelper.dateToString(date: message.date, format: "H:mm")
//            cell.cellTopLabel?.isHidden = false
        }
        return cell
    }
    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellBottomLabelAt indexPath: IndexPath) -> NSAttributedString? {
//        let message = messages[indexPath.item]
//        if message.senderId != senderId() {
//            return NSAttributedString(string: "hi")
//        }else{
//            return NSAttributedString(string: "his")
//        }
//        //return nil
//    }
    
//    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
//        let message = messages[indexPath.item]
//        if message.senderId != senderId() {
//            let paragraph = NSMutableParagraphStyle()
//            paragraph.alignment = .left
//            paragraph.firstLineHeadIndent = collectionView.collectionViewLayout.messageBubbleLeftRightMargin
//            
//            let attributes = [NSParagraphStyleAttributeName: paragraph]
//            return NSAttributedString(string: message.senderDisplayName, attributes: attributes)
//        }
//        return nil
//    }
//
//    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellBottomLabelAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(20)
//    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellBottomLabelAt indexPath: IndexPath) -> NSAttributedString? {
        let message = messages[indexPath.item]
        if message.senderId != senderId() {
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left
            paragraph.firstLineHeadIndent = collectionView.collectionViewLayout.messageBubbleLeftRightMargin
            
            let attributes = [NSParagraphStyleAttributeName: paragraph]
            let date = MiscHelper.dateToString(date: message.date, format: "h:mm")
            return NSAttributedString(string: date, attributes: attributes)
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(20)
    }
    
    override func senderId() -> String {
        return String(myUserID)
    }
    
    override func senderDisplayName() -> String {
        return myName
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView?, avatarImageDataForItemAt indexPath: IndexPath?) -> JSQMessageAvatarImageDataSource? {
        let message = messages[(indexPath?.item)!]
        if message.senderId != senderId() {
            return JSQMessagesAvatarImage(avatarImage: avatarImage, highlightedImage: avatarImage, placeholderImage: avatarImage!)
        }

        return nil
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory.outgoingMessagesBubbleImage(with: MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71))
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
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
                    self.addMessage(withId: senderId, name: senderDisplayName, text: text, timestamp: Date.init())
                
                    self.finishReceivingMessage()
                }else{
                    
                }
            }else{
                
            }
            
            return
        }
        

        
        finishSendingMessage() // 5
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
        messages.append(message)
    }

}
